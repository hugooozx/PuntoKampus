<?php

namespace App\Filament\Actions;

use Closure;
use Filament\Notifications\Notification;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;

class ResultadoModeracion
{
    public static function ejecutar(Closure $accion, string $mensaje): void
    {
        try {
            $accion();
        } catch (HttpExceptionInterface $error) {
            if ($error->getStatusCode() !== 409) {
                throw $error;
            }
            Notification::make()->warning()->title($error->getMessage())->send();

            return;
        }
        Notification::make()->success()->title($mensaje)->send();
    }
}
