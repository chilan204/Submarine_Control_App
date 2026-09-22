import 'package:flutter/material.dart';

import '../../../../../theme.dart';

class StatusBar extends StatelessWidget {
  final String status;
  final bool isListening;

  const StatusBar({
    super.key,
    required this.status,
    required this.isListening,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.surface.withValues(alpha: 0.7),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isListening ? AppColors.accent : AppColors.muted,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              status,
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
