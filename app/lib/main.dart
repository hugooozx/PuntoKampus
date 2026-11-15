import 'package:material_ui/material_ui.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/catalog_api.dart';
import 'real_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  runApp(
    PuntoKampusRealApp(
      api: CatalogApi(),
      storage: const FlutterSecureStorage(),
    ),
  );
}
