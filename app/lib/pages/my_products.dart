import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/catalog_cards.dart';
import '../ui/kampus_design.dart';

const _productsPath = 'mi-tienda/productos';
const _photoLimit = 2 * 1024 * 1024;

Future<Uint8List> _fitUpload(Uint8List bytes) async {
  if (bytes.length <= _photoLimit) return bytes;

  // Algunos selectores conservan PNG y su parámetro de calidad no reduce el peso.
  // Un PNG de 700 × 700 en RGBA cabe incluso con poca compresión.
  final codec = await ui.instantiateImageCodecWithSize(
    await ui.ImmutableBuffer.fromUint8List(bytes),
    getTargetSize: (width, height) {
      final longSide = width > height ? width : height;
      final scale = longSide > 700 ? 700 / longSide : 1.0;
      return ui.TargetImageSize(
        width: (width * scale).round().clamp(1, 700),
        height: (height * scale).round().clamp(1, 700),
      );
    },
  );
  try {
    final frame = await codec.getNextFrame();
    try {
      final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (png != null && png.lengthInBytes <= _photoLimit) {
        return png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
      }
    } finally {
      frame.image.dispose();
    }
  } finally {
    codec.dispose();
  }
  throw const ApiFailure(
    'No pudimos reducir la foto a 2 MB. Elige otra imagen.',
  );
}

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({
    super.key,
    required this.session,
    required this.shopName,
    required this.onChanged,
  });
  final AccountSession session;
  final String shopName;
  final VoidCallback onChanged;

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  late Future<List<Json>> products = _load();

  Future<List<Json>> _load() async {
    final result = await widget.session.authorized('GET', _productsPath);
    return (result['data'] as List).cast<Json>();
  }

  Future<void> _openForm([Json? product]) async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => _ProductForm(
          session: widget.session,
          shopName: widget.shopName,
          product: product,
        ),
      ),
    );
    if (!mounted || result == null) return;
    widget.onChanged();
    setState(() => products = _load());
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Mi tienda')),
    body: SafeArea(
      child: PageBody(
        width: 600,
        children: [
          TitleBlock('Mis productos', subtitle: widget.shopName),
          FutureBuilder<List<Json>>(
            future: products,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(
                  semanticsLabel: 'Cargando productos',
                );
              }
              if (snapshot.hasError) {
                final failure = snapshot.error;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      failure is ApiFailure
                          ? failure.message
                          : 'No pudimos cargar tus productos.',
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      onPressed: () => setState(() => products = _load()),
                      child: const Text('Reintentar'),
                    ),
                  ],
                );
              }
              final items = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: _openForm,
                    icon: const Icon(Icons.add),
                    label: const Text('Nuevo producto'),
                  ),
                  const SizedBox(height: 20),
                  if (items.isEmpty)
                    const Text(
                      'Aún no tienes productos. Publica el primero para mostrarlo en la Vitrina.',
                    ),
                  for (final item in items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ProductRow(
                        item: item,
                        api: widget.session.api.catalog,
                        onTap: () => _openForm(item),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.item,
    required this.api,
    required this.onTap,
  });
  final Json item;
  final CatalogApi api;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final photos = (item['fotos'] as List).cast<Json>();
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 68,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CatalogImage(
                    api: api,
                    url: photos.firstOrNull?['url'] as String?,
                    label: item['nombre'] as String,
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
                      item['nombre'] as String,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '\$${item['precio']}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        KampusBadge.availability(
                          available: item['disponible'] == true,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, semanticLabel: 'Editar producto'),
            ],
          ),
        ),
      ),
    );
  }
}

class _Photo {
  const _Photo.saved(this.id, this.url) : bytes = null;
  const _Photo.newPhoto(this.bytes) : id = null, url = null;
  final int? id;
  final String? url;
  final Uint8List? bytes;
}

class _ProductForm extends StatefulWidget {
  const _ProductForm({
    required this.session,
    required this.shopName,
    this.product,
  });
  final AccountSession session;
  final String shopName;
  final Json? product;

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(
    text: widget.product?['nombre'] as String?,
  );
  late final price = TextEditingController(
    text: widget.product?['precio'] as String?,
  );
  late final description = TextEditingController(
    text: widget.product?['descripcion'] as String?,
  );
  late final initialPhotos = (widget.product?['fotos'] as List? ?? [])
      .cast<Json>();
  late final photos = [
    for (final row in initialPhotos)
      _Photo.saved(row['id'] as int, row['url'] as String),
  ];
  late bool available = widget.product?['disponible'] as bool? ?? true;
  bool saving = false;
  bool picking = false;
  String? error;

  bool get editing => widget.product != null;
  bool get busy => saving || picking;
  String get normalizedPrice => price.text.trim().replaceAll(',', '.');
  String get path =>
      editing ? '$_productsPath/${widget.product!['id']}' : _productsPath;

