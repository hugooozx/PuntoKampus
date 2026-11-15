import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/account_api.dart';
import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/kampus_design.dart';
import 'institutional_account.dart';

const _payments = {
  'efectivo': 'Efectivo',
  'transferencia': 'Transferencia',
  'deuna': 'Deuna',
};

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
int _cents(String price) => (double.parse(price) * 100).round();
String _two(int n) => n.toString().padLeft(2, '0');
String _day(DateTime date) =>
    '${_two(date.day)}/${_two(date.month)}/${date.year}';
String _time(int minute) => '${_two(minute ~/ 60)}:${_two(minute % 60)}';
DateTime _ecuador(DateTime utc) =>
    utc.toUtc().subtract(const Duration(hours: 5));
DateTime _delivery(DateTime day, int minutes) => DateTime.utc(
  day.year,
  day.month,
  day.day,
  5,
).add(Duration(minutes: minutes));

class PurchaseCart extends ChangeNotifier {
  final Map<int, ({CatalogEntry product, int quantity})> _entries = {};
  CatalogEntry? shop;
  Iterable<({CatalogEntry product, int quantity})> get entries =>
      _entries.values;
  int quantity(int id) => _entries[id]?.quantity ?? 0;
  int get count => entries.fold(0, (sum, e) => sum + e.quantity);
  int get total =>
      entries.fold(0, (sum, e) => sum + _cents(e.product.price) * e.quantity);

  void add(CatalogEntry shop, CatalogEntry product, int amount) {
    assert(this.shop == null || this.shop!.id == shop.id);
    this.shop = shop;
    setQuantity(product, quantity(product.id) + amount);
  }

  void setQuantity(CatalogEntry product, int quantity) {
    if (quantity < 0 || quantity > 20) return;
    if (quantity == 0) {
      _entries.remove(product.id);
      if (_entries.isEmpty) shop = null;
    } else {
      _entries[product.id] = (product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void clear() {
    _entries.clear();
    shop = null;
    notifyListeners();
  }
}

class PurchaseScope extends InheritedWidget {
  const PurchaseScope({
    super.key,
    required this.session,
    required this.cart,
    required super.child,
  });
  final AccountSession session;
  final PurchaseCart cart;
  static PurchaseScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PurchaseScope>()!;
  @override
  bool updateShouldNotify(PurchaseScope oldWidget) =>
      session != oldWidget.session || cart != oldWidget.cart;
}

class CartButton extends StatelessWidget {
  const CartButton({super.key});
  @override
  Widget build(BuildContext context) {
    final cart = PurchaseScope.of(context).cart;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) => TextButton.icon(
        icon: const Icon(Icons.shopping_cart_outlined),
        label: Text(cart.count == 0 ? 'Carrito' : 'Carrito (${cart.count})'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const _CartPage()),
        ),
      ),
    );
  }
}

class ProductPurchase extends StatefulWidget {
  const ProductPurchase({super.key, required this.shop, required this.product});
  final CatalogEntry shop, product;
  @override
  State<ProductPurchase> createState() => _ProductPurchaseState();
}

class _ProductPurchaseState extends State<ProductPurchase> {
  int quantity = 1;

  Future<void> _add(PurchaseCart cart) async {
    if (cart.shop != null && cart.shop!.id != widget.shop.id) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tu carrito es de otra tienda'),
          content: Text(
            'Tienes productos de ${cart.shop!.name}. ¿Quieres vaciarlo y empezar uno nuevo?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Mantener carrito'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Vaciar y continuar'),
            ),
          ],
        ),
      );
      if (!mounted || replace != true) return;
      cart.clear();
    }
    if (cart.quantity(widget.product.id) + quantity > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Puedes agregar hasta 20 unidades por producto.'),
        ),
      );
      return;
    }
    cart.add(widget.shop, widget.product, quantity);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const _CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PurchaseScope.of(context);
    return ListenableBuilder(
      listenable: scope.session,
      builder: (context, _) {
        final ownShop =
            (scope.session.user?['tienda'] as Json?)?['id'] == widget.shop.id;
        if (ownShop) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.product.available) ...[
              const Text(
                'Cantidad',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              _Quantity(
                value: quantity,
                onChanged: (value) => setState(() => quantity = value),
              ),
              const SizedBox(height: 8),
              _Total(
                label: 'Subtotal',
                amount: _money(_cents(widget.product.price) * quantity),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton(
              onPressed: widget.product.available
                  ? () => _add(scope.cart)
                  : null,
              child: const Text('Agregar al carrito'),
            ),
          ],
        );
      },
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({required this.value, required this.onChanged});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.outlined(
        tooltip: 'Reducir cantidad',
        icon: const Icon(Icons.remove),
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
      ),
      SizedBox(
        width: 38,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          semanticsLabel: 'Cantidad: $value',
        ),
      ),
      IconButton.outlined(
        tooltip: 'Aumentar cantidad',
        icon: const Icon(Icons.add),
        onPressed: value < 20 ? () => onChanged(value + 1) : null,
      ),
    ],
  );
}

