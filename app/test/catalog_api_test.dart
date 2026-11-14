import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:punto_kampus/api/catalog_api.dart';
import 'package:punto_kampus/api/catalog_controller.dart';

http.Response page(String name, {int id = 1, int number = 1, int last = 1}) =>
    http.Response(
      jsonEncode({
        'data': [
          {'id': id, 'nombre': name, 'slug': 'tienda-$id'},
        ],
        'meta': {'current_page': number, 'last_page': last, 'total': last},
      }),
      200,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

void main() {
  test('Envía filtros y pagina al servidor sin filtrar localmente', () async {
    final api = CatalogApi(
      client: MockClient((request) async {
        expect(request.url.path, '/api/v1/productos');
        expect(request.url.queryParameters, {
          'buscar': 'café %_',
          'categoria': '2',
          'pagina': '3',
        });
        expect(request.headers['Accept'], 'application/json');
        return http.Response(
          jsonEncode({
            'data': [
              {
                'id': 1,
                'nombre': 'Café',
                'precio': '1.50',
                'disponible': false,
              },
            ],
            'meta': {'current_page': 3, 'last_page': 3, 'total': 41},
          }),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }),
    );
    final result = await api.search(
      products: true,
      term: ' café %_ ',
      category: 2,
      page: 3,
    );
    expect(result.total, 41);
    expect(result.entries.single.price, '1.50');
    expect(result.entries.single.available, false);
    api.close();
  });

  test('Una respuesta vieja no reemplaza una búsqueda reciente', () async {
    final slow = Completer<http.Response>();
    final api = CatalogApi(
      client: MockClient((request) async {
        if (!request.url.path.endsWith('tiendas')) {
          return http.Response('{"data":[]}', 200);
        }
        return request.url.queryParameters['buscar'] == 'viejo'
            ? slow.future
            : page('Nuevo');
      }),
    );
    final controller = CatalogController(api)..term = 'viejo';
    final first = controller.load();
    await Future<void>.delayed(Duration.zero);
    controller.term = 'nuevo';
    await controller.load();
    slow.complete(page('Viejo'));
    await first;
    expect(controller.entries.single.name, 'Nuevo');
    controller.dispose();
    api.close();
  });

  test(
    'Error de pagina siguiente conserva resultados y permite reintentar',
    () async {
      var fail = true;
      final api = CatalogApi(
        client: MockClient((request) async {
          if (!request.url.path.endsWith('tiendas')) {
            return http.Response('{"data":[]}', 200);
          }
          if (request.url.queryParameters['pagina'] == '2') {
            return fail
                ? http.Response('error', 500)
                : page('Segunda', id: 2, number: 2, last: 2);
          }
          return page('Primera', last: 2);
        }),
      );
      final controller = CatalogController(api);
      await controller.load();
      await controller.load(more: true);
      expect(controller.entries.single.name, 'Primera');
      expect(controller.moreError, isNotNull);
      fail = false;
      await controller.load(more: true);
      expect(controller.entries.map((e) => e.name), ['Primera', 'Segunda']);
      expect(controller.hasMore, false);
      controller.dispose();
      api.close();
    },
  );

  test('Errores de conexión no se presentan como una vitrina vacía', () async {
    final api = CatalogApi(
      client: MockClient((_) async => throw http.ClientException('sin red')),
    );
    final controller = CatalogController(api);
    await controller.load();
    expect(controller.error, contains('conectar'));
    expect(controller.loading, false);
    controller.dispose();
    api.close();
  });

  test('404, JSON invalido y timeout producen errores controlados', () async {
    for (final response in [
      http.Response('{}', 404),
      http.Response('<html>', 200),
    ]) {
      final api = CatalogApi(client: MockClient((_) async => response));
      await expectLater(api.shop('inexistente'), throwsA(isA<ApiFailure>()));
      api.close();
    }
    final api = CatalogApi(
      client: MockClient((_) => Completer<http.Response>().future),
      timeout: const Duration(milliseconds: 5),
    );
    await expectLater(api.shop('lenta'), throwsA(isA<ApiFailure>()));
    api.close();
  });

  test(
    'Cerrar pantalla durante una petición no notifica al controlador eliminado',
    () async {
      final pending = Completer<http.Response>();
      final api = CatalogApi(
        client: MockClient(
          (r) async => r.url.path.endsWith('tiendas')
              ? pending.future
              : http.Response('{"data":[]}', 200),
        ),
      );
      final controller = CatalogController(api);
      final task = controller.load();
      controller.dispose();
      pending.complete(page('Tarde'));
      await task;
      expect(controller.entries, isEmpty);
      api.close();
    },
  );
}
