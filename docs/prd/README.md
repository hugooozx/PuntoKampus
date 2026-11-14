# PuntoKampus: documentos de requisitos

Estos archivos dicen qué tiene que hacer la plataforma y cómo se comprueba que quedó bien hecha. Son la referencia para quien programa y para quien revisa. Si algo no está aquí, no entra sin antes hablarlo con el dueño del producto.

## Cómo encajan las piezas

La plataforma tiene dos partes que se construyen **al mismo tiempo**, no una después de la otra. Nada se "pasa" de PHP a Flutter.

| Parte | Hecha con | Qué hace | Quién la ve |
|---|---|---|---|
| App y versión web | Flutter | Las pantallas: vitrina, carrito, tienda. Un mismo código sale como app de Android y como página web | Compradores y vendedores |
| Servidor | Laravel (PHP) | Recibe lo que hace cada persona, revisa sus permisos, guarda y entrega los datos, envía el código al correo | Nadie: trabaja detrás |
| Base de datos | PostgreSQL | Guarda todo | Nadie |
| Panel del administrador | Filament (PHP), dentro del servidor | Tiendas, reportes, pagos | Solo el equipo |

Es como un restaurante: Flutter es el salón y la carta, lo que el cliente ve y toca. Laravel es la cocina, que recibe el pedido, lo prepara y lo anota. PostgreSQL es la despensa. El salón y la cocina se construyen a la vez y se hablan todo el tiempo.

Lo que une a las dos partes es la **API**: la lista de lo que la app le pide al servidor y de lo que el servidor le responde (por ejemplo, "dame las tiendas de la categoría Comida"). Está escrita en `04-datos-reglas-y-api.md`. Mientras los dos respeten esa lista, cada uno avanza sin esperar al otro.

## En qué orden leerlos

| Archivo | Qué contiene | Estado |
|---|---|---|
| `00-PRD-general.md` | El producto completo: problema, usuarios, funciones por tramo, arquitectura, requisitos generales y decisiones cerradas | Listo (12/11/2026) |
| `01-alcance-tramo-1.md` | Una página: qué entra en el tramo 1, qué no entra y cuándo se considera terminado | Listo (12/11/2026) |
| `02-historias-tramo-1.md` | Cada función del tramo 1 con su prueba de aceptación | Listo (12/11/2026) |
| `03-pantallas-y-flujos.md` | Pantallas, recorridos, estados y textos de la interfaz | Listo (12/11/2026) |
| `04-datos-reglas-y-api.md` | Tablas de la base de datos, reglas del negocio, permisos por rol y la API (el acuerdo entre servidor y app) | Listo (12/11/2026) |
| `05-privacidad-y-google-play.md` | Datos personales, consentimiento, política de privacidad, borrado de cuenta y prueba cerrada | Listo (12/11/2026) |
| `06-plan-de-trabajo.md` | Ciclos semanales y lista de revisión de cada viernes | Listo (12/11/2026) |
| `07-instrucciones-para-la-IA.md` | Reglas para la herramienta de IA que ayude a programar (se copia al proyecto de código) | Listo (12/11/2026) |

## Quién es quién

Los documentos no llevan nombres. Hablan de funciones:

- **Dueño del producto:** decide qué entra y qué no, aprueba estos documentos y revisa los avances cada viernes. También revisa los reportes de tiendas.
- **Servidor:** quien programa la parte de Laravel, la base de datos PostgreSQL y el panel del administrador.
- **App:** quien programa la app de Flutter (Android y versión web).

## Cómo se cambian

Cualquier cambio lo aprueba el dueño del producto. Al cambiar algo, se anota abajo con la fecha y el motivo. Los cambios no se aplican a mitad de semana: entran en el ciclo siguiente.

## Cambios

| Fecha | Cambio | Motivo |
|---|---|---|
| 12/11/2026 | Primera versión de `00` y `01` | Inicio del desarrollo |
| 12/11/2026 | Documentos `02` a `07` | Segunda parte del PRD |
| 12/11/2026 | `00` versión 1.1: insignia "Matriculado", regla de trabajos académicos y propuestas confirmadas. README: sección "Cómo encajan las piezas" | Respuestas del dueño del producto |
