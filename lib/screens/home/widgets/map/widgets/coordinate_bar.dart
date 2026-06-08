import 'package:flutter/material.dart';

import '../../../../../theme.dart';

class CoordinateBar extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String currentPositionLabel;

  const CoordinateBar({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.currentPositionLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      color: AppColors.surface.withValues(alpha: 0.7),
      child: Row(
        children: [
          const Icon(
            Icons.navigation,
            color: AppColors.accent,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${latitude.abs().toStringAsFixed(6)}°${latitude >= 0 ? 'N' : 'S'}, '
                      '${longitude.abs().toStringAsFixed(6)}°${longitude >= 0 ? 'E' : 'W'}',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                  ),
                ),
                Text(
                  currentPositionLabel,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}