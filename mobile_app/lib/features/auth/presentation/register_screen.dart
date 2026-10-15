import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../../app/router/app_routes.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/password_field.dart';

/// Registro de un nuevo CLIENTE (auto-login tras registro, ver contrato de
/// `POST /api/v1/auth/register`).
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  static const _minPassword = 6;

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit(String tenantSlug) async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref
          .read(authControllerProvider.notifier)
          .register(
            tenantSlug: tenantSlug,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            nombre: _nombreController.text.trim(),
          );
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _irALogin() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantSlug = ref.watch(selectedTenantSlugProvider);

    if (tenantSlug == null) {
      // Mismo resguardo que el login: sin lavadero elegido no hay a dónde
      // registrarse (antes el botón quedaba deshabilitado sin explicación).
      return AuthLayout(
        title: 'Elige tu lavadero',
        subtitle: 'Para crear tu cuenta, primero busca tu lavadero.',
        child: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.tenantSelection),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar lavadero'),
        ),
      );
    }

    return AuthLayout(
      leading: AuthBackButton(onPressed: _irALogin),
      title: 'Crea tu cuenta',
      subtitle: 'Reserva tu primer lavado en menos de un minuto.',
      brandHeadline: 'Tu auto,\nimpecable.',
      brandMessage:
          'Reserva tu lavado en segundos y sigue cada paso desde el celular.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SelectedTenantCard(),
              const SizedBox(height: LavaderoSpacing.lg),
              TextFormField(
                controller: _nombreController,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Nombre completo',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa tu nombre'
                    : null,
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
              PasswordField(
                controller: _passwordController,
                isNewPassword: true,
                helperText: 'Mínimo $_minPassword caracteres',
                onSubmitted: () => _submit(tenantSlug),
                validator: (value) =>
                    (value == null || value.length < _minPassword)
                    ? 'Mínimo $_minPassword caracteres'
                    : null,
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
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => _submit(tenantSlug),
                child: const Text('Crear cuenta'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              AuthSwitchLink(
                question: '¿Ya tienes cuenta?',
                action: 'Inicia sesión',
                onPressed: _irALogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
