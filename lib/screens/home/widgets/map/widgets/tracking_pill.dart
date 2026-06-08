import 'package:flutter/material.dart';

import '../../../../../theme.dart';

class TrackingPill extends StatelessWidget {
  final bool isConnected;
  final String liveText;

  const TrackingPill({
    super.key,
    required this.isConnected,
    required this.liveText,
  });

  @override
  Widget build(BuildContext context) {
    final statusText = liveText;
    final statusColor = isConnected ? AppColors.accent : AppColors.amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}