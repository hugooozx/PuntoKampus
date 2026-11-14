import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../ui/common.dart';
import 'checkout.dart';
import 'account.dart';

class CatalogPage extends StatefulWidget {
  const CatalogPage({super.key});
  @override
  State<CatalogPage> createState() => _CatalogPageState();
}

class _CatalogPageState extends State<CatalogPage> {
  final search = TextEditingController();
  String category = '';
  bool products = false;
  int limit = 20;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final shops = store.findShops(search.text, category);
    final foundProducts = store.findProducts(search.text, category);
    final count = products ? foundProducts.length : shops.length;
    return PageBody(
      children: [
        TitleBlock(
          'Vitrina',
          subtitle: 'Descubre lo que se crea en tu campus.',
          trailing: store.cartCount > 0
              ? Badge(
                  label: Text('${store.cartCount}'),
                  child: IconButton(
                    tooltip: 'Ver carrito',
                    icon: const Icon(Icons.shopping_bag_outlined),
                    onPressed: () => open(context, const CartPage()),
                  ),
                )
              : null,
        ),
        const Text(
          'Buscar tiendas o productos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: search,
          onChanged: (_) => setState(() => limit = 20),
          decoration: InputDecoration(
            hintText: '¿Qué estás buscando?',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Limpiar búsqueda',
                    onPressed: () => setState(search.clear),
                    icon: const Icon(Icons.close),
                  ),
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['', ...categories]
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(c.isEmpty ? 'Todas' : c),
                      labelStyle: TextStyle(
                        color: category == c ? Colors.white : ink,
                        fontWeight: category == c
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                      selected: category == c,
                      showCheckmark: false,
                      onSelected: (_) => setState(() {
                        category = c;
                        limit = 20;
                      }),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 420,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: false, label: Text('Tiendas')),
                ButtonSegment(value: true, label: Text('Productos')),
              ],
              selected: {products},
              onSelectionChanged: (value) => setState(() {
                products = value.first;
                limit = 20;
              }),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '$count ${products
              ? count == 1
                    ? 'producto'
                    : 'productos'
              : count == 1
              ? 'tienda'
              : 'tiendas'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 14),
        if (count == 0)
          EmptyState(
            search.text.trim().isNotEmpty
                ? 'No encontramos nada con «${search.text.trim()}».'
                : 'Todavía no hay ${products ? 'productos' : 'tiendas'} en esta categoría.',
            'Prueba con otra palabra o revisa las categorías.',
            action: FilledButton(
              onPressed: () => setState(() {
                search.clear();
                category = '';
              }),
              child: const Text('Limpiar búsqueda'),
            ),
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = products
                  ? (constraints.maxWidth >= 850
                        ? 3
                        : constraints.maxWidth >= 320
                        ? 2
                        : 1)
                  : constraints.maxWidth >= 700
                  ? 2
                  : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 16) / columns;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: products
                    ? foundProducts
                          .take(limit)
                          .map(
                            (p) =>
                                SizedBox(width: width, child: ProductCard(p)),
                          )
                          .toList()
                    : shops
                          .take(limit)
                          .map(
                            (s) => SizedBox(width: width, child: ShopCard(s)),
                          )
                          .toList(),
              );
            },
          ),
        if (count > limit)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: OutlinedButton(
              onPressed: () => setState(() => limit += 20),
              child: const Text('Cargar más'),
            ),
          ),
      ],
    );
  }
}

class ShopCard extends StatelessWidget {
  const ShopCard(this.shop, {super.key});
  final Shop shop;
  @override
  Widget build(BuildContext context) => Surface(
    onTap: () => open(context, ShopPage(shop.id)),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductArt(shop.kind),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shop.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Tag(shop.badge, gold: shop.premium),
              const SizedBox(height: 8),
              Text(shop.category, style: const TextStyle(fontSize: 14)),
              if (MediaQuery.sizeOf(context).width >= 1000 &&
                  shop.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    shop.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF555D57),
                    ),
                  ),
                ),
              Fact(Icons.location_on_outlined, shop.point),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 24),
          child: Icon(Icons.chevron_right, size: 22),
        ),
      ],
    ),
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard(this.product, {super.key});
  final Product product;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(10),
    onTap: () => open(context, ProductPage(product.id)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ProductArt(product.kind, expanded: true),
        Padding(
          padding: const EdgeInsets.all(6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                product.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                StoreScope.of(context).shop(product.shopId).name,
                style: const TextStyle(fontSize: 14, color: Color(0xFF555D57)),
              ),
              const SizedBox(height: 8),
              Text(
                money(product.price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Tag(product.available ? 'Disponible' : 'Agotado'),
              const SizedBox(height: 14),
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Ver producto',
                      style: TextStyle(
                        color: orange,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Icon(Icons.arrow_forward, color: orange, size: 18),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class ShopPage extends StatelessWidget {
  const ShopPage(this.id, {super.key});
  final String id;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context), s = StoreScope.of(context).shop(id);
    return PageBody(
      children: [
        TitleBlock(s.name, back: true),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ProductArt(s.kind, size: 72),
                  const SizedBox(width: 20),
                  Tag(s.badge, gold: s.premium),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                s.description,
                style: const TextStyle(fontSize: 17, height: 1.5),
              ),
              Fact(
                Icons.category_outlined,
                [
                  s.category,
                  s.secondary,
                ].where((e) => e.isNotEmpty).join(' · '),
              ),
              Fact(Icons.schedule, s.hours),
              Fact(Icons.location_on_outlined, s.point),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Productos',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 800
                ? 3
                : c.maxWidth >= 320
                ? 2
                : 1;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: store
                  .productsOf(id)
                  .map(
                    (p) => SizedBox(
                      width: (c.maxWidth - 16 * (columns - 1)) / columns,
                      child: ProductCard(p),
                    ),
                  )
                  .toList(),
            );
          },
        ),
        if (store.productsOf(id).isEmpty)
          const EmptyState(
            'Esta tienda aún no tiene productos',
            'Vuelve pronto para conocer lo que ofrece.',
            icon: Icons.storefront,
          ),
        if (s.owner != store.currentUserId)
          Padding(
            padding: const EdgeInsets.only(top: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  if (store.user == null) {
                    open(context, const LoginPage());
                    return;
                  }
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useSafeArea: true,
                    builder: (_) => ReportSheet(s),
                  );
                },
                icon: const Icon(Icons.flag_outlined),
                label: const Text('Reportar tienda'),
              ),
            ),
          ),
      ],
    );
  }
}

