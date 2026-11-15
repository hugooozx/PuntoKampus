# Catálogo académico y puntos de entrega

La carga inicial reúne 25 carreras de grado de las cuatro facultades identificadas por la [Universidad Técnica de Babahoyo](https://utb.edu.ec/resena_historica). La revisión se hizo el 15 de noviembre de 2026. La Extensión Quevedo es una sede. El formulario registra la facultad y la carrera y todavía no distingue sedes.

| Facultad | Oferta consultada |
| --- | --- |
| Administración, Finanzas e Informática | [Escuela de Administración](https://fafi.utb.edu.ec/cpa) y [Escuela de Tecnologías de la Información y la Comunicación](https://fafi.utb.edu.ec/info_tics) |
| Ciencias Agropecuarias | [Oferta de la facultad](https://faciag.utb.edu.ec/ofertaacademica) |
| Ciencias de la Salud | [Escuela de Salud y Bienestar](https://fcs.utb.edu.ec/saludybiestar) y [cursos de admisión](https://moodle.canu.utb.edu.ec/course/index.php?categoryid=8) |
| Ciencias Jurídicas, Sociales y de la Educación | [Presencial](http://fcjse.utb.edu.ec/oferta-academica/carrera-presencial), [en línea](http://fcjse.utb.edu.ec/oferta-academica/carrera-online) y [cursos de admisión](https://moodle.canu.utb.edu.ec/course/index.php?categoryid=6) |

Psicología aparece en páginas de ambas facultades. El catálogo inicial la registra en Ciencias Jurídicas, Sociales y de la Educación, que la enumera en sus carreras presenciales y en sus [prácticas preprofesionales](https://fcjse.utb.edu.ec/pppl_quienesomos). Queda por confirmar con la UTB si se requiere también una entrada de Ciencias de la Salud para alguna cohorte.

## Duración por malla publicada

| Carrera | Niveles o períodos | Fuente UTB |
| --- | --- | --- |
| Agroindustria | 8 | [Ficha](https://faciag.utb.edu.ec/agroindustria) |
| Agronomía | 8 | [Ficha](https://faciag.utb.edu.ec/agronomia) |
| Agropecuaria | 8 | [Ficha](https://faciag.utb.edu.ec/node/266) |
| Gestión Ambiental | 8 | [Ficha](https://faciag.utb.edu.ec/gestionambiental) |
| Medicina Veterinaria | 9 | [Ficha](https://faciag.utb.edu.ec/node/267) |
| Comercio | 8 | [Ficha](https://fafi.utb.edu.ec/detalle_carrera_com) |
| Contabilidad y Auditoría | 8 | [Ficha](https://fafi.utb.edu.ec/detalle_carrera_ca) |
| Tecnologías de la Información | 8 | [Ficha](https://fafi.utb.edu.ec/info_tics) |
| Comunicación | 8 | [Malla](https://fcjse.utb.edu.ec/eec-malla-ciencias-comunicacion) |
| Derecho | 8 | [Malla](https://fcjse.utb.edu.ec/eec-malla-ciencias-derecho_online) |
| Educación Básica | 8 | [Malla](https://fcjse.utb.edu.ec/eeb-malla-educacion-basica) |
| Educación Inicial | 8 | [Malla](https://fcjse.utb.edu.ec/eei-malla-educacion-inicial) |
| Pedagogía de la Actividad Física y Deporte | 8 | [Malla](https://fcjse.utb.edu.ec/eed-malla-educacion-deporte) |
| Pedagogía de las Ciencias Experimentales (Informática) | 8 o 9, según el plan | [Malla de 8 niveles](https://fcjse.utb.edu.ec/eei-malla-educacion-pcei) y [ficha de 9 períodos](https://fcjse.utb.edu.ec/content-10) |
| Psicología Educativa | 8 | [Malla](https://fcjse.utb.edu.ec/eec-malla-ciencias-psicologia-online) |
| Turismo | 8 | [Malla](https://fcjse.utb.edu.ec/eet-malla-ciencias-turismo) |

Las demás duraciones quedan por confirmar, incluidas las mallas de Salud. El formulario admite los semestres del 1 al 10 y conserva el semestre que registra cada estudiante. Para limitar el selector por carrera hay que identificar primero el plan que le corresponde, porque una misma carrera puede tener más de una malla.

## Encuentros en Babahoyo

El PRD propone inicialmente la biblioteca y la entrada de cada facultad. El catálogo incluye Biblioteca, Entrada de FAFI, Entrada de FACIAG, Entrada de Ciencias de la Salud y Entrada de FCJSE. La [Biblioteca Universitaria](https://biblioteca.utb.edu.ec/) y la [ubicación de FCJSE](https://fcjse.utb.edu.ec/nosotros/sitio) ubican el campus en la Av. Universitaria km 2½ vía Montalvo. Para acordar la referencia exacta de cada entrada y valorar otros puntos, el PRD usa la encuesta del piloto.

## Cargar en PostgreSQL

Desde `api/` y con el esquema migrado:

```powershell
php artisan db:seed --class=CatalogoAcademicoUtbSeeder
php artisan db:seed --class=CatalogosInicialesSeeder
```

Ambos comandos se pueden repetir. Conservan IDs, perfiles y pedidos existentes. La instalación nueva parte vacía hasta ejecutar las cargas expresamente.
