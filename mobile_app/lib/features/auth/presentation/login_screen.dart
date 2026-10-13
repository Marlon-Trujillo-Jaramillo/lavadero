import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../../app/router/app_routes.dart';
import '../application/auth_controller.dart';
import 'widgets/auth_widgets.dart';
import 'widgets/password_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
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
          .login(
            tenantSlug: tenantSlug,
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // La navegación post-login la resuelve el redirect guard del router
      // en función del nuevo AuthState (ver app/router/app_router.dart).
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _volver() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.tenantSelection);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantSlug = ref.watch(selectedTenantSlugProvider);

    if (tenantSlug == null) {
      // No debería ocurrir vía navegación normal (el redirect guard obliga
      // a pasar primero por tenant_selection), pero se cubre por robustez.
      return AuthLayout(
        title: 'Elige tu lavadero',
        subtitle: 'Antes de ingresar, dinos en qué lavadero tienes tu cuenta.',
        child: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.tenantSelection),
          icon: const Icon(Icons.search_rounded),
          label: const Text('Buscar lavadero'),
        ),
      );
    }

    return AuthLayout(
      leading: AuthBackButton(onPressed: _volver),
      title: 'Bienvenido de nuevo',
      subtitle: 'Ingresa para reservar y seguir tus lavados.',
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
                onSubmitted: () => _submit(tenantSlug),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Ingresa tu contraseña'
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
                icon: Icons.login_rounded,
                onPressed: () => _submit(tenantSlug),
                child: const Text('Ingresar'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              AuthSwitchLink(
                question: '¿No tienes cuenta?',
                action: 'Regístrate',
                onPressed: () => context.push(AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
