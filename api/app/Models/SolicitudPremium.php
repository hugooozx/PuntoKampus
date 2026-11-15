<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class SolicitudPremium extends Model
{
    protected $table = 'solicitudes_premium';

    protected $hidden = ['foto_comprobante', 'revisado_por'];

    public const CREATED_AT = 'creado_en';

    public const UPDATED_AT = 'actualizado_en';

    public function tienda(): BelongsTo
    {
        return $this->belongsTo(Tienda::class);
    }

    public function resumen(): array
    {
        return $this->only(['id', 'estado', 'numero_comprobante', 'monto', 'motivo_rechazo', 'creado_en'])
            + ['foto_disponible' => $this->foto_comprobante !== null];
    }
}
