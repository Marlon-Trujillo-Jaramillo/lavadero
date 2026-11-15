/// Reglas del "código del lavadero" (slug), las mismas que valida el backend
/// en `OnboardingTenantRequest`: minúsculas, números y guiones simples, entre
/// [slugMin] y [slugMax] caracteres.
const slugMin = 3;
const slugMax = 40;
final slugValido = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

const _sinTilde = {
  'á': 'a', 'à': 'a', 'ä': 'a', 'â': 'a', //
  'é': 'e', 'è': 'e', 'ë': 'e', 'ê': 'e', //
  'í': 'i', 'ì': 'i', 'ï': 'i', 'î': 'i', //
  'ó': 'o', 'ò': 'o', 'ö': 'o', 'ô': 'o', //
  'ú': 'u', 'ù': 'u', 'ü': 'u', 'û': 'u', //
  'ñ': 'n', 'ç': 'c',
};

/// Propone un slug a partir del nombre: "Lavadero El Poblado #2" →
/// "lavadero-el-poblado-2".
String slugDesdeNombre(String nombre) {
  final buffer = StringBuffer();
  for (final rune in nombre.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_sinTilde[ch] ?? ch);
  }
  var slug = buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  if (slug.length > slugMax) {
    slug = slug.substring(0, slugMax).replaceAll(RegExp(r'-+$'), '');
  }
  return slug;
}

/// Mensaje de error del campo, o `null` si el slug es válido.
String? validarSlug(String? value) {
  final slug = value?.trim() ?? '';
  if (slug.length < slugMin) return 'Mínimo $slugMin caracteres';
  if (slug.length > slugMax) return 'Máximo $slugMax caracteres';
  if (!slugValido.hasMatch(slug)) {
    return 'Solo minúsculas, números y guiones (ej. lavadero-centro)';
  }
  return null;
}
