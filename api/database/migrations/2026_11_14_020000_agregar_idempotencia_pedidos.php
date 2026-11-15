<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('pedidos', function (Blueprint $tabla) {
            $tabla->string('clave_envio', 32)->nullable();
            $tabla->string('huella_envio', 64)->nullable();
            $tabla->unique(['comprador_id', 'clave_envio'], 'uq_pedidos_envio');
        });
    }

    public function down(): void
    {
        Schema::table('pedidos', function (Blueprint $tabla) {
            $tabla->dropUnique('uq_pedidos_envio');
            $tabla->dropColumn(['clave_envio', 'huella_envio']);
        });
    }
};
