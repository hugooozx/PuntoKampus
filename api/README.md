# API de PuntoKampus

Laravel 13 y PostgreSQL. Esta entrega implementa las rutas públicas de Vitrina según [el contrato](../docs/prd/04-datos-reglas-y-api.md).

1. Instala PHP 8.3 o posterior con `pdo_pgsql` y Composer.
2. Ejecuta `composer install` en esta carpeta.
3. Copia `.env.example` a `.env` y configura tu base PostgreSQL local.
4. Ejecuta `php artisan key:generate`, `php artisan migrate --seed` y `php artisan serve`.

La carga inicial agrega las categorías y puntos de entrega propuestos. Las tiendas ficticias están en la demo de Flutter y los ejemplos de prueba de Laravel.

Rutas públicas bajo `/api/v1`:

| Ruta GET | Respuesta |
| --- | --- |
| `/categorias` | `data` con categorías activas en orden |
| `/puntos-entrega` | `data` con puntos activos en orden |
| `/tiendas` | `data`, `links` y `meta` de la lista paginada |
| `/tiendas/{slug}` | `data` con la tienda activa y sus productos |
| `/productos` | `data`, `links` y `meta` de la lista paginada |

Las listas aceptan `categoria` (ID), `buscar` y `pagina`. Se devuelven hasta 20 elementos por página. La búsqueda compara nombres y descripciones sin distinguir mayúsculas ni tildes. El plan Premium no cambia el orden. El precio se devuelve como texto decimal con dos cifras.

Ejecuta `php artisan test` con `pdo_sqlite` para verificar los filtros, la paginación y la visibilidad. Las pruebas usan SQLite en memoria. La integración con PostgreSQL, el acceso por correo y Filament quedan pendientes.
