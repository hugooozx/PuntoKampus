import 'package:material_ui/material_ui.dart';

import '../api/catalog_api.dart';
import 'kampus_design.dart';

class EntryGrid extends StatelessWidget {
  const EntryGrid({
    super.key,
    required this.entries,
    required this.api,
    required this.onOpen,
    this.categories = const [],
    this.points = const [],
  });
  final List<CatalogEntry> entries;
  final CatalogApi api;
  final ValueChanged<CatalogEntry> onOpen;
  final List<CatalogOption> categories, points;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final products = entries.firstOrNull?.isProduct == true;
      final textScale = MediaQuery.textScalerOf(context).scale(16) / 16;
      final detailed = constraints.maxWidth >= 740;
      final columns = products
          ? (textScale > 1.3
                ? (constraints.maxWidth / (260 * textScale)).floor().clamp(1, 4)
                : constraints.maxWidth >= 960
                ? 4
                : constraints.maxWidth >= 680
                ? 3
                : 2)
          : (detailed && textScale <= 1.3 ? 2 : 1);
      final gap = detailed ? 20.0 : 12.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final entry in entries)
            SizedBox(
              width: width,
              child: Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                elevation: 1,
                color: Colors.white,
                surfaceTintColor: Colors.transparent,
                shadowColor: ink.withValues(alpha: 0.12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: line),
                ),
                child: Semantics(
                  button: true,
                  child: InkWell(
                    onTap: () => onOpen(entry),
                    hoverColor: peach.withValues(alpha: 0.36),
                    focusColor: peach.withValues(alpha: 0.65),
                    child: entry.isProduct
                        ? _ProductCard(entry: entry, api: api)
                        : _ShopCard(
                            entry: entry,
                            api: api,
                            detailed: detailed,
                            category: categories
                                .where((c) => c.id == entry.category)
                                .firstOrNull
                                ?.name,
                            point: points
                                .where(
                                  (p) => p.id == entry.json['punto_entrega_id'],
                                )
                                .firstOrNull
                                ?.name,
                          ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.entry,
    required this.api,
    required this.detailed,
    this.category,
    this.point,
  });
  final CatalogEntry entry;
  final CatalogApi api;
  final bool detailed;
  final String? category, point;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.all(detailed ? 20 : 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: detailed ? 96 : 68,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: CatalogImage(
                  api: api,
                  url: entry.image,
                  label: entry.name,
                  height: detailed ? 96 : 72,
                  shop: true,
                  fallback: _ShopCategoryTile(category: category),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: detailed ? 22 : 18,
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  KampusBadge.plan(premium: entry.premium),
                  if (category != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: _MetaLine(
                        icon: detailed ? Icons.sell_outlined : null,
                        text: category!,
                      ),
                    ),
                  if (detailed)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              MediaQuery.textScalerOf(context).scale(14) * 2.8,
                        ),
                        child: Text(
                          entry.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: muted,
                          ),
                        ),
                      ),
                    ),
                  if (point != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _MetaLine(
                        icon: Icons.location_on_outlined,
                        text: point!,
                      ),
                    ),
                ],
              ),
            ),
            if (!detailed)
              const Padding(
                padding: EdgeInsets.only(top: 20, left: 4),
                child: Icon(Icons.chevron_right, size: 20),
              ),
          ],
        ),
        if (detailed) ...[
          const Divider(height: 28),
          const Align(
            alignment: Alignment.centerRight,
            child: _CardAction('Ver tienda'),
          ),
        ],
      ],
    ),
  );
}

class _ShopCategoryTile extends StatelessWidget {
  const _ShopCategoryTile({this.category});
  final String? category;

  @override
  Widget build(BuildContext context) {
    final name = category?.toLowerCase() ?? '';
    final (icon, tint, tone) = switch (name) {
      _ when name.contains('postre') || name.contains('dulce') => (
        Icons.bakery_dining_outlined,
        peach,
        orange,
      ),
      _ when name.contains('bebida') => (
        Icons.local_cafe_outlined,
        const Color(0xFFFBECD3),
        goldInk,
      ),
      _ when name.contains('comida') => (
        Icons.lunch_dining_outlined,
        const Color(0xFFF8ECD4),
        goldInk,
      ),
      _ when name.contains('papeler') || name.contains('útiles') => (
        Icons.auto_stories_outlined,
        softGreen,
        greenInk,
      ),
      _ when name.contains('tecnolog') => (
        Icons.devices_outlined,
        const Color(0xFFE6EEF6),
        const Color(0xFF315577),
      ),
      _ when name.contains('ropa') || name.contains('accesorio') => (
        Icons.checkroom_outlined,
        const Color(0xFFF2EAF7),
        const Color(0xFF634677),
      ),
      _ => (Icons.storefront_outlined, peach, orange),
    };
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tint, Color.lerp(tint, tone, 0.12)!],
          ),
          border: Border.all(color: tone.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(child: Icon(icon, color: tone, size: 36)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.entry, required this.api});
  final CatalogEntry entry;
  final CatalogApi api;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: AspectRatio(
            aspectRatio: 1.3,
            child: CatalogImage(api: api, url: entry.image, label: entry.name),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.textScalerOf(context).scale(18) * 1.15 * 2,
                ),
                child: Text(
                  entry.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (entry.json['tienda'] as Json)['nombre'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, height: 1.4, color: muted),
              ),
              const SizedBox(height: 4),
              Text(
                '\$${entry.price}',
                style: const TextStyle(
                  fontSize: 24,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 6),
              KampusBadge.availability(available: entry.available),
              const SizedBox(height: 6),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: _CardAction('Ver producto'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _CardAction extends StatelessWidget {
  const _CardAction(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: orange,
          ),
        ),
      ),
      const SizedBox(width: 4),
      const Icon(Icons.chevron_right, color: orange, size: 20),
    ],
  );
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({this.icon, required this.text});
  final IconData? icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
      Expanded(
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, height: 1.35),
        ),
      ),
    ],
  );
}

class CatalogImage extends StatelessWidget {
  const CatalogImage({
    super.key,
    required this.api,
    this.url,
    required this.label,
    this.height = 200,
    this.shop = false,
    this.fallback,
  });
  final CatalogApi api;
  final String? url;
  final String label;
  final double height;
  final bool shop;
  final Widget? fallback;
  @override
  Widget build(BuildContext context) {
    Widget placeholder() => fallback != null
        ? SizedBox(height: height, width: double.infinity, child: fallback)
        : Container(
            height: height,
            color: shop ? peach : softGray,
            alignment: Alignment.center,
            child: Icon(
              shop ? Icons.storefront_outlined : Icons.image_outlined,
              color: shop ? orange : muted,
              size: shop ? 32 : 40,
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
            frameBuilder: (_, child, frame, synchronouslyLoaded) =>
                synchronouslyLoaded || frame != null ? child : placeholder(),
            errorBuilder: (_, _, _) => placeholder(),
          );
  }
}
