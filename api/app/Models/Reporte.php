<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Reporte extends Model
{
    public const MOTIVOS = [
        'prohibido' => 'Producto prohibido',
        'no_entrego' => 'No entregó el pedido',
        'informacion_falsa' => 'Información falsa',
        'trato_inadecuado' => 'Trato inadecuado',
        'otro' => 'Otro',
    ];

    public const CREATED_AT = 'creado_en';

    public const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['tienda_id', 'reportado_por', 'motivo', 'detalle'];

    protected function casts(): array
    {
        return ['revisado_en' => 'datetime'];
    }

    public function tienda(): BelongsTo
    {
        return $this->belongsTo(Tienda::class);
    }
}
