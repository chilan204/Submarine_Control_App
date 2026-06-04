import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:submarine_flutter/screens/login/widgets/header.dart';
import '../../providers/app_provider.dart';
import '../../theme.dart';
import '../../widgets/background_wrapper.dart';
import '../../widgets/lang_toggle.dart';
import 'widgets/login_mode_content.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  LoginMode _mode = LoginMode.select;

  void _resetToSelect() {
    setState(() => _mode = LoginMode.select);
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final lang = appProvider.lang;
    final t = appProvider.t;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            spacing: 20,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: LangToggle(
                  lang: lang,
                  onChanged: (l) => context.read<AppProvider>().setLang(l),
                ),
              ),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accentDim,
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(Icons.security, color: AppColors.accent, size: 50),
              ),
              Text(
                t.loginSubtitle,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 17,
                ),
              ),
              Expanded(
                child: Center(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
                    child: LoginModeContent(
                      mode: _mode,
                      onBackToSelect: _resetToSelect,
                      onVoiceTap: () => setState(() => _mode = LoginMode.voice),
                      onPasswordTap: () => setState(() => _mode = LoginMode.password),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
