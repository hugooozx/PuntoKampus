# Flutter conectado a Vitrina

La entrada `app/lib/main.dart` consume exclusivamente las rutas públicas de Laravel. No inicializa `DemoStore`, no entra como un usuario ficticio y no usa el catálogo guardado por la demo. La entrada anterior queda disponible expresamente en `app/lib/main_demo.dart` para consultar recorridos antiguos.

## Funcionalidad

- Tiendas y productos consultados en la API, sin datos de respaldo inventados.
- Categorías desde `/categorias`, y puntos de entrega desde `/puntos-entrega`.
- Búsqueda con espera de 300 ms; filtros y páginas se resuelven en Laravel. Una respuesta antigua no puede reemplazar el filtro actual.
- Carga, vacío inicial, búsqueda sin resultados y error con reintento separados.
- Botón para cargar la siguiente página; un fallo conserva los resultados anteriores y permite reintentar esa misma página.
- Detalle público `/t/{slug}`, con logo, descripción, categorías, horario, punto de entrega, portada Premium y WhatsApp solo si la API lo devuelve.
- Productos disponibles y agotados, precios como texto decimal y fotos del servidor. El detalle vuelve a consultar la tienda para no abrir un producto eliminado a partir de una tarjeta antigua.
- La insignia «Sacó 10» no altera el orden recibido.

No hay cambios de contrato en esta tarea. Todavía no existen los servicios de acceso y escritura: Cuenta, Mi tienda y Mis pedidos lo indican expresamente. No se simula un login, un pedido o un reporte exitoso. El botón de pedir permanece deshabilitado.

## Configuración

Cliente: `http` 1.6.0, mantenido por dart.dev, sin nueva dependencia de gestión de estado. Referencias: [paquete oficial](https://pub.dev/packages/http) y [networking de Flutter](https://docs.flutter.dev/data-and-backend/networking).

Desde `app/`:

```powershell
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

En esta computadora usar `../.tools/flutter/bin/flutter.bat` en lugar de `flutter`. Para usar Edge:

```powershell
$env:CHROME_EXECUTABLE = 'C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe'
& ../.tools/flutter/bin/flutter.bat run -d chrome
```

Sin `API_BASE_URL`, web/escritorio usan `127.0.0.1:8000` y Android usa `10.0.2.2:8000` (emulador). Un teléfono físico requiere la dirección accesible de la API y configuración de red; no se comprobó un APK en esta entrega. Android permite HTTP solamente en la variante debug; usar HTTPS para release. No hay credenciales de MySQL en Flutter.

`API_BASE_URL` es un valor de compilación: volver a compilar después de cambiarlo. Para desplegar web en HTTPS, la API también debe usar HTTPS y CORS debe permitir el origen del sitio. La API pública actual permite peticiones sin cookies; esta política deberá revisarse al integrar autenticación.

Compilación local:

```powershell
flutter build web --no-web-resources-cdn --dart-define=API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Después abrir `Abrir PuntoKampus.cmd` en la raíz. Comprueba MySQL y API, y sirve la compilación en `http://127.0.0.1:8766`. El nombre histórico `scripts/abrir_demo.py` se conserva como servidor estático; lo servido es la compilación de la entrada real. Dejar abierta la ventana mientras se usa el sitio. MySQL/API continúan como procesos locales; `python scripts/mysql_local.py detener` detiene MySQL.

## Diseño y referencias pendientes

Se conservaron el logo PK, el acento naranja, el fondo cálido y la navegación móvil/escritorio. Se aplicaron las reglas de estados, legibilidad y tamaños táctiles del skill UI/UX Pro Max compartido por el usuario.

Las láminas aprobadas no se encontraron entre los archivos accesibles ni los adjuntos recuperables de este chat. Se solicitaron nuevamente. **No se afirma que esta interfaz reproduzca esas láminas**: la revisión de tipografía, composición y detalles contra las imágenes queda pendiente de recibirlas. Esta entrega avanza la conexión real sin declarar aprobado un rediseño.

## Validación

- `flutter analyze`: sin incidencias.
- `flutter test`: 15 pruebas aprobadas (11 nuevas de conexión/interfaz y 4 de la referencia anterior).
- Casos cubiertos: filtros enviados a la API, UTF-8, precios decimales, respuesta obsoleta, siguiente página fallida con reintento, timeout, 404, JSON inválido, controlador eliminado durante una petición y ausencia de datos ficticios.
- Widgets revisados a 320, 390 y 1440 px, reintento desplazando la pantalla y recorrido de producto agotado a tienda con punto de entrega real en la respuesta de prueba.
- Compilación web y comprobación en Edge contra Laravel/MySQL local: peticiones HTTP 200 desde el navegador para tiendas, categorías y puntos de entrega, sin errores JavaScript. La base no se pobló para esta comprobación.

Con Node 24 y Edge instalados, API activa y web compilada, ejecutar desde la raíz `node scripts/verificar_vitrina_web.mjs`. Capturas y registro de peticiones quedan en `.local/verificaciones/`, fuera de Git. El script abre y cierra su propio navegador de prueba; no utiliza el perfil personal del usuario.
