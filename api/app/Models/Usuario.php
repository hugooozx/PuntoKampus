<?php

namespace App\Models;

use Filament\Models\Contracts\FilamentUser;
use Filament\Models\Contracts\HasName;
use Filament\Panel;
use Illuminate\Foundation\Auth\User as Authenticatable;

class Usuario extends Authenticatable implements FilamentUser, HasName
{
    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['correo', 'nombres', 'acepto_privacidad_en'];

    protected $hidden = ['correo', 'codigo_estudiante', 'facultad', 'carrera', 'semestre', 'whatsapp', 'es_admin', 'acepto_privacidad_en'];

    protected function casts(): array
    {
        return ['es_admin' => 'boolean', 'acepto_privacidad_en' => 'datetime'];
    }

    public function canAccessPanel(Panel $panel): bool
    {
        return $this->es_admin && $this->estado === 'activa';
    }

    public function getFilamentName(): string
    {
        return $this->nombres ?? $this->correo;
    }
}
