import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../application/admin_auth_controller.dart';

/// Login de administración (dueño de lavadero / super-admin). UI de
/// escritorio/web: card centrada, en vez del layout mobile de
/// `mobile_app/features/auth/presentation/login_screen.dart`. Reutiliza la
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
      await ref.read(adminAuthControllerProvider.notifier).login(
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
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(LavaderoSpacing.lg),
            child: Padding(
              padding: const EdgeInsets.all(LavaderoSpacing.xl),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: LavaderoSpacing.sm),
                    Text(
                      'Lavadero Admin',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: LavaderoSpacing.lg),
                    TextFormField(
                      controller: _tenantSlugController,
                      decoration: const InputDecoration(
                        labelText: 'Slug del lavadero (tenant)',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? 'Ingresa el slug de tu lavadero'
                              : null,
                    ),
                    const SizedBox(height: LavaderoSpacing.sm),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          (value == null || !value.contains('@'))
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
                      validator: (value) =>
                          (value == null || value.isEmpty)
                              ? 'Ingresa tu contraseña'
                              : null,
                      onFieldSubmitted: (_) => _submit(),
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
                      onPressed: _submit,
                      child: const Text('Ingresar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
