# Integración de la API con MySQL v1

14 de noviembre de 2026. Base v1 aprobada por el dueño del producto. Rama `feat/api-vitrina-mysql`, dependiente de `feat/esquema-mysql` y de la API inicial de Vitrina.

## Qué se integró

- Migración de Laravel para las 19 tablas y 3 vistas, con registro técnico `migraciones`.
- Conexión MySQL 8.4 en UTC, modo estricto, InnoDB y `utf8mb4_0900_ai_ci`.
- Lecturas de Vitrina sobre tablas normalizadas; categorías mediante asociación, WhatsApp desde perfil de vendedor y Premium desde la vista de vigencia.
- Pruebas sobre MySQL con base y usuario separados; el entorno de desarrollo permanece vacío.

## Contrato para ambos desarrolladores

Los métodos y rutas públicas del PRD no cambian. `categoria_1_id` y `categoria_2_id` siguen siendo IDs escalares de entrada/salida; Laravel los lee desde `tiendas_categorias.orden`. Flutter no debe conocer la tabla intermedia.

Los precios continúan como texto decimal (`"1.50"`), la lista `fotos` conserva `id`, `url` y `orden`, y los listados mantienen `data`, `links`, `meta`. Las categorías y puntos de entrega no exponen las nuevas fechas internas.

`plan` se calcula desde las solicitudes aprobadas. `premium_hasta` es `null` cuando no hay Premium vigente, según el diseño aprobado; Flutter debe tratar esa fecha como opcional. Las portadas permanecen guardadas, pero la respuesta devuelve `portada_url: null` para el plan gratis.

WhatsApp se omite si no existe consentimiento. Con consentimiento se incluye tanto en el detalle como en las representaciones de tienda de los listados; antes la API inicial solo cargaba el usuario en el detalle. El campo sigue siendo opcional. Flutter debe comprobar su presencia, no sustituirlo por un teléfono ficticio.

No se cambian todavía los formularios de cuenta ni se agregan las rutas académicas propuestas. Su implementación se coordinará en la tarea de autenticación y perfil.

## Pruebas y límites

11 pruebas de Laravel, 87 aserciones, aprobadas en MySQL 8.4.13. Listados HTTP de desarrollo comprobados con cero registros. Las 51 verificaciones anteriores corresponden al diseño SQL, no se suman como si fueran nuevas pruebas de rutas.

No hay endpoints de escritura abiertos para crear datos sin autenticación. La prueba de publicar una tienda desde Flutter corresponde al siguiente recorrido con identidad y permisos; este PR no afirma que ya exista.

Instrucciones de reproducción, migraciones, compatibilidad con SQL importado y configuración local en [api/README.md](../api/README.md).