class _CartPage extends StatefulWidget {
  const _CartPage();
  @override
  State<_CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<_CartPage> {
  bool continuing = false;
  String? error;

  Future<void> _continue(PurchaseScope scope) async {
    setState(() {
      continuing = true;
      error = null;
    });
    try {
      final session = scope.session;
      if (!session.signedIn) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (_) => InstitutionalLogin(session: session),
          ),
        );
      }
      if (!mounted || !session.signedIn) return;
      if (session.needsProfile) {
        await Navigator.push(
          context,
          MaterialPageRoute<void>(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text('Acceso UTB')),
              body: SafeArea(
                child: ProfileForm(
                  session: session,
                  onCompleted: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        );
      }
      if (!mounted || !session.signedIn || session.needsProfile) return;
      if ((session.user?['tienda'] as Json?)?['id'] == scope.cart.shop?.id) {
        setState(
          () => error = 'No puedes pedir en tu propia tienda. Quita estos productos para continuar.',
        );
        return;
      }
      if (scope.cart.shop == null) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(builder: (_) => const _DeliveryPage()),
      );
    } finally {
      if (mounted) setState(() => continuing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = PurchaseScope.of(context);
    final cart = scope.cart;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguir comprando')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: cart,
          builder: (context, _) => PageBody(
            width: 560,
            children: [
              TitleBlock('Carrito', subtitle: cart.shop?.name),
              if (cart.entries.isEmpty) const Text('Tu carrito está vacío.'),
              for (final entry in cart.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.product.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text('${_money(_cents(entry.product.price))} cada uno'),
                        const SizedBox(height: 8),
                        Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          runSpacing: 8,
                          spacing: 16,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            _Quantity(
                              value: entry.quantity,
                              onChanged: (value) =>
                                  cart.setQuantity(entry.product, value),
                            ),
                            Text(
                              _money(
                                _cents(entry.product.price) * entry.quantity,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => cart.setQuantity(entry.product, 0),
                          child: const Text('Quitar'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (cart.entries.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Total(label: 'Total', amount: _money(cart.total)),
                const SizedBox(height: 8),
                const Text('Cada pedido corresponde a una sola tienda.'),
                if (error != null) _Error(error!),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: continuing ? null : () => _continue(scope),
                  child: const Text('Continuar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeliveryPage extends StatefulWidget {
  const _DeliveryPage();
  @override
  State<_DeliveryPage> createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<_DeliveryPage> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController();
  Future<List<CatalogOption>>? points;
  int? point, minute;
  DateTime? day;
  String? payment;
  bool sending = false, submitted = false;
  String? error, pointError, timeError;
  String? lastPayload, key;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    points ??= PurchaseScope.of(context).session.api.catalog
        .options('puntos-entrega');
  }

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  bool _validHour(DateTime date, int minute, DateTime now) {
    final utc = _delivery(date, minute);
    return !utc.isBefore(now.add(const Duration(minutes: 30))) &&
        !utc.isAfter(now.add(const Duration(days: 7)));
  }

  Future<void> _chooseDay() async {
    final now = DateTime.now().toUtc();
    final first = _ecuador(now.add(const Duration(minutes: 30)));
    final last = _ecuador(now.add(const Duration(days: 7)));
    final selected = await showDatePicker(
      context: context,
      initialDate:
          day == null ||
              day!.isBefore(DateUtils.dateOnly(first)) ||
              day!.isAfter(DateUtils.dateOnly(last))
          ? first
          : day!,
      firstDate: DateUtils.dateOnly(first),
      lastDate: DateUtils.dateOnly(last),
      helpText: 'Día de entrega',
      cancelText: 'Volver',
      confirmText: 'Elegir',
    );
    if (mounted && selected != null) {
      setState(() {
        day = selected;
        minute = null;
        timeError = null;
      });
    }
  }

  Future<void> _send(PurchaseScope scope) async {
    if (sending) return;
    if (!submitted) setState(() => submitted = true);
    if (!form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final delivery = _delivery(day!, minute!);
    final payload = <String, dynamic>{
      'tienda_id': scope.cart.shop!.id,
      'items': [
        for (final e in scope.cart.entries)
          {'producto_id': e.product.id, 'cantidad': e.quantity},
      ],
      'punto_entrega_id': point,
      'hora_entrega':
          '${delivery.year}-${_two(delivery.month)}-${_two(delivery.day)}T${_two(delivery.hour)}:${_two(delivery.minute)}:00+00:00',
      'forma_pago': payment,
      'nota': note.text.trim(),
    };
    final signature = jsonEncode(payload);
    if (signature != lastPayload) {
      final random = Random.secure();
      key = List.generate(
        16,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
      lastPayload = signature;
    }
    setState(() {
      sending = true;
      error = null;
      pointError = null;
      timeError = null;
    });
    try {
      final result = await scope.session.authorized(
        'POST',
        'pedidos',
        data: payload,
        requestId: key,
      );
      scope.cart.clear();
      if (!mounted) return;
      final order = result['pedido'] as Json;
      final whatsapp = _whatsappLink(result['whatsapp_url'] as String?);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => _OrderSent(order: order, whatsapp: whatsapp),
        ),
        (route) => route.isFirst,
      );
      if (whatsapp != null) await _openWhatsApp(whatsapp);
    } on AccountFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        pointError = failure.fields['punto_entrega_id'];
        timeError = failure.fields['hora_entrega'];
        if (pointError == null && timeError == null) error = failure.message;
      });
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = PurchaseScope.of(context);
    final now = DateTime.now().toUtc();
    final hours = day == null
        ? <int>[]
        : [
            for (var time = 0; time < 1440; time += 5)
              if (minute == time || _validHour(day!, time, now)) time,
          ];
    return PopScope(
      canPop: !sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Volver al carrito')),
        body: SafeArea(
          child: PageBody(
            width: 560,
            children: [
              TitleBlock('Entrega y pago', subtitle: scope.cart.shop?.name),
              FutureBuilder<List<CatalogOption>>(
                future: points,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const LinearProgressIndicator(
                      semanticsLabel: 'Cargando puntos de entrega',
                    );
                  }
                  final options = snapshot.data ?? [];
                  if (options.isEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.hasError
                              ? 'No pudimos cargar los puntos de entrega.'
                              : 'Aún no hay puntos de entrega activos.',
                        ),
                        OutlinedButton(
                          onPressed: () => setState(
                            () => points = scope.session.api.catalog.options(
                              'puntos-entrega',
                            ),
                          ),
                          child: const Text('Reintentar'),
                        ),
                      ],
                    );
                  }
                  return Form(
                    key: form,
                    autovalidateMode: submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: point,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Punto de entrega',
                            errorText: pointError,
                          ),
                          items: [
                            for (final value in options)
                              DropdownMenuItem(
                                value: value.id,
                                child: Text(value.name),
                              ),
                          ],
                          onChanged: sending
                              ? null
                              : (value) => setState(() {
                                  point = value;
                                  pointError = null;
                                }),
                          validator: (value) => value == null
                              ? 'Selecciona un punto de entrega.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        FormField<DateTime>(
                          validator: (_) =>
                              day == null ? 'Selecciona un día.' : null,
                          builder: (field) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton.icon(
                                onPressed: sending
                                    ? null
                                    : () async {
                                        await _chooseDay();
                                        if (mounted) field.didChange(day);
                                      },
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  day == null
                                      ? 'Elegir día'
                                      : 'Día: ${_day(day!)}',
                                ),
                              ),
                              if (field.hasError) _Error(field.errorText!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<int>(
                          key: ValueKey(day),
                          initialValue: hours.contains(minute) ? minute : null,
                          isExpanded: true,
                          menuMaxHeight: 300,
                          decoration: InputDecoration(
                            labelText: 'Hora de entrega',
                            errorText: timeError,
                          ),
                          items: [
                            for (final value in hours)
                              DropdownMenuItem(
                                value: value,
                                child: Text(_time(value)),
                              ),
                          ],
                          onChanged: sending || hours.isEmpty
                              ? null
                              : (value) => setState(() {
                                  minute = value;
                                  timeError = null;
                                }),
                          validator: (value) {
                            if (day == null ||
                                minute == null ||
                                value == null) {
                              return 'Selecciona una hora.';
                            }
                            return _validHour(
                                  day!,
                                  minute!,
                                  DateTime.now().toUtc(),
                                )
                                ? null
                                : 'Elige una hora que siga disponible.';
                          },
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Desde 30 minutos hasta 7 días. Hora de Ecuador continental.',
                          style: TextStyle(color: muted, fontSize: 14),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: payment,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Forma de pago',
                          ),
                          items: [
                            for (final value in _payments.entries)
                              DropdownMenuItem(
                                value: value.key,
                                child: Text(value.value),
                              ),
                          ],
                          onChanged: sending
                              ? null
                              : (value) => setState(() => payment = value),
                          validator: (value) => value == null
                              ? 'Selecciona cómo vas a pagar.'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: note,
                          enabled: !sending,
                          maxLength: 200,
                          maxLines: 3,
                          maxLengthEnforcement: MaxLengthEnforcement.enforced,
                          decoration: const InputDecoration(
                            labelText: 'Nota (opcional)',
                          ),
                        ),
                        _Total(
                          label: 'Total',
                          amount: _money(scope.cart.total),
                        ),
                        const SizedBox(height: 8),
                        const Text('Pagarás directamente a la tienda.'),
                        if (error != null) _Error(error!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: sending || scope.cart.shop == null
                              ? null
                              : () => _send(scope),
                          child: Text(
                            sending ? 'Guardando pedido…' : 'Enviar pedido',
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Uri? _whatsappLink(String? text) {
  final url = Uri.tryParse(text ?? '');
  return url != null && url.scheme == 'https' && url.host == 'wa.me'
      ? url
      : null;
}

Future<bool> _openWhatsApp(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } on Exception {
    return false;
  }
}

class _OrderSent extends StatelessWidget {
  const _OrderSent({required this.order, required this.whatsapp});
  final Json order;
  final Uri? whatsapp;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pedido enviado')),
    body: SafeArea(
      child: PageBody(
        width: 560,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Icon(Icons.check_circle_outline, size: 42, color: greenInk),
          ),
          const SizedBox(height: 10),
          const TitleBlock(
            'Tu pedido quedó registrado',
            subtitle: 'Termina de enviarlo por WhatsApp.',
          ),
          _OrderSummary(order: order),
          const SizedBox(height: 8),
          for (final item in (order['items'] as List).cast<Json>())
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${item['cantidad']} × ${item['nombre_producto']} · \$${item['subtotal']}',
              ),
            ),
          const SizedBox(height: 12),
          if (whatsapp != null)
            FilledButton.icon(
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir WhatsApp'),
              onPressed: () async {
                if (!await _openWhatsApp(whatsapp!) && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'No pudimos abrir WhatsApp. Inténtalo de nuevo.',
                      ),
                    ),
                  );
                }
              },
            )
          else
            const Text(
              'La tienda ya no tiene un WhatsApp disponible para abrir.',
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => Scaffold(
                  appBar: AppBar(),
                  body: const SafeArea(child: BuyerOrders(visible: true)),
                ),
              ),
            ),
            child: const Text('Ver mis pedidos'),
          ),
        ],
      ),
    ),
  );
}

