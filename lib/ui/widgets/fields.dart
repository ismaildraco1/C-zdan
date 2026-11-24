import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

class Validators {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? email(String v) =>
      _email.hasMatch(v.trim()) ? null : 'Geçerli bir e-posta adresi yaz.';

  static String? password(String v) =>
      v.length >= 8 ? null : 'En az 8 karakter olmalı.';

  static String? required(String v, String message) =>
      v.trim().isEmpty ? message : null;
}

/// Üstünde görünür etiketi olan metin alanı. `id`, testlerde ve
/// erişilebilirlikte alanı ayırt etmek için `Key` olarak kullanılır.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.id,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.obscure = false,
    this.error,
    this.onChanged,
    this.hint,
    this.suffix,
    this.autofillHints,
  });

  final String id;
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscure;
  final String? error;
  final ValueChanged<String>? onChanged;
  final String? hint;
  final String? suffix;
  final Iterable<String>? autofillHints;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c, width: w),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          key: Key(id),
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscure,
          onChanged: onChanged,
          autofillHints: autofillHints,
          style: const TextStyle(fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            errorText: error,
            filled: true,
            fillColor: AppColors.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: border(const Color(0xFFD5DCD7), 1),
            focusedBorder: border(AppColors.green, 2),
            errorBorder: border(AppColors.down, 1),
            focusedErrorBorder: border(AppColors.down, 2),
          ),
        ),
      ],
    );
  }
}
