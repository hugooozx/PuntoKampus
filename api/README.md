# API real de Vitrina

Laravel 13 con **MySQL 8.4**, sobre la versión 1 de la base aprobada. Las rutas públicas consultan MySQL. La aplicación Flutter ya consume esta API desde su entrada principal; el ajuste visual fiel a las láminas aprobadas sigue pendiente de recuperarlas.

## En esta computadora

Desde la raíz, abrir **`Iniciar API.cmd`**. Inicia MySQL portátil en `127.0.0.1:3307`, ejecuta las migraciones pendientes y sirve la API en `http://127.0.0.1:8000`. Mantener abierta la ventana de la API. Si ya está ejecutándose en ese puerto, usar esa instancia.

Para consultar o detener solamente MySQL:

```powershell
python scripts/mysql_local.py estado
python scripts/mysql_local.py detener
```

El servidor portátil no se instala como servicio de Windows. Sus datos persistentes están en `.local/mysql/datos`. Las contraseñas aleatorias se guardan únicamente en archivos ignorados por Git; los dos entornos tienen usuarios distintos, limitados cada uno a su base. Se preserva una copia local de los `.env` previos durante la primera configuración.

## En otra computadora

Se necesita MySQL 8.4, PHP 8.4 con `pdo_mysql`, Composer y las extensiones exigidas por `composer.lock`. No es necesario Node para ejecutar esta API.

1. Crear dos bases vacías con `utf8mb4_0900_ai_ci`: `puntokampus` y `puntokampus_pruebas`. Crear usuarios de desarrollo y pruebas con permisos de migración únicamente en su base respectiva.
2. Desde `api/`, ejecutar `composer install`.
3. Copiar `.env.example` a `.env` y completar los datos locales. Usar `DB_CONNECTION=mysql`, el puerto del servidor y `DB_COLLATION=utf8mb4_0900_ai_ci`.
4. Ejecutar `php artisan key:generate` y `php artisan migrate`.
5. Ejecutar `php artisan serve --host=127.0.0.1 --port=8000`.

No hace falta importar primero el SQL: la migración crea todas las tablas y vistas. También puede adoptar una base creada con el [SQL aprobado](../database/mysql/puntokampus.sql), incluso con registros, si sus definiciones coinciden. Verifica columnas, índices y restricciones mediante las definiciones canónicas de MySQL antes de crear cualquier tabla del dominio. El contador `AUTO_INCREMENT` no afecta esa comparación.

La base contiene **19 tablas de dominio vacías, 3 vistas y una tabla técnica `migraciones`**. Esta última tiene el registro de la migración; no es contenido ficticio. `DatabaseSeeder` no carga datos. El seeder de catálogos iniciales se conserva como opción explícita, pero no se ejecuta durante instalación ni arranque.

Las migraciones antiguas de PostgreSQL/SQLite están archivadas en `database/legacy`, fuera del directorio ejecutable. La nueva migración rechaza estructuras incompatibles en lugar de alterarlas silenciosamente. Su `down()` solo permite revertir si todas las tablas del dominio están vacías. No usar `migrate:fresh`, `db:wipe` o herramientas equivalentes sobre una base con datos: esos comandos evitan la protección del `down()`.

La definición congelada está en `database/baselines/mysql_v1.json`, con las sentencias exactas del SQL aprobado y las huellas de las definiciones de MySQL 8.4. No editarla al evolucionar el producto: crear nuevas migraciones. La adopción es estricta; una estructura equivalente pero con nombres de índices distintos necesita revisión, no un reemplazo forzado.

## API pública

| Ruta GET bajo `/api/v1` | Resultado |
| --- | --- |
| `/categorias` | Categorías activas, ordenadas por `orden` e `id` |
| `/puntos-entrega` | Puntos activos, ordenados por `orden` e `id` |
| `/tiendas` | Tiendas activas; `data`, `links` y `meta` |
| `/tiendas/{slug}` | Tienda activa con sus productos no eliminados |
| `/productos` | Productos no eliminados de tiendas activas; incluye agotados |

Filtros: `categoria`, `buscar` y `pagina`. Paginación estable por ID, 20 elementos por página. Una categoría secundaria también coincide. La búsqueda usa la collation de MySQL sin distinguir mayúsculas ni acentos y trata `%`, `_` y `!` como texto literal, no como patrones enviados por el cliente.

La respuesta mantiene `categoria_1_id`, `categoria_2_id`, `plan`, `premium_hasta`, `fotos` y los precios como cadenas con dos decimales. Laravel reconstruye esos campos desde las relaciones normalizadas y la vista de vigencia. Premium nunca cambia el orden. La portada se oculta si el plan está vencido; WhatsApp solo se incluye con `mostrar_whatsapp=true`. No se serializan perfiles, correos, códigos estudiantiles, comprobantes ni cuentas bancarias en estos recursos públicos.

Una base vacía responde `200` y `data: []`; una tienda ausente o dada de baja responde `404`. No se insertaron tiendas de demostración para llenar la vitrina.

## Pruebas reales sobre MySQL

Copiar `.env.testing.example` a `.env.testing` y completar la conexión con **el usuario exclusivo de pruebas**. Su base debe llamarse `puntokampus_pruebas`; la suite rechaza otro nombre o motor antes de ejecutar las pruebas.

Desde `api/`:

```powershell
php artisan config:clear
php artisan migrate --env=testing
php artisan test
```

En la instalación portátil, sustituir `php` por `../.tools/composer/php/php.exe`. Ejecutar los comandos de pruebas desde `api/`, no desde la raíz.

Resultado comprobado: **11 pruebas y 87 aserciones**, incluidas creación y reversión de una base vacía, adopción repetida con datos, rechazo de estructuras incompatibles, conservación de datos, filtros, búsqueda literal, paginación, privacidad, agotados y vencimiento Premium. Los fixtures de API se revierten mediante transacciones en la base de pruebas; las comprobaciones de DDL solo trabajan en esa misma base aislada. No se usa SQLite para simular estas reglas.

También se comprobaron los cuatro listados por HTTP contra la base de desarrollo: todos respondieron `200` y cero registros.

## Alcance pendiente

La estructura completa está migrada, pero este incremento implementa únicamente las lecturas de Vitrina. Aún faltan acceso institucional, escritura autenticada de tiendas/productos, pedidos, revisión Premium y Filament. Los endpoints académicos propuestos en el diseño no se publican en esta tarea.

Referencia de implementación: [migraciones de Laravel 13](https://github.com/laravel/docs/blob/13.x/migrations.md) y [pruebas de base de datos](https://github.com/laravel/docs/blob/13.x/database-testing.md).
