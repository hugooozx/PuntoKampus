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
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), 'inexistente');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        find.text('No encontramos nada con «inexistente».'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Reintenta una conexión fallida sin mostrar éxito ficticio', (
    tester,
  ) async {
    var fail = true;
    final api = CatalogApi(
      client: MockClient((r) async => fail ? http.Response('', 503) : empty(r)),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('No pudimos cargar la vitrina'), findsOneWidget);
    fail = false;
    await tester.ensureVisible(find.text('Reintentar'));
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();
    expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
  });

  testWidgets(
    'Abre un producto real de la API y muestra agotado sin permitir pedidos',
    (tester) async {
      final shop = <String, dynamic>{
        'id': 1,
        'nombre': 'Tienda de prueba',
        'slug': 'tienda-prueba',
        'descripcion': 'Descripción de prueba',
        'plan': 'premium',
        'categoria_1_id': 1,
        'categoria_2_id': null,
        'punto_entrega_id': 1,
        'horario': 'Lunes a viernes',
      };
      final product = <String, dynamic>{
        'id': 5,
        'tienda_id': 1,
        'nombre': 'Producto de prueba',
        'descripcion': 'Producto agotado',
        'precio': '2.00',
        'disponible': false,
        'fotos': [],
      };
      final api = CatalogApi(
        client: MockClient((request) async {
          final path = request.url.path;
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
      await tester.tap(find.text('Productos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Producto de prueba'));
      await tester.tap(find.text('Producto de prueba'));
      await tester.pumpAndSettle();
      expect(find.text('Agotado'), findsOneWidget);
      expect(find.text('\$2.00'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(
              find.widgetWithText(FilledButton, 'Agregar al carrito'),
            )
            .onPressed,
        isNull,
      );
      await tester.ensureVisible(find.text('Ver tienda'));
      await tester.tap(find.text('Ver tienda'));
      await tester.pumpAndSettle();
      expect(find.text('Entrega: Biblioteca'), findsOneWidget);
      expect(find.textContaining('WhatsApp:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
