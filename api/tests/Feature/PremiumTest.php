<?php

namespace Tests\Feature;

use App\Filament\Resources\SolicitudPremiumResource\Pages\ListarSolicitudes;
use App\Models\SolicitudPremium;
use App\Models\Tienda;
use App\Models\Usuario;
use Filament\Actions\Testing\TestAction;
use Filament\Facades\Filament;
use Illuminate\Foundation\Testing\DatabaseTransactions;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Livewire\Livewire;
use Tests\TestCase;

class PremiumTest extends TestCase
{
    use DatabaseTransactions;

    public function test_vendedor_envia_admin_aprueba_y_comprador_ve_el_plan(): void
    {
        Storage::fake('local');
        Storage::fake('public');
        [$vendedor, $tienda] = $this->vendedor('premium');
        [$otro] = $this->vendedor('otro');
        $comprador = $this->usuario('comprador');
        $admin = $this->usuario('admin');
        $admin->forceFill(['es_admin' => true])->save();
        $token = $this->token($vendedor);
        $this->withToken($this->token($comprador))->getJson('/api/v1/premium')->assertNotFound();
        $this->withToken($token)->getJson('/api/v1/premium')->assertOk()->assertJsonPath('pago', null);
        $periodo = $this->configurar();
        $this->getJson('/api/v1/premium')->assertOk()->assertJsonPath('pago.precio', '3.00');
        $this->post('/api/v1/premium/solicitudes', ['numero_comprobante' => 'A', 'monto' => '1.123'], ['Accept' => 'application/json'])
            ->assertUnprocessable()->assertJsonValidationErrors(['imagen', 'monto']);
        $id = $this->enviar('PK-PAGO-123');
        $this->post('/api/v1/premium/solicitudes', $this->comprobante('OTRO'), ['Accept' => 'application/json'])->assertConflict();
        $solicitud = SolicitudPremium::findOrFail($id);
        Storage::disk('local')->assertExists($solicitud->foto_comprobante);
        Storage::disk('public')->assertMissing($solicitud->foto_comprobante);
        $this->getJson("/api/v1/premium/solicitudes/$id/foto")->assertOk()->assertJsonStructure(['imagen']);
        $this->get("/admin/comprobantes/$id")->assertForbidden();
        $this->withToken($this->token($otro))->getJson("/api/v1/premium/solicitudes/$id/foto")->assertNotFound();
        $duplicada = $this->enviar('pk-pago-123');

        $this->actingAs($admin->refresh(), 'administracion')->get('/admin/solicitudes-premium')->assertOk();
        $this->get("/admin/comprobantes/$id")->assertOk();
        Filament::setCurrentPanel(Filament::getPanel('admin'));
        Livewire::test(ListarSolicitudes::class)
            ->callAction(TestAction::make('aprobar')->table($solicitud))->assertHasNoActionErrors()
            ->callAction(TestAction::make('aprobar')->table(SolicitudPremium::findOrFail($duplicada)))
            ->callAction(TestAction::make('rechazar')->table(SolicitudPremium::findOrFail($duplicada)), data: ['motivo' => 'Pago ya registrado'])
            ->assertHasNoActionErrors();
        $this->assertDatabaseHas('solicitudes_premium', ['id' => $id, 'estado' => 'aprobada', 'periodo_academico_id' => $periodo]);
        $this->getJson('/api/v1/premium')->assertOk()->assertJsonPath('ultima_solicitud.motivo_rechazo', 'Pago ya registrado');
        $url = $this->withToken($token)->post('/api/v1/mi-tienda/portada',
            ['imagen' => UploadedFile::fake()->image('portada.png')], ['Accept' => 'application/json'])->assertOk()->json('portada_url');
        $publica = '/api/v1/tiendas/'.$tienda->slug;
        $this->withToken($this->token($comprador))->getJson($publica)->assertOk()
            ->assertJsonPath('data.plan', 'premium')->assertJsonPath('data.portada_url', $url);
        $this->get($url)->assertOk();

        DB::table('periodos_academicos')->where('id', $periodo)->update(['fecha_fin' => now('America/Guayaquil')->subDay()->toDateString()]);
        $this->getJson($publica)->assertOk()->assertJsonPath('data.plan', 'gratis')->assertJsonPath('data.portada_url', null);
        $this->get($url)->assertNotFound();
        Storage::disk('public')->assertExists(substr($url, strlen('/storage/')));
    }

