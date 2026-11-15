<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        RateLimiter::for('acceso-contrasena', function (Request $request): array {
            $correo = $request->input('correo');
            $id = is_string($correo) ? strtolower(trim($correo)) : '';
            $ip = $request->ip();

            return [
                Limit::perMinute(30)->by('acceso-ip:'.$ip),
                Limit::perMinute(5)->by('acceso-cuenta:'.hash('sha256', $id.'|'.$ip)),
            ];
        });
    }
}
