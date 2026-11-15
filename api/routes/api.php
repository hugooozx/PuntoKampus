<?php

use App\Http\Controllers\CuentaController;
use App\Http\Controllers\MisProductosController;
use App\Http\Controllers\MiTiendaController;
use App\Http\Controllers\PedidoController;
use App\Http\Controllers\VitrinaController;
use App\Http\Middleware\SesionInstitucional;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('privacidad', fn () => [
        'responsable' => config('puntokampus.responsable'),
        'contacto' => config('puntokampus.contacto'),
    ]);
    Route::middleware('throttle:60,1')->group(function () {
        Route::post('auth/codigo', [CuentaController::class, 'pedirCodigo']);
        Route::post('auth/verificar', [CuentaController::class, 'verificar']);
        Route::post('cuentas/codigo-borrado', [CuentaController::class, 'pedirBorradoWeb']);
        Route::delete('cuentas', [CuentaController::class, 'borrarWeb']);
    });
    Route::middleware(SesionInstitucional::class.':alta')->group(function () {
        Route::post('auth/salir', [CuentaController::class, 'salir']);
        Route::get('yo', [CuentaController::class, 'ver']);
        Route::put('yo', [CuentaController::class, 'actualizar']);
        Route::post('yo/codigo-borrado', [CuentaController::class, 'pedirBorrado']);
        Route::delete('yo', [CuentaController::class, 'borrar']);
    });
    Route::get('categorias', [VitrinaController::class, 'categorias']);
    Route::get('facultades', [MiTiendaController::class, 'facultades']);
    Route::get('carreras', [MiTiendaController::class, 'carreras']);
    Route::middleware(SesionInstitucional::class)->group(function () {
        Route::post('pedidos', [PedidoController::class, 'crear']);
        Route::get('pedidos', [PedidoController::class, 'indice']);
        Route::post('pedidos/{id}/cancelar', [PedidoController::class, 'cancelarCompra'])->whereNumber('id');
        Route::get('mi-tienda/pedidos', [PedidoController::class, 'recibidos']);
        Route::post('mi-tienda/pedidos/{id}/entregado', [PedidoController::class, 'entregar'])->whereNumber('id');
        Route::post('mi-tienda/pedidos/{id}/cancelar', [PedidoController::class, 'cancelarVenta'])->whereNumber('id');
        Route::get('mi-tienda', [MiTiendaController::class, 'ver']);
        Route::post('mi-tienda', [MiTiendaController::class, 'crear']);
        Route::put('mi-tienda', [MiTiendaController::class, 'actualizar']);
        Route::post('mi-tienda/logo', [MiTiendaController::class, 'logo']);
        Route::post('mi-tienda/portada', [MiTiendaController::class, 'portada']);
        Route::prefix('mi-tienda/productos')->group(function () {
            Route::get('/', [MisProductosController::class, 'indice']);
            Route::post('/', [MisProductosController::class, 'crear']);
            Route::put('{producto}', [MisProductosController::class, 'actualizar'])->whereNumber('producto');
            Route::delete('{producto}', [MisProductosController::class, 'borrar'])->whereNumber('producto');
            Route::post('{producto}/inventario', [MisProductosController::class, 'inventario'])->whereNumber('producto');
            Route::post('{producto}/fotos', [MisProductosController::class, 'agregarFoto'])->whereNumber('producto');
            Route::delete('{producto}/fotos/{foto}', [MisProductosController::class, 'quitarFoto'])->whereNumber(['producto', 'foto']);
        });
    });
    Route::get('puntos-entrega', [VitrinaController::class, 'puntosEntrega']);
    Route::get('tiendas', [VitrinaController::class, 'tiendas']);
    Route::get('tiendas/{slug}', [VitrinaController::class, 'tienda']);
    Route::get('productos', [VitrinaController::class, 'productos']);
});
