<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;

class CatalogoAcademicoUtbSeeder extends Seeder
{
    public function run(): void
    {
        // Las fuentes y los planes consultados están en docs/catalogo-utb.md.
        $catalogo = [
            'Facultad de Administración, Finanzas e Informática' => [
                'Administración Pública',
                'Comercio',
                'Contabilidad y Auditoría',
                'Sistemas de Información',
                'Tecnologías de la Información',
            ],
            'Facultad de Ciencias Agropecuarias' => [
                'Agroindustria',
                'Agronomía',
                'Agropecuaria',
                'Gestión Ambiental',
                'Medicina Veterinaria',
            ],
            'Facultad de Ciencias de la Salud' => [
                'Enfermería',
                'Fisioterapia',
                'Nutrición y Dietética',
                'Obstetricia',
                'Optometría',
            ],
            'Facultad de Ciencias Jurídicas, Sociales y de la Educación' => [
                'Comunicación',
                'Derecho',
                'Educación Básica',
                'Educación Inicial',
                'Pedagogía de la Actividad Física y Deporte',
                'Pedagogía de las Ciencias Experimentales (Informática)',
                'Psicología',
                'Psicología Educativa',
                'Turismo',
                'Turismo Rural, Sostenible e Intercultural',
            ],
        ];

        DB::transaction(function () use ($catalogo) {
            foreach ($catalogo as $facultad => $carreras) {
                DB::table('facultades')->insertOrIgnore(['nombre' => $facultad]);
                $facultadId = DB::table('facultades')->where('nombre', $facultad)->value('id');
                DB::table('carreras')->insertOrIgnore(array_map(
                    fn (string $nombre) => ['facultad_id' => $facultadId, 'nombre' => $nombre],
                    $carreras,
                ));
            }
        });
    }
}
