import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:submarine_flutter/screens/login/widgets/voice/mic_button.dart';
import 'package:submarine_flutter/services/auth_api_service.dart';
import 'package:submarine_flutter/theme.dart';
import 'package:submarine_flutter/utils/audio_file.dart';
import '../../../../l10n/translations.dart';
import '../../../../providers/app_provider.dart';

class Voice extends StatefulWidget {
  const Voice({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<Voice> createState() => _VoiceState();
}

class _VoiceState extends State<Voice> with TickerProviderStateMixin {
  final _authApi = AuthApiService();
  final _audioRecorder = AudioRecorder();

  String _error = '';
  bool _isListening = false;
  bool _isVerifying = false;
  String _transcript = '';
  String _voiceStatus = '';
  String? _recordPath;

  late AnimationController _pulseCtrl;
  late stt.SpeechToText _speech;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _speech.stop();
    _audioRecorder.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (_isVerifying) return;
    _speech.stop();
    _audioRecorder.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    widget.onBack();
  }

  Future<void> _startVoiceRecognition(AppTranslations t, Lang lang) async {
    if (_isVerifying) return;

    if (kIsWeb) {
      setState(() => _voiceStatus = t.voiceNotSupported);
      return;
    }

    if (!await _audioRecorder.hasPermission()) {
      setState(() => _voiceStatus = t.voiceNotSupported);
      return;
    }

    if (!_speechAvailable) {
      setState(() => _voiceStatus = t.voiceNotSupported);
      return;
    }

    final dir = await getTemporaryDirectory();
    final path =
        '${dir.path}/voice_login_${DateTime.now().millisecondsSinceEpoch}.wav';

    await _audioRecorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    _recordPath = path;

    setState(() {
      _isListening = true;
      _voiceStatus = t.listening;
      _transcript = '';
      _error = '';
    });
    _pulseCtrl.repeat();

    await _speech.listen(
      localeId: lang == Lang.vi ? 'vi_VN' : 'en_US',
      onResult: (result) {
        setState(() => _transcript = result.recognizedWords);
      },
    );
  }

  Future<void> _stopAndVerify(AppTranslations t, Lang lang) async {
    if (!_isListening || _isVerifying) return;

    _speech.stop();
    final recordedPath = await _audioRecorder.stop();
    _pulseCtrl.stop();
    _pulseCtrl.reset();

    final path = recordedPath ?? _recordPath;
    if (path == null) {
      setState(() {
        _isListening = false;
        _voiceStatus = t.pressmic;
        _error = t.voiceVerifyFailed;
      });
      return;
    }

    setState(() {
      _isListening = false;
      _isVerifying = true;
      _voiceStatus = t.verifying;
      _error = '';
    });

    try {
      final bytes = await readAudioBytes(path);
      if (bytes.isEmpty) {
        setState(() {
          _error = t.voiceVerifyFailed;
          _voiceStatus = t.pressmic;
        });
        return;
      }

      final result = await _authApi.voiceLogin(
        audioBytes: bytes,
        language: lang == Lang.vi ? 'vi' : 'en',
      );
      if (!mounted) return;

      if (result.success && result.data != null) {
        setState(() => _voiceStatus = t.authSuccess);
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        context.read<AppProvider>().login(
              token: result.data!.token,
              username: result.data!.username,
              name: result.data!.name,
              role: result.data!.role,
            );
        return;
      }

      setState(() {
        _error = result.message ?? t.voiceVerifyFailed;
        _voiceStatus = t.voiceVerifyFailed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = t.networkError;
        _voiceStatus = t.pressmic;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          if (!_isListening && _error.isEmpty) {
            _voiceStatus = t.pressmic;
          }
        });
      }
      await deleteAudioFile(path);
    }
  }

  void _stopListening(AppTranslations t, Lang lang) {
    _stopAndVerify(t, lang);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final t = appProvider.t;
    final lang = appProvider.lang;

    if (_voiceStatus.isEmpty) _voiceStatus = t.pressmic;

    final busy = _isListening || _isVerifying;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: busy ? null : _handleBack,
            child: Text(t.back,
                style: const TextStyle(color: AppColors.muted, fontSize: 14)),
          ),
        ),
        const SizedBox(height: 16),
        Text(t.sayPhrase,
            style: const TextStyle(color: AppColors.muted, fontSize: 15)),
        const SizedBox(height: 16),
        const SizedBox(height: 16),
        MicButton(
          isListening: _isListening || _isVerifying,
          pulseController: _pulseCtrl,
          onTap: () => _isListening
              ? _stopListening(t, lang)
              : _startVoiceRecognition(t, lang),
        ),
        const SizedBox(height: 16),
        Text(_voiceStatus,
            style: const TextStyle(color: AppColors.muted, fontSize: 15)),
        if (_transcript.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              '"$_transcript"',
              style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontStyle: FontStyle.italic),
            ),
          ),
        ],
        if (_error.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_error,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
