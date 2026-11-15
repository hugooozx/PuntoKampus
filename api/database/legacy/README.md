# Referencia de la primera demo

Estas migraciones corresponden al esquema inicial de PostgreSQL/SQLite. Se conservan como historial, fuera de `database/migrations`; Artisan no las ejecuta.

El esquema MySQL v1 está congelado en `database/baselines/mysql_v1.json`. Su migración queda archivada aquí. El motor activo vuelve a PostgreSQL según el PRD. Para trasladar una base local MySQL v1, consulta [la guía de PostgreSQL](../../../database/postgresql/README.md). Mantén estas migraciones fuera del directorio ejecutable.

Se utilizan caché y sesiones en archivos, y cola síncrona durante esta etapa; no se crean las tablas técnicas `cache`, `jobs`, etc. El registro técnico de migraciones se llama `migraciones`.
