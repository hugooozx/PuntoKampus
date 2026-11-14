# Decisiones vigentes

Registro inicial: 13 de noviembre de 2026. Esta nota distingue las decisiones posteriores de los documentos originales del PRD; no sustituye el contrato de API.

## Producto y diseño

- La dirección visual de los bocetos guía la implementación: fondo claro cálido, acento naranja, tarjetas blancas, jerarquía legible y controles cómodos en celular.
- El logo provisional es **PK naranja**, simple y limpio. Los detalles adicionales siguen pendientes.
- **Tu campus, tus emprendimientos** es una propuesta provisional de eslogan; no se considera identidad definitiva.
- El login sigue siendo provisional. En esta entrega, el acceso local de demostración debe identificarse como tal; no puede afirmar que envió un correo ni validar identidad institucional real.
- La mascota no está definida. Se conserva únicamente una **mancha naranja provisional**, sin aprobar un personaje con cara, mochila, nombre o animaciones.
- La maqueta HTML original sirve como referencia de escenarios, no de diseño.
- El diseño sigue el skill **UI/UX Pro Max** compartido en `ui-ux-pro-max-skill-main.zip`. Sus recomendaciones se subordinan a los requisitos del producto.

## Navegación y reglas visuales

- Cuatro secciones: Vitrina, Mis pedidos, Mi tienda y Cuenta.
- Navegación inferior en celular; navegación lateral como adaptación de escritorio de los bocetos.
- Vitrina abre con tiendas y permite buscar, cambiar categoría y alternar Tiendas/Productos.
- La insignia Premium es **Sacó 10**. No cambia el orden de las tiendas ni expresa una calificación o certificación universitaria.
- Ámbar para pedidos pendientes y solicitudes en revisión. Verde para disponibilidad, entregas completadas o acciones guardadas correctamente; el texto del estado siempre acompaña al color.
- El visto de éxito de «Pedido registrado» significa que el registro se guardó, no que el vendedor lo entregó ni que se pagó.
- Crear tienda se propone en dos pasos: datos del vendedor y datos de la tienda. No cambia los campos del contrato.
- Los importes, cuentas bancarias y datos de los bocetos son ficticios. No fijan el precio de Premium ni una cuenta receptora real.

## Implementación y colaboración

- Se autorizó comenzar la implementación tomando los bocetos como referencia, con identidad, login y mascota provisionales.
- Stack: Flutter Android/web; API Laravel; PostgreSQL; administración Filament.
- Ambos desarrolladores trabajan en todo el stack. Reparten funcionalidades completas, usan una rama por tarea y revisión cruzada mediante PR antes de integrar a `main`.
- Los documentos originales que separan responsables por tecnologías se conservan como fuente histórica; la instrucción posterior del usuario prevalece.
- El contrato `docs/prd/04-datos-reglas-y-api.md` se conserva. Cualquier cambio de campos o respuestas requiere explicar su impacto en cliente y servidor.
- Una demostración local no equivale a un piloto con usuarios reales. El acceso OTP, correo, conexión con API, persistencia remota y operaciones de administración se validan antes de usar datos reales.
- El remoto de GitHub, la protección de `main` y el entorno de despliegue están pendientes de configuración.

## Diseño de la base de datos — 14 de noviembre de 2026

- Por solicitud posterior del usuario, se prepara el diseño para **MySQL 8.4 LTS**. Esta decisión sustituye PostgreSQL como motor objetivo; el código inicial de Laravel aún requiere adaptación.
- El SQL completo está en `database/mysql/puntokampus.sql`: nombres en español y plural, tablas en tercera forma normal, sin datos iniciales y reejecutable sin borrar registros.
- El modelo separa facultades, carreras y perfiles de vendedores; usa una tabla de asociación para las categorías; calcula totales y vigencia Premium sin duplicarlos en las tablas.
- Las diferencias con `04-datos-reglas-y-api.md`, la propuesta de campos/rutas académicos y el impacto en Flutter y Laravel se documentan en `database/mysql/README.md`. El PRD original permanece intacto como referencia.
- Esta entrega es el diseño de datos y su validación en MySQL, no la integración de la API con el nuevo esquema. Las migraciones iniciales no se deben ejecutar sobre este esquema hasta conciliarlas.

## Aprobación e integración de MySQL v1

- El 14 de noviembre el usuario aprobó la base y autorizó integrar Laravel.
- La migración nueva crea el esquema o adopta el SQL aprobado verificando definiciones. Las migraciones de la demo se archivaron fuera del ejecutor.
- La API pública de Vitrina ya consulta MySQL. Los cambios de representación y sus efectos para Flutter se detallan en `docs/integracion-mysql-v1.md`.
- Desarrollo permanece sin contenido; las pruebas usan una base independiente. No se agregan catálogos ni tiendas automáticamente.
- La conexión de Flutter, fidelidad visual a las láminas y funcionalidades autenticadas siguen siendo trabajo pendiente.
