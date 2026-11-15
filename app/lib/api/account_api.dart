import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'catalog_api.dart';

class AccountApi {
  AccountApi(this.catalog);
  final CatalogApi catalog;

  Future<Json> request(
    String method,
    String path, {
    Json? data,
    String? token,
  }) async {
    try {
      final request = http.Request(method, catalog.baseUrl.resolve(path))
        ..headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      if (data != null) {
        request.headers['Content-Type'] = 'application/json';
        request.bodyBytes = utf8.encode(jsonEncode(data));
      }
      final response = await catalog.client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(catalog.timeout);
      if (response.statusCode == 204) return {};
      final Json? json;
      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));
        json = decoded is Json ? decoded : null;
      } on FormatException {
        throw ApiFailure(
          'No pudimos completar la operación. Inténtalo de nuevo.',
          response.statusCode,
        );
      }
      if (response.statusCode >= 200 &&
          response.statusCode < 300 &&
          json != null) {
        return json;
      }
      final fields = json?['errors'];
      final fieldError = fields is Map && fields.isNotEmpty
          ? (fields.values.first as List).first as String
          : null;
      final message = response.statusCode >= 500
          ? 'El servicio no está disponible en este momento. Inténtalo de nuevo.'
          : fieldError ??
                json?['message'] as String? ??
                'No pudimos completar la operación.';
      throw AccountFailure(
        message,
        response.statusCode,
        int.tryParse(response.headers['retry-after'] ?? ''),
      );
    } on TimeoutException {
      throw const ApiFailure(
        'La conexión está tardando demasiado. Vuelve a intentarlo.',
      );
    } on http.ClientException {
      throw const ApiFailure(
        'No pudimos conectar. Revisa tu conexión y vuelve a intentarlo.',
      );
    }
  }
}

class AccountFailure extends ApiFailure {
  const AccountFailure(super.message, super.status, this.retryAfter);
  final int? retryAfter;
}
