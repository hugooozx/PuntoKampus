import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:punto_kampus/domain/models.dart';
import 'package:punto_kampus/domain/store.dart';
import 'package:punto_kampus/punto_kampus.dart';

void main() {
  test(
    'Conserva la tienda Premium en su posición y busca sin tildes',
    () async {
      final store = DemoStore(MemoryPersistence());
      await store.initialize();
      expect(store.findShops('', '').map((shop) => shop.name), [
        'Dulces de Ana',
        'Pausa Fría',
        'Papel y Tinta',
        'Punto Snack',
      ]);
      expect(
        store.findProducts('CAFE FRIO CON LECHE', 'Bebidas').single.name,
        'Café frío',
      );
      expect(
        store.findShops('EMPANADÁ', 'Comida').single.name,
        'Dulces de Ana',
      );
    },
  );

  test('Rechaza agotados, pedidos propios y mezcla de tiendas', () async {
    final store = DemoStore(MemoryPersistence());
    await store.initialize();
    expect(
      () => store.addToCart(store.product('galleta'), 1),
      throwsStateError,
    );
    expect(
      () => store.addToCart(store.product('cuaderno'), 1),
      throwsStateError,
    );
    store.addToCart(store.product('brownie'), 2);
    expect(() => store.addToCart(store.product('cafe'), 1), throwsStateError);
    expect(store.cartTotal, 300);
  });

  test('Registra el pedido pendiente y el vendedor puede entregarlo', () async {
    final persistence = MemoryPersistence();
    final store = DemoStore(persistence);
    await store.initialize();
    store.addToCart(store.product('brownie'), 2);
    final now = DateTime.now();
    expect(
      () => store.checkout(
        'Biblioteca',
        now.add(const Duration(minutes: 10)),
        'Efectivo',
        '',
        now: now,
      ),
      throwsStateError,
    );
    final purchase = store.checkout(
      'Biblioteca',
      now.add(const Duration(hours: 1)),
      'Efectivo',
      'Sin bolsa',
      now: now,
    );
    expect(purchase.status, 'pendiente');
    expect(purchase.total, 300);
    expect(purchase.message, contains(purchase.code));
    expect(store.cart, isEmpty);
    expect(() => store.changeOrder(purchase, 'entregado'), throwsStateError);
    store.switchPerson('ana');
    store.changeOrder(purchase, 'entregado');
    await store.saved;
    final restored = DemoStore(persistence);
    await restored.initialize();
    expect(restored.orders.first.status, 'entregado');
  });

  testWidgets('Vitrina abre y permite buscar sin resultados en celular', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = DemoStore(MemoryPersistence());
    await store.initialize();
    await tester.pumpWidget(PuntoKampusApp(store: store));
    await tester.pumpAndSettle();
    expect(find.text('Dulces de Ana'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'sushi');
    await tester.pumpAndSettle();
    expect(find.text('No encontramos nada con «sushi».'), findsOneWidget);
    await tester.ensureVisible(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pumpAndSettle();
    expect(find.text('4 tiendas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
