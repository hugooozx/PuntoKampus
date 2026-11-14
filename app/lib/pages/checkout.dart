import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../domain/store.dart';
import '../ui/common.dart';
import 'account.dart';
import 'catalog.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shop = store.cartShop;
    return PageBody(
      width: 620,
      children: [
        const TitleBlock('Carrito', back: true),
        if (shop == null)
          EmptyState(
            'Tu carrito está vacío',
            'Elige un producto en la vitrina.',
            icon: Icons.shopping_bag_outlined,
            action: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Volver'),
            ),
          )
        else ...[
          Text(shop.name, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          for (final entry in store.cart.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CartLine(
                product: store.product(entry.key),
                count: entry.value,
              ),
            ),
          TotalRow(store.cartTotal),
          const Text('Cada pedido corresponde a una sola tienda.'),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => open(
              context,
              store.user == null ? const LoginPage() : const CheckoutPage(),
            ),
            child: Text(
              store.user == null ? 'Entrar para continuar' : 'Continuar',
            ),
          ),
          TextButton(
            onPressed: () => open(context, ShopPage(shop.id)),
            child: const Text('Seguir viendo la tienda'),
          ),
        ],
      ],
    );
  }
}

class _CartLine extends StatelessWidget {
  const _CartLine({required this.product, required this.count});

