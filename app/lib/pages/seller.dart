import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../domain/models.dart';
import '../ui/common.dart';
import 'catalog.dart';
import 'checkout.dart';

class MyShopPage extends StatelessWidget {
  const MyShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shop = store.ownShop;
    return PageBody(
      width: 720,
      children: [
        const TitleBlock('Mi tienda'),
        if (shop == null)
          EmptyState(
            'Crea tu tienda',
            'Publica lo que vendes y elige dónde entregar en el campus.',
            icon: Icons.storefront_outlined,
            action: FilledButton(
              onPressed: () => open(context, const ShopForm()),
              child: const Text('Crear mi tienda'),
            ),
          )
        else ...[
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    ProductArt(shop.kind, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        shop.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Tag(shop.badge, gold: shop.premium),
                ),
                Fact(Icons.category_outlined, shop.category),
                Fact(Icons.location_on_outlined, shop.point),
                Fact(Icons.schedule, shop.hours),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: [
                    TextButton(
                      onPressed: () => open(context, ShopPage(shop.id)),
                      child: const Text('Vista previa'),
                    ),
                    TextButton(
                      onPressed: () => open(context, ShopForm(shop: shop)),
                      child: const Text('Editar tienda'),
                    ),
                  ],
                ),
                FilledButton.icon(
                  icon: const Icon(Icons.link),
                  label: const Text('Copiar enlace de prueba'),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: '${Uri.base.origin}/#/t/${shop.slug}',
                      ),
                    );
                    if (context.mounted) {
                      toast(context, 'Enlace local copiado.');
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Surface(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.inventory_2_outlined),
                  title: const Text('Mis productos'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(context, _SellerProducts(shop)),
                ),
                const Divider(color: line, height: 1),
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Pedidos de mi tienda'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(context, _SellerOrders(shop)),
                ),
                const Divider(color: line, height: 1),
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Premium'),
                  subtitle: Text(
                    shop.premium
                        ? 'Plan actual: Premium'
                        : 'Plan actual: Gratis',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(context, const _PremiumPage()),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class ShopForm extends StatefulWidget {
  const ShopForm({super.key, this.shop});

  final Shop? shop;

  @override
  State<ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<ShopForm> {
  final form = GlobalKey<FormState>();
  final fields = <String, TextEditingController>{};
  late String category = widget.shop?.category ?? categories.first;
  late String secondary = widget.shop?.secondary ?? '';
  late String point = widget.shop?.point ?? deliveryPoints.first;
  late bool sellerStep =
      widget.shop == null &&
      StoreScope.of(context).user?.seller.isEmpty == true;
  late bool showPhone = StoreScope.of(context).user?.showPhone ?? false;

  TextEditingController field(String key, [String initial = '']) =>
      fields.putIfAbsent(key, () => TextEditingController(text: initial));

  @override
  void dispose() {
    for (final field in fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Widget input(
    String title,
    String key, {
    String initial = '',
    int maxLength = 100,
    TextInputType? keyboard,
    int lines = 1,
    int min = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: field(key, initial),
      maxLength: maxLength,
      maxLines: lines,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: title, counterText: ''),
      validator: (value) {
        final text = value?.trim() ?? '';
        if (text.length < min) return 'Completa este campo.';
        if (key == 'whatsapp' && !RegExp(r'^09[0-9]{8}$').hasMatch(text)) {
          return 'Usa el formato 09XXXXXXXX.';
        }
        if (key == 'semestre' && !RegExp(r'^(10|[1-9])$').hasMatch(text)) {
          return 'Elige un semestre del 1 al 10.';
        }
        return null;
      },
    ),
  );

  Widget select(
    String title,
    String value,
    List<String> options,
    ValueChanged<String> change, {
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: title),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option,
            child: Text(option.isEmpty ? 'Ninguna' : option),
          ),
      ],
      onChanged: (value) {
        if (value != null) change(value);
      },
      validator: validator,
    ),
  );

  void save() {
    if (!form.currentState!.validate()) return;
    if (sellerStep) {
      setState(() => sellerStep = false);
      return;
    }
    final store = StoreScope.of(context);
    final user = store.user;
    if (user == null) return;
    final name = fields['nombre']!.text.trim();
    final candidate = Shop(
      id: 'shop-${DateTime.now().microsecondsSinceEpoch}',
      owner: user.id,
      name: name,
      description: fields['descripcion']!.text.trim(),
      category: category,
      secondary: secondary,
      point: point,
      hours: fields['horario']!.text.trim(),
    );
    if (candidate.slug.isEmpty ||
        store.shops.any(
          (shop) => shop != widget.shop && shop.slug == candidate.slug,
        )) {
      toast(context, 'Elige otro nombre para tu tienda.');
      return;
    }
    if (fields.containsKey('codigo')) {
      user.seller = {
        for (final key in ['codigo', 'facultad', 'carrera', 'semestre'])
          key: fields[key]!.text.trim(),
        'whatsapp': '593${fields['whatsapp']!.text.trim().substring(1)}',
      };
      user.showPhone = showPhone;
    }
    final previous = widget.shop;
    if (previous == null) {
      if (store.ownShop != null) {
        toast(context, 'Ya tienes una tienda.');
        return;
      }
      store.shops.add(candidate);
    } else {
      previous
        ..name = candidate.name
        ..description = candidate.description
        ..category = category
        ..secondary = secondary
        ..point = point
        ..hours = candidate.hours;
    }
    store.changed();
    Navigator.pop(context);
    toast(
      context,
      previous == null
          ? 'Tu tienda de prueba ya está en la vitrina.'
          : 'Cambios guardados.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.shop;
    return Form(
      key: form,
      child: PageBody(
        width: 620,
        children: [
          TitleBlock(
            shop == null ? 'Crear mi tienda' : 'Editar tienda',
            back: true,
            subtitle: shop == null
                ? (sellerStep ? '1 de 2 · Tus datos' : '2 de 2 · Tu tienda')
                : null,
          ),
          if (sellerStep) ...[
            input('Código de estudiante', 'codigo'),
            input('Facultad', 'facultad'),
            input('Carrera', 'carrera'),
            input(
              'Semestre',
              'semestre',
              keyboard: TextInputType.number,
              maxLength: 2,
            ),
            input(
              'WhatsApp de prueba',
              'whatsapp',
              keyboard: TextInputType.phone,
              maxLength: 10,
            ),
            SwitchListTile(
              title: const Text('Mostrar mi WhatsApp en mi tienda'),
              value: showPhone,
              onChanged: (value) => setState(() => showPhone = value),
            ),
          ] else ...[
            if (shop == null && fields.containsKey('codigo'))
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => sellerStep = true),
                  child: const Text('Volver a tus datos'),
                ),
              ),
            input(
              'Nombre de la tienda',
              'nombre',
              initial: shop?.name ?? '',
              maxLength: 40,
              min: 3,
            ),
            input(
              'Descripción',
              'descripcion',
              initial: shop?.description ?? '',
              maxLength: 300,
              lines: 3,
            ),
            select(
              'Categoría principal',
              category,
              categories,
              (value) => setState(() => category = value),
            ),
            select(
              'Segunda categoría (opcional)',
              secondary,
              ['', ...categories],
              (value) => setState(() => secondary = value),
              validator: (value) =>
                  value == category ? 'Elige una categoría distinta.' : null,
            ),
            input('Horario', 'horario', initial: shop?.hours ?? ''),
            select(
              'Punto de entrega habitual',
              point,
              deliveryPoints,
              (value) => setState(() => point = value),
            ),
            if (shop?.premium != true)
              const Fact(Icons.lock_outline, 'Portada disponible con Premium.'),
            if (shop == null)
              const Fact(
                Icons.info_outline,
                'Tu tienda se publicará con el plan gratis.',
              ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: save,
            child: Text(
              sellerStep
                  ? 'Continuar'
                  : shop == null
                  ? 'Crear mi tienda'
                  : 'Guardar cambios',
            ),
          ),
        ],
      ),
    );
  }
}

class _SellerOrders extends StatefulWidget {
  const _SellerOrders(this.shop);

