<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        $db = DB::connection();
        if ($db->getDriverName() !== 'mysql' || ! str_starts_with($db->selectOne('SELECT VERSION() AS version')->version, '8.4.')) {
            throw new RuntimeException('El esquema aprobado requiere MySQL 8.4. No se modificaron tablas del dominio.');
        }
        $baseline = $this->baseline();
        // Comprobar TODAS las tablas preexistentes antes de crear cualquiera.
        foreach ($baseline['tablas'] as $name => $table) {
            if ($db->getSchemaBuilder()->hasTable($name)) {
                $definition = array_values((array) $db->selectOne("SHOW CREATE TABLE `$name`"))[1];
                $definition = preg_replace('/ AUTO_INCREMENT=\d+/', '', $definition);
                if (! hash_equals($table['sha256'], hash('sha256', $definition))) {
                    throw new RuntimeException("La tabla $name no coincide con el esquema aprobado. Se requiere una migracion de datos especifica; no se sobrescribio.");
                }
            }
        }
        foreach ($baseline['tablas'] as $table) {
            $db->statement($table['sql']);
        }
        foreach ($baseline['vistas'] as $sql) {
            $db->statement($sql);
        }
    }

    public function down(): void
    {
        $db = DB::connection();
        $baseline = $this->baseline();
        foreach (array_keys($baseline['tablas']) as $name) {
            if ($db->table($name)->exists()) {
                throw new RuntimeException('La base contiene registros. No se permite revertir la estructura inicial con datos.');
            }
        }
        foreach (array_keys($baseline['vistas']) as $name) {
            $db->statement("DROP VIEW IF EXISTS `$name`");
        }
        foreach (array_reverse(array_keys($baseline['tablas'])) as $name) {
            $db->statement("DROP TABLE IF EXISTS `$name`");
        }
    }

    private function baseline(): array
    {
        return json_decode(file_get_contents(database_path('baselines/mysql_v1.json')), true, flags: JSON_THROW_ON_ERROR);
    }
};
