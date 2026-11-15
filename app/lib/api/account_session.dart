import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'account_api.dart';
import 'catalog_api.dart';

class AccountSession extends ChangeNotifier {
  AccountSession(this.api, {this.storage});
  final AccountApi api;
  final FlutterSecureStorage? storage;
  String get _key => 'puntokampus.sesion.v1.${api.catalog.baseUrl}';
  String? _token;
  Json? user;
  String? restoreError;
  bool restoring = false;
  bool persisted = true;
  bool _disposed = false;

  bool get signedIn => user != null;
  bool get needsProfile => signedIn && user!['acepto_privacidad_en'] == null;

  Future<void> restore() async {
    if (storage == null || restoring) return;
    restoring = true;
    restoreError = null;
    _changed();
    try {
      _token = await storage!.read(key: _key);
      if (_token != null) user = await _authorized('GET', 'yo');
    } on ApiFailure catch (error) {
      if (error.status != 401) restoreError = error.message;
    } catch (_) {
      restoreError = 'No pudimos recuperar la sesión de este dispositivo.';
    } finally {
      restoring = false;
      _changed();
    }
  }

  Future<void> signIn(String email, String code) async {
    final result = await api.request(
      'POST',
      'auth/verificar',
      data: {
        'correo': email,
        'codigo': code,
        'dispositivo': kIsWeb ? 'Navegador web' : 'Aplicación PuntoKampus',
      },
    );
    _token = result['token'] as String;
    user = result['usuario'] as Json;
    restoreError = null;
    persisted = true;
    try {
      await storage?.write(key: _key, value: _token);
    } catch (_) {
      persisted = false;
    }
    _changed();
  }

  Future<void> saveProfile(String name, {bool? consent, bool? whatsapp}) async {
    user = await _authorized('PUT', 'yo', {
      'nombres': name,
      if (consent == true) 'acepto_privacidad': true,
      'mostrar_whatsapp': ?whatsapp,
    });
    _changed();
  }

  Future<void> signOut() async {
    try {
      await _authorized('POST', 'auth/salir');
    } on ApiFailure catch (error) {
      if (error.status != 401) rethrow;
    }
    await clear();
  }

  Future<void> requestDeletion() async {
    await _authorized('POST', 'yo/codigo-borrado');
  }

  Future<void> deleteAccount(String code) async {
    await _authorized('DELETE', 'yo', {'codigo': code});
    await clear();
  }

  Future<Json> _authorized(String method, String path, [Json? data]) async {
    try {
      return await api.request(method, path, token: _token, data: data);
    } on ApiFailure catch (error) {
      if (error.status == 401) await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    _token = null;
    user = null;
    restoreError = null;
    try {
      await storage?.delete(key: _key);
    } catch (_) {
      // El servidor ya revocó el token o lo rechazó por vencido.
    }
    _changed();
  }

  void _changed() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
