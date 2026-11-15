<?php

namespace Tests\Feature;

use Illuminate\Database\QueryException;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\TestCase;

class EsquemaPostgresqlTest extends TestCase
{
    private function migration(): object
    {
        return require database_path('migrations/2026_11_14_000000_crear_esquema_postgresql.php');
    }

    public function test_migracion_vacia_reversible_y_repetible(): void
    {
        $migration = $this->migration();
        $inventario = require database_path('migrations/2026_11_15_000000_agregar_inventario.php');
        $inventario->down();
        $migration->down();
        $this->assertFalse(DB::getSchemaBuilder()->hasTable('usuarios'));
        $migration->up();
        $migration->up();
        (require database_path('migrations/2026_11_14_020000_agregar_idempotencia_pedidos.php'))->up();
        $inventario->up();
        (require database_path('migrations/2026_11_16_000000_agregar_codigo_administracion.php'))->up();
        $tables = DB::select("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE'");
        $this->assertCount(22, $tables); // 20 de dominio, migraciones y reintentos de archivos.
        $this->assertDatabaseCount('usuarios', 0);
        $this->assertDatabaseCount('tiendas', 0);
    }

    public function test_adopta_el_sql_con_datos_y_rechaza_rollback_destructivo(): void
    {
        $id = DB::table('categorias')->insertGetId(['nombre' => 'Conservar']);
        try {
            $this->migration()->up();
            $this->assertDatabaseHas('categorias', ['id' => $id, 'nombre' => 'Conservar']);
            try {
                $this->migration()->down();
                $this->fail('No debe revertir una base con registros.');
            } catch (RuntimeException $exception) {
                $this->assertStringContainsString('contiene registros', $exception->getMessage());
                $this->assertDatabaseHas('categorias', ['id' => $id]);
            }
        } finally {
            DB::table('categorias')->where('id', $id)->delete();
        }
    }

    public function test_no_adopta_un_esquema_anterior_sin_marca(): void
    {
        DB::statement('COMMENT ON TABLE usuarios IS NULL');
        try {
            $this->migration()->up();
            $this->fail('Una estructura distinta requiere migracion explicita.');
        } catch (QueryException $exception) {
            DB::unprepared('ROLLBACK');
            $this->assertStringContainsString('otro esquema', $exception->getMessage());
        } finally {
            DB::statement("COMMENT ON TABLE usuarios IS 'PuntoKampus PostgreSQL v1'");
        }
    }

    public function test_catalogo_conserva_unicidad_sin_mayusculas_ni_tildes(): void
    {
        $id = DB::table('categorias')->insertGetId(['nombre' => 'Café']);
        try {
            $this->expectException(UniqueConstraintViolationException::class);
            DB::table('categorias')->insert(['nombre' => 'CAFE']);
        } finally {
            DB::table('categorias')->where('id', $id)->delete();
        }
    }
}
