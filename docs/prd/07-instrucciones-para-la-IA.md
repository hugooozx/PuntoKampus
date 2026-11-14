# Instrucciones para la herramienta de IA

Versión 1, 12 de noviembre de 2026.

**Cómo se usa:** copia el bloque de abajo en un archivo `AGENTS.md` en la raíz del proyecto de código (si usan Claude Code, también como `CLAUDE.md`). Copia además la carpeta `PRD/` completa dentro del proyecto, en `docs/prd/`, para que la herramienta pueda leerla.

**Registro de uso de IA.** La guía de Emprendimiento exige declarar en un anexo qué herramientas de IA se usaron y para qué. Cada uno anota su uso en `docs/registro-ia.md`, con una línea por sesión de trabajo:

```
| Fecha | Quién (servidor/app) | Herramienta | Para qué | Qué se revisó a mano |
```

---

```markdown
# PuntoKampus

Vitrina digital para que los estudiantes de la Universidad Técnica de Babahoyo vendan a la comunidad universitaria. Los requisitos están en `docs/prd/`. Léelos antes de programar algo nuevo.

## Partes

- `servidor/`: Laravel (PHP) con API REST en `/api/v1`, PostgreSQL, Laravel Sanctum para los tokens y Filament para el panel en `/admin`.
- `app/`: Flutter (Material 3). Un solo código para Android y web.

## Reglas que no se rompen

1. La fuente de verdad es `docs/prd/04-datos-reglas-y-api.md`: tablas, campos, rutas y reglas (R1 a R31). Usa exactamente esos nombres, en español y sin tildes. Si algo no está ahí, pregunta antes de inventarlo.
2. No agregues funciones que no estén en `docs/prd/01-alcance-tramo-1.md`. Si una función es del tramo 2, no la hagas.
3. Todo texto que ve el usuario va en español, de tú, con las palabras de `docs/prd/03-pantallas-y-flujos.md` (sección 6). El código, las variables y los comentarios pueden ir en inglés, salvo los nombres de tablas, campos y rutas.
4. Toda regla de negocio se valida en el servidor. La app puede validar para ayudar al usuario, pero el servidor decide (por ejemplo, el total del pedido lo calcula el servidor).
5. Cada ruta protegida comprueba que el usuario solo toca lo suyo. Agrega una prueba que lo demuestre con un usuario ajeno.
6. Cada regla R1 a R31 que implementes lleva al menos una prueba automática (Pest o PHPUnit en el servidor; pruebas de widgets en Flutter para los formularios).
7. Nunca subas al repositorio el archivo `.env`, contraseñas, claves ni tokens.
8. No instales paquetes sin decir cuál, para qué y si está mantenido. Prefiere lo que ya trae Laravel o Flutter.
9. Las fotos de comprobantes se guardan fuera de la carpeta pública y solo se entregan a un administrador o al dueño de la solicitud.
10. Toda pantalla con datos tiene estado de carga, vacío y error (sección 4 de `03`). Botones de al menos 48 × 48 dp y etiquetas visibles en los campos (sección 5 de `03`).

## Cómo trabajar

- Antes de escribir código, di qué archivos vas a crear o cambiar y por qué.
- Haz cambios pequeños, uno por historia (H01, H02...). Al terminar, di qué prueba de `docs/prd/02-historias-tramo-1.md` ya pasa.
- Si una instrucción de la persona contradice los documentos de `docs/prd/`, avísalo antes de seguir.
- Si no sabes algo de una versión de Laravel, Filament o Flutter, revisa la documentación oficial en vez de suponerlo.
```
