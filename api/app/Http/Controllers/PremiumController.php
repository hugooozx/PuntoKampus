<?php

namespace App\Http\Controllers;

use App\Models\SolicitudPremium;
use App\Models\Tienda;
use App\Support\BorradoCuenta;
use App\Support\Premium;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Throwable;

class PremiumController extends Controller
{
    public function ver(Request $request, Premium $premium): array
    {
        $tienda = $this->tienda($request)->firstOrFail();
        $datos = $tienda->estado === 'activa' ? $premium->configuracion() : null;

        return [
            'plan' => $tienda->vigencia?->plan ?? 'gratis',
            'premium_hasta' => $tienda->vigencia?->premium_hasta?->toDateString(),
            'pago' => $datos ? [
                'precio' => $datos->precio_premium, 'fin_periodo' => $datos->fecha_fin,
                'banco' => $datos->banco, 'tipo_cuenta' => $datos->tipo_cuenta,
                'numero' => $datos->numero, 'titular' => $datos->titular, 'usuario_deuna' => $datos->usuario_deuna,
            ] : null,
            'ultima_solicitud' => SolicitudPremium::where('tienda_id', $tienda->id)->latest('id')->first()?->resumen(),
        ];
    }

    public function crear(Request $request, Premium $premium, BorradoCuenta $borrado)
    {
        $datos = $request->validate([
            'numero_comprobante' => ['required', 'string', 'max:100', 'regex:/^[^\pC]+$/u'],
            'monto' => ['required', 'numeric', 'decimal:0,2', 'gt:0', 'max:999999.99'],
            'imagen' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:2048', 'dimensions:max_width=4096,max_height=4096'],
        ], [
            'numero_comprobante.*' => 'Escribe el número del comprobante (hasta 100 caracteres).',
            'monto.*' => 'Escribe un importe positivo con hasta dos decimales.',
            'imagen.*' => 'Adjunta una foto JPG, PNG o WebP de hasta 2 MB.',
        ]);
        $ruta = null;
        try {
            $solicitud = DB::transaction(function () use ($request, $premium, $datos, &$ruta) {
                $tienda = $this->tienda($request)->lockForUpdate()->firstOrFail();
                abort_unless($tienda->estado === 'activa', 403, 'Tu tienda debe estar activa para solicitar Premium.');
                abort_if($tienda->tienePremium(), 409, 'Tu tienda ya tiene Premium vigente.');
                abort_unless($premium->configuracion(), 409, 'El cobro Premium aún no está configurado.');
                abort_if(SolicitudPremium::where('tienda_id', $tienda->id)->where('estado', 'pendiente')->exists(),
                    409, 'Ya tienes un comprobante en revisión.');
                $ruta = $request->file('imagen')->store('comprobantes', 'local');
                abort_unless($ruta, 503, 'No pudimos guardar el comprobante.');

                $solicitud = (new SolicitudPremium)->forceFill([
                    'tienda_id' => $tienda->id, 'numero_comprobante' => $datos['numero_comprobante'],
                    'monto' => $datos['monto'], 'foto_comprobante' => $ruta,
                ]);
                $solicitud->save();

                return $solicitud->refresh();
            });
        } catch (Throwable $error) {
            if ($ruta && ! Storage::disk('local')->delete($ruta)) {
                $borrado->encolar('local', $ruta);
            }
            throw $error;
        }

        return response()->json(['data' => $solicitud->resumen()], 201);
    }

    public function fotoVendedor(Request $request, int $id, Premium $premium)
    {
        $tienda = $this->tienda($request)->firstOrFail();
        $solicitud = SolicitudPremium::where('tienda_id', $tienda->id)->findOrFail($id);
        $contenido = Storage::disk('local')->get($premium->foto($solicitud));
        abort_unless(is_string($contenido), 404);

        return response()->json(['imagen' => base64_encode($contenido)])->header('Cache-Control', 'private, no-store');
    }

    public function fotoAdmin(int $id, Premium $premium)
    {
        $admin = Auth::guard('administracion')->user();
        abort_unless($admin?->es_admin && $admin->estado === 'activa', 403);
        $ruta = $premium->foto(SolicitudPremium::findOrFail($id));

        return Storage::disk('local')->response($ruta, headers: [
            'X-Content-Type-Options' => 'nosniff', 'Cache-Control' => 'private, no-store',
        ]);
    }

    private function tienda(Request $request)
    {
        abort_if($request->user()->es_admin, 403, 'Premium está disponible para vendedores.');

        return Tienda::where('usuario_id', $request->user()->id);
    }
}
