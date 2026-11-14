# PuntoKampus

Vitrina digital de emprendimientos de estudiantes de la Universidad Técnica de Babahoyo. **Tu campus, tus emprendimientos** es el eslogan propuesto para esta primera versión, todavía provisional.

El proyecto utiliza **Flutter para Android y web**, **Laravel para la API**, **MySQL 8.4 para los datos** y **Filament para administración**. Ambos desarrolladores trabajan en todo el stack: la división se hace por funcionalidades, no por tecnologías.

## Estado de este incremento

La API de Vitrina ya consulta la base real MySQL 8.4 aprobada, mediante migraciones verificadas. La interfaz Flutter conserva por ahora sus datos locales mientras se prepara la conexión. La interfaz de demostración no debe confundirse con una plataforma publicada: el acceso por correo institucional, los pedidos reales, los comprobantes y la moderación necesitan sus servicios definitivos antes del piloto.

La app guarda los cambios de demostración en el navegador o dispositivo. La API ya expone las rutas públicas de Vitrina. El contrato compartido es [Datos, reglas y API](docs/prd/04-datos-reglas-y-api.md). La conexión de Flutter a la API, el acceso institucional y el panel Filament quedan para los siguientes incrementos.

## Carpetas

**Actualización del 14 de noviembre de 2026:** el diseño de la base cambia a **MySQL 8.4** por solicitud del usuario. El [SQL completo y vacío](database/mysql/puntokampus.sql), el [modelo de relaciones](database/mysql/modelo.md) y las [reglas e impacto de integración](database/mysql/README.md) están disponibles. La integración de Laravel ya está implementada; las migraciones anteriores están archivadas. Ver [estado de integración](docs/integracion-mysql-v1.md).

| Ruta | Contenido |
| --- | --- |
| `app/` | Aplicación Flutter para Android y web |
| `api/` | API de Vitrina en Laravel conectada a MySQL 8.4 |
| `docs/prd/` | Los nueve archivos originales del PRD, copiados sin modificaciones |
| `docs/contexto/` | Contexto original del proyecto |
| `database/mysql/` | Diseño MySQL 8.4 en 3FN, SQL completo, diagrama y pruebas |
| `docs/decisiones.md` | Decisiones vigentes y elementos provisionales |
| `docs/primeras-tareas.md` | Incrementos y propuesta de reparto del trabajo |
| `.github/PULL_REQUEST_TEMPLATE.md` | Plantilla de revisión de cambios |

## Ejecutar Flutter

En la computadora donde ya está compilada la demo, abre `Abrir PuntoKampus.cmd`. Se necesita Python 3 y la ventana del servidor debe quedar abierta mientras pruebas.

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

Para probar el recorrido, abre Vitrina, elige Productos y agrega un brownie. Completa la entrega y revisa el pedido pendiente en Mis pedidos. Desde Cuenta puedes cambiar a Ana Pérez para atender el pedido de Dulces de Ana o a Mateo Ruiz para probar la creación de tienda.

## Ejecutar la API

En esta computadora, abrir `Iniciar API.cmd`. La API se sirve en `http://127.0.0.1:8000` y MySQL en `127.0.0.1:3307`. Las bases de desarrollo y pruebas están separadas. La configuración, migraciones y pruebas con MySQL real se describen en [api/README.md](api/README.md). La instalación no carga contenido.

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
