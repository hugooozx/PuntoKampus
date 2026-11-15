import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

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
    Uint8List? image,
    List<Uint8List> photos = const [],
  }) async {
    try {
      final url = catalog.baseUrl.resolve(path);
      final http.BaseRequest request;
      if (image != null || photos.isNotEmpty) {
        // PHP procesa multipart con POST; Laravel reconoce el método indicado.
        final upload = http.MultipartRequest(
          method == 'PUT' ? 'POST' : method,
          url,
        );
        if (method == 'PUT') upload.fields['_method'] = 'PUT';
        for (final entry in (data ?? const <String, dynamic>{}).entries) {
          final value = entry.value;
          if (value is List) {
            for (var i = 0; i < value.length; i++) {
              upload.fields['${entry.key}[$i]'] = value[i].toString();
            }
          } else if (value != null) {
            upload.fields[entry.key] = value is bool
                ? (value ? '1' : '0')
                : value.toString();
          }
        }
        if (image != null) {
          upload.files.add(
            http.MultipartFile.fromBytes('imagen', image, filename: 'imagen'),
          );
        }
        for (final bytes in photos) {
          upload.files.add(
            http.MultipartFile.fromBytes('fotos[]', bytes, filename: 'foto'),
          );
        }
        request = upload;
      } else {
        final jsonRequest = http.Request(method, url);
        if (data != null) {
          jsonRequest.headers['Content-Type'] = 'application/json';
          jsonRequest.bodyBytes = utf8.encode(jsonEncode(data));
        }
        request = jsonRequest;
      }
      request.headers['Accept'] = 'application/json';
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final response = await catalog.client
          .send(request)
          .then(http.Response.fromStream)
          .timeout(
            photos.isEmpty ? catalog.timeout : const Duration(seconds: 40),
          );
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
