# API Laravel de PuntoKampus

Laravel 13 usa PostgreSQL para Vitrina, acceso institucional, Cuenta y Mi tienda. Las rutas de Flutter se conservan.

## En esta computadora

Abre **Iniciar API.cmd** desde la raíz. Inicia PostgreSQL portátil en `127.0.0.1:5433`, aplica las migraciones y sirve la API en `http://127.0.0.1:8000`. Si la API ya está ejecutándose, puedes usar esa instancia. **Abrir PuntoKampus.cmd** también prepara PostgreSQL, la API y la aplicación web.

```powershell
python scripts/postgresql_local.py estado
python scripts/postgresql_local.py detener
```

Los datos persistentes están en `.local/postgresql/datos`. La instancia usa dos bases y dos roles separados para desarrollo y pruebas. Los archivos con claves quedan fuera de Git.

## En otra computadora

Se requiere PostgreSQL 16 o posterior con ICU y `unaccent`, PHP 8.4 con `pdo_pgsql`, GD con WebP para las fotos de productos y Composer. Crea las bases UTF-8 `puntokampus` y `puntokampus_pruebas`, cada una con su propio rol propietario. Desde `api/`:

1. Ejecuta `composer install`.
2. Copia `.env.example` a `.env` y configura la conexión `pgsql`.
3. Ejecuta `php artisan key:generate` y `php artisan migrate`.
4. Inicia con `php artisan serve --host=127.0.0.1 --port=8000`.

Las migraciones aplican el [SQL de PostgreSQL](../database/postgresql/puntokampus.sql) y preparan las tablas técnicas. Despliega la carpeta del esquema con la API. El [procedimiento de traslado](../database/postgresql/README.md) documenta cómo mover datos de una instalación MySQL v1. Los catálogos iniciales se cargan explícitamente cuando se necesiten.

## API pública

| Ruta GET bajo `/api/v1` | Resultado |
| --- | --- |
| `/categorias` | Categorías activas, ordenadas por `orden` e `id` |
| `/puntos-entrega` | Puntos activos, ordenados por `orden` e `id` |
| `/tiendas` | Tiendas activas; `data`, `links` y `meta` |
| `/tiendas/{slug}` | Tienda activa con sus productos no eliminados |
| `/productos` | Productos no eliminados de tiendas activas; incluye agotados |

Filtros: `categoria`, `buscar` y `pagina`. Paginación estable por ID, 20 elementos por página. Una categoría secundaria también coincide. La búsqueda usa unaccent y compara sin distinguir mayúsculas ni acentos y trata `%`, `_` y `!` como texto literal, no como patrones enviados por el cliente.

La respuesta mantiene `categoria_1_id`, `categoria_2_id`, `plan`, `premium_hasta`, `fotos` y los precios como cadenas con dos decimales. Laravel reconstruye esos campos desde las relaciones normalizadas y la vista de vigencia. Premium nunca cambia el orden. La portada se oculta si el plan está vencido; WhatsApp solo se incluye con `mostrar_whatsapp=true`. No se serializan perfiles, correos, códigos estudiantiles, comprobantes ni cuentas bancarias en estos recursos públicos.

Una base vacía responde `200` y `data: []`; una tienda ausente o dada de baja responde `404`. No se insertaron tiendas de demostración para llenar la vitrina.

## Pruebas sobre PostgreSQL

Copia `.env.testing.example` a `.env.testing` y completa las credenciales del rol exclusivo de pruebas. La suite exige PostgreSQL y la base `puntokampus_pruebas`.

```powershell
php artisan config:clear
php artisan migrate --env=testing
php artisan test
```

En esta computadora, desde `api/`, sustituye `php` por `../.tools/composer/php/php.exe`. Las pruebas usan PostgreSQL real e incluyen la ejecución repetida del esquema, búsqueda, acceso, Cuenta, permisos y publicación de tiendas.

Para los flujos autenticados, consulta [acceso y cuenta](../docs/acceso-y-cuenta.md) y [Mi tienda](../docs/mi-tienda.md).