  final Product product;
  final int count;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return Surface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProductArt(product.kind, size: 54),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    Text('${money(product.price)} cada uno'),
                  ],
                ),
              ),
              if (!product.available || product.deleted) const Tag('Agotado'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Quantity(count, (value) => store.setQuantity(product.id, value)),
              Text(
                money(product.price * count),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextButton(
                onPressed: () => store.removeFromCart(product.id),
                child: const Text('Quitar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final note = TextEditingController();
  late String point =
      StoreScope.of(context).cartShop?.point ?? deliveryPoints.first;
  String payment = 'Efectivo';
  DateTime delivery = DateTime.now().add(const Duration(hours: 1));
  String? error;
  bool sending = false;

  @override
  void dispose() {
    note.dispose();
    super.dispose();
  }

  Future<void> chooseDay() async {
    final now = DateTime.now();
    final chosen = await showDatePicker(
      context: context,
      initialDate: delivery.isBefore(now) ? now : delivery,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateUtils.dateOnly(now.add(const Duration(days: 7))),
    );
    if (chosen != null && mounted) {
      setState(
        () => delivery = DateTime(
          chosen.year,
          chosen.month,
          chosen.day,
          delivery.hour,
          delivery.minute,
        ),
      );
    }
  }

  Future<void> chooseTime() async {
    final chosen = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(delivery),
    );
    if (chosen != null && mounted) {
      setState(
        () => delivery = DateTime(
          delivery.year,
          delivery.month,
          delivery.day,
          chosen.hour,
          chosen.minute,
        ),
      );
    }
  }

  Future<void> send(DemoStore store) async {
    setState(() {
      sending = true;
      error = null;
    });
    try {
      final purchase = store.checkout(point, delivery, payment, note.text);
      await store.saved;
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => _PurchaseSent(purchase)),
      );
    } on StateError catch (failure) {
      if (mounted) {
        setState(() {
          sending = false;
          error = failure.message;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    return PageBody(
      width: 620,
      children: [
        TitleBlock(
          'Entrega y pago',
          back: true,
          subtitle: store.cartShop?.name,
        ),
        const Label('Punto de entrega'),
        DropdownButtonFormField<String>(
          initialValue: point,
          isExpanded: true,
          items: [
            for (final value in deliveryPoints)
              DropdownMenuItem(value: value, child: Text(value)),
          ],
          onChanged: (value) {
            if (value != null) point = value;
          },
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Label('Día'),
                  OutlinedButton(
                    onPressed: chooseDay,
                    child: Text(day(delivery)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Label('Hora'),
                  OutlinedButton(
                    onPressed: chooseTime,
                    child: Text(clock(delivery)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Elige una hora dentro de los próximos 7 días, con al menos 30 minutos de margen.',
        ),
        if (DemoStore.validateDelivery(delivery, DateTime.now())
            case final message?)
          Text(
            message,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const Label('Forma de pago'),
        Surface(
          padding: EdgeInsets.zero,
          child: RadioGroup<String>(
            groupValue: payment,
            onChanged: (value) {
              if (value != null) setState(() => payment = value);
            },
            child: const Column(
              children: [
                RadioListTile(value: 'Efectivo', title: Text('Efectivo')),
                RadioListTile(
                  value: 'Transferencia',
                  title: Text('Transferencia'),
                ),
                RadioListTile(value: 'Deuna', title: Text('Deuna')),
              ],
            ),
          ),
        ),
        const Label('Nota (opcional)'),
        TextField(controller: note, maxLines: 2, maxLength: 200),
        TotalRow(store.cartTotal),
        const Text(
          'El pago se coordina directamente con la tienda. En esta demo podrás copiar el mensaje para WhatsApp.',
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: sending || store.cart.isEmpty ? null : () => send(store),
          child: Text(sending ? 'Guardando…' : 'Enviar pedido'),
        ),
      ],
    );
  }
}

class _PurchaseSent extends StatelessWidget {
  const _PurchaseSent(this.purchase);

  final Purchase purchase;

  @override
  Widget build(BuildContext context) => PageBody(
    width: 620,
    children: [
      const TitleBlock('Pedido registrado', back: true),
      const Icon(
        Icons.check_circle_outline,
        size: 48,
        color: Color(0xFF285D2D),
      ),
      const SizedBox(height: 16),
      Text(
        purchase.code,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      Center(child: Tag(purchase.status)),
      const SizedBox(height: 20),
      PurchaseCard(purchase),
      const SizedBox(height: 16),
      FilledButton.icon(
        icon: const Icon(Icons.message_outlined),
        label: const Text('Ver mensaje para WhatsApp'),
        onPressed: () => showDialog<void>(
          context: context,
          builder: (dialog) => AlertDialog(
            title: const Text('Mensaje de prueba'),
            content: SingleChildScrollView(
              child: SelectableText(purchase.message),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: const Text('Cerrar'),
              ),
              TextButton(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: purchase.message),
                  );
                  if (dialog.mounted) Navigator.pop(dialog);
                  if (context.mounted) toast(context, 'Mensaje copiado.');
                },
                child: const Text('Copiar mensaje'),
              ),
            ],
          ),
        ),
      ),
      OutlinedButton(
        onPressed: () => open(context, const OrdersPage(back: true)),
        child: const Text('Ver mis pedidos'),
      ),
    ],
  );
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, this.back = false});

  final bool back;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final list = store.orders.where(
      (order) => order.buyerId == store.currentUserId,
    );
    return PageBody(
      width: 720,
      children: [
        TitleBlock(
          'Mis pedidos',
          subtitle: 'Revisa tus pedidos y su estado.',
          back: back,
        ),
        if (list.isEmpty)
          const EmptyState(
            'Todavía no has hecho pedidos',
            'Busca en la vitrina lo que necesitas.',
            icon: Icons.shopping_bag_outlined,
          )
        else
          for (final order in list)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PurchaseCard(order),
            ),
      ],
    );
  }
}

class PurchaseCard extends StatelessWidget {
  const PurchaseCard(this.order, {super.key, this.seller = false});

  final Purchase order;
  final bool seller;

  Future<void> change(BuildContext context, String status) async {
    final store = StoreScope.of(context);
    final cancel = status == 'cancelado';
    final yes = await confirm(
      context,
      cancel
          ? '¿Cancelar el pedido ${order.code}?'
          : '¿Marcar el pedido como entregado?',
      'La otra persona verá el cambio de estado.',
      cancel ? 'Cancelar pedido' : 'Marcar entregado',
    );
    if (yes && context.mounted) {
      handle(context, () => store.changeOrder(order, status));
    }
  }

  @override
  Widget build(BuildContext context) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [Tag(order.status), Text(order.code)],
        ),
        const SizedBox(height: 12),
        Text(
          seller ? order.buyerName : order.shopName,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        for (final item in order.items) Text('${item.quantity} × ${item.name}'),
        Fact(Icons.location_on_outlined, order.point),
        Fact(Icons.event_outlined, dateTime(order.delivery)),
        Fact(Icons.payments_outlined, order.payment),
        if (order.note.isNotEmpty) Fact(Icons.chat_bubble_outline, order.note),
        TotalRow(order.total),
        if (order.status == 'pendiente')
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              if (seller)
                FilledButton(
                  onPressed: () => change(context, 'entregado'),
                  child: const Text('Entregado'),
                ),
              OutlinedButton(
                onPressed: () => change(context, 'cancelado'),
                child: Text(seller ? 'Cancelar' : 'Cancelar pedido'),
              ),
            ],
          ),
      ],
    ),
  );
}
