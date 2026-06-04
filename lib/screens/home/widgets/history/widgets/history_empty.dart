import 'package:flutter/material.dart';
import '../../../../../translations/translations.dart';
import '../../../../../theme.dart';

class HistoryEmpty extends StatelessWidget {
  final AppTranslations t;

  const HistoryEmpty({
    super.key,
    required this.t,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search,
            size: 48,
            color: Color(0x338899aa),
          ),
          const SizedBox(height: 12),
          Text(
            t.noCommands,
            style: const TextStyle(
              color: AppColors.muted,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}