  @override
  void dispose() {
    name.dispose();
    price.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (busy || photos.length >= 3) return;
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 84,
        requestFullMetadata: false,
      );
      if (file == null || !mounted) return;
      if (await file.length() > 24 * 1024 * 1024) {
        throw const ApiFailure('Elige una foto de hasta 24 MB para reducirla.');
      }
      final bytes = await _fitUpload(await file.readAsBytes());
      if (mounted) setState(() => photos.add(_Photo.newPhoto(bytes)));
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } on Exception {
      if (mounted) setState(() => error = 'No pudimos abrir esa imagen.');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _save() async {
    if (busy || !form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final kept = photos.map((photo) => photo.id).whereType<int>().toSet();
    final removed = initialPhotos
        .map((photo) => photo['id'] as int)
        .where((id) => !kept.contains(id))
        .toList();
    await _submit(
      () => widget.session.authorized(
        editing ? 'PUT' : 'POST',
        path,
        data: {
          'nombre': name.text.trim(),
          'descripcion': description.text.trim(),
          'precio': normalizedPrice,
          'disponible': available,
          if (removed.isNotEmpty) 'fotos_eliminar': removed,
        },
        photos: photos
            .map((photo) => photo.bytes)
            .whereType<Uint8List>()
            .toList(),
      ),
      editing ? 'Cambios guardados.' : 'Producto publicado.',
    );
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Borrar ${widget.product!['nombre']}?'),
        content: const Text('Ya no aparecerá en tu tienda ni en la Vitrina.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Borrar producto'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || busy) return;
    await _submit(
      () => widget.session.authorized('DELETE', path),
      'Producto retirado.',
    );
  }

  Future<void> _submit(Future<Json> Function() request, String message) async {
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await request();
      if (mounted) Navigator.pop(context, message);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(title: const Text('Mis productos')),
      body: SafeArea(
        child: PageBody(
          width: 530,
          children: [
            TitleBlock(
              editing ? 'Editar producto' : 'Producto nuevo',
              subtitle: widget.shopName,
            ),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Fotos del producto',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      for (var i = 0; i < 3; i++) ...[
                        if (i != 0) const SizedBox(width: 8),
                        Expanded(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _photoSlot(i),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${photos.length} de 3 fotos',
                    style: const TextStyle(color: muted),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: name,
                    enabled: !saving,
                    maxLength: 60,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                    validator: (value) =>
                        (value?.trim().characters.length ?? 0) < 3
                        ? 'Escribe al menos 3 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: price,
                    enabled: !saving,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      TextInputFormatter.withFunction(
                        (previous, next) =>
                            next.composing.isValid &&
                                    !next.composing.isCollapsed ||
                                RegExp(r'^\d{0,3}(?:[.,]\d{0,2})?$')
                                    .hasMatch(next.text)
                            ? next
                            : previous,
                      ),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Precio (USD)',
                      prefixText: '\$',
                    ),
                    validator: (_) {
                      final number = double.tryParse(normalizedPrice);
                      return RegExp(r'^\d+(?:\.\d{1,2})?$')
                                  .hasMatch(normalizedPrice) &&
                              number != null &&
                              number > 0 &&
                              number <= 500
                          ? null
                          : 'Escribe un precio entre \$0.01 y \$500.00.';
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: description,
                    enabled: !saving,
                    maxLines: 3,
                    maxLength: 300,
                    decoration: const InputDecoration(
                      labelText: 'Descripción (opcional)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: line),
                    ),
                    child: SwitchListTile(
                      value: available,
                      title: const Text('Disponible'),
                      subtitle: Text(
                        available
                            ? 'Si lo desactivas, se mostrará como agotado.'
                            : 'Se muestra como agotado en la Vitrina.',
                      ),
                      onChanged: saving
                          ? null
                          : (value) => setState(() => available = value),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 12),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  FilledButton(
                    onPressed: busy ? null : _save,
                    child: Text(
                      saving
                          ? 'Guardando…'
                          : editing
                          ? 'Guardar cambios'
                          : 'Publicar producto',
                    ),
                  ),
                  if (editing) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      onPressed: busy ? null : _delete,
                      child: const Text('Borrar producto'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _photoSlot(int index) {
    final photo = index < photos.length ? photos[index] : null;
    final label = 'Foto ${index + 1} del producto';
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: line),
      ),
      child: photo == null
          ? Semantics(
              button: true,
              child: InkWell(
                onTap: busy ? null : _addPhoto,
                child: Tooltip(
                  message: 'Agregar foto ${index + 1}',
                  child: Center(
                    child: picking && index == photos.length
                        ? const CircularProgressIndicator(
                            semanticsLabel: 'Abriendo fotos',
                          )
                        : const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: orange,
                          ),
                  ),
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (photo.bytes case final Uint8List bytes)
                  Image.memory(
                    bytes,
                    fit: BoxFit.cover,
                    semanticLabel: label,
                    errorBuilder: (_, _, _) =>
                        const Icon(Icons.broken_image_outlined),
                  )
                else
                  CatalogImage(
                    api: widget.session.api.catalog,
                    url: photo.url,
                    label: label,
                  ),
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton.filledTonal(
                    tooltip: 'Quitar foto ${index + 1}',
                    icon: const Icon(Icons.close),
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            photos.removeAt(index);
                            error = null;
                          }),
                  ),
                ),
              ],
            ),
    );
  }
}
