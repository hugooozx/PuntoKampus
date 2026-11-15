<?php

namespace Tests\Feature;

use App\Models\Producto;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class PedidosTest extends TestCase
{
    use DatabaseTransactions;

    private const RUTA = '/api/v1/pedidos';

    public function test_guarda_antes_de_whatsapp_y_conserva_el_precio_al_reintentar(): void
    {
        [$tienda, $producto] = $this->tienda('compra-prueba');
        $datos = $this->datos($tienda, $producto);
        $this->postJson(self::RUTA, $datos)->assertUnauthorized();
        $this->withToken($this->sesion($this->usuario('compradora')))->withHeader('Idempotency-Key', str_repeat('a', 32));

        $nuevo = $this->postJson(self::RUTA, $datos)->assertCreated()
            ->assertJsonPath('pedido.estado', 'pendiente')
            ->assertJsonPath('pedido.total', '3.00')
            ->assertJsonPath('pedido.items.0.nombre_producto', 'Galleta')
            ->assertJsonPath('pedido.items.0.precio_unitario', '1.50');
        $codigo = $nuevo->json('pedido.codigo');
        $this->assertMatchesRegularExpression('/^PK-[0-9]{6}$/', $codigo);
        $url = $nuevo->json('whatsapp_url');
        $this->assertStringStartsWith('https://wa.me/593990000000?text=', $url);
        parse_str(parse_url($url, PHP_URL_QUERY), $consulta);
        $this->assertStringContainsString($codigo, $consulta['text']);
        $this->assertStringContainsString('2 x Galleta: $3.00', $consulta['text']);
        $this->assertStringContainsString('Nota: En la entrada', $consulta['text']);
        $this->assertDatabaseHas('pedidos', ['codigo' => $codigo, 'estado' => 'pendiente']);

        $producto->update(['nombre' => 'Galleta doble', 'precio' => '5.00']);
        $this->postJson(self::RUTA, $datos)->assertOk()
            ->assertJsonPath('pedido.codigo', $codigo)
            ->assertJsonPath('pedido.items.0.nombre_producto', 'Galleta')
            ->assertJsonPath('pedido.total', '3.00');
        $this->postJson(self::RUTA, array_replace($datos, ['nota' => 'Otra']))->assertConflict();
        $this->assertDatabaseCount('pedidos', 1);
        $this->getJson(self::RUTA)->assertOk()->assertJsonPath('data.0.codigo', $codigo);
        $this->withToken($this->sesion($this->usuario('otra-compradora')))
            ->getJson(self::RUTA)->assertOk()->assertJsonCount(0, 'data');
    }

    public function test_rechaza_cantidades_horario_y_productos_no_permitidos(): void
    {
        [$tienda, $producto, $dueno] = $this->tienda('validar-pedido');
        [, $ajeno] = $this->tienda('otra-tienda');
        $datos = $this->datos($tienda, $producto);
        $this->withToken($this->sesion($dueno))->postJson(self::RUTA, $datos)->assertUnprocessable()
            ->assertJsonPath('message', 'No puedes pedir en tu propia tienda.');
        $this->withToken($this->sesion($this->usuario('cliente')));

        foreach (['abc', true, 21, 0, 2.5] as $cantidad) {
            $this->postJson(self::RUTA, array_replace($datos, ['items' => [['producto_id' => $producto->id, 'cantidad' => $cantidad]]]))
                ->assertUnprocessable()->assertJsonValidationErrors('items.0.cantidad');
        }
        $this->postJson(self::RUTA, array_replace($datos, ['nota' => str_repeat('á', 201), 'forma_pago' => 'tarjeta']))
            ->assertUnprocessable()->assertJsonValidationErrors(['nota', 'forma_pago']);
        foreach ([now()->addMinutes(10), now()->addDays(8)] as $hora) {
            $this->postJson(self::RUTA, array_replace($datos, ['hora_entrega' => $hora->toIso8601String()]))
                ->assertUnprocessable()->assertJsonValidationErrors('hora_entrega');
        }
        $this->postJson(self::RUTA, array_replace($datos, ['items' => [['producto_id' => $ajeno->id, 'cantidad' => 1]]]))
            ->assertUnprocessable()->assertJsonValidationErrors('items');
        $producto->update(['disponible' => false]);
        $this->postJson(self::RUTA, $datos)->assertUnprocessable()->assertJsonValidationErrors('items')
            ->assertJsonPath('errors.items.0', 'Galleta se agotó mientras armabas tu pedido. Quítalo del carrito para continuar.');
        $this->assertDatabaseCount('pedidos', 0);
    }

    public function test_ventas_externas_reservas_y_entregas_conservan_las_existencias(): void
    {
        [$tienda, $producto, $dueno] = $this->tienda('inventario');
        $venta = $this->sesion($dueno);
        $compra = $this->sesion($this->usuario('comprador-inventario'));
        $ruta = "/api/v1/mi-tienda/productos/{$producto->id}/inventario";
        $activar = ['tipo' => 'activacion', 'cantidad' => 50, 'existencias_esperadas' => null];
        $this->withToken($compra)->postJson($ruta, $activar)->assertNotFound();
        $this->withToken($venta)->postJson($ruta, $activar)->assertOk()->assertJsonPath('data.existencias', 50);
        $ajuste = ['tipo' => 'venta_externa', 'cantidad' => 20, 'existencias_esperadas' => 50];
        $this->postJson($ruta, $ajuste)->assertOk()->assertJsonPath('data.unidades_disponibles', 30);
        $this->postJson($ruta, $ajuste)->assertConflict();
        $this->postJson($ruta, array_replace($ajuste, ['cantidad' => 'a', 'existencias_esperadas' => 30]))
            ->assertUnprocessable()->assertJsonValidationErrors('cantidad');

        $datos = $this->datos($tienda, $producto);
        $datos['items'][0]['cantidad'] = 5;
        $pedido = $this->withToken($compra)->postJson(self::RUTA, $datos)->assertCreated()->json('pedido.id');
        $publico = '/api/v1/tiendas/'.$tienda->slug;
        $this->getJson($publico)->assertOk()->assertJsonPath('data.productos.0.unidades_disponibles', 25)
            ->assertJsonMissingPath('data.productos.0.existencias');
        $gestion = $this->withToken($venta);
        $gestion->getJson('/api/v1/mi-tienda/productos')->assertOk()->assertJsonPath('data.0.reservadas', 5);
        $gestion->postJson($ruta, ['tipo' => 'correccion', 'cantidad' => 4, 'existencias_esperadas' => 30])
            ->assertUnprocessable()->assertJsonValidationErrors('cantidad');
        $gestion->postJson($ruta, ['tipo' => 'desactivacion', 'existencias_esperadas' => 30])
            ->assertUnprocessable()->assertJsonValidationErrors('cantidad');
        $gestion->getJson('/api/v1/mi-tienda/pedidos?estado=pendiente')->assertOk()
            ->assertJsonPath('data.0.comprador', 'Ana Pérez')->assertJsonPath('data.0.items.0.cantidad', 5);
        $entregar = "/api/v1/mi-tienda/pedidos/$pedido/entregado";
        $this->withToken($compra)->postJson($entregar)->assertNotFound();
        $this->withToken($venta)->postJson($entregar)->assertOk()->assertJsonPath('data.estado', 'entregado');
        $this->postJson($entregar)->assertOk();
        $this->assertDatabaseHas('productos', ['id' => $producto->id, 'existencias' => 25]);
        $this->assertDatabaseCount('movimientos_inventario', 3);
        $this->withToken($compra)->getJson(self::RUTA)->assertOk()->assertJsonPath('data.0.estado', 'entregado');
        $this->postJson(self::RUTA."/$pedido/cancelar")->assertConflict();
    }

    public function test_cancelacion_y_vencimiento_liberan_la_ultima_unidad(): void
    {
        [$tienda, $producto, $dueno] = $this->tienda('inventario-vencido');
        $venta = $this->sesion($dueno);
        $compra = $this->sesion($this->usuario('comprador-vencido'));
        $this->withToken($venta)->postJson("/api/v1/mi-tienda/productos/{$producto->id}/inventario",
            ['tipo' => 'activacion', 'cantidad' => 1, 'existencias_esperadas' => null])->assertOk();
        $datos = $this->datos($tienda, $producto);
        $datos['items'][0]['cantidad'] = 1;
        $this->withToken($compra);
        $primero = $this->postJson(self::RUTA, $datos)->assertCreated()->json('pedido.id');
        $this->getJson('/api/v1/productos')->assertOk()->assertJsonPath('data.0.disponible', false);
        $this->postJson(self::RUTA, $datos)->assertUnprocessable()->assertJsonValidationErrors('items');
        $this->postJson(self::RUTA."/$primero/cancelar")->assertOk()->assertJsonPath('data.cancelado_por', 'comprador');

        $segundo = $this->postJson(self::RUTA, $datos)->assertCreated()->json('pedido.id');
        $this->withToken($venta)->postJson("/api/v1/mi-tienda/pedidos/$segundo/cancelar")
            ->assertOk()->assertJsonPath('data.cancelado_por', 'vendedor');
        $tercero = $this->withToken($compra)->postJson(self::RUTA, $datos)->assertCreated()->json('pedido.id');
        $this->travel(24)->hours();
        $this->artisan('pedidos:vencer')->assertExitCode(0);
        $this->assertDatabaseHas('pedidos', ['id' => $tercero, 'estado' => 'pendiente']);
        $this->travel(2)->hours();
        $this->artisan('pedidos:vencer')->assertExitCode(0);
        $this->artisan('pedidos:vencer')->assertExitCode(0);
        $this->withToken($this->sesion($dueno))->getJson('/api/v1/mi-tienda/pedidos?estado=vencido')->assertOk()
            ->assertJsonPath('data.0.id', $tercero)->assertJsonPath('data.0.estado', 'vencido');
        $this->getJson('/api/v1/productos')->assertOk()->assertJsonPath('data.0.unidades_disponibles', 1);
        $this->assertDatabaseCount('movimientos_inventario', 1);
    }

    private function usuario(string $nombre): Usuario
    {
        return Usuario::create(['correo' => "$nombre@utb.edu.ec", 'nombres' => 'Ana Pérez', 'acepto_privacidad_en' => now()]);
    }

    private function tienda(string $nombre): array
    {
        $usuario = $this->usuario($nombre);
        $facultad = DB::table('facultades')->insertGetId(['nombre' => $nombre]);
        $carrera = DB::table('carreras')->insertGetId(['facultad_id' => $facultad, 'nombre' => $nombre]);
        DB::table('perfiles_vendedores')->insert([
            'usuario_id' => $usuario->id, 'carrera_id' => $carrera, 'codigo_estudiante' => 'PRUEBA',
            'semestre' => 5, 'whatsapp' => '593990000000', 'mostrar_whatsapp' => false,
        ]);
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => $nombre]);
        $categoria = DB::table('categorias')->insertGetId(['nombre' => $nombre]);
        $tienda = Tienda::create(['usuario_id' => $usuario->id, 'nombre' => $nombre, 'slug' => $nombre, 'punto_entrega_id' => $punto]);
        $tienda->categorias()->attach($categoria, ['orden' => 1]);
        $producto = Producto::create(['tienda_id' => $tienda->id, 'nombre' => 'Galleta', 'precio' => '1.50']);

        return [$tienda, $producto, $usuario];
    }

    private function sesion(Usuario $usuario): string
    {
        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert([
            'usuario_id' => $usuario->id, 'nombre_dispositivo' => 'Pruebas',
            'token_hash' => hash('sha256', $token), 'expira_en' => now()->addHour(),
        ]);

        return $token;
    }

    private function datos(Tienda $tienda, Producto $producto): array
    {
        return [
            'tienda_id' => $tienda->id, 'items' => [['producto_id' => $producto->id, 'cantidad' => 2]],
            'punto_entrega_id' => $tienda->punto_entrega_id, 'hora_entrega' => now()->addHour()->toIso8601String(),
            'forma_pago' => 'efectivo', 'nota' => 'En la entrada',
        ];
    }
}
