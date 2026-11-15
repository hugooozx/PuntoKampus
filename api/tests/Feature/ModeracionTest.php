<?php

namespace Tests\Feature;

use App\Filament\Resources\ReporteResource\Pages\ListarReportes;
use App\Filament\Resources\TiendaResource\Pages\ListarTiendas;
use App\Models\Reporte;
use App\Models\Tienda;
use App\Models\Usuario;
use Filament\Actions\Testing\TestAction;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Mail;
use Livewire\Livewire;
use Tests\TestCase;

class ModeracionTest extends TestCase
{
    use DatabaseTransactions;

    public function test_reportes_validan_autoria_detalle_y_24_horas(): void
    {
        [$tienda, $vendedor] = $this->tienda();
        $comprador = $this->usuario('comprador');
        $ruta = "/api/v1/tiendas/{$tienda->id}/reportes";
        $this->postJson($ruta, ['motivo' => 'prohibido'])->assertUnauthorized();
        $this->withToken($this->sesion($vendedor))->postJson($ruta, ['motivo' => 'prohibido'])->assertForbidden();
        $this->withToken($this->sesion($comprador))->postJson($ruta, ['motivo' => 'otro', 'detalle' => ' '])
            ->assertUnprocessable()->assertJsonValidationErrors('detalle');
        $this->postJson($ruta, ['motivo' => 'informacion_falsa', 'detalle' => str_repeat('a', 301)])
            ->assertUnprocessable()->assertJsonValidationErrors('detalle');
        $this->postJson($ruta, ['motivo' => 'otro', 'detalle' => 'Datos incompletos'])
            ->assertCreated()->assertJsonPath('estado', 'nuevo');
        $this->travel(23)->hours();
        $this->postJson($ruta, ['motivo' => 'prohibido'])->assertStatus(429)->assertHeader('Retry-After');
        $this->travel(2)->hours();
        $this->postJson($ruta, ['motivo' => 'prohibido'])->assertCreated();
        $this->assertDatabaseCount('reportes', 2);
    }

    public function test_filament_revisa_reportes_y_cancelar_pedidos_libera_reservas(): void
    {
        [$tienda, $vendedor] = $this->tienda();
        $comprador = $this->usuario('comprador');
        $admin = $this->usuario('administrador', true);
        $producto = $tienda->productos()->create(['nombre' => 'Galleta', 'precio' => '1.00']);
        $producto->forceFill(['existencias' => 5])->save();
        $pedido = DB::table('pedidos')->insertGetId([
            'codigo' => 'PK-830011', 'comprador_id' => $comprador->id, 'tienda_id' => $tienda->id,
            'punto_entrega_id' => $tienda->punto_entrega_id, 'hora_entrega' => now()->addHour(),
            'forma_pago' => 'efectivo',
        ]);
        DB::table('detalles_pedidos')->insert([
            'pedido_id' => $pedido, 'producto_id' => $producto->id,
            'nombre_producto' => 'Galleta', 'precio_unitario' => '1.00', 'cantidad' => 2,
        ]);
        $requiereBaja = Reporte::create(['tienda_id' => $tienda->id, 'reportado_por' => $comprador->id, 'motivo' => 'prohibido']);
        $cerrar = Reporte::create(['tienda_id' => $tienda->id, 'reportado_por' => $comprador->id, 'motivo' => 'no_entrego']);

        $this->get('/admin/reportes')->assertRedirect('/admin/login');
        $this->actingAs($comprador, 'administracion')->get('/admin/reportes')->assertForbidden();
        $this->actingAs($admin, 'administracion')->get('/admin/reportes')->assertOk();
        Filament::setCurrentPanel(Filament::getPanel('admin'));
        Livewire::test(ListarReportes::class)
            ->assertCanSeeTableRecords([$requiereBaja, $cerrar])
            ->callAction(TestAction::make('cerrar')->table($cerrar), data: ['nota' => 'El pedido fue entregado.'])
            ->assertHasNoActionErrors()
            ->callAction(TestAction::make('baja')->table($requiereBaja), data: ['motivo' => 'Publicación de prueba'])
            ->assertHasNoActionErrors();
        $this->assertDatabaseHas('reportes', ['id' => $cerrar->id, 'estado' => 'sin_accion', 'revisado_por' => $admin->id]);
        $this->assertDatabaseHas('reportes', ['id' => $requiereBaja->id, 'estado' => 'tienda_dada_de_baja']);
        $this->getJson('/api/v1/tiendas/'.$tienda->slug)->assertNotFound();
        $this->withToken($this->sesion($vendedor))->getJson('/api/v1/mi-tienda')->assertOk()
            ->assertJsonPath('tienda.motivo_baja', 'Publicación de prueba');
        $this->assertDatabaseHas('pedidos', ['id' => $pedido, 'estado' => 'cancelado', 'cancelado_por' => 'sistema']);
        $this->assertSame(5, $producto->refresh()->unidadesDisponibles());
        Livewire::test(ListarTiendas::class)
            ->callAction(TestAction::make('reactivar')->table($tienda->refresh()))
            ->assertHasNoActionErrors();
        $this->getJson('/api/v1/tiendas/'.$tienda->slug)->assertOk();
        $this->assertDatabaseHas('pedidos', ['id' => $pedido, 'estado' => 'cancelado']);
    }

