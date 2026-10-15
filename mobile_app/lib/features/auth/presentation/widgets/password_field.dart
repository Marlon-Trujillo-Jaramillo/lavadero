import 'package:flutter/material.dart';

/// Campo de contraseña con ícono y botón para mostrar/ocultar.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.validator,
    this.onSubmitted,
    this.isNewPassword = false,
    this.helperText,
  });

  final TextEditingController controller;
  final FormFieldValidator<String> validator;
  final VoidCallback? onSubmitted;

  /// En registro: pista de autofill para que el gestor sugiera una nueva.
  final bool isNewPassword;
  final String? helperText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      autofillHints: [
        widget.isNewPassword
            ? AutofillHints.newPassword
            : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: 'Contraseña',
        helperText: widget.helperText,
        prefixIcon: const Icon(Icons.lock_outline_rounded),
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Mostrar contraseña' : 'Ocultar contraseña',
          icon: Icon(
            _obscure
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
          ),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      validator: widget.validator,
      onFieldSubmitted: (_) => widget.onSubmitted?.call(),
    );
  }
}
