# PuntoKampus

Vitrina digital de emprendimientos de estudiantes de la Universidad Técnica de Babahoyo. **Tu campus, tus emprendimientos** es el eslogan propuesto para esta primera versión, todavía provisional.

El proyecto utiliza **Flutter para Android y web**, **Laravel para la API**, **PostgreSQL para los datos** y **Filament para administración**. Ambos desarrolladores trabajan en todo el stack y se reparten funcionalidades.

## Primera instalación local en Windows

Necesitas Git, Python 3, Flutter 3.50 o superior, PHP 8.4 con `pdo_pgsql` y GD con WebP, Composer y PostgreSQL 16 o superior con ICU y la extensión `unaccent` disponible. Usa `flutter doctor` para comprobar la instalación de Flutter. Para este recorrido web basta con un navegador.

### 1. Clonar la versión de revisión

Con acceso al repositorio, ejecuta en PowerShell los comandos siguientes. La rama `codex/recuperar-contrasena` contiene la versión que usamos para verificar el recorrido local.

```powershell
git clone --branch codex/recuperar-contrasena https://github.com/hugooozx/PuntoKampus.git
Set-Location PuntoKampus
```

### 2. Configurar PostgreSQL y Laravel

En tu instancia local de PostgreSQL, crea una base UTF-8 llamada `puntokampus` y un usuario `puntokampus` que sea su propietario. Si usas `psql`, entra como administrador de PostgreSQL con `psql -h 127.0.0.1 -U postgres -d postgres` y ejecuta esto una vez. `\password` te pedirá la contraseña del nuevo usuario.

```sql
CREATE ROLE puntokampus LOGIN;
\password puntokampus
CREATE DATABASE puntokampus OWNER puntokampus TEMPLATE template0 ENCODING 'UTF8';
\q
```

Desde la raíz del repositorio, entra a `api/` y crea tu configuración local.

```powershell
Set-Location api
Copy-Item .env.example .env
```

Abre `api/.env` en VS Code. Conserva `APP_ENV=local`, `DB_CONNECTION=pgsql`, `DB_HOST=127.0.0.1` y `MAIL_MAILER=log`. En `DB_PORT` usa el puerto de tu PostgreSQL, normalmente `5432`. Configura `DB_DATABASE=puntokampus`, `DB_USERNAME=puntokampus` y tu contraseña en `DB_PASSWORD`. Usa `APP_URL=http://127.0.0.1:8000`. El `.env` se queda en tu computadora.

En la misma terminal, instala Laravel, genera la clave, aplica las migraciones y carga los catálogos de la UTB, las categorías y los puntos de entrega.

```powershell
composer install
php artisan key:generate
php artisan migrate
php artisan db:seed --class=CatalogoAcademicoUtbSeeder
php artisan db:seed --class=CatalogosInicialesSeeder
php artisan serve --host=127.0.0.1 --port=8000
```

