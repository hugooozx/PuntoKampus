<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement('ALTER TABLE codigos_acceso DROP CONSTRAINT codigos_acceso_proposito_check');
        DB::statement("ALTER TABLE codigos_acceso ADD CONSTRAINT codigos_acceso_proposito_check CHECK (proposito IN ('acceso', 'eliminar_cuenta', 'administracion', 'recuperar_contrasena'))");
    }

    public function down(): void
    {
        DB::table('codigos_acceso')->where('proposito', 'recuperar_contrasena')->delete();
        DB::statement('ALTER TABLE codigos_acceso DROP CONSTRAINT codigos_acceso_proposito_check');
        DB::statement("ALTER TABLE codigos_acceso ADD CONSTRAINT codigos_acceso_proposito_check CHECK (proposito IN ('acceso', 'eliminar_cuenta', 'administracion'))");
    }
};
