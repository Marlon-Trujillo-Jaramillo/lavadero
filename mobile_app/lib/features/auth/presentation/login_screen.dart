import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../application/auth_controller.dart';

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
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(
            tenantSlug: tenantSlug,
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      // La navegación post-login la resuelve el redirect guard del router
      // en función del nuevo AuthState (ver app/router/app_router.dart).
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantSlug = ref.watch(selectedTenantSlugProvider);

    if (tenantSlug == null) {
      // No debería ocurrir vía navegación normal (el redirect guard obliga
      // a pasar primero por tenant_selection), pero se cubre por robustez.
      return Scaffold(
        appBar: AppBar(title: const Text('Iniciar sesión')),
        body: Center(
          child: FilledButton(
            onPressed: () => context.go('/tenant-selection'),
            child: const Text('Elegir lavadero'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Iniciar sesión')),
      body: Padding(
        padding: const EdgeInsets.all(LavaderoSpacing.md),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Lavadero: $tenantSlug',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Ingresa un email válido'
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Ingresa tu contraseña'
                    : null,
              ),
              const SizedBox(height: LavaderoSpacing.md),
              if (_errorMessage != null) ...[
                ErrorBanner(
                  message: _errorMessage!,
                  onDismiss: () => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: LavaderoSpacing.sm),
              ],
              LoadingButton(
                isLoading: _isLoading,
                onPressed: () => _submit(tenantSlug),
                child: const Text('Ingresar'),
              ),
              TextButton(
                onPressed: () => context.push('/register'),
                child: const Text('¿No tienes cuenta? Regístrate'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
