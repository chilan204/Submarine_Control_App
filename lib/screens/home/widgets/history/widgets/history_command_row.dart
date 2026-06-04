import 'package:flutter/material.dart';

import '../../../../../models/user_session_record.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';
import 'history_command_detail.dart';

class HistoryCommandRow extends StatelessWidget {
  final UserSessionRecord cmd;
  final AppTranslations t;
  final bool isExpanded;
  final VoidCallback onTap;

  const HistoryCommandRow({
    super.key,
    required this.cmd,
    required this.t,
    required this.isExpanded,
    required this.onTap,
  });

  Color get _color {
    final status = cmd.commandStatus;
    if (status == 'EXECUTED') return AppColors.accent;
    if (status == 'WARNING') return AppColors.amber;
    return AppColors.red;
  }

  IconData get _icon {
    final status = cmd.commandStatus;
    if (status == 'EXECUTED') return Icons.check_circle_outline;
    if (status == 'WARNING') return Icons.warning_amber_rounded;
    return Icons.warning_rounded;
  }

  String get _statusLabel {
    final status = cmd.commandStatus;
    if (status == 'EXECUTED') return t.statusSuccess;
    if (status == 'WARNING') return t.statusWarning;
    return t.statusError;
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return t.timeJustNow;
    if (diff.inMinutes < 60) return '${diff.inMinutes} ${t.timeMinAgo}';
    if (diff.inHours < 24) return '${diff.inHours} ${t.timeHrAgo}';
    return '${diff.inDays} ${t.timeDayAgo}';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: AppColors.accent.withValues(alpha: 0.05),
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _color.withValues(alpha: 0.2)),
              ),
              child: Icon(_icon, color: _color, size: 16),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          cmd.transcript ?? 'No transcript',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              color: AppColors.muted, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            cmd.createdDate != null
                                ? _timeAgo(cmd.createdDate!)
                                : '',
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),

                  Text(
                    '${cmd.action ?? '-'} | ${cmd.direction ?? '-'} | ${cmd.value ?? '-'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 11,
                    ),
                    maxLines: isExpanded ? null : 1,
                    overflow:
                    isExpanded ? null : TextOverflow.ellipsis,
                  ),

                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: HistoryCommandDetail(
                      cmd: cmd,
                      t: t,
                      color: _color,
                      statusLabel: _statusLabel,
                    ),
                    crossFadeState: isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down
                  : Icons.chevron_right,
              color: AppColors.muted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}