    public function test_tarea_borra_foto_revisada_y_conserva_numero_y_monto(): void
    {
        Storage::fake('local');
        [$vendedor] = $this->vendedor('retencion');
        $this->configurar();
        $this->withToken($this->token($vendedor));
        $id = $this->enviar('RETENCION');
        $pendiente = SolicitudPremium::findOrFail($id);
        $vieja = now()->subDays(31)->format('Y-m-d H:i:s');
        $this->artisan('premium:limpiar-comprobantes')->assertExitCode(0);
        Storage::disk('local')->assertExists($pendiente->foto_comprobante);
        DB::table('solicitudes_premium')->where('id', $id)->update([
            'creado_en' => $vieja, 'revisado_en' => $vieja, 'estado' => 'rechazada', 'motivo_rechazo' => 'Prueba',
        ]);
        $this->artisan('premium:limpiar-comprobantes')->assertExitCode(0);
        Storage::disk('local')->assertMissing($pendiente->foto_comprobante);
        $this->assertDatabaseHas('solicitudes_premium', ['id' => $id, 'monto' => '3.00', 'numero_comprobante' => 'RETENCION', 'foto_comprobante' => null]);
        $this->getJson("/api/v1/premium/solicitudes/$id/foto")->assertNotFound();
    }

    private function enviar(string $numero): int
    {
        return $this->post('/api/v1/premium/solicitudes', $this->comprobante($numero), ['Accept' => 'application/json'])
            ->assertCreated()->assertJsonPath('data.estado', 'pendiente')->assertJsonMissingPath('data.foto_comprobante')->json('data.id');
    }

    private function comprobante(string $numero): array
    {
        return ['numero_comprobante' => $numero, 'monto' => '3.00', 'imagen' => UploadedFile::fake()->image('comprobante.png')];
    }

    private function usuario(string $alias): Usuario
    {
        return Usuario::create(['correo' => "$alias@utb.edu.ec", 'nombres' => ucfirst($alias), 'acepto_privacidad_en' => now()]);
    }

    private function vendedor(string $alias): array
    {
        $usuario = $this->usuario($alias);
        $facultad = DB::table('facultades')->insertGetId(['nombre' => $alias]);
        $carrera = DB::table('carreras')->insertGetId(['nombre' => $alias, 'facultad_id' => $facultad]);
        $punto = DB::table('puntos_entrega')->insertGetId(['nombre' => $alias]);
        $categoria = DB::table('categorias')->insertGetId(['nombre' => $alias]);
        DB::table('perfiles_vendedores')->insert([
            'usuario_id' => $usuario->id, 'carrera_id' => $carrera,
            'codigo_estudiante' => 'PRUEBA', 'semestre' => 4, 'whatsapp' => '593990000000',
        ]);
        $tienda = Tienda::create(['usuario_id' => $usuario->id, 'nombre' => $alias, 'slug' => $alias, 'punto_entrega_id' => $punto]);
        $tienda->categorias()->attach($categoria, ['orden' => 1]);

        return [$usuario, $tienda];
    }

    private function configurar(): int
    {
        $banco = DB::table('cuentas_bancarias')->insertGetId(['banco' => 'Ficticio', 'numero' => '0000', 'titular' => 'Prueba', 'tipo_cuenta' => 'ahorros']);
        $periodo = DB::table('periodos_academicos')->insertGetId([
            'nombre' => 'Prueba', 'fecha_inicio' => now()->subDays(45)->toDateString(), 'fecha_fin' => now()->addDays(30)->toDateString(),
        ]);
        DB::table('configuraciones')->insert(['id' => 1, 'cuenta_bancaria_id' => $banco, 'periodo_actual_id' => $periodo, 'precio_premium' => '3.00', 'dias_conservacion_comprobantes' => 30]);

        return $periodo;
    }

    private function token(Usuario $usuario): string
    {
        $token = bin2hex(random_bytes(32));
        DB::table('sesiones_acceso')->insert(['usuario_id' => $usuario->id, 'token_hash' => hash('sha256', $token), 'nombre_dispositivo' => 'Test', 'expira_en' => now()->addHour()]);

        return $token;
    }
}
