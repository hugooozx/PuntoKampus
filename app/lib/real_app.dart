import 'package:material_ui/material_ui.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api/account_api.dart';
import 'api/account_session.dart';
import 'api/catalog_api.dart';
import 'api/catalog_controller.dart';
import 'ui/kampus_design.dart';
import 'ui/catalog_cards.dart';
import 'pages/institutional_account.dart';
import 'pages/my_shop.dart';
import 'pages/purchase.dart';
import 'pages/report_shop.dart';

class PuntoKampusRealApp extends StatefulWidget {
  const PuntoKampusRealApp({super.key, required this.api, this.storage});
  final CatalogApi api;
  final FlutterSecureStorage? storage;
  @override
  State<PuntoKampusRealApp> createState() => _RealAppState();
}

class _RealAppState extends State<PuntoKampusRealApp> {
  final cart = PurchaseCart();
  late final session = AccountSession(
    AccountApi(widget.api),
    storage: widget.storage,
  );
  @override
  void initState() {
    super.initState();
    session.restore();
  }

  @override
  void dispose() {
    cart.dispose();
    session.dispose();
    widget.api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PuntoKampus',
    debugShowCheckedModeBanner: false,
    locale: const Locale('es'),
    supportedLocales: const [Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: kampusTheme(),
    builder: (context, child) =>
        PurchaseScope(session: session, cart: cart, child: child!),
    onGenerateRoute: (settings) {
      final path = (Uri.tryParse(settings.name ?? '/')?.path ?? '/')
          .replaceFirst(RegExp(r'/$'), '');
      final match = RegExp(r'^/t/([a-z0-9-]+)$').firstMatch(path);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => switch (path) {
          '/privacidad' => PrivacyPage(api: session.api),
          '/borrar-cuenta' => DeleteAccountPage(
            session: session,
            publicPage: true,
          ),
          _ =>
            match == null
                ? RealShell(api: widget.api, session: session)
                : ShopScreen(api: widget.api, slug: match.group(1)!),
        },
      );
    },
  );
}

const destinations = [
  (label: 'Vitrina', icon: Icons.storefront_outlined),
  (label: 'Mis pedidos', icon: Icons.shopping_bag_outlined),
  (label: 'Mi tienda', icon: Icons.store_mall_directory_outlined),
  (label: 'Cuenta', icon: Icons.person_outline),
];

void openEntry(BuildContext context, CatalogApi api, CatalogEntry entry) {
  if (entry.isProduct) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ShopScreen(api: api, slug: entry.slug, productId: entry.id),
      ),
    );
  } else {
    Navigator.pushNamed(context, '/t/${entry.slug}');
  }
}

class RealShell extends StatefulWidget {
  const RealShell({super.key, required this.api, required this.session});
  final CatalogApi api;
  final AccountSession session;
  @override
  State<RealShell> createState() => _RealShellState();
}

