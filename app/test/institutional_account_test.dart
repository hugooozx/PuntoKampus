import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';
import 'package:punto_kampus/api/catalog_api.dart';
import 'package:punto_kampus/real_app.dart';

http.Response jsonResponse(Object data) => http.Response(
  jsonEncode(data),
  200,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

void main() {
  testWidgets('Vitrina, registro con consentimiento, edición y salida', (
    tester,
  ) async {
    final requests = <http.Request>[];
    final user = <String, dynamic>{
      'id': 1,
      'correo': 'ana@fafi.utb.edu.ec',
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
          'verificar' || 'entrar' => jsonResponse({
            'token': 'token-de-prueba',
            'usuario': user,
            'es_nuevo': true,
          }),
          'yo' => jsonResponse(
            user..addAll({
              'nombres': jsonDecode(request.body)['nombres'],
              'acepto_privacidad_en': '2026-11-14T00:00:00.000Z',
            }),
          ),
          _ => jsonResponse({
            'data': [],
            'meta': {'total': 0, 'current_page': 1, 'last_page': 1},
          }),
        };
      }),
    );
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pumpAndSettle();
    expect(find.text('Cuenta'), findsNothing);
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'ana@fafi.utb.edu.ec');
    await tester.tap(find.text('Enviarme el código'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Reenviar en'), findsOneWidget);
    expect(find.text('ana@fafi.utb.edu.ec'), findsOneWidget);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Crear cuenta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    expect(find.text('Escribe los 6 dígitos.'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '01a234567');
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'clave-de-prueba-utb',
    );
    await tester.enterText(
      find.byType(TextFormField).at(2),
      'clave-de-prueba-utb',
    );
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Crear cuenta'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    final verification = requests.singleWhere(
      (request) => request.url.path.endsWith('/auth/verificar'),
    );
    expect(jsonDecode(verification.body)['codigo'], '012345');
    expect(find.text('Completa tu perfil'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Ana');
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continuar'))
          .onPressed,
      isNull,
    );
    expect(find.text('Acepta la política para continuar.'), findsOneWidget);
    expect(requests.where((r) => r.method == 'PUT'), isEmpty);
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();
    expect(find.text('Vitrina'), findsWidgets);
    await tester.tap(find.widgetWithText(TextButton, 'Cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Ana María');
    await tester.tap(find.text('Guardar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Cambios guardados.'), findsOneWidget);
    final save = requests.last;
    expect(save.headers['Authorization'], 'Bearer token-de-prueba');
    expect(jsonDecode(save.body), {'nombres': 'Ana María'});
    await tester.ensureVisible(find.text('Cerrar sesión'));
    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();
    expect(requests.last.url.path, '/api/v1/auth/salir');
    expect(find.text('Entrar'), findsOneWidget);
    final sent = requests
        .where((request) => request.url.path.endsWith('/auth/codigo'))
        .length;
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'ana@fafi.utb.edu.ec',
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      'clave-de-prueba-utb',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Iniciar sesión'));
    await tester.pumpAndSettle();
    final login = requests.singleWhere(
      (request) => request.url.path.endsWith('/auth/entrar'),
    );
    expect(jsonDecode(login.body)['contrasena'], 'clave-de-prueba-utb');
    expect(
      requests.where((request) => request.url.path.endsWith('/auth/codigo')),
      hasLength(sent),
    );
    expect(find.text('Vitrina'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Acceso con código cabe a 320 px con el texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final api = CatalogApi(
      client: MockClient(
        (request) async => request.url.path.endsWith('/codigo')
            ? http.Response('', 204)
            : jsonResponse({
                'data': [],
                'meta': {'total': 0, 'current_page': 1, 'last_page': 1},
              }),
      ),
    );
    await tester.pumpWidget(PuntoKampusRealApp(api: api));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.tap(find.widgetWithText(TextButton, 'Crear cuenta'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField),
      'estudiante@fafi.utb.edu.ec',
    );
    await tester.ensureVisible(find.text('Enviarme el código'));
    await tester.tap(find.text('Enviarme el código'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '012345');
    await tester.pumpAndSettle();
    expect(find.text('Verifica tu correo UTB'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
