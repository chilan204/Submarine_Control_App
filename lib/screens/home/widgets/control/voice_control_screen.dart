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
import '../../../../theme.dart';
import '../../../../utils/audio_file.dart';
import '../../../../utils/recording_lifecycle.dart';
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
  bool _hasData = false;
  bool _wsConnected = false;
  double _depth = 0.0;
  double _speed = 0.0;
  double _heading = 0.0;
  double _pressure = 0.0;

  late stt.SpeechToText _speech;
  bool _speechReady = false;
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _textCtrl = TextEditingController();

  // Audio recording for WAV capture
  final AudioRecorder _audioRecorder = AudioRecorder();
  final RecordingLifecycle _recording = RecordingLifecycle();
  String? _recordPath;
  final VoiceCommandService _voiceCommandService = VoiceCommandService();

  // WebSocket telemetry — shared data source with GpsMapScreen
  late final TelemetryService _telemetry;
  StreamSubscription<TelemetryData>? _telemetrySub;
  StreamSubscription<bool>? _statusSub;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();

    // Connect to WebSocket for real-time telemetry
    _telemetry = TelemetryService();
    _telemetrySub = _telemetry.stream.listen(_onTelemetryData);
    _statusSub = _telemetry.statusStream.listen((connected) {
      if (!mounted) return;
      setState(() {
        _wsConnected = connected;
        if (!connected) {
          _hasData = false;
        }
      });
    });
    _telemetry.connect(context.read<AppProvider>().authToken);
  }

  Future<void> _initSpeech() async {
    try {
      final ready = await _speech.initialize();
      if (mounted) _speechReady = ready;
    } catch (e) {
      debugPrint('[VoiceControl] Speech initialization failed: $e');
    }
  }

  /// Update metrics from WebSocket telemetry data.
  void _onTelemetryData(TelemetryData data) {
    if (!mounted) return;
    setState(() {
      _hasData = true;
      _depth = data.depth;
      _speed = data.speed;
      _heading = data.heading;
      _pressure = data.pressure;
    });
  }

  @override
  void dispose() {
    _statusSub?.cancel();
    _telemetrySub?.cancel();
    _telemetry.disconnect();
    unawaited(_recording.dispose(_releaseRecorder).catchError((Object e) {
      debugPrint('[VoiceControl] Recorder cleanup failed: $e');
    }));
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _releaseRecorder() async {
    try {
      await _speech.stop();
    } finally {
      try {
        await _audioRecorder.stop();
      } finally {
        await _audioRecorder.dispose();
        final path = _recordPath;
        _recordPath = null;
        if (path != null) await deleteAudioFile(path);
      }
    }
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

  void _addUnsentCommand(String text, AppProvider provider) {
    final cmd = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      status: CommandStatus.error,
      response: provider.lang == Lang.vi
          ? 'Lệnh chưa được gửi đến AUV.'
          : 'The command was not sent to the AUV.',
    );
    provider.addCommand(cmd);

    // Metrics are now driven by WebSocket telemetry — no local mutation
    setState(() {
      _commands.add(cmd);
    });
    _scrollToBottom();
  }

  Future<void> _startListening(AppProvider provider) async {
    if (_isSending || !mounted || !_recording.beginStart()) return;
    final lang = provider.lang;
    final token = provider.authToken;
    _recordPath = null;
    setState(() => _transcript = '');
    try {
      await _recording.track(() async {
        if (!kIsWeb) {
          final permitted = await _audioRecorder.hasPermission();
          if (!mounted || provider.authToken != token) return;
          if (!permitted) throw StateError('Microphone permission denied');
          final dir = await getTemporaryDirectory();
          if (!mounted || provider.authToken != token) return;
          _recordPath =
              '${dir.path}/voice_cmd_${DateTime.now().millisecondsSinceEpoch}.wav';
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.wav,
              sampleRate: 16000,
              numChannels: 1,
            ),
            path: _recordPath!,
          );
          if (!mounted) return;
          if (provider.authToken != token) throw StateError('Session changed');
        }
        if (_speechReady) {
          await _speech.listen(
            listenOptions: stt.SpeechListenOptions(
              localeId: lang == Lang.vi ? 'vi_VN' : 'en_US',
            ),
            onResult: (result) {
              if (mounted && _isListening) {
                setState(() => _transcript = result.recognizedWords);
              }
            },
          );
          if (!mounted) return;
          if (provider.authToken != token) throw StateError('Session changed');
        }
        _recording.started();
        setState(() {
          _isListening = true;
          _status = provider.t.listeningCmd;
        });
      });
    } catch (e) {
      debugPrint('[VoiceControl] Record start error: $e');
      if (mounted) {
        try {
          await _recording.track(() async {
            await _speech.stop();
            await _audioRecorder.stop();
            final path = _recordPath;
            _recordPath = null;
            if (path != null) await deleteAudioFile(path);
          });
        } catch (cleanupError) {
          debugPrint('[VoiceControl] Start cleanup failed: $cleanupError');
        }
        if (mounted) setState(() => _status = provider.t.voiceNotSupported);
      }
    } finally {
      if (_recording.isStarting) _recording.finish();
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopListening(AppProvider provider) async {
    if (!_isListening || _isSending || !_recording.beginStop()) return;
    final token = provider.authToken;
    final language = provider.lang == Lang.vi ? 'vi' : 'en';
    final metadata = CommandRequestMetadata.create();
    var path = _recordPath;
    _recordPath = null;
    final capturedTranscript = _transcript;

    // Lock before the first await so rapid taps cannot submit the recording twice.
    setState(() {
      _isListening = false;
      _isSending = true;
      _transcript = '';
      _status = provider.t.sendingAudio;
    });

    try {
      path = await _recording.track(() async {
            await _speech.stop();
            return await _audioRecorder.stop();
          }) ??
          path;
      if (!mounted || provider.authToken != token) return;
      if (path != null && token != null) {
        final bytes = await readAudioBytes(path);
        if (!mounted || provider.authToken != token) return;
        if (bytes.isNotEmpty) {
          setState(() => _status = provider.t.processingCmd);
          final result = await _voiceCommandService.sendVoiceCommand(
            audioBytes: bytes,
            token: token,
            language: language,
            metadata: metadata,
          );
          if (mounted && provider.authToken == token) {
            _handleApiResponse(result, capturedTranscript, provider);
          }
        } else {
          // Never report success for a command that was not sent to the server.
          if (capturedTranscript.isNotEmpty) {
            _addUnsentCommand(capturedTranscript, provider);
          }
        }
      } else if (capturedTranscript.isNotEmpty) {
        // No recording or no token means nothing reached the server.
        _addUnsentCommand(capturedTranscript, provider);
      }
    } catch (e) {
      debugPrint('[VoiceControl] Recording error: $e');
      if (capturedTranscript.isNotEmpty &&
          mounted &&
          provider.authToken == token) {
        _addUnsentCommand(capturedTranscript, provider);
      }
    } finally {
      try {
        if (path != null) await deleteAudioFile(path);
      } finally {
        _recording.finish();
        if (mounted) {
          setState(() {
            _isSending = false;
            _status = provider.t.systemReady;
          });
        }
      }
    }
  }

  void _handleApiResponse(
    VoiceCommandResult result,
    String transcript,
    AppProvider provider,
  ) {
    if (result.unauthorized) {
      provider.logout();
      return;
    }

    final t = provider.t;
    final data = result.data;
    final status = data?.status ?? '';

    // Determine command status and response message
    CommandStatus cmdStatus;
    String response;

    if (result.success && status == 'SENT_UNCONFIRMED') {
      cmdStatus = CommandStatus.warning;
      final detail = data?.command;
      response = detail != null
          ? '${provider.lang == Lang.vi ? 'Đã gửi (chưa xác nhận AUV)' : 'Sent (AUV unconfirmed)'}: ${detail.action ?? ''} ${detail.direction ?? ''}'
              .trim()
          : (provider.lang == Lang.vi
              ? 'Đã gửi, chưa xác nhận AUV'
              : 'Sent, AUV unconfirmed');
    } else if (status == 'COMMAND_EXPIRED') {
      cmdStatus = CommandStatus.warning;
      response = provider.lang == Lang.vi
          ? 'Lệnh đã hết hạn; không gửi thêm đến AUV.'
          : 'Command expired; no further transmission to the AUV.';
    } else if (status == 'DUPLICATE_REQUEST' || status == 'OUTCOME_UNKNOWN') {
      cmdStatus = CommandStatus.warning;
      response = provider.lang == Lang.vi
          ? 'Chưa xác định được kết quả gửi lệnh. Kiểm tra trạng thái AUV trước khi ra lệnh mới.'
          : 'Transmission outcome unknown. Check the AUV before issuing a new command.';
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

    if (data?.auditSaved == false) {
      response += provider.lang == Lang.vi
          ? ' Không lưu được lịch sử trên máy chủ; không gửi lại lệnh chỉ để lưu lịch sử.'
          : ' Server history could not be saved; do not resend just to save history.';
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
    _addUnsentCommand(text, provider);
    _textCtrl.clear();
    setState(() => _inputText = '');
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final lang = provider.lang;
    final t = provider.t;
    if (_status.isEmpty ||
        _status == 'Hệ thống sẵn sàng' ||
        _status == 'System ready') {
      _status = t.systemReady;
    }

    if (!_hasData) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              lang == Lang.vi
                  ? 'Đang chờ dữ liệu tàu ngầm...'
                  : 'Waiting for submarine data...',
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Text(
              _wsConnected
                  ? (lang == Lang.vi
                      ? 'Trạng thái: Đã kết nối máy chủ'
                      : 'Status: Connected to server')
                  : (lang == Lang.vi
                      ? 'Trạng thái: Đang kết nối...'
                      : 'Status: Connecting...'),
              style: TextStyle(
                color: _wsConnected ? AppColors.accent : AppColors.amber,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        StatusBar(status: _status, isListening: _isListening),
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
                ? 'Nhấn microphone hoặc nhập lệnh để điều khiển AUV'
                : 'Press microphone or type a command to control the AUV',
          ),
        ),
        InputArea(
          t: t,
          isListening: _isListening,
          isSending: _isSending || _recording.isStarting,
          inputText: _inputText,
          textController: _textCtrl,
          onMicTap: _isSending || _recording.isStarting
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
