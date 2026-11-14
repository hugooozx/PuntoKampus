# Referencia de la primera demo

Estas migraciones corresponden al esquema inicial de PostgreSQL/SQLite. Se conservan como historial, fuera de `database/migrations`; Artisan no las ejecuta.

El esquema aprobado para MySQL está congelado en `database/baselines/mysql_v1.json` y lo aplica la migración del 14 de noviembre. Una base del esquema anterior requiere un plan incremental de transferencia de datos: la nueva migración la rechaza si sus tablas no coinciden. No copiar estos archivos otra vez al directorio ejecutable.

Se utilizan caché y sesiones en archivos, y cola síncrona durante esta etapa; no se crean las tablas técnicas `cache`, `jobs`, etc. El registro técnico de migraciones se llama `migraciones`.
