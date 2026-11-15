<?php

namespace App\Support;

use App\Models\Usuario;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use RuntimeException;
use Throwable;

class BorradoCuenta
{
    public function borrar(string $correo): void
    {
        $usuario = Usuario::where('correo', $correo)->lockForUpdate()->first();
        DB::table('codigos_acceso')->where('correo', $correo)->delete();
        if (! $usuario) {
            return;
        }

        $tienda = DB::table('tiendas')->where('usuario_id', $usuario->id)->lockForUpdate()->first();
        $pedidos = DB::table('pedidos')->where(function ($consulta) use ($usuario, $tienda) {
            $consulta->where('comprador_id', $usuario->id);
            if ($tienda) {
                $consulta->orWhere('tienda_id', $tienda->id);
            }
        });
        (clone $pedidos)->update(['nota' => null]);
        (clone $pedidos)->where('estado', 'pendiente')->update([
            'estado' => 'cancelado', 'cancelado_por' => 'sistema',
            'estado_cambiado_en' => now()->format('Y-m-d H:i:s.u'),
        ]);
        DB::table('reportes')->where('reportado_por', $usuario->id)->delete();
        if ($tienda) {
            $this->archivosTienda($tienda);
        }
        $usuario->delete();
        DB::table('pedidos')->whereNull('comprador_id')->whereNull('tienda_id')->delete();
    }

    private function archivosTienda(object $tienda): void
    {
        $fotos = DB::table('fotos_productos as f')->join('productos as p', 'p.id', '=', 'f.producto_id')
            ->where('p.tienda_id', $tienda->id)->pluck('f.url');
        foreach ($fotos->push($tienda->logo_url, $tienda->portada_url) as $url) {
            $base = rtrim(config('filesystems.disks.public.url'), '/').'/';
            $ruta = $url && str_starts_with($url, $base) ? substr($url, strlen($base))
                : ($url && str_starts_with($url, '/storage/') ? substr($url, 9) : null);
            $this->encolar('public', $ruta);
        }

        $solicitudes = DB::table('solicitudes_premium')->where('tienda_id', $tienda->id);
        foreach ((clone $solicitudes)->pluck('foto_comprobante') as $foto) {
            $this->encolar('local', $foto);
        }
        (clone $solicitudes)->where('estado', '!=', 'aprobada')->delete();
        $solicitudes->whereNotNull('foto_comprobante')->update([
            'foto_comprobante' => null, 'foto_borrada_en' => now()->format('Y-m-d H:i:s.u'),
        ]);
    }

    private function encolar(string $disco, ?string $ruta): void
    {
        if ($ruta && preg_match('~^[a-zA-Z0-9_-]+(?:[./][a-zA-Z0-9_-]+)*$~D', $ruta)) {
            DB::table('borrados_archivos')->insert(['disco' => $disco, 'ruta' => $ruta]);
        }
    }

    public function limpiarArchivos(): void
    {
        DB::table('borrados_archivos')->orderBy('id')->chunkById(100, function ($archivos) {
            foreach ($archivos as $archivo) {
                try {
                    $disco = Storage::disk($archivo->disco);
                    if ($disco->exists($archivo->ruta) && ! $disco->delete($archivo->ruta)) {
                        throw new RuntimeException('No se pudo eliminar un archivo de una cuenta borrada.');
                    }
                    DB::table('borrados_archivos')->where('id', $archivo->id)->delete();
                } catch (Throwable $error) {
                    report($error);
                }
            }
        });
    }
}