  final Shop shop;

  @override
  State<_SellerOrders> createState() => _SellerOrdersState();
}

class _SellerOrdersState extends State<_SellerOrders> {
  String status = '';
  static const states = {
    '': 'Todos',
    'pendiente': 'Pendientes',
    'entregado': 'Entregados',
    'cancelado': 'Cancelados',
    'vencido': 'Vencidos',
  };

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final orders = store.orders.where(
      (order) =>
          order.shopId == widget.shop.id &&
          (status.isEmpty || order.status == status),
    );
    return PageBody(
      width: 720,
      children: [
        TitleBlock(
          'Pedidos de mi tienda',
          back: true,
          subtitle: widget.shop.name,
        ),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            for (final entry in states.entries)
              ChoiceChip(
                label: Text(entry.value),
                selected: status == entry.key,
                showCheckmark: false,
                onSelected: (_) => setState(() => status = entry.key),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (orders.isEmpty)
          const EmptyState(
            'No hay pedidos en este estado',
            'Aquí aparecerán los pedidos de tu tienda.',
            icon: Icons.receipt_long_outlined,
          )
        else
          for (final order in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: PurchaseCard(order, seller: true),
            ),
      ],
    );
  }
}

class _SellerProducts extends StatelessWidget {
  const _SellerProducts(this.shop);

