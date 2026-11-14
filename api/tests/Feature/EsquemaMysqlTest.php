<?php

namespace Tests\Feature;

use Illuminate\Support\Facades\DB;
use RuntimeException;
use Tests\TestCase;

class EsquemaMysqlTest extends TestCase
{
    private function migration(): object
    {
        return require database_path('migrations/2026_11_14_000000_adoptar_esquema_mysql_v1.php');
    }

    public function test_migracion_vacia_reversible_y_repetible(): void
    {
        $migration = $this->migration();
        $migration->down();
        $this->assertFalse(DB::getSchemaBuilder()->hasTable('usuarios'));
        $migration->up();
        $migration->up();
        $tables = DB::select("SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE'");
        $this->assertCount(20, $tables); // 19 de dominio y migraciones.
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

    public function test_no_adopta_una_tabla_con_definicion_incompatible(): void
    {
        DB::statement('ALTER TABLE categorias ADD columna_incompatible INT NULL');
        try {
            $this->migration()->up();
            $this->fail('Una estructura distinta requiere migracion explicita.');
        } catch (RuntimeException $exception) {
            $this->assertStringContainsString('categorias no coincide', $exception->getMessage());
        } finally {
            DB::statement('ALTER TABLE categorias DROP COLUMN columna_incompatible');
        }
    }
}
