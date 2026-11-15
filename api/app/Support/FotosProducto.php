<?php

namespace App\Support;

use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

final class FotosProducto
{
    public const PREFIJO = '/storage/productos/';

    public function guardar(UploadedFile $archivo): string
    {
        abort_unless(function_exists('imagewebp'), 503, 'El procesamiento de fotos no está disponible.');
        $ruta = $archivo->getPathname();
        $medidas = @getimagesize($ruta);
        if (! $medidas || $medidas[0] * $medidas[1] > 18_000_000) {
            throw ValidationException::withMessages(['fotos' => 'Elige una foto de hasta 18 megapíxeles.']);
        }
        $foto = match ($medidas[2]) {
            IMAGETYPE_JPEG => @imagecreatefromjpeg($ruta),
            IMAGETYPE_PNG => @imagecreatefrompng($ruta),
            IMAGETYPE_WEBP => @imagecreatefromwebp($ruta),
            default => false,
        };
        if (! $foto) {
            throw ValidationException::withMessages(['fotos' => 'No pudimos leer la foto. Selecciona otra imagen.']);
        }
        if (max($medidas[0], $medidas[1]) > 1080) {
            $escala = 1080 / max($medidas[0], $medidas[1]);
            $foto = imagescale($foto, max(1, (int) round($medidas[0] * $escala)), max(1, (int) round($medidas[1] * $escala)));
            abort_unless($foto, 503, 'No pudimos reducir la foto.');
        }
        if (! imageistruecolor($foto)) {
            imagepalettetotruecolor($foto);
        }
        imagesavealpha($foto, true);
        ob_start();
        try {
            $ok = imagewebp($foto, null, 84);
            $webp = ob_get_contents();
        } finally {
            ob_end_clean();
        }
        abort_unless($ok && $webp, 503, 'No pudimos preparar la foto.');
        $nombre = Str::lower(Str::random(40)).'.webp';
        abort_unless(Storage::disk('public')->put('productos/'.$nombre, $webp), 503, 'No pudimos guardar la foto.');

        return self::PREFIJO.$nombre;
    }

    public function encolarBorrado(string $url): void
    {
        if (preg_match('~^/storage/(productos/[a-z0-9]{40}\.webp)$~D', $url, $ruta)) {
            DB::table('borrados_archivos')->insert(['disco' => 'public', 'ruta' => $ruta[1]]);
        }
    }

    public function descartarCarga(string $url): void
    {
        if (! Storage::disk('public')->delete(substr($url, strlen('/storage/')))) {
            $this->encolarBorrado($url);
        }
    }
}
