import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:punto_kampus/api/catalog_api.dart';
import 'package:punto_kampus/real_app.dart';

http.Response _json(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

http.Response _catalog() => _json({
  'data': [],
  'meta': {'total': 0, 'current_page': 1, 'last_page': 1},
});

void main() {
  testWidgets('La portada a 320 px ofrece Vitrina pública sin sesión', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final requests = <String>[];
    final api = CatalogApi(
      client: MockClient((request) async {
        requests.add(request.url.path);
        return _catalog();
      }),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api, publicLanding: true));
    await tester.pumpAndSettle();
    expect(requests, isEmpty);
    await tester.ensureVisible(find.text('Explorar la Vitrina'));
    await tester.tap(find.text('Explorar la Vitrina'));
    await tester.pumpAndSettle();
    expect(find.text('La vitrina está por estrenarse'), findsOneWidget);
    expect(requests, contains('/api/v1/tiendas'));
    expect(requests.any((path) => path.contains('/auth/')), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Quiero vender conserva el destino y cerrar sesión vuelve a la portada',
    (tester) async {
      tester.view.physicalSize = const Size(1440, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <http.Request>[];
      final user = <String, dynamic>{
        'id': 1,
        'correo': 'vendedora@utb.edu.ec',
        'nombres': null,
        'acepto_privacidad_en': null,
        'mostrar_whatsapp': null,
        'tienda': null,
      };
      final api = CatalogApi(
        client: MockClient((request) async {
          requests.add(request);
          return switch (request.url.pathSegments.last) {
            'codigo' || 'salir' => http.Response('', 204),
            'verificar' => _json({'token': 'sesion-ficticia', 'usuario': user}),
            'yo' => _json(
              user..addAll({
                'nombres': jsonDecode(request.body)['nombres'],
                'acepto_privacidad_en': '2026-11-15T00:00:00.000Z',
              }),
            ),
            'mi-tienda' => _json({'tienda': null}),
            _ => _catalog(),
          };
        }),
      );
      await tester.pumpWidget(
        PuntoKampusRealApp(api: api, publicLanding: true),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Quiero vender'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('crear o gestionar tu tienda'),
        findsOneWidget,
      );
      await tester.enterText(
        find.byType(TextFormField),
        'vendedora@utb.edu.ec',
      );
      await tester.tap(find.text('Enviarme el código'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.text('Entrar'));
      await tester.pumpAndSettle();
      expect(find.text('Completa tu perfil'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'Sara Torres');
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(find.text('Crear mi tienda'), findsOneWidget);
      await tester.tap(find.byType(PopupMenuButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cerrar sesión'));
      await tester.pumpAndSettle();
      expect(find.text('Explorar la Vitrina'), findsOneWidget);
      expect(find.text('Entrar'), findsOneWidget);
      expect(find.text('Crear mi tienda'), findsNothing);
      final logout = requests.singleWhere(
        (r) => r.url.path.endsWith('/auth/salir'),
      );
      expect(logout.headers['Authorization'], 'Bearer sesion-ficticia');
      expect(tester.takeException(), isNull);
    },
  );
}
