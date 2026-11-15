<?php

namespace App\Support;

use Carbon\CarbonImmutable;
use Closure;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Symfony\Component\HttpKernel\Exception\HttpException;
use Throwable;

class AccesoInstitucional
{
    public function porCorreo(string $correo, Closure $operacion): mixed
    {
        // También serializa el alta de correos que aún no tienen fila en usuarios.
        $db = DB::connection();
        $llave = 'puntokampus:acceso:'.$correo;
        $limite = hrtime(true) + 5_000_000_000;
        do {
            $tomado = $db->selectOne('SELECT pg_try_advisory_lock(hashtextextended(?, 0))::int AS tomado', [$llave], false);
            if ((int) $tomado->tomado === 1) {
                break;
            }
            abort_if(hrtime(true) >= $limite, 503, 'Inténtalo de nuevo en unos segundos.');
            usleep(100_000);
        } while (true);

        try {
            return $operacion();
        } finally {
            $db->selectOne('SELECT pg_advisory_unlock(hashtextextended(?, 0))', [$llave], false);
        }
    }

    public function enviar(string $correo, string $proposito): void
    {
        $ahora = now();
        $recientes = DB::table('codigos_acceso')->where('correo', $correo)
            ->where('creado_en', '>', $ahora->copy()->subHour());
        $ultimaFecha = (clone $recientes)->max('creado_en');
        $disponible = $ultimaFecha ? CarbonImmutable::parse($ultimaFecha, 'UTC')->addSeconds(60) : null;
        if ($disponible && $disponible->gt($ahora)) {
            $this->esperar((int) ceil($ahora->diffInSeconds($disponible)));
        }
        if ($recientes->count() >= 5) {
            $primera = CarbonImmutable::parse($recientes->min('creado_en'), 'UTC');
            $this->esperar((int) ceil($ahora->diffInSeconds($primera->addHour())));
        }
        if (! app()->environment('local', 'testing') && in_array(config('mail.default'), ['log', 'array'], true)) {
            abort(503, 'El envío de correos aún no está disponible.');
        }

        $codigo = sprintf('%06d', random_int(0, 999999));
        $id = DB::transaction(function () use ($correo, $proposito, $codigo, $ahora) {
            DB::table('codigos_acceso')->where(compact('correo', 'proposito'))
                ->whereNull('usado_en')->whereNull('invalidado_en')->update(['invalidado_en' => $ahora]);

            return DB::table('codigos_acceso')->insertGetId([
                'correo' => $correo,
                'proposito' => $proposito,
                'codigo_hash' => Hash::make($this->huellaCodigo($codigo)),
                'creado_en' => $ahora,
                'expira_en' => $ahora->copy()->addMinutes(10),
            ]);
        });

        try {
            [$accion, $asunto] = match ($proposito) {
                'administracion' => ['entrar al panel de PuntoKampus', 'Tu código para el panel de PuntoKampus'],
                'eliminar_cuenta' => ['confirmar el borrado de tu cuenta', 'Confirma el borrado de tu cuenta PuntoKampus'],
                default => ['entrar en PuntoKampus', 'Tu código de acceso a PuntoKampus'],
            };
            Mail::send(
                ['html' => 'correos.codigo', 'text' => 'correos.codigo-texto'],
                compact('accion', 'asunto', 'codigo'),
                fn ($mensaje) => $mensaje->to($correo)->subject($asunto),
            );
        } catch (Throwable) {
            DB::table('codigos_acceso')->where('id', $id)->update(['invalidado_en' => now()]);
            abort(503, 'No pudimos enviar el correo. Vuelve a intentarlo en un minuto.');
        }
    }

    private function esperar(int $segundos): never
    {
        throw new HttpException(429, 'Espera antes de pedir otro código.', headers: ['Retry-After' => (string) max(1, $segundos)]);
    }

    private function huellaCodigo(string $codigo): string
    {
        $clave = config('app.key');
        abort_unless(is_string($clave) && $clave !== '', 503, 'El acceso aún no está configurado.');

        return hash_hmac('sha256', $codigo, $clave);
    }

    // Llamar con el bloqueo por correo antes de abrir la transacción de la operación.
    // Así los intentos fallidos se conservan aunque la respuesta sea un error.
    public function verificar(string $correo, string $proposito, string $codigo): int
    {
        $fila = DB::table('codigos_acceso')->where(compact('correo', 'proposito'))->latest('id')->first();
        $ahora = now();
        if ($fila && $fila->intentos >= 5 && CarbonImmutable::parse($fila->expira_en, 'UTC')->gt($ahora)) {
            abort(429, 'Hiciste muchos intentos. Pide un código nuevo.');
        }
        if (! $fila || $fila->usado_en || $fila->invalidado_en || CarbonImmutable::parse($fila->expira_en, 'UTC')->lte($ahora)) {
            abort(422, 'Este código ya no está vigente. Pide uno nuevo.');
        }
        if (! Hash::check($this->huellaCodigo($codigo), $fila->codigo_hash)) {
            $faltan = 4 - $fila->intentos;
            DB::table('codigos_acceso')->where('id', $fila->id)->increment('intentos');
            abort_if($faltan === 0, 429, 'Hiciste muchos intentos. Pide un código nuevo.');
            abort(422, "Ese código no es correcto. Te quedan {$faltan} intentos.");
        }

        return $fila->id;
    }

    public function vencimientoSesion(): CarbonImmutable
    {
        $hoy = now('America/Guayaquil')->toDateString();
        $fin = DB::table('configuraciones as c')->join('periodos_academicos as p', 'p.id', '=', 'c.periodo_actual_id')
            ->where('c.id', 1)->where('p.fecha_inicio', '<=', $hoy)->where('p.fecha_fin', '>=', $hoy)
            ->value('p.fecha_fin');
        if ($fin) {
            return CarbonImmutable::parse($fin, 'America/Guayaquil')->addDay()->utc();
        }
        abort_unless(app()->environment('local', 'testing'), 503, 'No hay un periodo académico activo.');

        return CarbonImmutable::instance(now())->addDays(7);
    }
}
