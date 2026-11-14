# Trabajo compartido

Las dos personas pueden modificar Flutter, Laravel, MySQL y Filament. Cada tarea tiene una persona responsable de implementarla y otra de revisarla. No hay una asignación permanente de frontend o backend.

## Una rama por tarea

Antes de empezar, acuerden quién toma la tarea y qué archivos o servicios puede afectar. Si dos tareas dependen del mismo contrato, definan primero la respuesta compartida o integren primero la dependencia.

Con un remoto ya conectado y un árbol de trabajo limpio:

```powershell
git switch main
git pull --ff-only
git switch -c feat/nombre-de-la-tarea
```

Si `main` todavía no tiene su primer commit, quien prepare la estructura inicial debe completar ese paso antes de que la otra persona cree ramas dependientes.

Prefijos sugeridos: `feat/`, `fix/`, `docs/` y `chore/`. El nombre identifica el resultado, por ejemplo `feat/pedido-whatsapp`, no al desarrollador ni solo a la tecnología.

## Commits y PR

- Guarda cambios coherentes y revisables: `feat(vitrina): buscar productos sin distinguir tildes`.
- Revisa `git diff` y `git status` antes de confirmar. Agrega archivos concretos cuando sea posible.
- Incluye las migraciones y las pruebas necesarias para reproducir el avance.
- Conserva `pubspec.lock` y `composer.lock` para que ambos usen las mismas dependencias.
- Sube la rama con `git push -u origin nombre-de-la-rama` cuando el remoto esté configurado.
- Abre un PR y utiliza la plantilla. La otra persona revisa antes de integrar en `main`.
- Si una prueba depende de un servicio no disponible, indica cuál falta; no marques la prueba como aprobada.

No suban directamente cambios de funcionalidades a `main`. La protección de rama y la revisión obligatoria se configurarán en GitHub cuando exista el repositorio remoto. Este documento no las habilita por sí mismo.

## Contrato de API

[04-datos-reglas-y-api.md](docs/prd/04-datos-reglas-y-api.md) es el acuerdo compartido. Antes de cambiarlo, avisen a la otra persona y al dueño del producto.

El PR que proponga un cambio debe mostrar:

| Dato | Qué explicar |
| --- | --- |
| Ruta o campo | Nombre exacto y método HTTP |
| Antes y después | Ejemplo concreto de petición o respuesta |
| Impacto Flutter | Modelo, validación, pantalla y estados afectados |
| Impacto servidor | Validación, migración, permisos y respuesta afectados |
| Compatibilidad | Si el cliente anterior sigue funcionando o hay que desplegar juntos |
| Dependencias | PR previo o cambio coordinado necesario |

No cambien silenciosamente nombres, estados o el significado de `null`. Tampoco agreguen campos para resolver una preferencia visual sin justificar su necesidad.

## Datos y secretos

Los `.env`, tokens, claves de firma Android, credenciales de servicios y comprobantes reales quedan fuera de Git. El ejemplo de entorno solo contiene valores ficticios o vacíos. Antes de subir, revisen también capturas, fixtures y logs.

Los datos de demostración deben poder distinguirse de datos reales y cargarse de forma explícita. No se cargan tiendas ni pedidos inventados en producción.

## Validación antes de revisión

Ejecuta las pruebas correspondientes al cambio: análisis y tests de Flutter para aplicación; tests Laravel y migraciones para API. Comprueba los flujos visuales modificados en pantalla estrecha y de escritorio. Documenta el resultado real y cualquier limitación del entorno en el PR.
