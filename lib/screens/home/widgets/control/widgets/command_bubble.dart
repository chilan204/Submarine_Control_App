import 'package:flutter/material.dart';

import '../../../../../models/command.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class CommandBubble extends StatelessWidget {
  final Command cmd;
  final AppTranslations t;

  const CommandBubble({
    super.key,
    required this.cmd,
    required this.t,
  });

  Color get _color {
    switch (cmd.status) {
      case CommandStatus.success:
        return AppColors.accent;
      case CommandStatus.warning:
        return AppColors.amber;
      case CommandStatus.error:
        return AppColors.red;
    }
  }

  IconData get _icon {
    switch (cmd.status) {
      case CommandStatus.success:
        return Icons.check_circle_outline;
      case CommandStatus.warning:
        return Icons.warning_amber_rounded;
      case CommandStatus.error:
        return Icons.warning_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1a2a4a).withValues(alpha: 0.8),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border.all(
                  color: AppColors.borderBlue,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cmd.text,
                    style: const TextStyle(
                      color: Color(0xFF88aaff),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatTime(cmd.timestamp),
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (cmd.response.isNotEmpty) ...[
            const SizedBox(height: 4),

            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    topRight: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: _color.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _icon,
                          color: _color,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          t.systemLabel,
                          style: TextStyle(
                            color: _color,
                            fontSize: 10,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cmd.response,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }
}