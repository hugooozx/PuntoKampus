import 'package:material_ui/material_ui.dart';

import '../api/catalog_api.dart';
import '../ui/catalog_cards.dart';
import '../ui/kampus_design.dart';
import 'purchase.dart';

class ProductDetail extends StatelessWidget {
  const ProductDetail({
    super.key,
    required this.api,
    required this.shop,
    required this.product,
    required this.onOpenShop,
  });
  final CatalogApi api;
  final CatalogEntry shop, product;
  final VoidCallback onOpenShop;

  @override
  Widget build(BuildContext context) => PageBody(
    width: 1090,
    children: [
      LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 800;
          final gallery = _ProductGallery(
            api: api,
            product: product,
            wide: wide,
          );
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontSize: wide ? 42 : 31,
                    letterSpacing: wide ? -1.5 : -0.8,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Tooltip(
                  message: 'Ver tienda',
                  child: TextButton(
                    onPressed: onOpenShop,
                    style: TextButton.styleFrom(
                      foregroundColor: ink,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_outlined,
                          color: orange,
                          size: 21,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            shop.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.chevron_right,
                          color: orange,
                          size: 19,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '\$${product.price}',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: wide ? 38 : 32,
                      letterSpacing: -0.8,
                    ),
                  ),
                  KampusBadge.availability(available: product.available),
                ],
              ),
              if (product.description.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  product.description,
                  style: const TextStyle(color: muted, height: 1.5),
                ),
              ],
              const SizedBox(height: 20),
              ProductPurchase(shop: shop, product: product),
            ],
          );
          return wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 54, child: gallery),
                    const SizedBox(width: 42),
                    Expanded(flex: 46, child: info),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [gallery, const SizedBox(height: 16), info],
                );
        },
      ),
    ],
  );
}

class _ProductGallery extends StatefulWidget {
  const _ProductGallery({
    required this.api,
    required this.product,
    required this.wide,
  });
  final CatalogApi api;
  final CatalogEntry product;
  final bool wide;

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
    final photos = (widget.product.json['fotos'] as List? ?? const [])
        .map((photo) => photo['url'] as String)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
            aspectRatio: widget.wide ? 1.18 : 1.48,
            child: photos.isEmpty
                ? CatalogImage(api: widget.api, label: widget.product.name)
                : PageView.builder(
                    controller: pages,
                    itemCount: photos.length,
                    onPageChanged: (index) => setState(() => current = index),
                    itemBuilder: (_, index) => CatalogImage(
                      api: widget.api,
                      url: photos[index],
                      label:
                          '${widget.product.name}, foto ${index + 1} de ${photos.length}',
                    ),
                  ),
          ),
        ),
        if (photos.length > 1)
          if (widget.wide)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 10,
                children: [
                  for (var i = 0; i < photos.length; i++)
                    Semantics(
                      label: 'Ver foto ${i + 1}',
                      selected: current == i,
                      child: OutlinedButton(
                        onPressed: () => pages.jumpToPage(i),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(3),
                          side: BorderSide(
                            color: current == i ? orange : line,
                            width: current == i ? 2 : 1,
                          ),
                        ),
                        child: ExcludeSemantics(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: SizedBox(
                              width: 64,
                              child: CatalogImage(
                                api: widget.api,
                                url: photos[i],
                                label: widget.product.name,
                                height: 58,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < photos.length; i++)
                  Semantics(
                    selected: current == i,
                    child: IconButton(
                      tooltip: 'Ver foto ${i + 1}',
                      onPressed: () => pages.jumpToPage(i),
                      icon: Icon(
                        current == i ? Icons.circle : Icons.circle_outlined,
                        size: 10,
                        color: current == i ? orange : muted,
                      ),
                    ),
                  ),
              ],
            ),
      ],
    );
  }
}
