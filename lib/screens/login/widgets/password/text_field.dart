import 'package:flutter/material.dart';
import 'package:submarine_flutter/theme.dart';

class LoginTextField extends StatelessWidget {
  const LoginTextField({
    super.key,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.hintText,
    required this.onChanged,
    required this.onSubmit,
  });

  final String? hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon:
            Icon(icon, color: AppColors.blue.withValues(alpha: 0.5), size: 18),
        suffixIcon: suffixIcon,
      ),
      onChanged: onChanged,
      onSubmitted: (_) => onSubmit(),
    );
  }
}
