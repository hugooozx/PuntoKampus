import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

class PreferencesPersistence implements DemoPersistence {
  static const _key = 'puntokampus.demo.v1';
  @override
  Future<Map<String, dynamic>?> read() async {
    final text = (await SharedPreferences.getInstance()).getString(_key);
    return text == null ? null : jsonDecode(text) as Map<String, dynamic>;
  }

  @override
  Future<void> write(Map<String, dynamic> data) async {
    final success = await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode(data),
    );
    if (!success) throw StateError('No se pudo guardar la sesión.');
  }
}
