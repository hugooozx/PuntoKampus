import 'package:material_ui/material_ui.dart';

import 'domain/preferences_persistence.dart';
import 'domain/store.dart';
import 'punto_kampus.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = DemoStore(PreferencesPersistence());
  await store.initialize();
  runApp(PuntoKampusApp(store: store));
}
