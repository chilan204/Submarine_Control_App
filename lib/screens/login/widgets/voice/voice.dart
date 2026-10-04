import 'dart:async';
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
import '../../../../utils/recording_lifecycle.dart';
import '../../../../utils/stop_recording.dart';

class Voice extends StatefulWidget {
  const Voice({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<Voice> createState() => _VoiceState();
}

class _VoiceState extends State<Voice> with TickerProviderStateMixin {
  final _authApi = AuthApiService();
  final _audioRecorder = AudioRecorder();
  final _recording = RecordingLifecycle();

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
    try {
      final available = await _speech.initialize();
      if (mounted) _speechAvailable = available;
    } catch (e) {
      debugPrint('[VoiceLogin] Speech initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    unawaited(_recording.dispose(_releaseRecorder).catchError((Object e) {
      debugPrint('[VoiceLogin] Recorder cleanup failed: $e');
    }));
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

  void _handleBack() {
    if (_isVerifying || _isListening || _recording.isStarting) return;
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    widget.onBack();
  }

  Future<void> _startVoiceRecognition(AppTranslations t, Lang lang) async {
    if (_isVerifying || !mounted || !_recording.beginStart()) return;
    setState(() => _error = '');
    try {
      await _recording.track(() async {
        if (kIsWeb) {
          setState(() => _voiceStatus = t.voiceNotSupported);
          return;
        }

        final permitted = await _audioRecorder.hasPermission();
        if (!mounted) return;
        if (!permitted) {
          setState(() => _voiceStatus = t.voiceNotSupported);
          return;
        }

        final dir = await getTemporaryDirectory();
        if (!mounted) return;
        final path =
            '${dir.path}/voice_login_${DateTime.now().millisecondsSinceEpoch}.wav';
        _recordPath = path;

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
          ),
          path: path,
        );
        if (!mounted) return;

        if (_speechAvailable) {
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
        }
        _recording.started();
        setState(() {
          _isListening = true;
          _voiceStatus = t.listening;
          _transcript = '';
          _error = '';
        });
        _pulseCtrl.repeat();
      });
    } catch (e) {
      debugPrint('[VoiceLogin] Recording start failed: $e');
      if (mounted) {
        try {
          await _recording.track(() async {
            await stopRecording(
                stopSpeech: _speech.stop, stopRecorder: _audioRecorder.stop);
            final path = _recordPath;
            _recordPath = null;
            if (path != null) await deleteAudioFile(path);
          });
        } catch (cleanupError) {
          debugPrint('[VoiceLogin] Start cleanup failed: $cleanupError');
        }
        if (mounted) setState(() => _error = t.voiceVerifyFailed);
      }
    } finally {
      if (_recording.isStarting) _recording.finish();
      if (mounted) setState(() {});
    }
  }

  Future<void> _stopAndVerify(AppTranslations t, Lang lang) async {
    if (!_isListening || _isVerifying || !_recording.beginStop()) return;
    // Lock before stopping either plugin: a second tap must not submit twice.
    setState(() {
      _isListening = false;
      _isVerifying = true;
      _voiceStatus = t.verifying;
      _error = '';
    });
    _pulseCtrl.stop();
    _pulseCtrl.reset();
    var path = _recordPath;
    _recordPath = null;
    try {
      path = await _recording.track(() async {
            return await stopRecording(
                stopSpeech: _speech.stop, stopRecorder: _audioRecorder.stop);
          }) ??
          path;
      if (!mounted) return;
      if (path == null) {
        setState(() {
          _isListening = false;
          _voiceStatus = t.pressmic;
          _error = t.voiceVerifyFailed;
        });
        return;
      }

      final bytes = await readAudioBytes(path);
      if (!mounted) return;
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
              token: result.data!.token!,
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
      _recording.finish();
      if (mounted) {
        setState(() {
          _isVerifying = false;
          if (!_isListening && _error.isEmpty) {
            _voiceStatus = t.pressmic;
          }
        });
      }
      if (path != null) await deleteAudioFile(path);
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

    final busy = _isListening || _isVerifying || _recording.isStarting;

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
          onTap: _isVerifying || _recording.isStarting
              ? null
              : () => _isListening
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
                    style: const TextStyle(color: AppColors.red, fontSize: 12)),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
