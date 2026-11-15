<?php

namespace App\Support;

use App\Models\Reporte;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class ModeracionTiendas
{
    public function cerrar(Usuario $actor, Reporte $reporte, string $nota): void
    {
        $this->autorizar($actor);
        $nota = $this->texto($nota, 'nota');
        DB::transaction(function () use ($actor, $reporte, $nota) {
            $reporte = Reporte::lockForUpdate()->findOrFail($reporte->id);
            $this->revisar($reporte, $actor, 'sin_accion', $nota);
        }, 3);
    }

    public function darDeBaja(Usuario $actor, int $tiendaId, string $motivo, ?int $reporteId = null): void
    {
        $this->autorizar($actor);
        $motivo = $this->texto($motivo, 'motivo');
        DB::transaction(function () use ($actor, $tiendaId, $motivo, $reporteId) {
            $tienda = Tienda::withoutEagerLoads()->lockForUpdate()->findOrFail($tiendaId);
            abort_unless($tienda->estado === 'activa', 409, 'La tienda ya está dada de baja.');
            if ($reporteId !== null) {
                $reporte = Reporte::where('tienda_id', $tiendaId)->lockForUpdate()->findOrFail($reporteId);
                $this->revisar($reporte, $actor, 'tienda_dada_de_baja', $motivo);
            }
            $ahora = now();
            $tienda->forceFill(['estado' => 'dada_de_baja', 'motivo_baja' => $motivo, 'dada_de_baja_en' => $ahora])->save();
            DB::table('pedidos')->where('tienda_id', $tiendaId)->where('estado', 'pendiente')->update([
                'estado' => 'cancelado',
                'cancelado_por' => 'sistema',
                'estado_cambiado_en' => $ahora->format('Y-m-d H:i:s.u'),
            ]);
        }, 3);
    }

    public function reactivar(Usuario $actor, int $tiendaId): void
    {
        $this->autorizar($actor);
        DB::transaction(function () use ($tiendaId) {
            $tienda = Tienda::withoutEagerLoads()->lockForUpdate()->findOrFail($tiendaId);
            abort_unless($tienda->estado === 'dada_de_baja', 409, 'La tienda ya está activa.');
            $tienda->forceFill(['estado' => 'activa', 'motivo_baja' => null, 'dada_de_baja_en' => null])->save();
        }, 3);
    }

    private function revisar(Reporte $reporte, Usuario $actor, string $estado, string $nota): void
    {
        abort_unless($reporte->estado === 'nuevo', 409, 'El reporte ya fue revisado.');
        $reporte->forceFill([
            'estado' => $estado,
            'revisado_por' => $actor->id,
            'revisado_en' => now(),
            'nota_admin' => $nota,
        ])->save();
    }

    private function texto(string $valor, string $campo): string
    {
        return Validator::make([$campo => trim($valor)], [$campo => 'required|string|max:500'])->validate()[$campo];
    }

    private function autorizar(Usuario $actor): void
    {
        abort_unless(Usuario::whereKey($actor->id)->where('es_admin', true)->where('estado', 'activa')->exists(), 403);
    }
}
