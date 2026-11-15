<?php

namespace App\Http\Controllers;

use App\Models\Reporte;
use App\Models\Tienda;
use Carbon\CarbonImmutable;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class ReporteController extends Controller
{
    public function crear(Request $request, int $id)
    {
        $datos = $request->validate([
            'motivo' => ['required', Rule::in(array_keys(Reporte::MOTIVOS))],
            'detalle' => ['required_if:motivo,otro', 'nullable', 'string', 'max:300'],
        ], [
            'motivo.*' => 'Elige un motivo para el reporte.',
            'detalle.required_if' => 'Describe el motivo cuando elijas Otro.',
            'detalle.*' => 'El detalle puede tener hasta 300 caracteres.',
        ]);

        DB::transaction(function () use ($request, $id, $datos) {
            $tienda = Tienda::withoutEagerLoads()->activas()->lockForUpdate()->findOrFail($id);
            $usuario = $request->user();
            abort_if($tienda->usuario_id === $usuario->id, 403, 'No puedes reportar tu propia tienda.');

            $ultimo = Reporte::where('tienda_id', $id)->where('reportado_por', $usuario->id)->latest('creado_en')->first();
            $ahora = CarbonImmutable::now('UTC');
            $siguiente = $ultimo?->creado_en?->addHours(24);
            if ($siguiente?->gt($ahora)) {
                $segundos = (int) ceil($ahora->diffInSeconds($siguiente));
                $hora = $siguiente->setTimezone('America/Guayaquil')->format('d/m H:i');
                abort(429, "Ya reportaste esta tienda. Puedes volver a reportarla desde el $hora.", ['Retry-After' => (string) $segundos]);
            }

            Reporte::create($datos + ['tienda_id' => $id, 'reportado_por' => $usuario->id]);
        }, 3);

        return response()->json(['estado' => 'nuevo'], 201);
    }
}
