import 'package:flutter/material.dart';

import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class SubmarinePopup extends StatelessWidget {
  final double lat;
  final double lng;
  final double depth;
  final double speed;
  final double heading;
  final double pressure;
  final AppTranslations t;

  const SubmarinePopup({
    super.key,
    required this.lat,
    required this.lng,
    required this.depth,
    required this.speed,
    required this.heading,
    required this.pressure,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🚢 NAUTICOM SUB-1',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${lat.toStringAsFixed(4)}°N, ${lng.toStringAsFixed(4)}°E',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            '${t.depth}: ${depth.toStringAsFixed(0)}m',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            '${t.speed}: ${speed.toStringAsFixed(1)} kn',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            '${t.heading}: ${heading.toStringAsFixed(0)}°',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
          Text(
            '${t.pressure}: ${pressure.toStringAsFixed(1)} atm',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}