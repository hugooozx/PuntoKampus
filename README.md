# PuntoKampus

Vitrina digital de emprendimientos de estudiantes de la Universidad Técnica de Babahoyo. **Tu campus, tus emprendimientos** es el eslogan propuesto para esta primera versión, todavía provisional.

El proyecto utiliza **Flutter para Android y web**, **Laravel para la API**, **PostgreSQL para los datos** y **Filament para administración**. Ambos desarrolladores trabajan en todo el stack: la división se hace por funcionalidades, no por tecnologías.

## Estado de este incremento

Esta entrega inicia la aplicación Flutter con datos ficticios y recorridos locales de demostración, junto con la base de la API de Vitrina. La interfaz de demostración no debe confundirse con una plataforma publicada: el acceso por correo institucional, los pedidos reales, los comprobantes y la moderación necesitan sus servicios definitivos antes del piloto.

La aplicación y la API avanzan por separado en este primer incremento. El contrato compartido es [Datos, reglas y API](docs/prd/04-datos-reglas-y-api.md). No se asume una base PostgreSQL disponible ni un repositorio remoto conectado.

## Carpetas

| Ruta | Contenido |
| --- | --- |
| `app/` | Aplicación Flutter para Android y web |
| `api/` | API Laravel y administración Filament |
| `docs/prd/` | Los nueve archivos originales del PRD, copiados sin modificaciones |
| `docs/contexto/` | Contexto original del proyecto |
| `docs/decisiones.md` | Decisiones vigentes y elementos provisionales |
| `docs/primeras-tareas.md` | Incrementos y propuesta de reparto del trabajo |
| `.github/PULL_REQUEST_TEMPLATE.md` | Plantilla de revisión de cambios |

## Ejecutar Flutter

Se necesita un SDK de Flutter estable compatible con `app/pubspec.yaml`. Para Android también se requiere Android SDK, un emulador o un dispositivo; para empezar a revisar el diseño se puede usar la versión web.

Desde la raíz:

```powershell
cd app
flutter pub get
flutter run -d chrome
```

Para producir los archivos web:

```powershell
flutter build web
```

Para validar el código:

```powershell
flutter analyze
flutter test
```

La instalación de herramientas y los resultados efectivos de validación se registran al cerrar cada tarea; estos comandos no significan que todos los entornos estén configurados.

## Ejecutar la API

La configuración, instalación, migraciones, datos de demostración y pruebas se describen en [api/README.md](api/README.md). PostgreSQL es la base acordada para el despliegue. Los datos ficticios son exclusivos de desarrollo y no deben cargarse en producción.

Los archivos `.env` son locales. Cada desarrollador crea el suyo a partir del ejemplo y configura sus propios servicios. Nunca se comparten credenciales, claves privadas ni comprobantes reales mediante Git.

## Trabajar entre dos personas

1. Elegir una tarea completa y revisar sus dependencias en [primeras tareas](docs/primeras-tareas.md).
2. Crear una rama para esa tarea, por ejemplo `feat/vitrina-busqueda`.
3. Implementar los cambios necesarios en Flutter, API, migraciones y pruebas.
4. Guardar avances con commits pequeños y claros.
5. Abrir un PR con qué cambió, cómo probarlo y de qué depende.
6. La otra persona revisa antes de integrar en `main`.

Consulta [CONTRIBUTING.md](CONTRIBUTING.md) para el flujo y las reglas del contrato. **El remoto de GitHub está pendiente de definir**; no se ha supuesto una URL ni publicado el proyecto.

## Fuente de requisitos

Empieza por [alcance del tramo 1](docs/prd/01-alcance-tramo-1.md), [pantallas y flujos](docs/prd/03-pantallas-y-flujos.md) y [contrato de datos y API](docs/prd/04-datos-reglas-y-api.md).

Las decisiones expresas posteriores del dueño del producto —como que ambos desarrolladores trabajen en todo el stack— se recogen en [decisiones](docs/decisiones.md), sin reescribir retroactivamente los documentos originales.
