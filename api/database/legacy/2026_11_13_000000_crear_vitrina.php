<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('usuarios', function (Blueprint $table) {
            $table->id();
            $table->string('correo')->unique();
            $table->string('nombres');
            $table->string('codigo_estudiante')->nullable();
            $table->string('facultad')->nullable();
            $table->string('carrera')->nullable();
            $table->unsignedTinyInteger('semestre')->nullable();
            $table->string('whatsapp')->nullable();
            $table->boolean('mostrar_whatsapp')->default(false);
            $table->boolean('es_admin')->default(false);
            $table->timestampTz('acepto_privacidad_en');
            $table->enum('estado', ['activa', 'desactivada'])->default('activa');
            $table->timestampTz('creado_en')->nullable();
            $table->timestampTz('actualizado_en')->nullable();
        });
        foreach (['categorias', 'puntos_entrega'] as $name) {
            Schema::create($name, function (Blueprint $table) use ($name) {
                $table->id();
                $table->string('nombre');
                $table->boolean('activa')->default(true);
                $table->unsignedInteger('orden')->default(0);
                if ($name === 'puntos_entrega') {
                    $table->text('descripcion')->nullable();
                }
            });
        }
        Schema::create('tiendas', function (Blueprint $table) {
            $table->id();
            $table->foreignId('usuario_id')->unique()->constrained('usuarios');
            $table->string('nombre', 40);
            $table->string('slug')->unique();
            $table->string('descripcion', 300)->nullable();
            $table->text('logo_url')->nullable();
            $table->text('portada_url')->nullable();
            $table->foreignId('categoria_1_id')->constrained('categorias');
            $table->foreignId('categoria_2_id')->nullable()->constrained('categorias');
            $table->string('horario', 100)->nullable();
            $table->foreignId('punto_entrega_id')->constrained('puntos_entrega');
            $table->enum('plan', ['gratis', 'premium'])->default('gratis');
            $table->date('premium_hasta')->nullable();
            $table->enum('estado', ['activa', 'dada_de_baja'])->default('activa')->index();
            $table->text('motivo_baja')->nullable();
            $table->timestampTz('dada_de_baja_en')->nullable();
        });
        Schema::create('productos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tienda_id')->constrained('tiendas');
            $table->string('nombre', 60);
            $table->string('descripcion', 300)->nullable();
            $table->decimal('precio', 8, 2);
            $table->boolean('disponible')->default(true);
            $table->timestampTz('eliminado_en')->nullable();
        });
        Schema::create('producto_fotos', function (Blueprint $table) {
            $table->id();
            $table->foreignId('producto_id')->constrained('productos');
            $table->text('url');
            $table->unsignedTinyInteger('orden');
        });
    }

    public function down(): void
    {
        foreach (['producto_fotos', 'productos', 'tiendas', 'puntos_entrega', 'categorias', 'usuarios'] as $name) {
            Schema::dropIfExists($name);
        }
    }
};
