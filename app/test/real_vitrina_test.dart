import 'dart:async';
import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:punto_kampus/api/catalog_api.dart';
import 'package:punto_kampus/real_app.dart';

http.Response empty(http.Request request) => http.Response(
  jsonEncode({
    'data': [],
    if (['tiendas', 'productos'].contains(request.url.pathSegments.last))
      'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
  }),
  200,
);

void main() {
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('Vitrina vacía sin datos ficticios ni overflow a $width px', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <String>[];
      final api = CatalogApi(
        client: MockClient((r) async {
          requests.add(r.url.path);
          return empty(r);
        }),
      );
      await tester.pumpWidget(PuntoKampusRealApp(api: api));
      await tester.pumpAndSettle();
      expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
      expect(find.text('Dulces de Ana'), findsNothing);
      expect(find.text('Modo demo'), findsNothing);
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      expect(requests, contains('/api/v1/productos'));
      expect(find.text('Aún no hay productos'), findsOneWidget);
      expect(find.text('Ver tiendas'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        find.text('No encontramos nada con «inexistente».'),
        findsOneWidget,
      );
      await tester.ensureVisible(find.text('Limpiar búsqueda'));
      await tester.tap(find.text('Limpiar búsqueda'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(find.text('Aún no hay productos'), findsOneWidget);
      await tester.ensureVisible(find.text('Ver tiendas'));
      await tester.tap(find.text('Ver tiendas'));
      await tester.pumpAndSettle();
      expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Muestra la carga y permite reintentar tras agotar la espera', (
    tester,
  ) async {
    final slow = Completer<http.Response>();
    final api = CatalogApi(
      timeout: const Duration(seconds: 2),
      client: MockClient(
        (r) async => r.url.path.endsWith('/tiendas') && !slow.isCompleted
            ? slow.future
            : empty(r),
      ),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pump();
    expect(find.text('Cargando tiendas…'), findsOneWidget);
    expect(find.text('La vitrina está por estrenarse'), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar la vitrina'), findsOneWidget);
    expect(
      find.textContaining('La conexión está tardando demasiado'),
      findsOneWidget,
    );
    slow.complete(http.Response('', 503));
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
  });

  testWidgets('Una tienda sin productos enlaza a la Vitrina', (tester) async {
    final shop = {
      'id': 3,
      'nombre': 'Papelería del campus',
      'slug': 'papeleria-del-campus',
      'productos': [],
    };
    final api = CatalogApi(
      client: MockClient(
        (r) async => r.url.path.endsWith('/papeleria-del-campus')
            ? http.Response(
                jsonEncode({'data': shop}),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              )
            : empty(r),
      ),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/t/papeleria-del-campus');
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay productos'), findsOneWidget);
    await tester.ensureVisible(find.text('Explorar la Vitrina'));
    await tester.tap(find.text('Explorar la Vitrina'));
    await tester.pumpAndSettle();
    expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
  });

  testWidgets('La tienda no disponible permite volver a la Vitrina', (
    tester,
  ) async {
    final api = CatalogApi(
      client: MockClient(
        (request) async => request.url.path.endsWith('/no-disponible')
            ? http.Response('', 404)
            : empty(request),
      ),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pumpAndSettle();
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .pushNamed('/t/no-disponible');
    await tester.pumpAndSettle();
    expect(find.text('Esta tienda no está disponible.'), findsOneWidget);
    await tester.tap(find.text('Ir a la vitrina'));
    await tester.pumpAndSettle();
    expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
  });

  for (final available in [false, true]) {
    testWidgets(
      available
          ? 'Producto y carrito respetan el stock, recalculan el total y permiten quitar'
          : 'Abre un producto real de la API y muestra agotado sin permitir pedidos',
      (tester) async {
        if (available) {
          tester.view.physicalSize = const Size(320, 900);
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        }
        final shop = <String, dynamic>{
          'id': 1,
          'nombre': 'Tienda de prueba',
          'slug': 'tienda-prueba',
          'descripcion': 'Descripción de prueba',
          'plan': 'premium',
          'categoria_1_id': 1,
          'categoria_2_id': null,
          'punto_entrega_id': 1,
          'punto_entrega_nombre': 'Biblioteca',
          'categorias_nombres': ['Comida'],
          'horario': 'Lunes a viernes',
        };
        final product = <String, dynamic>{
          'id': 5,
          'tienda_id': 1,
          'nombre': 'Producto de prueba',
          'descripcion': available ? 'Hecho en el campus' : 'Producto agotado',
          'precio': '2.00',
          'disponible': available,
          'unidades_disponibles': available ? 2 : 0,
          'fotos': [],
        };
        final requests = <String>[];
        final api = CatalogApi(
          client: MockClient((request) async {
            final path = request.url.path;
            requests.add(path);
            final Object body;
            if (path.endsWith('categorias')) {
              body = {
                'data': [
                  {'id': 1, 'nombre': 'Comida'},
                ],
              };
            } else if (path.endsWith('puntos-entrega')) {
              body = {
                'data': [
                  {'id': 1, 'nombre': 'Biblioteca'},
                ],
              };
            } else if (path.endsWith('/tienda-prueba')) {
              body = {
                'data': {
                  ...shop,
                  'productos': [product],
                },
              };
            } else {
              body = {
                'data': [
                  if (path.endsWith('productos'))
                    {...product, 'tienda': shop}
                  else
                    shop,
                ],
                'meta': {'current_page': 1, 'last_page': 1, 'total': 1},
              };
            }
            return http.Response(
              jsonEncode(body),
              200,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }),
        );
        await tester.pumpWidget(PuntoKampusRealApp(api: api));
        await tester.pumpAndSettle();
        expect(find.text('Sacó 10'), findsOneWidget);
        await tester.ensureVisible(find.text('Productos'));
        await tester.tap(find.text('Productos'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Producto de prueba'));
        await tester.tap(find.text('Producto de prueba'));
        await tester.pumpAndSettle();
        if (available) {
          final increase = find.byWidgetPredicate(
            (widget) =>
                widget is IconButton && widget.tooltip == 'Aumentar cantidad',
          );
          final decrease = find.byWidgetPredicate(
            (widget) =>
                widget is IconButton && widget.tooltip == 'Reducir cantidad',
          );
          await tester.ensureVisible(increase);
          await tester.tap(increase);
          await tester.pumpAndSettle();
          await tester.ensureVisible(find.text('Agregar al carrito'));
          await tester.tap(find.text('Agregar al carrito'));
          await tester.pumpAndSettle();
          expect(find.text('Quitar'), findsOneWidget);
          expect(tester.widget<IconButton>(increase).onPressed, isNull);
          expect(find.text(r'$4.00'), findsNWidgets(2));
          await tester.ensureVisible(decrease);
          await tester.tap(decrease);
          await tester.pumpAndSettle();
          expect(find.text(r'$2.00'), findsNWidgets(2));
          expect(tester.widget<IconButton>(increase).onPressed, isNotNull);
          await tester.ensureVisible(find.text('Quitar'));
          await tester.tap(find.text('Quitar'));
          await tester.pumpAndSettle();
          expect(find.text('Tu carrito está vacío.'), findsOneWidget);
          expect(find.text('Continuar'), findsNothing);
          expect(tester.takeException(), isNull);
          return;
        }
        expect(find.text('Agotado'), findsOneWidget);
        expect(find.text('\$2.00'), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(
                find.ancestor(
                  of: find.text('Agregar al carrito'),
                  matching: find.byWidgetPredicate(
                    (widget) => widget is FilledButton,
                  ),
                ),
              )
              .onPressed,
          isNull,
        );
        await tester.ensureVisible(find.text('Tienda de prueba'));
        await tester.tap(find.text('Tienda de prueba'));
        await tester.pumpAndSettle();
        expect(find.text('Entrega: Biblioteca'), findsOneWidget);
        expect(find.text('Comida'), findsWidgets);
        expect(
          requests.where((path) => path.endsWith('/puntos-entrega')),
          hasLength(1),
        );
        expect(find.textContaining('WhatsApp:'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