  final Shop shop;

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final products = store.productsOf(shop.id);
    return PageBody(
      width: 720,
      children: [
        TitleBlock('Mis productos', back: true, subtitle: shop.name),
        FilledButton.icon(
          onPressed: () => open(context, _ProductForm(shop)),
          icon: const Icon(Icons.add),
          label: const Text('Agregar producto'),
        ),
        const SizedBox(height: 16),
        if (products.isEmpty)
          const EmptyState(
            'Tu tienda no tiene productos',
            'Agrega el primero para empezar.',
            icon: Icons.inventory_2_outlined,
          ),
        for (final product in products)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  Text(money(product.price)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(product.available ? 'Disponible' : 'Agotado'),
                    value: product.available,
                    onChanged: (available) {
                      product.available = available;
                      store.changed();
                    },
                  ),
                  TextButton(
                    onPressed: () =>
                        open(context, _ProductForm(shop, product: product)),
                    child: const Text('Editar producto'),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProductForm extends StatefulWidget {
  const _ProductForm(this.shop, {this.product});

  final Shop shop;
  final Product? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.product?.name);
  late final description = TextEditingController(
    text: widget.product?.description,
  );
  late final price = TextEditingController(
    text: widget.product == null
        ? ''
        : (widget.product!.price / 100).toStringAsFixed(2),
  );
  late bool available = widget.product?.available ?? true;

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    price.dispose();
    super.dispose();
  }

  int? get cents {
    final value = price.text.trim().replaceAll(',', '.');
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(value)) return null;
    final dollars = double.tryParse(value);
    if (dollars == null || dollars <= 0 || dollars > 500) return null;
    return (dollars * 100).round();
  }

  @override
  Widget build(BuildContext context) => Form(
    key: form,
    child: PageBody(
      width: 620,
      children: [
        TitleBlock(
          widget.product == null ? 'Agregar producto' : 'Editar producto',
          back: true,
        ),
        TextFormField(
          controller: name,
          maxLength: 60,
          decoration: const InputDecoration(labelText: 'Nombre'),
          validator: (value) => (value?.trim().length ?? 0) < 3
              ? 'Escribe al menos 3 letras.'
              : null,
        ),
        TextFormField(
          controller: price,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Precio en dólares'),
          validator: (_) =>
              cents == null ? 'Escribe un precio de 0.01 a 500.00.' : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: description,
          maxLength: 300,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        SwitchListTile(
          title: const Text('Disponible'),
          value: available,
          onChanged: (value) => setState(() => available = value),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () {
            if (!form.currentState!.validate()) return;
            final store = StoreScope.of(context);
            final product =
                widget.product ??
                Product(
                  id: 'product-${DateTime.now().microsecondsSinceEpoch}',
                  shopId: widget.shop.id,
                  name: name.text.trim(),
                  description: description.text.trim(),
                  price: cents!,
                  kind: widget.shop.kind,
                );
            if (widget.product == null) store.products.add(product);
            product
              ..name = name.text.trim()
              ..description = description.text.trim()
              ..price = cents!
              ..available = available;
            store.changed();
            Navigator.pop(context);
            toast(context, 'Producto guardado.');
          },
          child: const Text('Guardar producto'),
        ),
      ],
    ),
  );
}

class _PremiumPage extends StatefulWidget {
  const _PremiumPage();

  @override
  State<_PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<_PremiumPage> {
  final number = TextEditingController();
  final amount = TextEditingController();
  bool attached = false;

  @override
  void dispose() {
    number.dispose();
    amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shop = store.ownShop;
    if (shop == null) return const MyShopPage();
    final request = store.currentPremiumRequest;
    return PageBody(
      width: 620,
      children: [
        TitleBlock('Premium', back: true, subtitle: shop.name),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Plan actual: ${shop.premium ? 'Premium' : 'Gratis'}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              Tag(shop.badge, gold: shop.premium),
              const Fact(
                Icons.workspace_premium_outlined,
                'Insignia «Sacó 10»',
              ),
              const Fact(Icons.image_outlined, 'Portada propia'),
              const Fact(
                Icons.receipt_long_outlined,
                'Ambos planes admiten pedidos sin límite.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (request != null)
          Surface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag('En revisión'),
                const SizedBox(height: 10),
                Text(
                  'Comprobante ${request.number} · ${money(request.amount)}',
                ),
                const Text('Solicitud guardada en la demo.'),
              ],
            ),
          )
        else if (!shop.premium) ...[
          const Text(
            'Precio de ejemplo: \$3.00 por periodo. Usa un comprobante ficticio para probar el formulario.',
          ),
          const Label('Foto del comprobante'),
          OutlinedButton.icon(
            icon: Icon(attached ? Icons.check : Icons.attach_file),
            onPressed: () => setState(() => attached = !attached),
            label: Text(
              attached
                  ? 'comprobante-demo.jpg · Quitar'
                  : 'Adjuntar comprobante de prueba',
            ),
          ),
          const Label('Número del comprobante'),
          TextField(controller: number, maxLength: 60),
          const Label('Monto pagado'),
          TextField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => handle(context, () {
              final value = double.tryParse(amount.text.replaceAll(',', '.'));
              if (value == null ||
                  !value.isFinite ||
                  value <= 0 ||
                  value > 100000) {
                throw StateError('Escribe un monto válido.');
              }
              store.requestPremium(
                number.text,
                (value * 100).round(),
                attached ? 'comprobante-demo.jpg' : '',
              );
              toast(context, 'Recibimos tu comprobante de prueba.');
            }),
            child: const Text('Enviar comprobante'),
          ),
        ],
      ],
    );
  }
}
