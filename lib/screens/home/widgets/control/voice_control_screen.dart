import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../l10n/translations.dart';
import '../../../../models/command.dart';
import '../../../../models/voice_command_response.dart';
import '../../../../providers/app_provider.dart';
import '../../../../services/telemetry_service.dart';
import '../../../../services/voice_command_service.dart';
import '../../../../utils/audio_file.dart';
import 'widgets/status_bar.dart';
import '../metrics_panel.dart';
import 'widgets/command_log.dart';
import 'widgets/input_area.dart';

class VoiceControlScreen extends StatefulWidget {
  const VoiceControlScreen({super.key});

  @override
  State<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends State<VoiceControlScreen> {
  final List<Command> _commands = [];
  bool _isListening = false;
  bool _isSending = false;
  String _transcript = '';
  String _inputText = '';
  String _status = '';
  double _depth = -35;
  double _speed = 4.2;
  double _heading = 60;
  double _pressure = 3.5;

  late stt.SpeechToText _speech;
  bool _speechReady = false;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();

  // Audio recording for WAV capture
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _recordPath;
  final VoiceCommandService _voiceCommandService = VoiceCommandService();

  // WebSocket telemetry — shared data source with GpsMapScreen
  late final TelemetryService _telemetry;
  StreamSubscription<TelemetryData>? _telemetrySub;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    // Connect to WebSocket for real-time telemetry
    _telemetry = TelemetryService();
    _telemetry.connect();
    _telemetrySub = _telemetry.stream.listen(_onTelemetryData);
  }

  Future<void> _initSpeech() async {
    _speechReady = await _speech.initialize();
  }

  /// Update metrics from WebSocket telemetry data.
  void _onTelemetryData(TelemetryData data) {
    if (!mounted) return;
    setState(() {
      _depth = data.depth;
      _speed = data.speed;
      _heading = data.heading;
      _pressure = data.pressure;
    });
  }

  @override
  void dispose() {
    _telemetrySub?.cancel();
    _telemetry.dispose();
    _speech.stop();
    _audioRecorder.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _addCommand(String text, AppProvider provider) {
    final cmd = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      status: CommandStatus.success,
      response: '',
    );
    provider.addCommand(cmd);

    setState(() {
      _commands.add(cmd);
    });
    _scrollToBottom();
  }

  Future<void> _startListening(AppProvider provider) async {
    if (_isSending) return;
    final lang = provider.lang;

    // Start WAV recording in parallel with speech-to-text
    if (!kIsWeb) {
      try {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path =
              '${dir.path}/voice_cmd_${DateTime.now().millisecondsSinceEpoch}.wav';
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1,
            ),
            path: path,
          );
          _recordPath = path;
        }
      } catch (e) {
        debugPrint('[VoiceControl] Record start error: $e');
      }
    }

    setState(() {
      _isListening = true;
      _status = provider.t.listeningCmd;
    });

    if (_speechReady) {
      await _speech.listen(
        listenOptions: stt.SpeechListenOptions(
          localeId: lang == Lang.vi ? 'vi_VN' : 'en_US',
        ),
        onResult: (result) {
          setState(() => _transcript = result.recognizedWords);
        },
      );
    }
  }

  Future<void> _stopListening(AppProvider provider) async {
    if (!_isListening || _isSending) return;

    _speech.stop();
    final recordedPath = await _audioRecorder.stop();
    final path = recordedPath ?? _recordPath;
    final capturedTranscript = _transcript;

    setState(() {
      _isListening = false;
      _isSending = true;
      _transcript = '';
      _status = provider.t.sendingAudio;
    });

    // If we have a WAV file AND an auth token, send to backend
    if (path != null && provider.authToken != null) {
      try {
        final bytes = await readAudioBytes(path);
        if (bytes.isNotEmpty) {
          setState(() => _status = provider.t.processingCmd);
          final result = await _voiceCommandService.sendVoiceCommand(
            audioBytes: bytes,
            token: provider.authToken!,
            language: provider.lang == Lang.vi ? 'vi' : 'en',
          );
          if (mounted) {
            _handleApiResponse(result, capturedTranscript, provider);
          }
        } else {
          // Empty audio file — fallback to local parsing
          if (capturedTranscript.isNotEmpty) {
            _addCommand(capturedTranscript, provider);
          }
        }
      } catch (e) {
        debugPrint('[VoiceControl] Send error: $e');
        // Fallback to local parsing on network error
        if (capturedTranscript.isNotEmpty && mounted) {
          _addCommand(capturedTranscript, provider);
        }
      } finally {
        await deleteAudioFile(path);
      }
    } else {
      // No recording or no token — fallback to local parsing
      if (capturedTranscript.isNotEmpty) {
        _addCommand(capturedTranscript, provider);
      }
    }

    if (mounted) {
      setState(() {
        _isSending = false;
        _status = provider.t.systemReady;
      });
    }
  }

  void _handleApiResponse(
    VoiceCommandResult result,
    String transcript,
    AppProvider provider,
  ) {
    final t = provider.t;
    final data = result.data;
    final status = data?.status ?? '';

    // Determine command status and response message
    CommandStatus cmdStatus;
    String response;

    if (result.success && status == 'EXECUTED') {
      cmdStatus = CommandStatus.success;
      final detail = data?.command;
      response = detail != null
          ? '${t.cmdExecuted}: ${detail.action ?? ''} ${detail.direction ?? ''} ${detail.value ?? ''}'
              .trim()
          : t.cmdExecuted;
    } else if (status == 'SPEAKER_VERIFICATION_FAILED') {
      cmdStatus = CommandStatus.error;
      response = t.speakerFailed;
    } else if (status == 'ROLE_DENIED') {
      cmdStatus = CommandStatus.warning;
      response = '${t.roleDenied} (${data?.role ?? ""})';
    } else if (status == 'INVALID_COMMAND') {
      cmdStatus = CommandStatus.warning;
      response = t.invalidCommand;
    } else {
      cmdStatus = CommandStatus.error;
      response = result.message ?? t.cmdRejected;
    }

    final cmd = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: data?.text ?? transcript,
      timestamp: DateTime.now(),
      status: cmdStatus,
      response: response,
    );

    provider.addCommand(cmd);
    setState(() => _commands.add(cmd));
    _scrollToBottom();
  }

  void _sendTextCommand(AppProvider provider) {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _addCommand(text, provider);
    _textCtrl.clear();
    setState(() => _inputText = '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final t = provider.t;
    if (_status.isEmpty) _status = t.systemReady;

    return Column(
      children: [
        StatusBar(
          status: _status,
          isListening: _isListening,
        ),

        MetricsPanel(
          t: t,
          depth: _depth,
          speed: _speed,
          heading: _heading,
          pressure: _pressure,
        ),

        Expanded(
          child: CommandLog(
            commands: _commands,
            transcript: _transcript,
            scrollController: _scrollCtrl,
            t: t,
            emptyMessage: provider.lang == Lang.vi
              ? 'Nhấn microphone hoặc nhập lệnh để điều khiển tàu ngầm'
              : 'Press microphone or type a command to control the submarine',
          )
        ),

        InputArea(
          t: t,
          isListening: _isListening,
          isSending: _isSending,
          inputText: _inputText,
          textController: _textCtrl,

          onMicTap: _isSending
              ? null
              : () => _isListening
              ? _stopListening(provider)
              : _startListening(provider),

          onSendTap: () => _sendTextCommand(provider),

          onChanged: (value) {
            setState(() {
              _inputText = value;
            });
          },

          onSubmitted: (_) {
            _sendTextCommand(provider);
          },
        ),
      ],
    );
  }
}