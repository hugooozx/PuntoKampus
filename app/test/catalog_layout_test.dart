import 'dart:convert';
import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:punto_kampus/api/catalog_api.dart';
import 'package:punto_kampus/real_app.dart';

void main() {
  final fixture =
      jsonDecode(File('test/fixtures/vitrina.json').readAsStringSync()) as Json;
  for (final size in [
    const Size(320, 844),
    const Size(375, 844),
    const Size(768, 1024),
    const Size(844, 390),
    const Size(1440, 900),
  ]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'Tarjetas, filtros y orden a ${size.width}×${size.height}, texto $scale',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          tester.platformDispatcher.textScaleFactorTestValue = scale;
          tester.platformDispatcher.accessibilityFeaturesTestValue =
              const FakeAccessibilityFeatures(disableAnimations: true);
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.platformDispatcher.clearAllTestValues);
          final requests = <Uri>[];
          final api = CatalogApi(
            client: MockClient((r) async {
              requests.add(r.url);
              final key = r.url.pathSegments.last;
              final data = (fixture[key] as List).map((value) {
                final entry = Map<String, dynamic>.from(value as Map);
                if (key == 'productos') {
                  entry['fotos'] = [];
                  entry['tienda'] = fixture['tiendas'][0];
                }
                return entry;
              }).toList();
              return http.Response(
                jsonEncode({
                  'data': data,
                  'meta': {
                    'total': data.length,
                    'current_page': 1,
                    'last_page': 1,
                  },
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            }),
          );
          await tester.pumpWidget(PuntoKampusRealApp(api: api));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          // Premium conserva su tercera posición, también con el nuevo diseño.
          final shops = find
              .byType(Card)
              .evaluate()
              .map(
                (element) => find
                    .descendant(
                      of: find.byWidget(element.widget),
                      matching: find.byType(Text),
                    )
                    .evaluate()
                    .map((e) => (e.widget as Text).data)
                    .first,
              )
              .toList();
          expect(shops, [
            'Dulces de Ana',
            'Pausa Fría',
            'Papel y Tinta para todo el campus UTB',
            'Punto Snack',
          ]);
          expect(find.text('Biblioteca'), findsNWidgets(2));
          expect(find.text('Sacó 10'), findsOneWidget);
          final longShop = tester.widget<Text>(
            find.text('Papel y Tinta para todo el campus UTB'),
          );
          expect(longShop.maxLines, scale > 1 ? isNull : 2);
          await tester.ensureVisible(find.text('Comida').first);
          await tester.tap(find.text('Comida').first);
          await tester.pumpAndSettle();
          expect(requests.last.queryParameters['categoria'], '1');
          await tester.ensureVisible(find.text('Productos'));
          await tester.tap(find.text('Productos'));
          await tester.pumpAndSettle();
          expect(find.text('Disponible'), findsOneWidget);
          expect(find.text('Agotado'), findsOneWidget);
          expect(find.text('\$1.50'), findsOneWidget);
          final longProduct = tester.widget<Text>(
            find.text('Brownie de chocolate con nueces y trozos de cacao'),
          );
          expect(longProduct.maxLines, scale > 1 ? isNull : 2);
          expect(tester.takeException(), isNull);
          final cards = find.byType(Card);
          if (size.width <= 375 && scale == 1) {
            expect(
              tester.getTopLeft(cards.first).dy,
              tester.getTopLeft(cards.last).dy,
            );
            expect(
              tester.getTopLeft(cards.first).dx,
              lessThan(tester.getTopLeft(cards.last).dx),
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
