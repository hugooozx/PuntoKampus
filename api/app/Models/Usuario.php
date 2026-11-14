<?php

namespace App\Models;

use Illuminate\Foundation\Auth\User as Authenticatable;

class Usuario extends Authenticatable
{
    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['correo', 'nombres', 'acepto_privacidad_en'];

    protected $hidden = ['correo', 'codigo_estudiante', 'facultad', 'carrera', 'semestre', 'whatsapp', 'es_admin', 'acepto_privacidad_en'];

    protected function casts(): array
    {
        return ['es_admin' => 'boolean', 'acepto_privacidad_en' => 'datetime'];
    }
}
