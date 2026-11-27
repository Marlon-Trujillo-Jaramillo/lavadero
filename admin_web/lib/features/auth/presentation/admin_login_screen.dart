import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lavadero_core/lavadero_core.dart';

import 'package:go_router/go_router.dart';

import '../../../app/di/providers.dart';
import '../../../app/router/app_routes.dart';
import '../application/admin_auth_controller.dart';

/// Activado solo en el despliegue de demostración con
/// `--dart-define=DEMO_MODE=true`. En producción es `false` y la pantalla se
/// comporta igual que siempre (sin banner, sin credenciales precargadas y con
/// el enlace de alta self-service visible).
const bool _demoMode = bool.fromEnvironment('DEMO_MODE');

const String _demoSlug = 'demo';
const String _demoEmail = 'demo@lavadero.app';
const String _demoPassword = 'LavaderoDemo2026';

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
  void initState() {
    super.initState();
    if (_demoMode) {
      _tenantSlugController.text = _demoSlug;
      _emailController.text = _demoEmail;
      _passwordController.text = _demoPassword;
    }
  }

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
              if (_demoMode) ...[
                const _DemoBanner(),
                const SizedBox(height: LavaderoSpacing.md),
              ],
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
              if (!_demoMode) ...[
                const SizedBox(height: LavaderoSpacing.sm),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => context.go(AppRoutes.registro),
                  child: const Text('¿Tu lavadero aún no tiene cuenta? Créala'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Aviso visible solo en el despliegue de demostración: deja claro que es un
/// entorno de prueba con datos de ejemplo y que las credenciales ya vienen
/// cargadas (basta pulsar «Ingresar»).
class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(LavaderoSpacing.md),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(LavaderoRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.science_outlined, color: scheme.onPrimaryContainer),
          const SizedBox(width: LavaderoSpacing.sm),
          Expanded(
            child: Text(
              'Modo demostración · datos de ejemplo. Las credenciales ya están '
              'cargadas: solo pulsa «Ingresar» para explorar el panel.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
          ),
        ],
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
