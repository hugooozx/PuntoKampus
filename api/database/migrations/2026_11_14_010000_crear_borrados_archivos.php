<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('borrados_archivos', function (Blueprint $tabla) {
            $tabla->id();
            $tabla->string('disco', 16);
            $tabla->string('ruta', 2048);
        });
    }

    public function down(): void
    {
        if (DB::table('borrados_archivos')->exists()) {
            throw new RuntimeException('Hay archivos de cuentas pendientes de borrar.');
        }
        Schema::dropIfExists('borrados_archivos');
    }
};
