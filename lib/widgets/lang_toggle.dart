import 'package:flutter/material.dart';
import '../translations/translations.dart';
import '../theme.dart';

// VI / EN language toggle — mirrors LangToggle in App.tsx
class LangToggle extends StatelessWidget {
  final Lang lang;
  final ValueChanged<Lang> onChanged;

  const LangToggle({super.key, required this.lang, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Lang.vi, Lang.en].map((l) {
          final isActive = lang == l;
          return GestureDetector(
            onTap: () => onChanged(l),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                l == Lang.vi ? 'VI' : 'EN',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 0.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                  color: isActive ? AppColors.background : AppColors.muted,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
