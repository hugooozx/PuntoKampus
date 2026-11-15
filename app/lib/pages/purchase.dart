import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../api/account_api.dart';
import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/catalog_cards.dart';
import '../ui/kampus_design.dart';
import 'institutional_account.dart';

const _payments = {
  'efectivo': 'Efectivo',
  'transferencia': 'Transferencia',
  'deuna': 'Deuna',
};

String _money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
int _cents(String price) => (double.parse(price) * 100).round();
int _quantityLimit(CatalogEntry product) =>
    min(20, product.json['unidades_disponibles'] as int? ?? 20);
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
    if (quantity < 0 || quantity > _quantityLimit(product)) return;
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
    final compact =
        MediaQuery.sizeOf(context).width < 520 &&
        MediaQuery.textScalerOf(context).scale(14) > 20;
    return ListenableBuilder(
      listenable: cart,
      builder: (context, _) {
        final label = cart.count == 0 ? 'Carrito' : 'Carrito (${cart.count})';
        void open() => Navigator.push(
          context,
          MaterialPageRoute<void>(builder: (_) => const _CartPage()),
        );
        const icon = Icon(Icons.shopping_cart_outlined);
        return compact
            ? IconButton(
                tooltip: label,
                onPressed: open,
                icon: Badge(
                  isLabelVisible: cart.count > 0,
                  backgroundColor: orange,
                  child: icon,
                ),
              )
            : TextButton.icon(icon: icon, label: Text(label), onPressed: open);
      },
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
  int get maximum => _quantityLimit(widget.product);

  Future<void> _add(PurchaseCart cart, int selected) async {
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
    if (cart.quantity(widget.product.id) + selected > maximum) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Puedes agregar hasta $maximum unidades de este producto.',
          ),
        ),
      );
      return;
    }
    cart.add(widget.shop, widget.product, selected);
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const _CartPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = PurchaseScope.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([scope.session, scope.cart]),
      builder: (context, _) {
        final ownShop =
            (scope.session.user?['tienda'] as Json?)?['id'] == widget.shop.id;
        if (ownShop) return const SizedBox.shrink();
        final alreadyAdded = scope.cart.quantity(widget.product.id);
        final remaining = maximum - alreadyAdded;
        final canAdd = widget.product.available && remaining > 0;
        final selected = quantity.clamp(1, max(1, remaining)).toInt();
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (canAdd) ...[
                const Text(
                  'Cantidad',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _Quantity(
                      value: selected,
                      maximum: remaining,
                      onChanged: (value) => setState(() => quantity = value),
                    ),
                    Text(
                      alreadyAdded == 0
                          ? 'Máximo $maximum por producto'
                          : 'En el carrito: $alreadyAdded',
                      style: const TextStyle(fontSize: 14, color: muted),
                    ),
                  ],
                ),
                const Divider(height: 28),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      const Expanded(child: Text('Subtotal')),
                      Expanded(
                        child: Text(
                          _money(_cents(widget.product.price) * selected),
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ] else if (widget.product.available) ...[
                const Text(
                  'Ya tienes el máximo disponible de este producto en el carrito.',
                ),
                const SizedBox(height: 12),
              ],
              FilledButton.icon(
                onPressed: canAdd ? () => _add(scope.cart, selected) : null,
                icon: const Icon(Icons.add_shopping_cart_outlined),
                label: const Text('Agregar al carrito'),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Quantity extends StatelessWidget {
  const _Quantity({
    required this.value,
    required this.onChanged,
    required this.maximum,
  });
  final int value, maximum;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: canvas,
      border: Border.all(color: line),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Reducir cantidad',
          icon: const Icon(Icons.remove),
          onPressed: value > 1 ? () => onChanged(value - 1) : null,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 42),
          child: Text(
            '$value',
            textAlign: TextAlign.center,
            semanticsLabel: 'Cantidad: $value',
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        IconButton(
          tooltip: 'Aumentar cantidad',
          icon: const Icon(Icons.add),
          onPressed: value < maximum ? () => onChanged(value + 1) : null,
        ),
      ],
    ),
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
      if (!await ensureInstitutionalProfile(context, session) || !mounted) {
        return;
      }
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
    final api = scope.session.api.catalog;
    return Scaffold(
      appBar: AppBar(title: const Text('Seguir comprando')),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: cart,
          builder: (context, _) {
            final shop = cart.shop;
            if (shop == null || cart.entries.isEmpty) {
              return PageBody(
                width: 670,
                children: [
                  const TitleBlock('Carrito'),
                  StatusPanel(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Tu carrito está vacío.',
                    message: 'Encuentra algo que te guste en la Vitrina y agrégalo aquí.',
                    action: FilledButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/vitrina',
                        (_) => false,
                      ),
                      child: const Text('Ir a la vitrina'),
                    ),
                  ),
                ],
              );
            }
            final items = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Panel(
                  child: _CartShop(api: api, shop: shop),
                ),
                for (final entry in cart.entries)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _CartItem(
                      api: api,
                      cart: cart,
                      product: entry.product,
                      quantity: entry.quantity,
                    ),
                  ),
              ],
            );
            final summary = _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    cart.count == 1 ? '1 unidad' : '${cart.count} unidades',
                    style: const TextStyle(color: muted),
                  ),
                  const Divider(height: 20),
                  Semantics(
                    liveRegion: true,
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            _money(cart.total),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(fontSize: 26),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Cada pedido corresponde a una sola tienda.',
                    style: TextStyle(fontSize: 14, color: muted),
                  ),
                  if (error != null) _Error(error!),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: continuing ? null : () => _continue(scope),
                    child: const Text('Continuar'),
                  ),
                  TextButton(
                    onPressed: continuing
                        ? null
                        : () => Navigator.pushReplacementNamed(
                            context,
                            '/t/${shop.slug}',
                          ),
                    child: const Text('Seguir viendo la tienda'),
                  ),
                ],
              ),
            );
            return PageBody(
              width: 1060,
              children: [
                const TitleBlock('Carrito'),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide =
                        constraints.maxWidth >= 820 &&
                        MediaQuery.textScalerOf(context).scale(16) <= 22;
                    return wide
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 6, child: items),
                              const SizedBox(width: 24),
                              Expanded(flex: 4, child: summary),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              items,
                              const SizedBox(height: 16),
                              summary,
                            ],
                          );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _CartItem extends StatelessWidget {
  const _CartItem({
    required this.api,
    required this.cart,
    required this.product,
    required this.quantity,
  });
  final CatalogApi api;
  final PurchaseCart cart;
  final CatalogEntry product;
  final int quantity;
  @override
  Widget build(BuildContext context) {
    final price = _cents(product.price);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 68,
                  child: CatalogImage(
                    api: api,
                    url: product.image,
                    label: product.name,
                    height: 68,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_money(price)} cada uno',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _Quantity(
                value: quantity,
                maximum: _quantityLimit(product),
                onChanged: (value) => cart.setQuantity(product, value),
              ),
              Text(
                _money(price * quantity),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => cart.setQuantity(product, 0),
              style: TextButton.styleFrom(foregroundColor: ink),
              child: const Text(
                'Quitar',
                style: TextStyle(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
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
    FocusScope.of(context).unfocus();
    final invalid = form.currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 200),
        alignment: 0.15,
      );
      return;
    }
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
        (route) => route.settings.name == '/vitrina' || route.isFirst,
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
    final cart = scope.cart;
    return PopScope(
      canPop: !sending,
      child: Scaffold(
        appBar: AppBar(title: const Text('Volver al carrito')),
        body: SafeArea(
          child: PageBody(
            width: 1010,
            children: [
              const TitleBlock('Entrega y pago'),
              FutureBuilder<List<CatalogOption>>(
                future: points,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const StatusPanel(
                      icon: Icons.location_on_outlined,
                      title: 'Cargando puntos de entrega…',
                      message: 'En un momento podrás elegir dónde recibir tu pedido.',
                      busy: true,
                    );
                  }
                  final options = snapshot.data ?? [];
                  if (options.isEmpty) {
                    return StatusPanel(
                      icon: Icons.location_off_outlined,
                      title: snapshot.hasError
                          ? 'No pudimos cargar los puntos de entrega'
                          : 'Aún no hay puntos de entrega activos',
                      message: 'Puedes reintentar o volver al carrito.',
                      action: OutlinedButton(
                        onPressed: () => setState(
                          () => points = scope.session.api.catalog.options(
                            'puntos-entrega',
                          ),
                        ),
                        child: const Text('Reintentar'),
                      ),
                    );
                  }
                  return Form(
                    key: form,
                    autovalidateMode: submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final wide =
                            constraints.maxWidth >= 800 &&
                            MediaQuery.textScalerOf(context).scale(16) <= 20;
                        final fields = _checkoutFields(options);
                        final summary = _Panel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (cart.shop case final shop?)
                                _CartShop(
                                  api: scope.session.api.catalog,
                                  shop: shop,
                                ),
                              const Divider(height: 24),
                              for (final entry in cart.entries)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _OrderAmount(
                                    label:
                                        '${entry.quantity} × ${entry.product.name}',
                                    amount: _money(
                                      _cents(entry.product.price) *
                                          entry.quantity,
                                    ),
                                  ),
                                ),
                              const Divider(height: 20),
                              _OrderAmount(
                                label: 'Total',
                                amount: _money(cart.total),
                                total: true,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Pagarás directamente a la tienda. Al registrar el pedido intentaremos abrir WhatsApp.',
                                style: TextStyle(color: muted, height: 1.4),
                              ),
                              if (error != null) _Error(error!),
                              const SizedBox(height: 16),
                              FilledButton(
                                onPressed: sending || cart.shop == null
                                    ? null
                                    : () => _send(scope),
                                child: Text(
                                  sending
                                      ? 'Guardando pedido…'
                                      : 'Enviar pedido',
                                ),
                              ),
                            ],
                          ),
                        );
                        return wide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 6, child: fields),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 4, child: summary),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  fields,
                                  const SizedBox(height: 16),
                                  summary,
                                ],
                              );
                      },
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

  Widget _checkoutFields(List<CatalogOption> options) {
    final now = DateTime.now().toUtc();
    final hours = day == null
        ? <int>[]
        : [
            for (var time = 0; time < 1440; time += 5)
              if (minute == time || _validHour(day!, time, now)) time,
          ];
    final dayField = FormField<DateTime>(
      validator: (_) => day == null ? 'Selecciona un día.' : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Día de entrega',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: sending
                ? null
                : () async {
                    await _chooseDay();
                    if (mounted) field.didChange(day);
                  },
            icon: const Icon(Icons.event_outlined),
            label: Text(day == null ? 'Elegir día' : 'Día: ${_day(day!)}'),
          ),
          if (field.hasError) _Error(field.errorText!),
        ],
      ),
    );
    final hourField = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Hora de entrega',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          key: ValueKey(day),
          initialValue: hours.contains(minute) ? minute : null,
          isExpanded: true,
          menuMaxHeight: 300,
          decoration: InputDecoration(
            errorText: timeError,
            hintText: day == null ? 'Elige un día primero' : 'Elegir hora',
          ),
          items: [
            for (final value in hours)
              DropdownMenuItem(value: value, child: Text(_time(value))),
          ],
          onChanged: sending || hours.isEmpty
              ? null
              : (value) => setState(() {
                  minute = value;
                  timeError = null;
                }),
          validator: (value) {
            if (day == null || value == null) return 'Selecciona una hora.';
            return _validHour(day!, value, DateTime.now().toUtc())
                ? null
                : 'Elige una hora que siga disponible.';
          },
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Entrega en el campus',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<int>(
                initialValue: point,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Punto de entrega',
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  errorText: pointError,
                ),
                items: [
                  for (final value in options)
                    DropdownMenuItem(value: value.id, child: Text(value.name)),
                ],
                onChanged: sending
                    ? null
                    : (value) => setState(() {
                        point = value;
                        pointError = null;
                      }),
                validator: (value) =>
                    value == null ? 'Selecciona un punto de entrega.' : null,
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final inline =
                      constraints.maxWidth >= 315 &&
                      MediaQuery.textScalerOf(context).scale(16) <= 20;
                  return inline
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: dayField),
                            const SizedBox(width: 12),
                            Expanded(child: hourField),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            dayField,
                            const SizedBox(height: 12),
                            hourField,
                          ],
                        );
                },
              ),
              const SizedBox(height: 8),
              const Text(
                'Desde 30 minutos hasta 7 días. Hora de Ecuador continental.',
                style: TextStyle(color: muted, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Forma de pago',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              FormField<String>(
                initialValue: payment,
                validator: (value) =>
                    value == null ? 'Selecciona cómo vas a pagar.' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RadioGroup<String>(
                      groupValue: field.value,
                      onChanged: (value) {
                        field.didChange(value);
                        payment = value;
                      },
                      child: Column(
                        children: [
                          for (final option in _payments.entries)
                            RadioListTile<String>(
                              value: option.key,
                              enabled: !sending,
                              contentPadding: EdgeInsets.zero,
                              title: Text(option.value),
                            ),
                        ],
                      ),
                    ),
                    if (field.hasError) _Error(field.errorText!),
                  ],
                ),
              ),
              const Divider(height: 22),
              TextFormField(
                controller: note,
                enabled: !sending,
                maxLength: 200,
                minLines: 2,
                maxLines: 3,
                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                decoration: const InputDecoration(
                  labelText: 'Nota (opcional)',
                  alignLabelWithHint: true,
                ),
                validator: (value) => (value?.trim().runes.length ?? 0) > 200
                    ? 'La nota admite hasta 200 caracteres.'
                    : null,
              ),
            ],
          ),
        ),
      ],
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
  Widget build(BuildContext context) {
    final local = _ecuador(DateTime.parse('${order['hora_entrega']}Z'));
    final shop = order['tienda'] as String? ?? 'Tienda eliminada';
    return Scaffold(
      appBar: AppBar(title: const Text('Pedido enviado')),
      body: SafeArea(
        child: PageBody(
          width: 600,
          children: [
            Column(
              children: [
                const CircleAvatar(
                  radius: 27,
                  backgroundColor: softGreen,
                  foregroundColor: greenInk,
                  child: Icon(Icons.check, size: 32),
                ),
                const SizedBox(height: 12),
                Semantics(
                  header: true,
                  child: Text(
                    'Tu pedido quedó registrado',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                Semantics(
                  label: 'Código del pedido ${order['codigo']}',
                  excludeSemantics: true,
                  child: SelectableText(
                    order['codigo'] as String,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 8),
                _OrderBadge(state: order['estado']),
                const SizedBox(height: 12),
                if (whatsapp != null)
                  const Text(
                    'Confirma el pedido con la tienda por WhatsApp.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _OrderFact(
                    icon: Icons.storefront_outlined,
                    child: Text(
                      shop,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 22),
                  for (final item in (order['items'] as List).cast<Json>())
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _OrderAmount(
                        label:
                            '${item['cantidad']} × ${item['nombre_producto']}',
                        amount: '\$${item['subtotal']}',
                      ),
                    ),
                  _OrderAmount(
                    label: 'Total',
                    amount: '\$${order['total']}',
                    total: true,
                  ),
                  const Divider(height: 22),
                  _OrderFact(
                    icon: Icons.location_on_outlined,
                    child: Text(order['punto_entrega'] as String),
                  ),
                  const SizedBox(height: 8),
                  _OrderFact(
                    icon: Icons.event_outlined,
                    child: Text(
                      '${_day(local)} · ${_time(local.hour * 60 + local.minute)}',
                    ),
                  ),
                  const SizedBox(height: 8),
                  _OrderFact(
                    icon: Icons.payments_outlined,
                    child: Text(_payments[order['forma_pago']] ?? ''),
                  ),
                  if (order['nota'] case final String note
                      when note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _OrderFact(icon: Icons.notes_outlined, child: Text(note)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (whatsapp != null) ...[
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
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                'La tienda ya no tiene un WhatsApp disponible para abrir.',
              ),
              const SizedBox(height: 8),
            ],
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
}

class _OrderFact extends StatelessWidget {
  const _OrderFact({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 21, color: muted),
      const SizedBox(width: 10),
      Expanded(child: child),
    ],
  );
}

class _OrderAmount extends StatelessWidget {
  const _OrderAmount({
    required this.label,
    required this.amount,
    this.total = false,
  });
  final String label, amount;
  final bool total;

  @override
  Widget build(BuildContext context) {
    final style = total ? Theme.of(context).textTheme.titleLarge : null;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Text(label, style: style)),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            amount,
            textAlign: TextAlign.end,
            style: style ?? const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class BuyerOrders extends StatelessWidget {
  const BuyerOrders({super.key, required this.visible, this.onChanged});
  final bool visible;
  final VoidCallback? onChanged;
  @override
  Widget build(BuildContext context) {
    final session = PurchaseScope.of(context).session;
    if (!visible || !session.signedIn) return const SizedBox.shrink();
    return _OrderHistory(session: session, onChanged: onChanged);
  }
}

class SellerOrdersPage extends StatelessWidget {
  const SellerOrdersPage({
    super.key,
    required this.session,
    required this.shopName,
    required this.onChanged,
  });
  final AccountSession session;
  final String shopName;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi tienda')),
    body: SafeArea(
      child: _OrderHistory(
        session: session,
        shopName: shopName,
        onChanged: onChanged,
      ),
    ),
  );
}

const _filters = <String, String>{
  '': 'Todos',
  'pendiente': 'Pendientes',
  'entregado': 'Entregados',
  'cancelado': 'Cancelados',
  'vencido': 'Vencidos',
};

class _OrderHistory extends StatefulWidget {
  const _OrderHistory({required this.session, this.shopName, this.onChanged});
  final AccountSession session;
  final String? shopName;
  final VoidCallback? onChanged;

  @override
  State<_OrderHistory> createState() => _OrderHistoryState();
}

class _OrderHistoryState extends State<_OrderHistory> {
  String filter = '';
  int page = 1;
  bool busy = false;
  String? error;
  bool get seller => widget.shopName != null;
  String get path => seller ? 'mi-tienda/pedidos' : 'pedidos';
  late Future<Json> result = _load();

  Future<Json> _load() => widget.session.authorized(
    'GET',
    '$path?pagina=$page${filter.isEmpty ? '' : '&estado=$filter'}',
  );

  void _go(int next, {String? state}) => setState(() {
    page = next;
    filter = state ?? filter;
    error = null;
    result = _load();
  });

  Future<void> _change(Json order, {required bool deliver}) async {
    final action = deliver ? 'Marcar como entregado' : 'Cancelar pedido';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text(
          deliver
              ? 'Confirma que entregaste el pedido ${order['codigo']}.'
              : 'Se cancelará el pedido ${order['codigo']} y se liberarán las unidades reservadas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.session.authorized(
        'POST',
        '$path/${order['id']}/${deliver ? 'entregado' : 'cancelar'}',
      );
      if (!mounted) return;
      widget.onChanged?.call();
      _go(1);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        error = failure.message;
        result = _load();
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PageBody(
      width: 600,
      children: [
        TitleBlock(
          seller ? 'Pedidos de mi tienda' : 'Mis pedidos',
          subtitle: widget.shopName,
        ),
        if (seller) ...[
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final entry in _filters.entries)
                ChoiceChip(
                  label: Text(entry.value),
                  labelStyle: entry.key == 'vencido' && filter == entry.key
                      ? const TextStyle(color: Colors.white)
                      : null,
                  selectedColor: entry.key == 'vencido'
                      ? const Color(0xFF52385E)
                      : null,
                  showCheckmark: false,
                  selected: filter == entry.key,
                  onSelected: busy ? null : (_) => _go(1, state: entry.key),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (error != null) _Error(error!),
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
                  const Text('No pudimos cargar los pedidos.'),
                  OutlinedButton(
                    onPressed: () => _go(page),
                    child: const Text('Reintentar'),
                  ),
                ],
              );
            }
            final orders = (snapshot.data?['data'] as List? ?? []).cast<Json>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (orders.isEmpty)
                  Text(
                    seller
                        ? filter.isEmpty
                              ? 'Aún no te llegan pedidos. Comparte el enlace de tu tienda para que te encuentren.'
                              : 'No tienes pedidos con este estado.'
                        : 'Todavía no has hecho pedidos. Busca en la Vitrina lo que necesitas.',
                  ),
                for (final order in orders)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _OrderSummary(
                      key: ValueKey(order['id']),
                      order: order,
                      seller: seller,
                      history: true,
                      onCancel: !busy && order['estado'] == 'pendiente'
                          ? () => _change(order, deliver: false)
                          : null,
                      onDeliver:
                          seller && !busy && order['estado'] == 'pendiente'
                          ? () => _change(order, deliver: true)
                          : null,
                    ),
                  ),
                Wrap(
                  spacing: 8,
                  children: [
                    if (page > 1)
                      OutlinedButton(
                        onPressed: busy ? null : () => _go(page - 1),
                        child: const Text('Anterior'),
                      ),
                    if (snapshot.data?['next_page_url'] != null)
                      OutlinedButton(
                        onPressed: busy ? null : () => _go(page + 1),
                        child: const Text('Siguiente'),
                      ),
                  ],
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
  const _OrderSummary({
    super.key,
    required this.order,
    this.seller = false,
    this.history = false,
    this.onCancel,
    this.onDeliver,
  });
  final Json order;
  final bool seller, history;
  final VoidCallback? onCancel, onDeliver;
  @override
  Widget build(BuildContext context) {
    final local = _ecuador(DateTime.parse('${order['hora_entrega']}Z'));
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (seller)
          Text(
            order['comprador'] as String? ?? 'Usuario eliminado',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        for (final item in (order['items'] as List? ?? const []).cast<Json>())
          Text('${item['cantidad']} × ${item['nombre_producto']}'),
        if (order['nota'] case final String note when note.isNotEmpty)
          Text('Nota: $note'),
        if (history && order['estado'] == 'pendiente') ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (seller)
                FilledButton(
                  onPressed: onDeliver,
                  child: const Text('Entregado'),
                ),
              OutlinedButton(
                onPressed: onCancel,
                child: Text(seller ? 'Cancelar' : 'Cancelar pedido'),
              ),
            ],
          ),
        ],
        if (seller && order['estado'] == 'vencido')
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Venció 24 h después de la hora de entrega.'),
          ),
      ],
    );
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order['codigo'] as String,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          _OrderBadge(state: order['estado']),
          const SizedBox(height: 8),
          if (!seller)
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
          if (seller) ...[const Divider(), details],
          if (history && !seller)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              title: const Text('Ver detalle'),
              children: [SizedBox(width: double.infinity, child: details)],
            ),
        ],
      ),
    );
  }
}

class _OrderBadge extends StatelessWidget {
  const _OrderBadge({required this.state});
  final String state;

  @override
  Widget build(BuildContext context) {
    final (label, tone, tint) = switch (state) {
      'pendiente' => ('Pendiente', orange, const Color(0xFFFFECD9)),
      'entregado' => ('Entregado', greenInk, const Color(0xFFE8F3E7)),
      'cancelado' => ('Cancelado', muted, const Color(0xFFEEECE8)),
      _ => ('Vencido', const Color(0xFF52385E), const Color(0xFFEADDF3)),
    };
    return KampusBadge(label: label, background: tint, foreground: tone);
  }
}

class _CartShop extends StatelessWidget {
  const _CartShop({required this.api, required this.shop});
  final CatalogApi api;
  final CatalogEntry shop;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: SizedBox(
          width: 48,
          child: CatalogImage(
            api: api,
            url: shop.image,
            label: shop.name,
            height: 48,
            shop: true,
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Text(shop.name, style: Theme.of(context).textTheme.titleMedium),
      ),
    ],
  );
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