class BuyerOrders extends StatefulWidget {
  const BuyerOrders({super.key, required this.visible});
  final bool visible;
  @override
  State<BuyerOrders> createState() => _BuyerOrdersState();
}

class _BuyerOrdersState extends State<BuyerOrders> {
  Future<Json>? result;
  @override
  void didUpdateWidget(BuyerOrders oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) result = null;
  }

  @override
  Widget build(BuildContext context) {
    final session = PurchaseScope.of(context).session;
    if (widget.visible && session.signedIn) {
      result ??= session.authorized('GET', 'pedidos');
    }
    return PageBody(
      width: 560,
      children: [
        const TitleBlock('Mis pedidos'),
        FutureBuilder<Json>(
          future: result,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LinearProgressIndicator(
                semanticsLabel: 'Cargando tus pedidos',
              );
            }
            if (snapshot.hasError) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('No pudimos cargar tus pedidos.'),
                  OutlinedButton(
                    onPressed: () => setState(
                      () => result = session.authorized('GET', 'pedidos'),
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final orders = (snapshot.data?['data'] as List? ?? []).cast<Json>();
            if (orders.isEmpty) {
              return const Text(
                'Todavía no has hecho pedidos. Busca en la vitrina lo que necesitas.',
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final order in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderSummary(order: order),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _OrderSummary extends StatelessWidget {
  const _OrderSummary({required this.order});
  final Json order;
  @override
  Widget build(BuildContext context) {
    final local = _ecuador(DateTime.parse('${order['hora_entrega']}Z'));
    final status = switch (order['estado']) {
      'pendiente' => 'Pendiente',
      'entregado' => 'Entregado',
      'cancelado' => 'Cancelado',
      _ => 'Vencido',
    };
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order['codigo'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          Text(
            status,
            style: const TextStyle(fontWeight: FontWeight.w700, color: orange),
          ),
          const SizedBox(height: 8),
          Text(
            order['tienda'] as String? ?? 'Tienda eliminada',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${order['punto_entrega']} · ${_day(local)} · ${_time(local.hour * 60 + local.minute)}',
          ),
          Text(_payments[order['forma_pago']]!),
          const Divider(),
          Text(
            'Total: \$${order['total']}',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: line),
    ),
    child: Padding(padding: const EdgeInsets.all(14), child: child),
  );
}

class _Total extends StatelessWidget {
  const _Total({required this.label, required this.amount});
  final String label, amount;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    ),
  );
}

class _Error extends StatelessWidget {
  const _Error(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    ),
  );
}
