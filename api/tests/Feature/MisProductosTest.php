<?php

namespace Tests\Feature;

use App\Models\Producto;
use App\Models\Tienda;
use App\Models\Usuario;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class MisProductosTest extends TestCase
{
    use DatabaseTransactions;

    private const RUTA = '/api/v1/mi-tienda/productos';

    public function test_producto_publicado_agotado_y_retirado_conserva_historial(): void
    {
        [$tienda, $token] = $this->vendedor('galletas-productos');
        $this->getJson(self::RUTA)->assertUnauthorized();
        $this->withToken($token)->postJson(self::RUTA, ['nombre' => 'Galleta de avena', 'precio' => '0'])
            ->assertUnprocessable()->assertJsonValidationErrors(['precio']);
        $creado = $this->postJson(self::RUTA, ['nombre' => 'Galleta de avena', 'precio' => '1.50'])
            ->assertCreated()->assertJsonPath('data.precio', '1.50')->assertJsonPath('data.disponible', true);
        $id = $creado->json('data.id');
        $ruta = self::RUTA.'/'.$id;

        $this->getJson('/api/v1/productos?buscar=galleta')->assertOk()->assertJsonPath('data.0.id', $id);
        $this->getJson('/api/v1/tiendas/'.$tienda->slug)->assertOk()->assertJsonPath('data.productos.0.id', $id);

        [, $ajeno] = $this->vendedor('otra-tienda-productos');
        $this->withToken($ajeno)->putJson($ruta, ['disponible' => false])->assertNotFound();
        $this->deleteJson($ruta)->assertNotFound();
        $this->getJson(self::RUTA)->assertOk()->assertJsonCount(0, 'data');

        $this->withToken($token)->putJson($ruta, ['disponible' => false, 'precio' => '2.25'])
            ->assertOk()->assertJsonPath('data.disponible', false)->assertJsonPath('data.precio', '2.25');
        $this->getJson('/api/v1/productos?buscar=galleta')->assertOk()->assertJsonPath('data.0.disponible', false);

        $pedido = DB::table('pedidos')->insertGetId([
            'codigo' => 'PK-947268', 'tienda_id' => $tienda->id,
            'comprador_id' => Usuario::where('correo', 'otra-tienda-productos@utb.edu.ec')->value('id'),
            'punto_entrega_id' => $tienda->punto_entrega_id, 'hora_entrega' => now()->addHour(),
            'forma_pago' => 'efectivo',
        ]);
        DB::table('detalles_pedidos')->insert([
            'pedido_id' => $pedido, 'producto_id' => $id,
            'nombre_producto' => 'Galleta de avena', 'precio_unitario' => '1.50', 'cantidad' => 2,
        ]);
        $this->deleteJson($ruta)->assertNoContent();
        $this->assertSoftDeleted('productos', ['id' => $id], deletedAtColumn: 'eliminado_en');
        $this->assertNotNull(Producto::withTrashed()->find($id));
        $this->assertDatabaseHas('detalles_pedidos', ['pedido_id' => $pedido, 'producto_id' => $id, 'precio_unitario' => '1.50']);
        $this->getJson('/api/v1/productos?buscar=galleta')->assertOk()->assertJsonCount(0, 'data');
        $this->getJson('/api/v1/tiendas/'.$tienda->slug)->assertOk()->assertJsonCount(0, 'data.productos');
    }

    public function test_las_fotos_se_reducen_y_se_reemplazan_dentro_del_limite(): void
    {
        Storage::fake('public');
        [, $token] = $this->vendedor('fotos-productos');
        $this->withToken($token);
        $registro = $this->post(self::RUTA, [
            'nombre' => 'Brownie de chocolate', 'precio' => '1.50',
            'fotos' => [UploadedFile::fake()->image('grande.jpg', 1600, 1200)],
        ], ['Accept' => 'application/json'])->assertCreated();
        $ruta = self::RUTA.'/'.$registro->json('data.id');
        $primera = $registro->json('data.fotos.0');
        $archivo = substr($primera['url'], strlen('/storage/'));
        $this->assertSame([1080, 810], array_slice(getimagesize(Storage::disk('public')->path($archivo)), 0, 2));
        $this->get($primera['url'], ['Origin' => 'http://127.0.0.1:8766'])
            ->assertOk()->assertHeader('Content-Type', 'image/webp')->assertHeader('Access-Control-Allow-Origin', '*');
        foreach ([2, 3] as $orden) {
            $this->post($ruta.'/fotos', ['imagen' => UploadedFile::fake()->image('foto.jpg')], ['Accept' => 'application/json'])
                ->assertCreated()->assertJsonPath('data.orden', $orden);
        }
        $this->post($ruta, [
            '_method' => 'PUT', 'nombre' => 'Cambio que excede el límite', 'fotos' => [UploadedFile::fake()->image('foto.jpg')],
        ], ['Accept' => 'application/json'])->assertUnprocessable()->assertJsonValidationErrors('fotos');
        $this->assertDatabaseHas('productos', ['id' => $registro->json('data.id'), 'nombre' => 'Brownie de chocolate']);

        $this->post($ruta, [
            '_method' => 'PUT', 'nombre' => 'Brownie casero', 'fotos_eliminar' => [$primera['id']],
            'fotos' => [UploadedFile::fake()->image('foto.png')],
        ], ['Accept' => 'application/json'])->assertOk()
            ->assertJsonPath('data.nombre', 'Brownie casero')->assertJsonCount(3, 'data.fotos')
            ->assertJsonPath('data.fotos.0.orden', 1)->assertJsonPath('data.fotos.2.orden', 3);
        $this->get($primera['url'])->assertNotFound();
        Storage::disk('public')->assertMissing($archivo);
    }

    private function vendedor(string $slug): array
    {
        $usuario = Usuario::create(['correo' => "$slug@utb.edu.ec", 'nombres' => 'Prueba', 'acepto_privacidad_en' => now()]);
        $facultad = DB::table('facultades')->insertGetId(['nombre' => 'Facultad '.$slug]);
        $carrera = DB::table('carreras')->insertGetId(['facultad_id' => $facultad, 'nombre' => 'Carrera '.$slug]);
        DB::table('perfiles_vendedores')->insert([
            'usuario_id' => $usuario->id, 'carrera_id' => $carrera, 'codigo_estudiante' => 'PRUEBA',
            'semestre' => 5, 'whatsapp' => '593991234567',
        ]);
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => 'Biblioteca '.$slug]);
        $categoria = DB::table('categorias')->insertGetId(['nombre' => 'Comida '.$slug]);
        $tienda = Tienda::create(['usuario_id' => $usuario->id, 'nombre' => $slug, 'slug' => $slug, 'punto_entrega_id' => $punto]);
        $tienda->categorias()->attach($categoria, ['orden' => 1]);

        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert([
            'usuario_id' => $usuario->id, 'nombre_dispositivo' => 'Pruebas',
            'token_hash' => hash('sha256', $token), 'expira_en' => now()->addHour(),
        ]);

        return [$tienda, $token];
    }
}
