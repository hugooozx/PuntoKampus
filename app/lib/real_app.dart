import 'package:material_ui/material_ui.dart';

import 'api/catalog_api.dart';
import 'api/catalog_controller.dart';
import 'ui/common.dart'
    show Brand, PageBody, TitleBlock, orange, ink, canvas, line;

class PuntoKampusRealApp extends StatefulWidget {
  const PuntoKampusRealApp({super.key, required this.api});
  final CatalogApi api;
  @override
  State<PuntoKampusRealApp> createState() => _RealAppState();
}

class _RealAppState extends State<PuntoKampusRealApp> {
  @override
  void dispose() {
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
    theme: ThemeData(
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      colorScheme: ColorScheme.fromSeed(seedColor: orange)
          .copyWith(primary: orange, surface: canvas, onSurface: ink),
      scaffoldBackgroundColor: canvas,
      textTheme: const TextTheme(
        bodyMedium: TextStyle(fontSize: 16, height: 1.5),
        headlineMedium: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
      ),
    ),
    onGenerateRoute: (settings) {
      final path = Uri.tryParse(settings.name ?? '/')?.path ?? '/';
      final match = RegExp(r'^/t/([a-z0-9-]+)$').firstMatch(path);
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => match == null
            ? RealShell(api: widget.api)
            : ShopScreen(api: widget.api, slug: match.group(1)!),
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

class RealShell extends StatefulWidget {
  const RealShell({super.key, required this.api});
  final CatalogApi api;
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
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final body = IndexedStack(
      index: tab,
      children: [
        RealCatalog(controller: controller),
        for (final destination in destinations.skip(1))
          PageBody(
            children: [
              TitleBlock(destination.label),
              StatusPanel(
                icon: destination.icon,
                title: 'Próximamente',
                message: 'Esta sección estará disponible cuando se habilite el acceso con tu correo institucional.',
                action: TextButton(
                  onPressed: () => setState(() => tab = 0),
                  child: const Text('Explorar la vitrina'),
                ),
              ),
            ],
          ),
      ],
    );
    return Scaffold(
      appBar: desktop
          ? null
          : AppBar(
              title: const Brand(small: true),
              toolbarHeight: 72,
              backgroundColor: Colors.white,
            ),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (desktop)
              Container(
                width: 240,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: line)),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Brand(),
                    const SizedBox(height: 36),
                    for (var i = 0; i < destinations.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: tab == i
                              ? const Color(0xFFFFEBDD)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: ListTile(
                            selected: tab == i,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            leading: Icon(destinations[i].icon),
                            title: Text(destinations[i].label),
                            onTap: () => setState(() => tab = i),
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Text(
                      'Tu campus,\ntus emprendimientos.',
                      style: TextStyle(color: Color(0xFF555D57), height: 1.5),
                    ),
                  ],
                ),
              ),
            Expanded(child: body),
          ],
        ),
      ),
      bottomNavigationBar: desktop
          ? null
          : NavigationBar(
              selectedIndex: tab,
              onDestinationSelected: (value) => setState(() => tab = value),
              destinations: [
                for (final d in destinations)
                  NavigationDestination(icon: Icon(d.icon), label: d.label),
              ],
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
      return RefreshIndicator(
        onRefresh: c.refresh,
        child: SingleChildScrollView(
          key: const PageStorageKey('vitrina'),
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(
            MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const TitleBlock(
                    'Vitrina',
                    subtitle: 'Descubre lo que se crea en tu campus.',
                  ),
                  TextField(
                    controller: search,
                    onChanged: (text) => c.filter(text: text),
                    decoration: InputDecoration(
                      labelText: 'Buscar tiendas o productos',
                      hintText: '¿Qué estás buscando?',
                      prefixIcon: const Icon(Icons.search),
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
                  const SizedBox(height: 20),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in [null, ...c.categories])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(option?.name ?? 'Todas'),
                              selected: c.category == option?.id,
                              showCheckmark: false,
                              selectedColor: orange,
                              labelStyle: TextStyle(
                                color: c.category == option?.id
                                    ? Colors.white
                                    : ink,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              onSelected: (_) => c.filter(
                                categoryId: option?.id,
                                changeCategory: true,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        minimumSize: WidgetStatePropertyAll(Size(120, 48)),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Tiendas'),
                          icon: Icon(Icons.storefront_outlined),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Productos'),
                          icon: Icon(Icons.local_mall_outlined),
                        ),
                      ],
                      selected: {c.products},
                      onSelectionChanged: (values) =>
                          c.filter(showProducts: values.first),
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (c.loading)
                    const StatusPanel(
                      icon: Icons.hourglass_empty,
                      title: 'Cargando la vitrina',
                      message: 'Un momento, por favor.',
                      busy: true,
                    )
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
                          ? Icons.search_off
                          : Icons.storefront_outlined,
                      title: c.filtered
                          ? 'No encontramos resultados'
                          : 'La vitrina está por estrenarse',
                      message: c.filtered
                          ? 'No encontramos nada${c.term.trim().isEmpty ? '' : ' con «${c.term.trim()}»'}. Prueba con otra palabra o revisa las categorías.'
                          : 'Todavía no hay $noun publicados. Aquí descubrirás los emprendimientos de la comunidad UTB.',
                      action: c.filtered
                          ? TextButton(
                              onPressed: () {
                                search.clear();
                                c.term = '';
                                c.filter(
                                  categoryId: null,
                                  changeCategory: true,
                                );
                              },
                              child: const Text('Limpiar filtros'),
                            )
                          : TextButton.icon(
                              onPressed: c.refresh,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Actualizar'),
                            ),
                    )
                  else ...[
                    Text(
                      '${c.total} $noun',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    EntryGrid(
                      entries: c.entries,
                      api: c.api,
                      categories: c.categories,
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

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.busy = false,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  final bool busy;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: line),
    ),
    child: Column(
      children: [
        if (busy)
          const CircularProgressIndicator(semanticsLabel: 'Cargando')
        else
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Color(0xFFFFEBDD),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: orange, size: 34),
          ),
        const SizedBox(height: 20),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
        ),
        const SizedBox(height: 10),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(message, textAlign: TextAlign.center),
        ),
        if (action != null) ...[const SizedBox(height: 20), action!],
      ],
    ),
  );
}

