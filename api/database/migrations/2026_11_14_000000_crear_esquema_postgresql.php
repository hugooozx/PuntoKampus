<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public $withinTransaction = false;

    private const TABLAS = [
        'facultades', 'carreras', 'periodos_academicos', 'usuarios', 'perfiles_vendedores',
        'codigos_acceso', 'sesiones_acceso', 'categorias', 'puntos_entrega', 'tiendas',
        'tiendas_categorias', 'productos', 'fotos_productos', 'pedidos', 'detalles_pedidos',
        'reportes', 'cuentas_bancarias', 'configuraciones', 'solicitudes_premium',
    ];

    public function up(): void
    {
        if (DB::getDriverName() !== 'pgsql' || (int) (DB::selectOne('SHOW server_version_num')->server_version_num) < 160000) {
            throw new RuntimeException('PuntoKampus requiere PostgreSQL 16 o posterior.');
        }

        $sql = file_get_contents(base_path('../database/postgresql/puntokampus.sql'));
        DB::unprepared($sql);
    }

    public function down(): void
    {
        DB::transaction(function () {
            foreach (self::TABLAS as $tabla) {
                if (DB::table($tabla)->exists()) {
                    throw new RuntimeException('La base contiene registros. No se permite revertir la estructura inicial con datos.');
                }
            }
            DB::statement('DROP VIEW vistas_planes_tiendas, vistas_totales_pedidos, vistas_detalles_pedidos');
            foreach (array_reverse(self::TABLAS) as $tabla) {
                DB::getSchemaBuilder()->drop($tabla);
            }
            DB::statement('DROP FUNCTION marcar_actualizacion()');
            DB::statement('DROP COLLATION puntokampus_sin_acentos, puntokampus_sin_mayusculas');
        });
    }
};
