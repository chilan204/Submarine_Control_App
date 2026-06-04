import 'package:flutter/material.dart';

import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';
import '../../../../../widgets/sound_bars.dart';
import 'mic_button.dart';

class InputArea extends StatelessWidget {
  final AppTranslations t;

  final bool isListening;
  final bool isSending;

  final String inputText;

  final TextEditingController textController;

  final VoidCallback? onMicTap;
  final VoidCallback? onSendTap;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  const InputArea({
    super.key,
    required this.t,
    required this.isListening,
    required this.isSending,
    required this.inputText,
    required this.textController,
    required this.onMicTap,
    required this.onSendTap,
    this.onChanged,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final sendDisabled =
        isListening || isSending || inputText.trim().isEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.7),
        border: const Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              MicButton(
                isListening: isListening || isSending,
                onTap: onMicTap,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: isListening
                    ? Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                    AppColors.surfaceAlt.withValues(alpha: 0.8),
                    borderRadius:
                    BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: const Center(
                    child: SoundBars(),
                  ),
                )
                    : TextField(
                  controller: textController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                  ),
                  decoration: InputDecoration(
                    hintText: t.enterCmd,
                  ),
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: sendDisabled ? null : onSendTap,
                child: Opacity(
                  opacity: sendDisabled ? 0.3 : 1,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentDim,
                      border: Border.all(
                        color: AppColors.border,
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}