class EntryGrid extends StatelessWidget {
  const EntryGrid({
    super.key,
    required this.entries,
    required this.api,
    this.categories = const [],
  });
  final List<CatalogEntry> entries;
  final CatalogApi api;
  final List<CatalogOption> categories;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = constraints.maxWidth >= 900
          ? 3
          : constraints.maxWidth >= 620
          ? 2
          : 1;
      final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final entry in entries)
            SizedBox(
              width: width,
              child: Card(
                clipBehavior: Clip.antiAlias,
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: line),
                ),
                child: InkWell(
                  onTap: () {
                    if (entry.isProduct) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopScreen(
                            api: api,
                            slug: entry.slug,
                            productId: entry.id,
                          ),
                        ),
                      );
                    } else {
                      Navigator.pushNamed(context, '/t/${entry.slug}');
                    }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CatalogImage(
                        api: api,
                        url: entry.image,
                        label: entry.name,
                        height: 170,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (entry.isProduct) ...[
                              Text(
                                '\$${entry.price}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: orange,
                                ),
                              ),
                              Text(
                                entry.available ? 'Disponible' : 'Agotado',
                                style: TextStyle(
                                  color: entry.available
                                      ? const Color(0xFF246640)
                                      : const Color(0xFF795222),
                                ),
                              ),
                            ] else ...[
                              Text(
                                entry.premium ? 'Sacó 10' : 'Matriculado',
                                style: const TextStyle(
                                  color: orange,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (categories
                                      .where((c) => c.id == entry.category)
                                      .firstOrNull
                                  case final category?)
                                Text(category.name),
                            ],
                            if (entry.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                entry.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.api,
    this.url,
    required this.label,
    this.height = 200,
  });
  final CatalogApi api;
  final String? url;
  final String label;
  final double height;
  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
      height: height,
      color: const Color(0xFFF2EEE8),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: Color(0xFF756D63),
        size: 40,
        semanticLabel: 'Sin imagen',
      ),
    );
    return url == null || url!.isEmpty
        ? placeholder()
        : Image.network(
            api.imageUrl(url!),
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            semanticLabel: label,
            errorBuilder: (_, _, _) => placeholder(),
          );
  }
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

