import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lavadero_core/lavadero_core.dart';

void main() {
  testWidgets('con "reducir movimiento" el esqueleto es estático (pumpAndSettle termina)', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LavaderoTheme.light(),
        home: const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: Scaffold(body: SkeletonList(itemCount: 3)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Skeleton), findsWidgets);
  });

  testWidgets('dentro de un SkeletonScope los bloques comparten la animación', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LavaderoTheme.light(),
        home: const Scaffold(body: SkeletonList(itemCount: 4)),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    // Los 12 bloques cuelgan de un único SkeletonScope (un solo ticker).
    expect(find.byType(Skeleton), findsNWidgets(12));
    expect(find.byType(SkeletonScope), findsOneWidget);
    expect(tester.hasRunningAnimations, isTrue);
  });
}
