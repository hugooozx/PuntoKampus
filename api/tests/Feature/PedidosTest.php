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
