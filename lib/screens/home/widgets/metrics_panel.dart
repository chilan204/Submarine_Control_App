import 'package:flutter/material.dart';

import '../../../translations/translations.dart';
import '../../../theme.dart';
import '../../../widgets/stat_tile.dart';

class MetricsPanel extends StatelessWidget {
  final double depth;
  final double speed;
  final double heading;
  final double pressure;
  final AppTranslations t;

  const MetricsPanel({
    super.key,
    required this.depth,
    required this.speed,
    required this.heading,
    required this.pressure,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.1),
          ),
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: StatTile(
              icon: Icons.navigation,
              label: t.depth,
              value: '${depth.toStringAsFixed(0)}m',
              color: AppColors.blue,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: StatTile(
              icon: Icons.speed,
              label: t.speed,
              value: '${speed.toStringAsFixed(1)} kn',
              color: AppColors.accent,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: StatTile(
              icon: Icons.explore,
              label: t.heading,
              value: '${heading.toStringAsFixed(0)}°',
              color: AppColors.amber,
            ),
          ),
          Container(
            width: 1,
            height: 48,
            color: AppColors.border,
          ),
          Expanded(
            child: StatTile(
              icon: Icons.waves,
              label: t.pressure,
              value: '${pressure.toStringAsFixed(1)} atm',
              color: AppColors.pink,
            ),
          ),
        ],
      ),
    );
  }
}