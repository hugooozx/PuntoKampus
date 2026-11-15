# PuntoKampus

Vitrina digital de emprendimientos de estudiantes de la Universidad Técnica de Babahoyo. **Tu campus, tus emprendimientos** es el eslogan propuesto para esta primera versión, todavía provisional.

El proyecto utiliza **Flutter para Android y web**, **Laravel para la API**, **PostgreSQL para los datos** y **Filament para administración**. Ambos desarrolladores trabajan en todo el stack y se reparten funcionalidades.

## Estado de este incremento

Laravel consulta PostgreSQL. Flutter representa el catálogo y sus estados de carga, error y vacío con las respuestas de esa API.

La app principal conecta la Vitrina, el acceso institucional, Cuenta, las tiendas, los productos, el inventario, los pedidos y los reportes con la API real. Filament permite revisar reportes, dar de baja y reactivar tiendas. Las guías incluyen [probar el acceso](docs/acceso-y-cuenta.md), [publicar una tienda](docs/mi-tienda.md), [gestionar productos](docs/mis-productos.md), [hacer y gestionar pedidos](docs/carrito-y-pedidos.md) y [moderar tiendas](docs/reportes-y-moderacion.md). El SMTP y los datos definitivos de privacidad se configuran antes del piloto. La referencia de recorridos se conserva en `app/lib/main_demo.dart`.

## Carpetas

PostgreSQL es el motor del PRD. El [SQL completo](database/postgresql/puntokampus.sql) y la [guía de instalación y traslado](database/postgresql/README.md) documentan el esquema y el paso desde la versión MySQL.

| Ruta | Contenido |
| --- | --- |
| `app/` | Aplicación Flutter para Android y web |
| `api/` | API Laravel conectada a PostgreSQL |
| `docs/prd/` | Los nueve archivos originales del PRD, copiados sin modificaciones |
| `docs/contexto/` | Contexto original del proyecto |
| `database/postgresql/` | Esquema PostgreSQL en 3FN y guía de traslado |
| `database/mysql/` | Esquema histórico MySQL y diagrama de relaciones |
| `docs/decisiones.md` | Decisiones vigentes y elementos provisionales |
| `docs/primeras-tareas.md` | Incrementos y propuesta de reparto del trabajo |
| `.github/PULL_REQUEST_TEMPLATE.md` | Plantilla de revisión de cambios |

## Ejecutar Flutter

En esta computadora, abre `Abrir PuntoKampus.cmd` para iniciar PostgreSQL, la API y la compilación web de Flutter. Se necesita Python 3 y la ventana del servidor debe quedar abierta mientras pruebas. Configuración y alcance en [Flutter conectado a la API](docs/flutter-vitrina-api.md).

Para compilar desde el código se necesita Flutter 3.50 o posterior. Para Android también se requiere Android SDK y un emulador o un dispositivo.

Desde la raíz:

```powershell
cd app
flutter pub get
flutter run -d chrome
```

Para producir los archivos web:

```powershell
flutter build web --no-web-resources-cdn
cd ..
python scripts/abrir_demo.py
```

Para validar el código:

```powershell
flutter analyze
flutter test
```

En la instalación portátil de esta computadora, usa `../.tools/flutter/bin/flutter.bat` en lugar de `flutter` cuando estés dentro de `app/`.

Para probar la versión real, abre Vitrina y alterna Tiendas/Productos. La base parte vacía. Pulsa «Entrar» para solicitar un código y completar tu perfil. Después, abre Mi tienda para publicar tu emprendimiento con los catálogos cargados. La demo antigua se ejecuta con `flutter run -t lib/main_demo.dart`.

## Ejecutar la API

En esta computadora, abre `Iniciar API.cmd`. La API se sirve en `http://127.0.0.1:8000` y PostgreSQL en `127.0.0.1:5433`. Las bases de desarrollo y pruebas están separadas. Consulta la configuración en [api/README.md](api/README.md).

Los archivos `.env` son locales. Cada desarrollador crea el suyo a partir del ejemplo y configura sus propios servicios. Nunca se comparten credenciales, claves privadas ni comprobantes reales mediante Git.

## Trabajar entre dos personas

1. Elegir una tarea completa y revisar sus dependencias en [primeras tareas](docs/primeras-tareas.md).
2. Crear una rama para esa tarea, por ejemplo `feat/vitrina-busqueda`.
3. Implementar los cambios necesarios en Flutter, API, migraciones y pruebas.
4. Guardar avances con commits pequeños y claros.
5. Abrir un PR con qué cambió, cómo probarlo y de qué depende.
6. La otra persona revisa antes de integrar en `main`.

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para el flujo y las reglas del contrato. El remoto del proyecto es [hugooozx/PuntoKampus](https://github.com/hugooozx/PuntoKampus).

## Fuente de requisitos

Empieza por [alcance del tramo 1](docs/prd/01-alcance-tramo-1.md), [pantallas y flujos](docs/prd/03-pantallas-y-flujos.md) y [contrato de datos y API](docs/prd/04-datos-reglas-y-api.md).

Las decisiones expresas posteriores del dueño del producto —como que ambos desarrolladores trabajen en todo el stack— se recogen en [decisiones](docs/decisiones.md), sin reescribir retroactivamente los documentos originales.
