import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../../translations/translations.dart';
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

// Command parsing — mirrors parseCommand() in VoiceControlScreen.tsx
Map<String, dynamic> _parseCommand(String text, Lang lang) {
  final lower = text.toLowerCase();
  final cmdsVi = <String, Map<String, dynamic>>{
    'lặn xuống': {'response': 'Đang thực hiện lặn xuống. Độ sâu mục tiêu: -50m', 'status': CommandStatus.success},
    'nổi lên': {'response': 'Đang nổi lên. Độ sâu mục tiêu: 0m', 'status': CommandStatus.success},
    'tiến': {'response': 'Động cơ đẩy kích hoạt. Tốc độ 5 hải lý/h', 'status': CommandStatus.success},
    'dừng': {'response': 'Hệ thống đẩy dừng. Giữ vị trí hiện tại', 'status': CommandStatus.success},
    'quay trái': {'response': 'Bánh lái trái 15°. Đang điều hướng', 'status': CommandStatus.success},
    'quay phải': {'response': 'Bánh lái phải 15°. Đang điều hướng', 'status': CommandStatus.success},
    'phóng ngư lôi': {'response': 'CẢNH BÁO: Cần xác nhận từ chỉ huy cấp cao', 'status': CommandStatus.warning},
    'tàng hình': {'response': 'Hệ thống âm học tắt. Chế độ im lặng kích hoạt', 'status': CommandStatus.success},
    'kiểm tra': {'response': 'Tất cả hệ thống bình thường. Pin: 87%. Oxy: 94%', 'status': CommandStatus.success},
    'khẩn cấp': {'response': 'KHẨN CẤP: Thổi két nước dằn. Nổi lên khẩn cấp!', 'status': CommandStatus.error},
  };
  final cmdsEn = <String, Map<String, dynamic>>{
    'dive': {'response': 'Executing dive. Target depth: -50m', 'status': CommandStatus.success},
    'surface': {'response': 'Surfacing. Target depth: 0m', 'status': CommandStatus.success},
    'forward': {'response': 'Propulsion engaged. Speed: 5 knots', 'status': CommandStatus.success},
    'stop': {'response': 'Propulsion stopped. Holding current position', 'status': CommandStatus.success},
    'turn left': {'response': 'Rudder left 15°. Navigating', 'status': CommandStatus.success},
    'turn right': {'response': 'Rudder right 15°. Navigating', 'status': CommandStatus.success},
    'torpedo': {'response': 'WARNING: Requires senior command confirmation', 'status': CommandStatus.warning},
    'stealth': {'response': 'Acoustic systems off. Silent mode activated', 'status': CommandStatus.success},
    'check': {'response': 'All systems normal. Battery: 87%. Oxygen: 94%', 'status': CommandStatus.success},
    'emergency': {'response': 'EMERGENCY: Blowing ballast tanks. Emergency ascent!', 'status': CommandStatus.error},
  };

  final cmds = lang == Lang.vi ? cmdsVi : cmdsEn;
  for (final entry in cmds.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return lang == Lang.vi
      ? {'response': 'Lệnh nhận được: "$text". Đang xử lý...', 'status': CommandStatus.success}
      : {'response': 'Command received: "$text". Processing...', 'status': CommandStatus.success};
}

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
  double _heading = 247;
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
    final lang = provider.lang;
    final result = _parseCommand(text, lang);
    final cmd = Command(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      timestamp: DateTime.now(),
      status: result['status'] as CommandStatus,
      response: result['response'] as String,
    );
    provider.addCommand(cmd);

    // Metrics are now driven by WebSocket telemetry — no local mutation
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
        localeId: lang == Lang.vi ? 'vi_VN' : 'en_US',
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