class _RealShellState extends State<RealShell> {
  late final controller = CatalogController(widget.api);
  int tab = 0;
  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) => buildShell(context),
  );

  Widget buildShell(BuildContext context) {
    final session = widget.session;
    final signedIn = session.signedIn;
    final selected = signedIn ? tab : 0;
    void enter() {
      if (session.restoring) return;
      setState(() => tab = 0);
      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => InstitutionalLogin(session: session),
        ),
      );
    }

    if (session.needsProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Acceso UTB')),
        body: SafeArea(child: ProfileForm(session: session)),
      );
    }
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final body = IndexedStack(
      index: selected,
      children: [
        RealCatalog(controller: controller),
        BuyerOrders(
          key: ValueKey(session.user?['id']),
          visible: selected == 1,
          onChanged: () => controller.refresh(),
        ),
        if (signedIn)
          MyShopPage(
            key: ValueKey(session.user!['id']),
            session: session,
            visible: selected == 2,
            onChanged: controller.refresh,
          ),
        if (signedIn)
          ProfileForm(
            key: ValueKey((
              session.user!['id'],
              session.user!['mostrar_whatsapp'] != null,
            )),
            session: session,
          ),
      ],
    );
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (desktop)
              Container(
                width: 280,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: line)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            child: Brand(),
                          ),
                          const SizedBox(height: 36),
                          for (
                            var i = 0;
                            i < (signedIn ? destinations.length : 1);
                            i++
                          )
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Semantics(
                                selected: tab == i,
                                child: TextButton(
                                  onPressed: () => setState(() => tab = i),
                                  style: TextButton.styleFrom(
                                    foregroundColor: tab == i ? orange : ink,
                                    backgroundColor: tab == i
                                        ? peach
                                        : Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(destinations[i].icon, size: 28),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Text(
                                          destinations[i].label,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: tab == i
                                                ? FontWeight.w700
                                                : FontWeight.w400,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          if (!signedIn)
                            FilledButton(
                              onPressed: session.restoring ? null : enter,
                              child: const Text('Entrar'),
                            ),
                        ],
                      ),
                    ),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        'Tu campus,\ntus emprendimientos.',
                        style: TextStyle(color: muted, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  if (!desktop)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                      child: Row(
                        children: [
                          const Expanded(child: Brand()),
                          if (!signedIn)
                            TextButton(
                              onPressed: session.restoring ? null : enter,
                              child: const Text('Entrar'),
                            ),
                        ],
                      ),
                    ),
                  if (session.restoreError case final String error)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        children: [
                          Text(error),
                          TextButton(
                            onPressed: session.restore,
                            child: const Text('Reintentar sesión'),
                          ),
                        ],
                      ),
                    ),
                  Expanded(child: body),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: desktop || !signedIn
          ? null
          : DecoratedBox(
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: line)),
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < destinations.length; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Semantics(
                              selected: tab == i,
                              child: TextButton(
                                onPressed: () => setState(() => tab = i),
                                style: TextButton.styleFrom(
                                  backgroundColor: tab == i
                                      ? peach
                                      : Colors.white,
                                  foregroundColor: tab == i ? orange : ink,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 2,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(destinations[i].icon, size: 26),
                                    const SizedBox(height: 4),
                                    Text(
                                      destinations[i].label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.25,
                                        fontWeight: tab == i
                                            ? FontWeight.w700
                                            : FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class RealCatalog extends StatefulWidget {
  const RealCatalog({super.key, required this.controller});
  final CatalogController controller;
  @override
  State<RealCatalog> createState() => _RealCatalogState();
}

class _RealCatalogState extends State<RealCatalog> {
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.controller,
    builder: (context, _) {
      final c = widget.controller;
      final noun = c.products ? 'productos' : 'tiendas';
      final desktop = MediaQuery.sizeOf(context).width >= 1000;
      return RefreshIndicator(
        onRefresh: c.refresh,
        child: SingleChildScrollView(
          key: const PageStorageKey('vitrina'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            desktop ? 40 : 16,
            desktop ? 40 : 12,
            desktop ? 40 : 16,
            32,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (desktop)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text(
                        'EMPRENDIMIENTOS DE LA UTB',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Vitrina',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontSize: desktop ? 44 : 32),
                        ),
                      ),
                      const CartButton(),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Descubre lo que se crea en tu campus.',
                    style: TextStyle(fontSize: desktop ? 18 : 16),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Buscar tiendas o productos',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: search,
                    onChanged: (text) => c.filter(text: text),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: '¿Qué estás buscando?',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: ink,
                        size: 26,
                      ),
                      suffixIcon: search.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Limpiar búsqueda',
                              onPressed: () {
                                search.clear();
                                c.filter(text: '');
                              },
                              icon: const Icon(Icons.close),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in [null, ...c.categories])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Semantics(
                              selected: c.category == option?.id,
                              child: OutlinedButton(
                                onPressed: () => c.filter(
                                  categoryId: option?.id,
                                  changeCategory: true,
                                ),
                                style: OutlinedButton.styleFrom(
                                  backgroundColor: c.category == option?.id
                                      ? orange
                                      : Colors.white,
                                  foregroundColor: c.category == option?.id
                                      ? Colors.white
                                      : ink,
                                  side: BorderSide(
                                    color: c.category == option?.id
                                        ? orange
                                        : line,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  textStyle: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 15,
                                    fontWeight: c.category == option?.id
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                  ),
                                ),
                                child: Text(option?.name ?? 'Todas'),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  CatalogSwitch(
                    products: c.products,
                    onChanged: (value) => c.filter(showProducts: value),
                  ),
                  const SizedBox(height: 16),
                  if (c.loading)
                    const _CatalogSkeleton()
                  else if (c.error != null)
                    StatusPanel(
                      icon: Icons.wifi_off_outlined,
                      title: 'No pudimos cargar la vitrina',
                      message: c.error!,
                      action: FilledButton(
                        onPressed: c.refresh,
                        child: const Text('Reintentar'),
                      ),
                    )
                  else if (c.entries.isEmpty)
                    StatusPanel(
                      icon: c.filtered
                          ? Icons.search
                          : Icons.storefront_outlined,
                      title: c.filtered
                          ? (c.term.trim().isEmpty
                                ? 'No encontramos resultados'
                                : 'No encontramos nada con «${c.term.trim()}».')
                          : 'La vitrina está por estrenarse',
                      message: c.filtered
                          ? 'Prueba con otra palabra o revisa las categorías.'
                          : 'Todavía no hay $noun. Aquí descubrirás los emprendimientos de la comunidad UTB.',
                      action: c.filtered
                          ? FilledButton(
                              onPressed: () {
                                search.clear();
                                c.term = '';
                                c.filter(
                                  categoryId: null,
                                  changeCategory: true,
                                );
                              },
                              child: const Text('Limpiar búsqueda'),
                            )
                          : OutlinedButton.icon(
                              onPressed: c.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                            ),
                    )
                  else ...[
                    Text(
                      '${c.total} ${c.total == 1 ? (c.products ? 'producto' : 'tienda') : noun}',
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    EntryGrid(
                      entries: c.entries,
                      api: c.api,
                      categories: c.categories,
                      points: c.points,
                      onOpen: (entry) => openEntry(context, c.api, entry),
                    ),
                    if (c.moreError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Text(c.moreError!, semanticsLabel: c.moreError),
                      ),
                    if (c.hasMore)
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: Center(
                          child: c.loadingMore
                              ? const CircularProgressIndicator(
                                  semanticsLabel: 'Cargando más resultados',
                                )
                              : OutlinedButton(
                                  onPressed: () => c.load(more: true),
                                  child: Text(
                                    c.moreError == null
                                        ? 'Ver más'
                                        : 'Reintentar más resultados',
                                  ),
                                ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Cargando la vitrina',
    liveRegion: true,
    child: ExcludeSemantics(
      child: Column(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: softGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 16, width: 160, color: softGray),
                        const SizedBox(height: 12),
                        Container(height: 12, width: 100, color: softGray),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

class ShopScreen extends StatefulWidget {
  const ShopScreen({
    super.key,
    required this.api,
    required this.slug,
    this.productId,
  });
  final CatalogApi api;
  final String slug;
  final int? productId;
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopFact extends StatelessWidget {
  const _ShopFact({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 22),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({required this.api, required this.product});
  final CatalogApi api;
  final CatalogEntry product;
  @override
  State<_ProductGallery> createState() => _ProductGalleryState();
}

class _ProductGalleryState extends State<_ProductGallery> {
  final pages = PageController();
  int current = 0;
  @override
  void dispose() {
    pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final photos = (widget.product.json['fotos'] as List? ?? [])
        .map((p) => p['url'] as String)
        .toList();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: 1.25,
            child: photos.isEmpty
                ? CatalogImage(api: widget.api, label: widget.product.name)
                : PageView.builder(
                    controller: pages,
                    itemCount: photos.length,
                    onPageChanged: (index) => setState(() => current = index),
                    itemBuilder: (context, index) => CatalogImage(
                      api: widget.api,
                      url: photos[index],
                      label:
                          '${widget.product.name}, foto ${index + 1} de ${photos.length}',
                    ),
                  ),
          ),
        ),
        if (photos.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < photos.length; i++)
                IconButton(
                  tooltip: 'Ver foto ${i + 1}',
                  onPressed: () => pages.jumpToPage(i),
                  icon: Icon(
                    current == i ? Icons.circle : Icons.circle_outlined,
                    size: 10,
                    color: current == i ? orange : muted,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _ShopScreenState extends State<ShopScreen> {
  late Future<CatalogEntry> future = load();

  Future<CatalogEntry> load() => widget.api.shop(widget.slug);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.productId == null ? 'Tienda' : 'Producto'),
      actions: const [CartButton()],
    ),
    body: FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PageBody(
            children: [
              StatusPanel(
                icon: Icons.hourglass_empty,
                title: 'Cargando',
                message: 'Un momento, por favor.',
                busy: true,
              ),
            ],
          );
        }
        if (snapshot.hasError) {
          return PageBody(
            children: [
              StatusPanel(
                icon: Icons.storefront_outlined,
                title: snapshot.error is ApiFailure
                    ? (snapshot.error as ApiFailure).message
                    : 'No pudimos cargar la tienda.',
                message: 'Puedes volver a la vitrina o intentarlo de nuevo.',
                action: FilledButton(
                  onPressed: () => setState(() => future = load()),
                  child: const Text('Reintentar'),
                ),
              ),
            ],
          );
        }
        final shop = snapshot.data!;
        final products = (shop.json['productos'] as List? ?? [])
            .map(
              (p) => CatalogEntry({
                ...p as Json,
                'tienda': shop.json,
              }, isProduct: true),
            )
            .toList();
        if (widget.productId != null) {
          final product = products
              .where((p) => p.id == widget.productId)
              .firstOrNull;
          if (product == null) {
            return const PageBody(
              children: [
                StatusPanel(
                  icon: Icons.inventory_2_outlined,
                  title: 'Este producto ya no está disponible',
                  message: 'Vuelve a la tienda para ver otros productos.',
                ),
              ],
            );
          }
          return PageBody(
            width: 1040,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final info = Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        product.name,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              Navigator.pushNamed(context, '/t/${shop.slug}'),
                          icon: const Icon(Icons.storefront_outlined),
                          label: Text(shop.name),
                          style: TextButton.styleFrom(
                            foregroundColor: ink,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: KampusBadge.availability(
                          available: product.available,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '\$${product.price}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(product.description),
                      const SizedBox(height: 24),
                      ProductPurchase(shop: shop, product: product),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/t/${shop.slug}'),
                        child: const Text('Ver tienda'),
                      ),
                    ],
                  );
                  final gallery = _ProductGallery(
                    api: widget.api,
                    product: product,
                  );
                  return constraints.maxWidth >= 800
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: gallery),
                            const SizedBox(width: 40),
                            Expanded(child: info),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [gallery, const SizedBox(height: 20), info],
                        );
                },
              ),
            ],
          );
        }
        final categoryNames =
            (shop.json['categorias_nombres'] as List? ?? const []).join(' · ');
        return PageBody(
          children: [
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: line),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (shop.premium && shop.json['portada_url'] != null)
                    CatalogImage(
                      api: widget.api,
                      url: shop.json['portada_url'] as String,
                      label: 'Portada de ${shop.name}',
                    ),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 80,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CatalogImage(
                                  api: widget.api,
                                  url: shop.image,
                                  label: shop.name,
                                  height: 80,
                                  shop: true,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop.name,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      height: 1.15,
                                      letterSpacing: -0.6,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  KampusBadge.plan(premium: shop.premium),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(shop.description),
                        if (categoryNames.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ShopFact(
                            icon: Icons.sell_outlined,
                            text: categoryNames,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _ShopFact(
                          icon: Icons.location_on_outlined,
                          text:
                              'Entrega: ${shop.json['punto_entrega_nombre'] ?? 'Punto habitual no disponible'}',
                        ),
                        if (shop.json['horario']
                            case final String schedule) ...[
                          const SizedBox(height: 12),
                          _ShopFact(
                            icon: Icons.schedule,
                            text: 'Horario: $schedule',
                          ),
                        ],
                        if (shop.json['whatsapp'] case final String phone) ...[
                          const SizedBox(height: 12),
                          SelectableText('WhatsApp: +$phone'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Productos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.6,
              ),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const StatusPanel(
                icon: Icons.inventory_2_outlined,
                title: 'Aún no hay productos',
                message: 'Esta tienda todavía no ha publicado productos.',
              )
            else
              EntryGrid(
                entries: products,
                api: widget.api,
                onOpen: (entry) => openEntry(context, widget.api, entry),
              ),
            const SizedBox(height: 28),
            const Divider(),
            ReportShopButton(
              shop: shop,
              session: PurchaseScope.of(context).session,
            ),
          ],
        );
      },
    ),
  );
}
