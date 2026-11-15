# PuntoKampus para Android y web

Aplicación Flutter conectada a la API Laravel, que usa PostgreSQL. La entrada principal es `lib/main.dart` y consulta los datos del servidor.

Consulta [conexión, configuración y alcance](../docs/flutter-vitrina-api.md). En esta computadora, inicia la API con `Iniciar API.cmd` y usa F5 en VS Code. Para abrir la compilación web, utiliza `Abrir PuntoKampus.cmd`.

Desde esta carpeta:

```powershell
flutter pub get
flutter analyze
flutter test
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

La referencia de recorridos antigua se ejecuta solo si se pide expresamente `flutter run -t lib/main_demo.dart`. No es la entrada de la aplicación real.

La fidelidad visual a las láminas está pendiente de recuperarlas; no se considera terminado el ajuste de diseño. Acceso, pedidos y gestión de tienda requieren los servicios autenticados todavía pendientes.
