import 'package:flutter/material.dart';
import 'package:submarine_flutter/theme.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.isListening,
    required this.pulseController,
    required this.onTap,
  });

  final bool isListening;
  final AnimationController pulseController;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening)
            AnimatedBuilder(
              animation: pulseController,
              builder: (_, __) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Opacity(
                        opacity: (1 - (pulseController.value + i * 0.33) % 1.0)
                            .clamp(0, 0.5),
                        child: SizedBox(
                          width: 96 +
                              ((pulseController.value + i * 0.33) % 1.0) * 60,
                          height: 96 +
                              ((pulseController.value + i * 0.33) % 1.0) * 60,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.4),
                                  width: 1.5),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isListening
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.accentDim,
                border: Border.all(
                  color: isListening
                      ? AppColors.accent
                      : AppColors.accent.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                isListening ? Icons.mic_off : Icons.mic,
                color: AppColors.accent,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
