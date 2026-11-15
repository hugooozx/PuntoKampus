<?php

namespace App\Http\Controllers;

use App\Models\PerfilVendedor;
use App\Models\Producto;
use App\Models\PuntoEntrega;
use App\Models\Tienda;
use Carbon\CarbonImmutable;
use Illuminate\Database\UniqueConstraintViolationException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PedidoController extends Controller
{
    private const PAGO = ['efectivo' => 'Efectivo', 'transferencia' => 'Transferencia', 'deuna' => 'Deuna'];

    public function indice(Request $request)
    {
        $datos = $request->validate(['estado' => ['sometimes', Rule::in(['pendiente', 'entregado', 'cancelado', 'vencido'])]]);
        $lista = $this->consultaPedidos()->where('p.comprador_id', $request->user()->id)
            ->when(isset($datos['estado']), fn ($consulta) => $consulta->where('p.estado', $datos['estado']))
            ->orderByDesc('p.id')->simplePaginate(20, pageName: 'pagina');

        return response()->json($lista);
    }

    public function crear(Request $request)
    {
        $datos = $request->validate([
            'tienda_id' => ['required', 'integer:strict', 'min:1'],
            'items' => ['required', 'array', 'list', 'min:1'],
            'items.*' => ['required', 'array:producto_id,cantidad'],
            'items.*.producto_id' => ['required', 'integer:strict', 'min:1', 'distinct'],
            'items.*.cantidad' => ['required', 'integer:strict', 'between:1,20'],
            'punto_entrega_id' => ['required', 'integer:strict', 'min:1'],
            'hora_entrega' => ['required', 'date_format:Y-m-d\TH:i:sP'],
            'forma_pago' => ['required', Rule::in(array_keys(self::PAGO))],
            'nota' => ['nullable', 'string', 'max:200'],
        ], [
            'tienda_id.*' => 'Selecciona una tienda válida.',
            'items.*' => 'Agrega al menos un producto válido.',
            'items.*.producto_id.distinct' => 'Cada producto debe aparecer una sola vez en el carrito.',
            'items.*.producto_id.*' => 'Hay un producto inválido en tu carrito.',
            'items.*.cantidad.*' => 'La cantidad por producto debe ser de 1 a 20.',
            'punto_entrega_id.*' => 'Elige un punto de entrega válido.',
            'hora_entrega.*' => 'Elige un día y una hora de entrega válidos.',
            'forma_pago.*' => 'Elige efectivo, transferencia o Deuna.',
            'nota.*' => 'La nota puede tener hasta 200 caracteres.',
        ]);
        $clave = $request->header('Idempotency-Key');
        if ($clave !== null && ! preg_match('/^[a-f0-9]{32}$/D', $clave)) {
            throw ValidationException::withMessages(['envio' => 'La clave del envío no es válida. Vuelve al carrito.']);
        }
        $comprador = $request->user();
        $entrega = CarbonImmutable::parse($datos['hora_entrega'])->utc();
        $nota = $datos['nota'] ?? null;
        $cantidades = collect($datos['items'])->mapWithKeys(fn ($item) => [(int) $item['producto_id'] => (int) $item['cantidad']])->sortKeys();
        $huella = hash('sha256', json_encode([
            (int) $datos['tienda_id'], (int) $datos['punto_entrega_id'], $entrega->toIso8601String(),
            $datos['forma_pago'], $nota, $cantidades,
        ], JSON_THROW_ON_ERROR));
        if ($clave !== null && ($existente = DB::table('pedidos')
            ->where('comprador_id', $comprador->id)->where('clave_envio', $clave)->first())) {
            abort_unless(hash_equals($existente->huella_envio, $huella), 409, 'Este envío ya se usó con otros datos.');

            return response()->json($this->confirmacion($existente->id, $comprador->nombres));
        }

        // La sesión serializa los envíos del comprador. Se bloquean tienda y productos antes de copiar precios.
        for ($intento = 0; ; $intento++) {
            try {
                $id = DB::transaction(function () use ($datos, $comprador, $cantidades, $entrega, $nota, $clave, $huella) {
                    $tienda = Tienda::activas()->whereKey($datos['tienda_id'])->lockForUpdate()->first();
                    abort_unless($tienda, 422, 'Esta tienda ya no está disponible.');
                    abort_if($tienda->usuario_id === $comprador->id, 422, 'No puedes pedir en tu propia tienda.');
                    abort_unless($this->whatsapp($tienda->usuario_id), 422, 'La tienda no tiene un WhatsApp válido para recibir pedidos.');
                    $punto = PuntoEntrega::where('activa', true)->whereKey($datos['punto_entrega_id'])->sharedLock()->first();
                    if (! $punto) {
                        throw ValidationException::withMessages(['punto_entrega_id' => 'Elige un punto de entrega activo.']);
                    }
                    $productos = Producto::withTrashed()->whereIn('id', $cantidades->keys())->orderBy('id')->lockForUpdate()->get()->keyBy('id');
                    $lineas = [];
                    foreach ($cantidades as $productoId => $cantidad) {
                        $producto = $productos->get($productoId);
                        if (! $producto || $producto->tienda_id !== $tienda->id) {
                            throw ValidationException::withMessages(['items' => 'Hay un producto que ya no pertenece a esta tienda. Revisa tu carrito.']);
                        }
                        if ($producto->trashed() || ! $producto->disponible) {
                            throw ValidationException::withMessages(['items' => "$producto->nombre se agotó mientras armabas tu pedido. Quítalo del carrito para continuar."]);
                        }
                        $lineas[] = [
                            'producto_id' => $producto->id, 'nombre_producto' => $producto->nombre,
                            'precio_unitario' => $producto->precio, 'cantidad' => $cantidad,
                        ];
                    }
                    $ahora = CarbonImmutable::now('UTC');
                    if ($entrega->lt($ahora->addMinutes(30)) || $entrega->gt($ahora->addDays(7))) {
                        throw ValidationException::withMessages(['hora_entrega' => 'Elige una hora entre 30 minutos y 7 días a partir de ahora.']);
                    }
                    $fecha = $ahora->format('Y-m-d H:i:s.u');
                    $id = DB::table('pedidos')->insertGetId([
                        'codigo' => sprintf('PK-%06d', random_int(0, 999999)),
                        'comprador_id' => $comprador->id, 'tienda_id' => $tienda->id, 'punto_entrega_id' => $punto->id,
                        'hora_entrega' => $entrega, 'forma_pago' => $datos['forma_pago'], 'nota' => $nota,
                        'clave_envio' => $clave, 'huella_envio' => $clave === null ? null : $huella,
                        'creado_en' => $fecha, 'estado_cambiado_en' => $fecha,
                    ]);
                    DB::table('detalles_pedidos')->insert(array_map(fn ($linea) => ['pedido_id' => $id] + $linea, $lineas));

                    return $id;
                });
                break;
            } catch (UniqueConstraintViolationException $error) {
                if ($intento >= 4 || ! str_contains($error->getMessage(), 'uq_pedidos_codigo')) {
                    throw $error;
                }
            }
        }

        return response()->json($this->confirmacion($id, $comprador->nombres), 201);
    }

    private function whatsapp(?int $usuario): ?string
    {
        $numero = $usuario === null ? null : PerfilVendedor::whereKey($usuario)->value('whatsapp');

        return $numero && preg_match('/^5939[0-9]{8}$/D', $numero) ? $numero : null;
    }

    private function consultaPedidos()
    {
        return DB::table('pedidos as p')
            ->leftJoin('tiendas as t', 't.id', '=', 'p.tienda_id')
            ->join('puntos_entrega as e', 'e.id', '=', 'p.punto_entrega_id')
            ->join('vistas_totales_pedidos as v', 'v.pedido_id', '=', 'p.id')
            ->select(['p.id', 'p.codigo', 'p.estado', 'p.hora_entrega', 'p.forma_pago', 'p.nota',
                'p.tienda_id', 'p.punto_entrega_id', 't.nombre as tienda', 'e.nombre as punto_entrega', 'v.total']);
    }

    private function confirmacion(int $id, string $comprador): array
    {
        $pedido = $this->consultaPedidos()->where('p.id', $id)->first();
        $pedido->items = DB::table('vistas_detalles_pedidos')->where('pedido_id', $id)->orderBy('id')
            ->get(['producto_id', 'nombre_producto', 'precio_unitario', 'cantidad', 'subtotal']);
        $entrega = CarbonImmutable::parse($pedido->hora_entrega, 'UTC')->setTimezone('America/Guayaquil')->locale('es');
        $mensaje = ["Hola, soy $comprador. Te hice un pedido por PuntoKampus ($pedido->codigo):"];
        foreach ($pedido->items as $item) {
            $mensaje[] = "- $item->cantidad x $item->nombre_producto: \$$item->subtotal";
        }
        $mensaje[] = "Total: \$$pedido->total";
        $mensaje[] = 'Entrega: '.$pedido->punto_entrega.', '.$entrega->translatedFormat('l d/m').' a las '.$entrega->format('H:i');
        $mensaje[] = 'Pago: '.self::PAGO[$pedido->forma_pago];
        if ($pedido->nota !== null) {
            $mensaje[] = 'Nota: '.$pedido->nota;
        }
        $usuario = $pedido->tienda_id === null ? null : Tienda::whereKey($pedido->tienda_id)->value('usuario_id');
        $numero = $this->whatsapp($usuario);

        return [
            'pedido' => $pedido,
            'whatsapp_url' => $numero === null ? null : 'https://wa.me/'.$numero.'?text='.rawurlencode(implode("\n", $mensaje)),
        ];
    }
}
