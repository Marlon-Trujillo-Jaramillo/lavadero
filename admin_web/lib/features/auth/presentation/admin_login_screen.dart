import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../app/router/app_routes.dart';
import '../application/admin_auth_controller.dart';

/// Login de administración (dueño de lavadero / super-admin) sobre
/// [AuthLayout]: panel de marca a la izquierda y formulario a la derecha. Reutiliza la
/// lógica de auth de `lavadero_core` (mismo `AuthRepository`, mismo patrón
/// de refresh transparente vía `ApiClient`).
class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tenantSlugController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _tenantSlugController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final tenantSlug = _tenantSlugController.text.trim();
    try {
      ref.read(selectedTenantSlugProvider.notifier).state = tenantSlug;
      await ref
          .read(adminAuthControllerProvider.notifier)
          .login(
            tenantSlug: tenantSlug,
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // La navegación post-login la resuelve el redirect guard del router.
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Bienvenido de nuevo',
      subtitle: 'Ingresa al panel de tu lavadero.',
      brandHeadline: 'Tu lavadero,\nbajo control.',
      brandMessage:
          'Agenda del día, equipo, precios y resultados en tiempo real, '
          'desde cualquier navegador.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _tenantSlugController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Lavadero',
                  hintText: 'ej. lavadero-centro',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  helperText: 'Déjalo vacío si administras la plataforma',
                ),
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Ingresa un email válido'
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.md),
              _PasswordField(
                controller: _passwordController,
                onSubmitted: _submit,
              ),
              const SizedBox(height: LavaderoSpacing.lg),
              if (_errorMessage != null) ...[
                ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: LavaderoSpacing.md),
              ],
              LoadingButton(
                isLoading: _isLoading,
                onPressed: _submit,
                child: const Text('Ingresar'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(AppRoutes.registro),
                child: const Text('¿Tu lavadero aún no tiene cuenta? Créala'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatefulWidget {
  const _PasswordField({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final VoidCallback onSubmitted;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: 'Contraseña',
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
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Ingresa tu contraseña' : null,
      onFieldSubmitted: (_) => widget.onSubmitted(),
    );
  }
}