    public function test_panel_usa_codigo_de_administracion_y_sesion_propia(): void
    {
        $admin = $this->usuario('administrador', true);
        $comprador = $this->usuario('comprador');
        $this->get('/admin/login')->assertOk()->assertSee('Correo institucional');
        $this->post('/admin/acceso/codigo', ['correo' => $comprador->correo])->assertRedirect('/admin/login');
        $this->assertDatabaseCount('codigos_acceso', 0);
        $this->post('/admin/acceso/codigo', ['correo' => $admin->correo])->assertRedirect('/admin/login');
        $this->assertDatabaseHas('codigos_acceso', ['correo' => $admin->correo, 'proposito' => 'administracion']);
        $mensaje = Mail::mailer('array')->getSymfonyTransport()->messages()->last()->getOriginalMessage()->getTextBody();
        preg_match('/\b([0-9]{6})\b/', $mensaje, $partes);
        $this->postJson('/api/v1/auth/verificar', [
            'correo' => $admin->correo, 'codigo' => $partes[1], 'dispositivo' => 'Prueba',
            'contrasena' => 'clave-de-prueba-admin', 'contrasena_confirmation' => 'clave-de-prueba-admin',
        ])->assertUnprocessable();
        $this->post('/admin/acceso/verificar', ['codigo' => $partes[1]])->assertRedirect('/admin/reportes');
        $this->assertAuthenticatedAs($admin, 'administracion');
        $this->assertGuest('web');
        $this->get('/admin/tiendas')->assertOk();
        $admin->forceFill(['es_admin' => false])->save();
        Auth::guard('administracion')->forgetUser();
        $this->get('/admin/reportes')->assertForbidden();
    }

    private function usuario(string $alias, bool $admin = false): Usuario
    {
        $usuario = Usuario::create(['correo' => "$alias@utb.edu.ec", 'nombres' => ucfirst($alias), 'acepto_privacidad_en' => now()]);
        $usuario->forceFill(['es_admin' => $admin])->save();

        return $usuario->refresh();
    }

    private function tienda(): array
    {
        $vendedor = $this->usuario('vendedor');
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => 'Biblioteca']);
        $categoria = DB::table('categorias')->insertGetId(['nombre' => 'Comida']);
        $facultad = DB::table('facultades')->insertGetId(['nombre' => 'Facultad de prueba']);
        $carrera = DB::table('carreras')->insertGetId(['facultad_id' => $facultad, 'nombre' => 'Carrera de prueba']);
        DB::table('perfiles_vendedores')->insert([
            'usuario_id' => $vendedor->id, 'carrera_id' => $carrera, 'codigo_estudiante' => 'PRUEBA',
            'semestre' => 5, 'whatsapp' => '593990000000',
        ]);
        $tienda = Tienda::create([
            'usuario_id' => $vendedor->id, 'nombre' => 'Tienda de moderación', 'slug' => 'tienda-moderacion', 'punto_entrega_id' => $punto,
        ]);
        $tienda->categorias()->attach($categoria, ['orden' => 1]);

        return [$tienda, $vendedor];
    }

    private function sesion(Usuario $usuario): string
    {
        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert([
            'usuario_id' => $usuario->id, 'nombre_dispositivo' => 'Pruebas',
            'token_hash' => hash('sha256', $token), 'expira_en' => now()->addDays(2),
        ]);

        return $token;
    }
}
