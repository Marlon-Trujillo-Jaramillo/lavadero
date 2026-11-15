import 'package:admin_web/features/auth/application/slug_lavadero.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('slugDesdeNombre', () {
    test('quita tildes, espacios y símbolos', () {
      expect(
        slugDesdeNombre('Lavadero El Poblado #2'),
        'lavadero-el-poblado-2',
      );
      expect(slugDesdeNombre('Autolavado Peñalisa'), 'autolavado-penalisa');
      expect(slugDesdeNombre('  Brillo   Express!! '), 'brillo-express');
    });

    test('nunca supera el máximo ni termina en guion', () {
      final slug = slugDesdeNombre('Lavadero ${'muy ' * 20}largo');
      expect(slug.length, lessThanOrEqualTo(slugMax));
      expect(slug.endsWith('-'), isFalse);
      expect(validarSlug(slug), isNull);
    });
  });

  group('validarSlug', () {
    test('acepta un slug correcto', () {
      expect(validarSlug('lavadero-centro'), isNull);
    });

    test('rechaza lo que el backend también rechaza', () {
      expect(validarSlug('ab'), isNotNull);
      expect(validarSlug('Lavadero Centro'), isNotNull);
      expect(validarSlug('lavadero--centro'), isNotNull);
      expect(validarSlug('-lavadero'), isNotNull);
    });
  });
}