Deja abierta la terminal. Puedes comprobar la API en [categorías locales](http://127.0.0.1:8000/api/v1/categorias).

### 3. Abrir la web

En otra terminal, desde la raíz del repositorio, compila y sirve la aplicación.

```powershell
Set-Location app
flutter pub get
flutter build web --no-web-resources-cdn
Set-Location ..
python scripts/abrir_demo.py
```

Deja abierta esa terminal y entra a [PuntoKampus](http://127.0.0.1:8766/). En Windows puedes usar `py` si tu instalación registra Python con ese nombre. Después del primer arranque, para volver a abrir la app basta con mantener PostgreSQL activo, iniciar Laravel y ejecutar de nuevo el servidor web de Python. Vuelve a compilar Flutter cuando cambie la app y ejecuta `php artisan migrate` cuando lleguen migraciones nuevas.

### 4. Crear tus cuentas de prueba

Las cuentas, tiendas y pedidos de otra computadora pertenecen a su base local. Crea tus cuentas con correos ficticios distintos, como los de la tabla, y elige tus propias contraseñas.

| Rol | Pestaña | Correo de ejemplo |
| --- | --- | --- |
| Comprador | [Vitrina en 127.0.0.1](http://127.0.0.1:8766/) | `pk-prueba-comprador@utb.edu.ec` |
| Vendedor | [Vitrina en localhost](http://localhost:8766/) | `pk-prueba-vendedor@utb.edu.ec` |
| Administrador | [Panel Filament](http://127.0.0.1:8000/admin/login) | `pk-prueba-admin@utb.edu.ec` |

1. **Comprador y vendedor.** En cada pestaña pulsa **Entrar → Crear cuenta**. Solicita el código y abre `api/storage/logs/laravel.log` en VS Code. Busca desde el final la entrada más reciente para ese correo. Copia los seis dígitos, elige una contraseña de al menos 12 caracteres y completa el perfil y el consentimiento. Usa **Iniciar sesión** con esa contraseña a partir de entonces. Las dos direcciones de la tabla mantienen sesiones distintas en el mismo navegador. También puedes usar una ventana privada para una de las dos cuentas.
2. **Administrador.** Crea una tercera cuenta ficticia con el mismo flujo en una ventana privada o un perfil separado para conservar las otras dos sesiones. Abre una terminal adicional en `api/` y ejecuta `php artisan tinker`. Ya dentro de Tinker, pega esta línea sobre tu base de desarrollo local y luego escribe `exit`.

   ```php
   \App\Models\Usuario::where('correo', 'pk-prueba-admin@utb.edu.ec')->firstOrFail()->forceFill(['es_admin' => true])->save();
   ```

   En Filament solicita el código de administración para esa cuenta y usa el mensaje más reciente del registro de Laravel. Si acabas de pedir el código de registro, espera un minuto antes de pedir el del panel. Filament usa su propia sesión.

### 5. Probar el recorrido con las tres pestañas

1. Como **vendedor**, abre **Mi tienda** y crea `Tienda de prueba PK`. Usa un código de estudiante ficticio, elige una carrera, un semestre, una categoría y **Biblioteca** como punto de entrega. Usa `0900000000` como WhatsApp ficticio. Ve a **Mis productos → Nuevo producto** y publica un `Brownie de prueba` por `$2,50`.
2. Como **comprador**, busca la tienda o el brownie en la Vitrina, agrégalo al carrito y elige Biblioteca, un día, una hora válida y **Efectivo**. Guarda el pedido. Si se abre WhatsApp, cierra esa pestaña para evitar contactar al número de prueba. Revisa el pedido en **Mis pedidos**.
3. Como **vendedor**, entra a **Mi tienda → Pedidos de mi tienda** y marca el pedido como **Entregado**. Vuelve a **Mis pedidos** con la cuenta compradora y comprueba el estado.
4. Desde la tienda pública y con la cuenta **compradora**, pulsa **Reportar** y elige un motivo de prueba. Abre **Reportes** en Filament y confirma que aparece.

Si el registro local no muestra el código, verifica `MAIL_MAILER=log` en `api/.env`, ejecuta `php artisan config:clear` desde `api/` y reinicia Laravel. Si la tienda no se puede crear por falta de opciones, comprueba que ambos comandos de carga de catálogos se ejecutaron sobre la misma base configurada en Laravel.

## Estado de este incremento

Laravel consulta PostgreSQL. Flutter representa el catálogo y sus estados de carga, error y vacío con las respuestas de esa API.

Los datos definitivos y el recorrido con tres participantes están en [preparación de la prueba web](docs/preparacion-piloto.md).

La app principal conecta la Vitrina, el acceso institucional, Cuenta, las tiendas, los productos, el inventario, los pedidos, los reportes y Premium con la API real. Filament permite revisar reportes y comprobantes, dar de baja y reactivar tiendas. Las guías incluyen [probar el acceso](docs/acceso-y-cuenta.md), [publicar una tienda](docs/mi-tienda.md), [gestionar productos](docs/mis-productos.md), [hacer y gestionar pedidos](docs/carrito-y-pedidos.md), [moderar tiendas](docs/reportes-y-moderacion.md) y [probar Premium](docs/premium.md). El SMTP y los datos definitivos de privacidad se configuran antes del piloto. La referencia de recorridos se conserva en `app/lib/main_demo.dart`.

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

## Desarrollo con Flutter

Para editar Flutter con recarga rápida, mantén Laravel activo y ejecuta desde la raíz del repositorio los comandos siguientes. Para Android también se requiere Android SDK y un emulador o un dispositivo.

```powershell
cd app
flutter pub get
flutter run -d chrome
```

Para validar el código desde `app/` ejecuta estos comandos.

```powershell
flutter analyze
flutter test
```

Consulta también [Flutter conectado a la API](docs/flutter-vitrina-api.md). La maqueta de referencia se ejecuta con `flutter run -t lib/main_demo.dart`.

## Atajos de la instalación portátil en Windows

Si ya tienes las herramientas portátiles en `.tools/`, usa `Abrir PuntoKampus.cmd` para servir la compilación web y arrancar la API y PostgreSQL. `Iniciar API.cmd` sirve solo la API con PostgreSQL en el puerto `5433`. Para ejecutar Flutter desde `app/`, puedes usar `../.tools/flutter/bin/flutter.bat`. Los binarios de `.tools/` se preparan por separado en cada computadora. Consulta la configuración en [api/README.md](api/README.md).

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
