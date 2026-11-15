<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('productos', fn (Blueprint $tabla) => $tabla->integer('existencias')->nullable());
        DB::statement('ALTER TABLE productos ADD CONSTRAINT ck_productos_existencias CHECK (existencias BETWEEN 0 AND 999999)');
        Schema::create('movimientos_inventario', function (Blueprint $tabla) {
            $tabla->id();
            $tabla->foreignId('producto_id')->constrained('productos')->cascadeOnDelete();
            $tabla->foreignId('pedido_id')->nullable()->constrained('pedidos')->nullOnDelete();
            $tabla->string('tipo', 20);
            $tabla->integer('variacion');
            $tabla->integer('existencias_resultantes')->nullable();
            $tabla->timestamp('creado_en')->useCurrent();
            $tabla->index(['producto_id', 'id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('movimientos_inventario');
        Schema::table('productos', fn (Blueprint $tabla) => $tabla->dropColumn('existencias'));
    }
};
