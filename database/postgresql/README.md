# PostgreSQL de PuntoKampus

PostgreSQL es el motor vigente según el PRD. El [SQL del tramo 1](puntokampus.sql) define las 19 tablas de dominio y las 3 vistas. Mantiene nombres en español, tablas en plural y el [modelo relacional de tercera forma normal](../mysql/modelo.md). Laravel añade las tablas técnicas `migraciones` y `borrados_archivos`.

## Crear una base

1. Usa PostgreSQL 16 o posterior con ICU y la extensión `unaccent` disponible. Crea una base UTF-8 llamada `puntokampus` y un rol propietario con contraseña.
2. Conéctate a esa base con el rol que administra su esquema. Configura `api/.env` desde el ejemplo y ejecuta `php artisan migrate` desde `api/`. La migración aplica el SQL.
3. Para ejecutar el SQL manualmente en pgAdmin o psql, selecciona el archivo completo sobre la base ya creada. El bloque es transaccional, crea la estructura sin filas de negocio y se puede repetir sobre su propia versión. Las tablas de esquemas anteriores sin la marca de PuntoKampus PostgreSQL v1 requieren un destino separado.

Mantenemos claves foráneas, comprobaciones de estado, identificadores autogenerados, importes decimales e índices parciales de Premium. Las marcas de tiempo se guardan en UTC. La fecha de fin de Premium se evalúa en `America/Guayaquil`. La búsqueda conserva coincidencias sin tildes o mayúsculas y trata los comodines como texto.

Flutter usa la base mediante la API de Laravel. Los bloqueos de PostgreSQL por correo serializan los envíos y verificaciones de códigos y la apertura de sesiones.

La migración del acceso por contraseña agrega `usuarios.contrasena_hash` a instalaciones nuevas y existentes. Las filas anteriores conservan su correo y su perfil. Consulta el [contrato de acceso](../../docs/acceso-y-cuenta.md) para desplegar Laravel y Flutter juntos.

## Trasladar desde MySQL v1 en local

1. Conserva el origen y una copia privada de su `.env`. Crea un destino PostgreSQL vacío con sus propias credenciales y aplica `php artisan migrate`.
2. Pon la API en mantenimiento y detén escrituras programadas mientras dure el traslado. Pasa las rutas de los dos archivos de configuración al comando desde la raíz del repositorio:

   ```powershell
   php api/database/legacy/trasladar_mysql_a_postgresql.php origen.env destino.env
   ```

3. Cuando termine, activa el archivo de destino manteniendo `APP_KEY`. El traslado conserva IDs y referencias, valida el contenido de las filas por tabla y ajusta las secuencias para nuevas altas. Las migraciones del destino conservan su propio historial. Los archivos de imagen se conservan en el almacenamiento de Laravel.
4. Levanta la API, comprueba la Vitrina y el acceso institucional. Conserva los datos del origen como respaldo. Si se escriben datos nuevos en PostgreSQL, cualquier reversión requiere trasladarlos para conservarlos.

En el equipo actual, PostgreSQL portátil escucha en `127.0.0.1:5433`. La base anterior queda en `.local/mysql/datos`, con su configuración privada en `.local/postgresql/origen.env`. Los instaladores y contraseñas se mantienen fuera de Git.
