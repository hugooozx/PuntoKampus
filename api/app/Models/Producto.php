<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;
use Illuminate\Support\Facades\DB;

class Producto extends Model
{
    use SoftDeletes;

    const DELETED_AT = 'eliminado_en';

    const CREATED_AT = 'creado_en';

    const UPDATED_AT = 'actualizado_en';

    protected $fillable = ['tienda_id', 'nombre', 'descripcion', 'precio', 'disponible'];

    protected function casts(): array
    {
        return ['precio' => 'decimal:2', 'disponible' => 'boolean', 'existencias' => 'integer'];
    }

    private static function reservas()
    {
        return DB::table('detalles_pedidos as d')->join('pedidos as p', 'p.id', '=', 'd.pedido_id')
            ->where('p.estado', 'pendiente');
    }

    public function scopeConReservas(Builder $consulta): Builder
    {
        return $consulta->addSelect(['reservadas' => self::reservas()
            ->selectRaw('COALESCE(SUM(d.cantidad), 0)')->whereColumn('d.producto_id', 'productos.id')]);
    }

    public function reservadas(): int
    {
        return (int) ($this->attributes['reservadas'] ?? self::reservas()
            ->where('d.producto_id', $this->id)->sum('d.cantidad'));
    }

    public function unidadesDisponibles(): ?int
    {
        return $this->existencias === null ? null : $this->existencias - $this->reservadas();
    }

    public function registrarExistencias(?int $cantidad, string $tipo, ?int $pedido = null): void
    {
        DB::table('movimientos_inventario')->insert([
            'producto_id' => $this->id, 'pedido_id' => $pedido, 'tipo' => $tipo,
            'variacion' => ($cantidad ?? 0) - ($this->existencias ?? 0), 'existencias_resultantes' => $cantidad,
        ]);
        $this->forceFill(['existencias' => $cantidad])->save();
    }

    public function tienda(): BelongsTo
    {
        return $this->belongsTo(Tienda::class);
    }

    public function fotos(): HasMany
    {
        return $this->hasMany(ProductoFoto::class)->orderBy('orden')->orderBy('id');
    }
}
