import 'package:flutter/material.dart';

import '../../../../../models/user_session_record.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class HistoryCommandDetail extends StatelessWidget {
  final UserSessionRecord cmd;
  final AppTranslations t;
  final Color color;
  final String statusLabel;

  const HistoryCommandDetail({
    super.key,
    required this.cmd,
    required this.t,
    required this.color,
    required this.statusLabel,
  });

  String _fullTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _detailField(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.muted,
            fontSize: 9,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _detailField(
                  t.timeLabel,
                  cmd.createdDate != null
                      ? _fullTime(cmd.createdDate!)
                      : '',
                  color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _detailField(
                  t.statusLabel,
                  statusLabel,
                  color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _detailField(
            'Action Details',
            'Action: ${cmd.action}\nDirection: ${cmd.direction}\nValue: ${cmd.value}',
            Colors.white70,
          ),
          const SizedBox(height: 6),
          _detailField(
            t.cmdId,
            '#${cmd.id}',
            AppColors.muted,
          ),
        ],
      ),
    );
  }
}