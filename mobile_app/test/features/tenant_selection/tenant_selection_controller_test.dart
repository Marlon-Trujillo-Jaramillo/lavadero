import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';
import 'package:mobile_app/app/di/providers.dart';
import 'package:mobile_app/features/tenant_selection/application/tenant_selection_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockTenantRepository extends Mock implements TenantRepository {}

void main() {
  late MockTenantRepository tenantRepository;
  late ProviderContainer container;

  setUp(() {
    tenantRepository = MockTenantRepository();
    container = ProviderContainer(
      overrides: [
        tenantRepositoryProvider.overrideWithValue(tenantRepository),
      ],
    );
    addTearDown(container.dispose);
  });

  test('search populates results on success', () async {
    when(() => tenantRepository.search('lavadero')).thenAnswer(
      (_) async => const [
        TenantSummary(id: '1', slug: 'lavadero-central', nombre: 'Central'),
      ],
    );

    await container
        .read(tenantSelectionControllerProvider.notifier)
        .search('lavadero');

    final state = container.read(tenantSelectionControllerProvider);
    expect(state.results, hasLength(1));
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNull);
  });

  test('search surfaces ApiException.message on failure', () async {
    when(() => tenantRepository.search(any())).thenThrow(
      const ApiException(message: 'Error inesperado.'),
    );

    await container
        .read(tenantSelectionControllerProvider.notifier)
        .search('x');

    final state = container.read(tenantSelectionControllerProvider);
    expect(state.errorMessage, 'Error inesperado.');
    expect(state.isLoading, isFalse);
  });

  test('empty query clears results without calling the repository',
      () async {
    await container
        .read(tenantSelectionControllerProvider.notifier)
        .search('   ');

    verifyNever(() => tenantRepository.search(any()));
    expect(
      container.read(tenantSelectionControllerProvider).results,
      isEmpty,
    );
  });

  test('select() stores the tenant slug in selectedTenantSlugProvider', () {
    container.read(tenantSelectionControllerProvider.notifier).select(
          const TenantSummary(
            id: '1',
            slug: 'lavadero-central',
            nombre: 'Central',
          ),
        );

    expect(container.read(selectedTenantSlugProvider), 'lavadero-central');
  });
}