class _ShopScreenState extends State<ShopScreen> {
  late Future<
    ({
      CatalogEntry shop,
      List<CatalogOption> points,
      List<CatalogOption> categories,
    })
  >
  future = load();

  Future<
    ({
      CatalogEntry shop,
      List<CatalogOption> points,
      List<CatalogOption> categories,
    })
  >
  load() async {
    final results = await Future.wait<Object>([
      widget.api.shop(widget.slug),
      widget.api.options('puntos-entrega'),
      widget.api.options('categorias'),
    ]);
    return (
      shop: results[0] as CatalogEntry,
      points: results[1] as List<CatalogOption>,
      categories: results[2] as List<CatalogOption>,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.productId == null ? 'Tienda' : 'Producto'),
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
        final shop = snapshot.data!.shop;
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
            children: [
              TitleBlock(product.name, subtitle: shop.name),
              CatalogImage(
                api: widget.api,
                url: product.image,
                label: product.name,
                height: 280,
              ),
              if ((product.json['fotos'] as List? ?? []).length > 1)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final photo in (product.json['fotos'] as List).skip(1))
                      SizedBox(
                        width: 120,
                        child: CatalogImage(
                          api: widget.api,
                          url: photo['url'] as String,
                          label: product.name,
                          height: 100,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 24),
              Text(
                '\$${product.price}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              Text(product.available ? 'Disponible' : 'Agotado'),
              const SizedBox(height: 16),
              Text(product.description),
              const SizedBox(height: 24),
              const FilledButton(onPressed: null, child: Text('Pedir')),
              const SizedBox(height: 8),
              const Text('Los pedidos todavía no están habilitados.'),
              TextButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/t/${shop.slug}'),
                child: const Text('Ver tienda'),
              ),
            ],
          );
        }
        return PageBody(
          children: [
            if (shop.image != null)
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 80,
                  child: CatalogImage(
                    api: widget.api,
                    url: shop.image,
                    label: shop.name,
                    height: 80,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TitleBlock(shop.name, subtitle: shop.description),
            Text(
              snapshot.data!.categories
                  .where(
                    (category) => [
                      shop.json['categoria_1_id'],
                      shop.json['categoria_2_id'],
                    ].contains(category.id),
                  )
                  .map((category) => category.name)
                  .join(' · '),
            ),
            Text(
              shop.premium ? 'Sacó 10' : 'Matriculado',
              style: const TextStyle(
                color: orange,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (shop.premium && shop.json['portada_url'] != null) ...[
              const SizedBox(height: 16),
              CatalogImage(
                api: widget.api,
                url: shop.json['portada_url'] as String,
                label: shop.name,
              ),
            ],
            if (shop.json['horario'] case final String schedule)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Horario: $schedule'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Entrega: ${snapshot.data!.points.where((point) => point.id == shop.json['punto_entrega_id']).firstOrNull?.name ?? 'Punto habitual no disponible'}',
              ),
            ),
            if (shop.json['whatsapp'] case final String phone)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText('WhatsApp: +$phone'),
              ),
            const SizedBox(height: 28),
            const Text(
              'Productos',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            if (products.isEmpty)
              const StatusPanel(
                icon: Icons.inventory_2_outlined,
                title: 'Aún no hay productos',
                message: 'Esta tienda todavía no ha publicado productos.',
              )
            else
              EntryGrid(entries: products, api: widget.api),
          ],
        );
      },
    ),
  );
}
