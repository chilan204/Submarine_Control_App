import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:submarine_flutter/screens/login/widgets/password/text_field.dart';
import 'package:submarine_flutter/services/auth_api_service.dart';
import 'package:submarine_flutter/theme.dart';
import '../../../../providers/app_provider.dart';

class Password extends StatefulWidget {
  const Password({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<Password> createState() => _PasswordState();
}

class _PasswordState extends State<Password> {
  final _authApi = AuthApiService();
  String _username = '';
  String _password = '';
  bool _showPassword = false;
  bool _isLoading = false;
  String _error = '';

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    final t = context.read<AppProvider>().t;
    if (_username.trim().isEmpty || _password.isEmpty) {
      setState(() => _error = t.wrongCreds);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final result = await _authApi.passwordLogin(
        username: _username,
        password: _password,
      );
      if (!mounted) return;

      if (result.success && result.data != null) {
        context.read<AppProvider>().login(
              token: result.data!.token,
              username: result.data!.username,
              name: result.data!.name,
              role: result.data!.role,
            );
        return;
      }

      setState(() => _error = result.message ?? t.wrongCreds);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = t.networkError);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppProvider>().t;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: _isLoading ? null : widget.onBack,
          child: Text(t.back,
              style: const TextStyle(color: AppColors.muted, fontSize: 14)),
        ),
        const SizedBox(height: 18),

        Text(t.usernameLabel,
            style: const TextStyle(
                color: AppColors.blue, fontSize: 14, letterSpacing: 1)),
        const SizedBox(height: 6),
        LoginTextField(
          hintText: t.usernameHint,
          icon: Icons.person_outline,
          onChanged: (v) => setState(() => _username = v),
          onSubmit: _handleLogin,
        ),
        const SizedBox(height: 12),

        Text(t.passwordLabel,
            style: const TextStyle(
                color: AppColors.blue, fontSize: 14, letterSpacing: 1)),
        const SizedBox(height: 6),
        LoginTextField(
          hintText: '••••••••••',
          icon: Icons.lock_outline,
          obscureText: !_showPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.blue.withValues(alpha: 0.5),
              size: 20,
            ),
            onPressed: () => setState(() => _showPassword = !_showPassword),
          ),
          onChanged: (v) => setState(() => _password = v),
          onSubmit: _handleLogin,
        ),

        if (_error.isNotEmpty) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.red, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(_error,
                    style: const TextStyle(
                        color: AppColors.red, fontSize: 12)),
              ),
            ],
          ),
        ],
        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _isLoading ? null : _handleLogin,
            child: _isLoading
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    t.authenticate,
                    style: const TextStyle(
                        color: Colors.white,
                        letterSpacing: 2,
                        fontSize: 13),
                  ),
          ),
        ),
      ],
    );
  }
}
