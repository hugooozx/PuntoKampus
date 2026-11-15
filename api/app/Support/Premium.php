<?php

namespace App\Support;

use App\Models\SolicitudPremium;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class Premium
{
    public function configuracion()
    {
        $hoy = now('America/Guayaquil')->toDateString();

        return DB::table('configuraciones as c')
            ->join('cuentas_bancarias as b', 'b.id', '=', 'c.cuenta_bancaria_id')
            ->join('periodos_academicos as p', 'p.id', '=', 'c.periodo_actual_id')
            ->where('c.id', 1)->where('p.fecha_inicio', '<=', $hoy)->where('p.fecha_fin', '>=', $hoy)
            ->first(['c.precio_premium', 'c.periodo_actual_id', 'c.usuario_deuna', 'p.fecha_fin', 'b.banco', 'b.tipo_cuenta', 'b.numero', 'b.titular']);
    }

    public function revisar(Usuario $admin, SolicitudPremium $solicitud, ?string $rechazo = null): void
    {
        abort_unless(Usuario::whereKey($admin->id)->where('es_admin', true)->where('estado', 'activa')->exists(), 403);
        if ($rechazo !== null) {
            $rechazo = Validator::make(['motivo' => trim($rechazo)], ['motivo' => 'required|string|max:300'])->validate()['motivo'];
        }
        try {
            DB::transaction(function () use ($admin, $solicitud, $rechazo) {
                $tienda = Tienda::withoutEagerLoads()->whereKey($solicitud->tienda_id)->lockForUpdate()->first();
                $solicitud = SolicitudPremium::lockForUpdate()->findOrFail($solicitud->id);
                abort_unless($solicitud->estado === 'pendiente', 409, 'Esta solicitud ya fue revisada.');
                $periodo = null;
                if ($rechazo === null) {
                    abort_unless($tienda?->estado === 'activa', 409, 'La tienda debe estar activa para aprobar la solicitud.');
                    $configuracion = $this->configuracion();
                    abort_unless($configuracion, 409, 'Configura un periodo académico vigente antes de aprobar.');
                    $periodo = $configuracion->periodo_actual_id;
                }
                $solicitud->forceFill([
                    'estado' => $rechazo === null ? 'aprobada' : 'rechazada',
                    'periodo_academico_id' => $periodo, 'motivo_rechazo' => $rechazo,
                    'revisado_por' => $admin->id, 'revisado_en' => now(),
                ])->save();
            }, 3);
        } catch (UniqueConstraintViolationException $error) {
            if (str_contains($error->getMessage(), 'uq_solicitudes_premium_comprobante')) {
                abort(409, 'Ese número de comprobante ya fue aprobado en otra solicitud.');
            }
            throw $error;
        }
    }

    public function foto(SolicitudPremium $solicitud): string
    {
        $ruta = $solicitud->foto_comprobante;
        abort_unless($ruta && str_starts_with($ruta, 'comprobantes/') && Storage::disk('local')->exists($ruta), 404, 'El comprobante ya no está disponible.');

        return $ruta;
    }

    public function retirarFotos(BorradoCuenta $borrado): void
    {
        $dias = DB::table('configuraciones')->where('id', 1)->value('dias_conservacion_comprobantes') ?? 30;
        $limite = now()->subDays($dias);
        $vencidas = SolicitudPremium::whereNotNull('foto_comprobante')->where('revisado_en', '<=', $limite);
        $vencidas->select('id')->chunkById(100, function ($lote) use ($vencidas, $borrado) {
            DB::transaction(function () use ($lote, $vencidas, $borrado) {
                foreach ((clone $vencidas)->select('*')->whereKey($lote->modelKeys())->orderBy('id')->lockForUpdate()->get() as $solicitud) {
                    $borrado->encolar('local', $solicitud->foto_comprobante);
                    $solicitud->forceFill(['foto_comprobante' => null, 'foto_borrada_en' => now()])->save();
                }
            }, 3);
        });
        $borrado->limpiarArchivos();
    }
}
