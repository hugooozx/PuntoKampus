import 'package:material_ui/material_ui.dart';

import 'api/catalog_api.dart';
import 'real_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(PuntoKampusRealApp(api: CatalogApi()));
}
