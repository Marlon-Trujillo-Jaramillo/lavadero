import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lavadero_core/lavadero_core.dart';

import '../../../app/di/providers.dart';
import '../../../app/router/app_routes.dart';
import '../application/admin_auth_controller.dart';
import '../application/slug_lavadero.dart';

/// Alta self-service de un lavadero: crea el lavadero, su sucursal principal
/// y la cuenta del dueño, y entra directo al panel. Mismas reglas que el
/// backend (`OnboardingTenantRequest`) para no mandar algo que se va a
/// rechazar.
class AdminSignupScreen extends ConsumerStatefulWidget {
  const AdminSignupScreen({super.key});

  @override
  ConsumerState<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends ConsumerState<AdminSignupScreen> {
  static const _passwordMin = 8;
  static const _passwordMax = 128;

  final _formKey = GlobalKey<FormState>();
  final _nombreLavadero = TextEditingController();
  final _nit = TextEditingController();
  final _slug = TextEditingController();
  final _nombreAdmin = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _slugEditadoAMano = false;
  bool _obscure = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    for (final c in [
      _nombreLavadero,
      _nit,
      _slug,
      _nombreAdmin,
      _email,
      _password,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Mientras el usuario no toque el código, lo propone a partir del nombre.
  void _onNombreChanged(String nombre) {
    if (_slugEditadoAMano) return;
    _slug.text = slugDesdeNombre(nombre);
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final slug = _slug.text.trim();
    try {
      await ref
          .read(adminAuthControllerProvider.notifier)
          .crearCuenta(
            tenantNombre: _nombreLavadero.text.trim(),
            tenantNit: _nit.text.trim(),
            tenantSlug: slug,
            adminNombre: _nombreAdmin.text.trim(),
            email: _email.text.trim(),
            password: _password.text,
          );
      // Desde aquí las peticiones van a nombre del lavadero recién creado.
      ref.read(selectedTenantSlugProvider.notifier).state = slug;
      // La navegación al panel la resuelve el redirect del router.
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _requerido(String? value, String campo) =>
      (value == null || value.trim().isEmpty) ? 'Ingresa $campo' : null;

  @override
  Widget build(BuildContext context) {
    return AuthLayout(
      title: 'Crea la cuenta de tu lavadero',
      subtitle: 'En un minuto tendrás tu panel listo.',
      brandHeadline: 'Empieza a recibir\nreservas hoy.',
      brandMessage:
          'Tus clientes reservan desde el celular, tu equipo ve la agenda '
          'del día y tú controlas precios y resultados.',
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nombreLavadero,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                onChanged: _onNombreChanged,
                decoration: const InputDecoration(
                  labelText: 'Nombre del lavadero',
                  prefixIcon: Icon(Icons.local_car_wash_outlined),
                ),
                validator: (v) => _requerido(v, 'el nombre del lavadero'),
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _slug,
                textInputAction: TextInputAction.next,
                autocorrect: false,
                onChanged: (_) => _slugEditadoAMano = true,
                decoration: const InputDecoration(
                  labelText: 'Código del lavadero',
                  prefixIcon: Icon(Icons.storefront_outlined),
                  helperText: 'Tú y tus clientes lo usarán para entrar',
                ),
                validator: validarSlug,
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _nit,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'NIT o documento',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (v) => _requerido(v, 'el NIT o documento'),
              ),
              const SizedBox(height: LavaderoSpacing.lg),
              TextFormField(
                controller: _nombreAdmin,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Tu nombre',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (v) => _requerido(v, 'tu nombre'),
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.alternate_email_rounded),
                ),
                validator: (v) {
                  final email = v?.trim() ?? '';
                  final partes = email.split('@');
                  return (partes.length != 2 ||
                          partes[0].isEmpty ||
                          !partes[1].contains('.'))
                      ? 'Ingresa un email válido'
                      : null;
                },
              ),
              const SizedBox(height: LavaderoSpacing.md),
              TextFormField(
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  helperText: 'Mínimo $_passwordMin caracteres',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure
                        ? 'Mostrar contraseña'
                        : 'Ocultar contraseña',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) {
                  final length = v?.length ?? 0;
                  if (length < _passwordMin) {
                    return 'Mínimo $_passwordMin caracteres';
                  }
                  if (length > _passwordMax) {
                    return 'Máximo $_passwordMax caracteres';
                  }
                  return null;
                },
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
                child: const Text('Crear mi lavadero'),
              ),
              const SizedBox(height: LavaderoSpacing.sm),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go(AppRoutes.login),
                child: const Text('¿Ya tienes cuenta? Ingresa'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
