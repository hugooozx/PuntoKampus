<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class Usuario extends Authenticatable
{
    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['correo', 'nombres', 'codigo_estudiante', 'facultad', 'carrera', 'semestre', 'whatsapp', 'mostrar_whatsapp', 'acepto_privacidad_en'];

    protected $hidden = ['correo', 'codigo_estudiante', 'facultad', 'carrera', 'semestre', 'whatsapp', 'es_admin', 'acepto_privacidad_en'];

    protected function casts(): array
    {
        return ['es_admin' => 'boolean', 'mostrar_whatsapp' => 'boolean', 'acepto_privacidad_en' => 'datetime'];
    }
}
