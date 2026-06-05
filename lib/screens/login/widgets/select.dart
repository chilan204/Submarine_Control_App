import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:submarine_flutter/screens/login/widgets/auth_cart.dart';
import 'package:submarine_flutter/theme.dart';
import '../../../providers/app_provider.dart';

class Select extends StatelessWidget {
  const Select({
    super.key,
    required this.onVoiceTap,
    required this.onPasswordTap,
  });

  final VoidCallback onVoiceTap;
  final VoidCallback onPasswordTap;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;

    return Column(
      spacing: 20,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          t.selectAuth,
          style: const TextStyle(color: AppColors.muted, fontSize: 14),
        ),
        AuthCart(
          icon: Icons.mic,
          title: t.voiceAuth,
          subtitle: t.voiceAuthDesc,
          color: AppColors.accent,
          onTap: onVoiceTap,
        ),
        AuthCart(
          icon: Icons.lock_outline,
          title: t.passwordAuth,
          subtitle: t.passwordAuthDesc,
          color: AppColors.blue,
          onTap: onPasswordTap,
        ),
      ],
    );
  }
}
