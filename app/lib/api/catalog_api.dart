import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

typedef Json = Map<String, dynamic>;

class ApiFailure implements Exception {
  const ApiFailure(this.message, [this.status]);
  final String message;
  final int? status;
}

class CatalogOption {
  CatalogOption(Json json)
    : id = json['id'] as int,
      name = json['nombre'] as String;
  final int id;
  final String name;
}

class CatalogEntry {
  CatalogEntry(this.json, {required this.isProduct});
  final Json json;
  final bool isProduct;
  int get id => json['id'] as int;
  String get name => json['nombre'] as String;
  String get description => json['descripcion'] as String? ?? '';
  String get slug => isProduct
      ? (json['tienda'] as Json)['slug'] as String
      : json['slug'] as String;
  String? get image {
    if (!isProduct) return json['logo_url'] as String?;
    final photos = json['fotos'] as List? ?? [];
    return photos.isEmpty ? null : photos.first['url'] as String?;
  }

  String get price => json['precio'] as String;
  bool get available => json['disponible'] == true;
  bool get premium => json['plan'] == 'premium';
  int? get category => json['categoria_1_id'] as int?;
}

class CatalogPageData {
  CatalogPageData(Json json, bool products)
    : entries = (json['data'] as List)
          .map((e) => CatalogEntry(e as Json, isProduct: products))
          .toList(),
      page = json['meta']['current_page'] as int,
      lastPage = json['meta']['last_page'] as int,
      total = json['meta']['total'] as int;
  final List<CatalogEntry> entries;
  final int page, lastPage, total;
}

class CatalogApi {
  CatalogApi({
    http.Client? client,
    Uri? baseUrl,
    this.timeout = const Duration(seconds: 12),
  }) : client = client ?? http.Client(),
       baseUrl = baseUrl ?? defaultUrl();
  final http.Client client;
  final Uri baseUrl;
  final Duration timeout;

  static Uri defaultUrl() {
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) {
      return Uri.parse(configured.endsWith('/') ? configured : '$configured/');
    }
    final host = !kIsWeb && defaultTargetPlatform == TargetPlatform.android
        ? '10.0.2.2'
        : '127.0.0.1';
    return Uri.parse('http://$host:8000/api/v1/');
  }

  Future<Json> get(String path, [Map<String, String>? query]) async {
    try {
      final response = await client
          .get(
            baseUrl.resolve(path).replace(queryParameters: query),
            headers: {'Accept': 'application/json'},
          )
          .timeout(timeout);
      if (response.statusCode == 404) {
        throw const ApiFailure('Esta tienda no está disponible.', 404);
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ApiFailure(
          'No pudimos cargar la información. Inténtalo de nuevo.',
          response.statusCode,
        );
      }
      return jsonDecode(utf8.decode(response.bodyBytes)) as Json;
    } on TimeoutException {
      throw const ApiFailure(
        'La conexión está tardando demasiado. Vuelve a intentarlo.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        'No pudimos conectar. Revisa tu conexión y vuelve a intentarlo.',
      );
    } on FormatException {
      throw const ApiFailure('La respuesta no es válida. Inténtalo de nuevo.');
    }
  }

  Future<List<CatalogOption>> options(String path) async =>
      ((await get(path))['data'] as List)
          .map((e) => CatalogOption(e as Json))
          .toList();

  Future<CatalogPageData> search({
    required bool products,
    String term = '',
    int? category,
    int page = 1,
  }) async => CatalogPageData(
    await get(products ? 'productos' : 'tiendas', {
      'pagina': '$page',
      if (term.trim().isNotEmpty) 'buscar': term.trim(),
      if (category != null) 'categoria': '$category',
    }),
    products,
  );

  Future<CatalogEntry> shop(String slug) async => CatalogEntry(
    (await get('tiendas/${Uri.encodeComponent(slug)}'))['data'] as Json,
    isProduct: false,
  );
  String imageUrl(String url) => baseUrl.resolve(url).toString();
  void close() => client.close();
}
