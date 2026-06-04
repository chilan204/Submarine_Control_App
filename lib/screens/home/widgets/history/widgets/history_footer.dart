import 'package:flutter/material.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class HistoryFooter extends StatelessWidget {
  final AppTranslations t;
  final int shown;
  final int total;

  const HistoryFooter({
    super.key,
    required this.t,
    required this.shown,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      color: AppColors.surface.withValues(alpha: 0.7),
      child: Row(
        children: [
          Text(
            '${t.showing} $shown ${t.of} $total',
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 11,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                t.autoRecord,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}