<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class PerfilVendedor extends Model
{
    protected $table = 'perfiles_vendedores';

    protected $primaryKey = 'usuario_id';

    public $incrementing = false;

    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['usuario_id', 'carrera_id', 'codigo_estudiante', 'semestre', 'whatsapp', 'mostrar_whatsapp'];

    protected $hidden = ['codigo_estudiante', 'carrera_id', 'semestre', 'whatsapp'];

    protected function casts(): array
    {
        return ['mostrar_whatsapp' => 'boolean', 'semestre' => 'integer'];
    }
}
