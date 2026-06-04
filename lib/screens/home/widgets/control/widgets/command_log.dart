import 'package:flutter/material.dart';

import '../../../../../translations/translations.dart';
import '../../../../../models/command.dart';
import '../../../../../theme.dart';
import 'command_bubble.dart';
import 'empty_command_state.dart';

class CommandLog extends StatelessWidget {
  final List<Command> commands;
  final String transcript;
  final ScrollController scrollController;
  final AppTranslations t;
  final String emptyMessage;

  const CommandLog({
    super.key,
    required this.commands,
    required this.transcript,
    required this.scrollController,
    required this.t,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    if (commands.isEmpty) {
      return EmptyCommandState(
        message: emptyMessage,
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: commands.length + (transcript.isNotEmpty ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == commands.length) {
          return Align(
            alignment: Alignment.centerRight,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderBlue,
                ),
              ),
              child: Text(
                '$transcript...',
                style: const TextStyle(
                  color: AppColors.blue,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          );
        }

        final cmd = commands[index];

        return CommandBubble(
          cmd: cmd,
          t: t,
        );
      },
    );
  }
}