class ProductPage extends StatefulWidget {
  const ProductPage(this.id, {super.key});
  final String id;
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context),
        p = StoreScope.of(context).product(widget.id);
    final s = store.shop(p.shopId);
    return PageBody(
      width: 640,
      children: [
        TitleBlock('Producto', back: true),
        ProductArt(p.kind, expanded: true),
        const SizedBox(height: 24),
        Text(
          p.name,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => open(context, ShopPage(s.id)),
            child: Text(s.name),
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: Tag(p.available ? 'Disponible' : 'Agotado'),
        ),
        const SizedBox(height: 16),
        Text(
          money(p.price),
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(p.description, style: const TextStyle(fontSize: 17, height: 1.5)),
        const SizedBox(height: 24),
        if (s.owner == store.currentUserId)
          const Text('Este producto pertenece a tu tienda.')
        else ...[
          const Label('Cantidad'),
          Quantity(quantity, (v) => setState(() => quantity = v)),
          const SizedBox(height: 8),
          const Text(
            'Máximo 20 unidades por producto.',
            style: TextStyle(fontSize: 13),
          ),
          TotalRow(p.price * quantity, label: 'Subtotal'),
          FilledButton(
            onPressed: p.available
                ? () async {
                    var replace = false;
                    if (store.needsCartReplacement(p)) {
                      replace = await confirm(
                        context,
                        '¿Empezar un carrito nuevo?',
                        'Tu carrito tiene productos de ${store.cartShop!.name}. ¿Quieres vaciarlo y empezar uno nuevo?',
                        'Vaciar y continuar',
                      );
                      if (!replace || !context.mounted) return;
                    }
                    handle(context, () {
                      store.addToCart(p, quantity, replace: replace);
                      open(context, const CartPage());
                    });
                  }
                : null,
            child: Text(p.available ? 'Agregar al carrito' : 'Agotado'),
          ),
        ],
      ],
    );
  }
}

class ReportSheet extends StatefulWidget {
  const ReportSheet(this.shop, {super.key});
  final Shop shop;
  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  final detail = TextEditingController();
  String? reason;
  String? error;
  @override
  void dispose() {
    detail.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * .9,
        maxWidth: 600,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reportar tienda',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
            Text(widget.shop.name),
            const Label('Motivo'),
            RadioGroup<String>(
              groupValue: reason,
              onChanged: (value) => setState(() => reason = value),
              child: Column(
                children:
                    [
                          'Producto prohibido',
                          'No entregó el pedido',
                          'Información falsa',
                          'Trato inadecuado',
                          'Otro',
                        ]
                        .map(
                          (value) => RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            title: Text(value),
                            value: value,
                          ),
                        )
                        .toList(),
              ),
            ),
            Label(
              reason == 'Otro'
                  ? 'Cuéntanos qué pasó (obligatorio)'
                  : 'Detalle (opcional)',
            ),
            TextField(controller: detail, maxLines: 3, maxLength: 300),
            const SizedBox(height: 12),
            const Text(
              'Este reporte se guardará solo en esta demostración; no se enviará a un equipo real.',
              style: TextStyle(fontSize: 13),
            ),
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                try {
                  StoreScope.of(context)
                      .submitReport(widget.shop, reason ?? '', detail.text);
                  Navigator.pop(context);
                  toast(
                    context,
                    'Reporte de prueba guardado en este dispositivo.',
                  );
                } on StateError catch (e) {
                  setState(() => error = e.message);
                }
              },
              child: const Text('Enviar reporte'),
            ),
          ],
        ),
      ),
    ),
  );
}
