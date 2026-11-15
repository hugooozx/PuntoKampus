import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/catalog_cards.dart';
import '../ui/kampus_design.dart';
import 'my_products.dart';

Future<Uint8List?> _chooseLogo() async {
  final image = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1024,
    maxHeight: 1024,
    imageQuality: 85,
    requestFullMetadata: false,
  );
  if (image == null) return null;
  if (await image.length() > 2 * 1024 * 1024) {
    throw const ApiFailure('El logo puede pesar hasta 2 MB.');
  }
  return image.readAsBytes();
}

class MyShopPage extends StatefulWidget {
  const MyShopPage({
    super.key,
    required this.session,
    required this.visible,
    required this.onChanged,
  });
  final AccountSession session;
  final bool visible;
  final VoidCallback onChanged;

  @override
  State<MyShopPage> createState() => _MyShopPageState();
}

class _MyShopPageState extends State<MyShopPage> {
  Future<Json>? shop;
  bool uploading = false;
  String? uploadError;

  @override
  void initState() {
    super.initState();
    if (widget.visible) shop = _read();
  }

  @override
  void didUpdateWidget(MyShopPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) shop ??= _read();
  }

  Future<Json> _read() => widget.session.authorized('GET', 'mi-tienda');

  void _refresh() => setState(() => shop = _read());

  Future<void> _edit(Json data) async {
    final result = await Navigator.push<Json>(
      context,
      MaterialPageRoute(
        builder: (_) => _ShopForm(session: widget.session, initial: data),
      ),
    );
    if (!mounted || result == null) return;
    widget.session.reflectShop(result);
    widget.onChanged();
    setState(() => shop = Future.value(result));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          data['tienda'] == null
              ? 'Tu tienda ya está publicada.'
              : 'Cambios guardados.',
        ),
      ),
    );
  }

  Future<void> _replaceLogo(Json data) async {
    setState(() {
      uploading = true;
      uploadError = null;
    });
    try {
      final image = await _chooseLogo();
      if (!mounted || image == null) return;
      final result = await widget.session.authorized(
        'POST',
        'mi-tienda/logo',
        image: image,
      );
      if (!mounted) return;
      final updated = {
        ...data,
        'tienda': {...data['tienda'] as Json, ...result},
      };
      setState(() => shop = Future.value(updated));
      widget.onChanged();
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => uploadError = failure.message);
    } on Exception {
      if (mounted) setState(() => uploadError = 'No pudimos abrir esa imagen.');
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Json>(
    future: shop,
    builder: (context, snapshot) {
      final failure = snapshot.error;
      final data = snapshot.data;
      final store = data?['tienda'] as Json?;
      final active = store?['estado'] == 'activa';
      return PageBody(
        width: 600,
        children: [
          const TitleBlock('Mi tienda'),
          if (snapshot.connectionState == ConnectionState.waiting)
            const LinearProgressIndicator(semanticsLabel: 'Cargando tu tienda')
          else if (failure != null) ...[
            Text(
              failure is ApiFailure
                  ? failure.message
                  : 'No pudimos cargar tu tienda.',
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: _refresh,
              child: const Text('Reintentar'),
            ),
          ] else if (data != null && store == null) ...[
            const Text(
              'Publica tu emprendimiento y comparte tu tienda con la comunidad UTB.',
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _edit(data),
              icon: const Icon(Icons.storefront_outlined),
              label: const Text('Crear mi tienda'),
            ),
          ] else if (data != null && store != null) ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: line),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 64,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CatalogImage(
                          api: widget.session.api.catalog,
                          url: store['logo_url'] as String?,
                          label: store['nombre'] as String,
                          height: 64,
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
                            store['nombre'] as String,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 6),
                          if (active)
                            KampusBadge.plan(
                              premium: store['plan'] == 'premium',
                            ),
                          Text(
                            active
                                ? (store['plan'] == 'premium'
                                      ? 'Plan Premium'
                                      : 'Plan gratis')
                                : 'Tienda dada de baja',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!active) ...[
              const SizedBox(height: 12),
              Text(
                store['motivo_baja'] as String? ??
                    'Tu tienda está fuera de la Vitrina.',
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) => MyProductsPage(
                    session: widget.session,
                    shopName: store['nombre'] as String,
                    onChanged: widget.onChanged,
                  ),
                ),
              ),
              icon: const Icon(Icons.inventory_2_outlined),
              label: const Text('Mis productos'),
            ),
            const SizedBox(height: 8),
            if (active)
              OutlinedButton(
                onPressed: () =>
                    Navigator.pushNamed(context, '/t/${store['slug']}'),
                child: const Text('Ver tienda en la Vitrina'),
              ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: uploading ? null : () => _edit(data),
              child: const Text('Editar tienda'),
            ),
            TextButton(
              onPressed: uploading ? null : () => _replaceLogo(data),
              child: Text(uploading ? 'Subiendo logo…' : 'Cambiar logo'),
            ),
            if (uploadError != null) _ShopError(uploadError!),
            if (store['plan'] != 'premium')
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.lock_outline),
                title: Text('Portada con Premium'),
                subtitle: Text(
                  'La portada propia se habilita al activar el plan Premium.',
                ),
              ),
          ],
        ],
      );
    },
  );
}

class _ShopForm extends StatefulWidget {
  const _ShopForm({required this.session, required this.initial});
  final AccountSession session;
  final Json initial;

  @override
  State<_ShopForm> createState() => _ShopFormState();
}

class _ShopFormState extends State<_ShopForm> {
  final form = GlobalKey<FormState>();
  final code = TextEditingController();
  final phone = TextEditingController();
  late final store = widget.initial['tienda'] as Json?;
  late final name = TextEditingController(text: store?['nombre'] as String?);
  late final description = TextEditingController(
    text: store?['descripcion'] as String?,
  );
  late final hours = TextEditingController(text: store?['horario'] as String?);
  late final bool needsSeller = widget.initial['ya_es_vendedor'] != true;
  late bool showSeller = needsSeller;
  bool shareWhatsapp = false, saving = false, picking = false;
  int? faculty, career, semester;
  late int? primary = store?['categoria_1_id'] as int?;
  late int? secondary = store?['categoria_2_id'] as int?;
  late int? delivery = store?['punto_entrega_id'] as int?;
  Uint8List? logo;
  String? error;
  CatalogApi get api => widget.session.api.catalog;
  late var catalogs = _load();
  Future<List<CatalogOption>>? careers;

  Future<List<List<CatalogOption>>> _load() => Future.wait([
    needsSeller ? api.options('facultades') : Future.value(<CatalogOption>[]),
    api.options('categorias'),
    api.options('puntos-entrega'),
  ]);

  @override
  void dispose() {
    for (final field in [code, phone, name, description, hours]) {
      field.dispose();
    }
    super.dispose();
  }

  void _selectFaculty(int? value) {
    setState(() {
      faculty = value;
      career = null;
      careers = value == null
          ? null
          : api.options('carreras', {'facultad_id': '$value'});
    });
  }

  void _step(bool seller) => setState(() {
    showSeller = seller;
    error = null;
  });

  Future<void> _pick() async {
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final bytes = await _chooseLogo();
      if (mounted && bytes != null) setState(() => logo = bytes);
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
    } on Exception {
      if (mounted) setState(() => error = 'No pudimos abrir esa imagen.');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _save() async {
    if (saving || !form.currentState!.validate()) return;
    if (showSeller) {
      if (career == null) {
        setState(() => error = 'Elige una carrera para continuar.');
        return;
      }
      _step(false);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final result = await widget.session.authorized(
        store == null ? 'POST' : 'PUT',
        'mi-tienda',
        data: {
          'nombre': name.text.trim(),
          'descripcion': description.text.trim(),
          'horario': hours.text.trim(),
          'categoria_1_id': primary,
          'categoria_2_id': secondary == 0 ? null : secondary,
          'punto_entrega_id': delivery,
          if (needsSeller) ...{
            'codigo_estudiante': code.text.trim(),
            'carrera_id': career,
            'semestre': semester,
            'whatsapp': phone.text.trim(),
            'mostrar_whatsapp': shareWhatsapp,
          },
        },
        image: logo,
      );
      if (mounted) Navigator.pop(context, result);
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
      appBar: AppBar(
        title: Text(store == null ? 'Crear mi tienda' : 'Editar tienda'),
      ),
      body: SafeArea(
        child: FutureBuilder<List<List<CatalogOption>>>(
          future: catalogs,
          builder: (context, snapshot) {
            final options = snapshot.data;
            return PageBody(
              key: ValueKey(showSeller),
              width: 530,
              children: [
                if (needsSeller) ...[
                  Text(
                    showSeller ? '1 de 2 · Tus datos' : '2 de 2 · Tu tienda',
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: showSeller ? 0.5 : 1,
                    semanticsLabel: 'Progreso del formulario',
                  ),
                  const SizedBox(height: 20),
                ],
                TitleBlock(
                  showSeller ? 'Datos del vendedor' : 'Datos de la tienda',
                ),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(
                    semanticsLabel: 'Cargando opciones',
                  )
                else if (options == null) ...[
                  const Text('No pudimos cargar las opciones para tu tienda.'),
                  OutlinedButton(
                    onPressed: () => setState(() => catalogs = _load()),
                    child: const Text('Reintentar'),
                  ),
                ] else if (options[1].isEmpty ||
                    options[2].isEmpty ||
                    (needsSeller && options[0].isEmpty)) ...[
                  const Text(
                    'La publicación se habilitará cuando estén disponibles las categorías, los puntos de entrega y el catálogo académico.',
                  ),
                  OutlinedButton(
                    onPressed: () => setState(() => catalogs = _load()),
                    child: const Text('Volver a comprobar'),
                  ),
                ] else
                  Form(
                    key: form,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showSeller)
                          ..._sellerFields(options[0])
                        else
                          ..._storeFields(options[1], options[2]),
                        if (error != null) _ShopError(error!),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: saving || picking ? null : _save,
                          child: Text(
                            saving
                                ? 'Guardando…'
                                : showSeller
                                ? 'Continuar'
                                : store == null
                                ? 'Publicar tienda'
                                : 'Guardar cambios',
                          ),
                        ),
                        if (!showSeller && needsSeller)
                          TextButton(
                            onPressed: saving ? null : () => _step(true),
                            child: const Text('Volver a tus datos'),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );

  List<Widget> _sellerFields(List<CatalogOption> faculties) => [
    _text('Código de estudiante', code, 40, minimum: 1),
    _select('Facultad', faculties, faculty, _selectFaculty),
    FutureBuilder<List<CatalogOption>>(
      future: careers,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(
            semanticsLabel: 'Cargando carreras',
          );
        }
        if (snapshot.hasError) {
          return OutlinedButton(
            onPressed: () => _selectFaculty(faculty),
            child: const Text('Reintentar cargar carreras'),
          );
        }
        final choices = snapshot.data ?? [];
        if (faculty != null && choices.isEmpty) {
          return const Text('Esta facultad aún no tiene carreras disponibles.');
        }
        return _select(
          'Carrera',
          choices,
          career,
          (value) => setState(() => career = value),
        );
      },
    ),
    _select(
      'Semestre',
      [
        for (var i = 1; i <= 10; i++) CatalogOption({'id': i, 'nombre': '$i'}),
      ],
      semester,
      (value) => setState(() => semester = value),
    ),
    _text(
      'WhatsApp',
      phone,
      40,
      keyboard: TextInputType.phone,
      hint: '0991234567',
      validator: (value) =>
          RegExp(r'^(?:0|\+?593)9[0-9]{8}$')
              .hasMatch((value ?? '').replaceAll(RegExp(r'[\s().-]+'), ''))
          ? null
          : 'Escribe un número de celular de Ecuador.',
    ),
    SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: const Text('Mostrar mi WhatsApp en la tienda'),
      subtitle: const Text('Por defecto tu número es privado.'),
      value: shareWhatsapp,
      onChanged: (value) => setState(() => shareWhatsapp = value),
    ),
  ];

  List<Widget> _storeFields(
    List<CatalogOption> categories,
    List<CatalogOption> deliveryPoints,
  ) => [
    if (store == null) ...[
      if (logo != null)
        Align(
          alignment: Alignment.centerLeft,
          child: Image.memory(
            logo!,
            height: 72,
            width: 72,
            fit: BoxFit.cover,
            semanticLabel: 'Logo elegido',
            errorBuilder: (_, _, _) =>
                const Text('No se pudo previsualizar el logo.'),
          ),
        ),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: saving || picking ? null : _pick,
          icon: const Icon(Icons.image_outlined),
          label: Text(
            picking
                ? 'Abriendo imágenes…'
                : logo == null
                ? 'Agregar logo (opcional)'
                : 'Elegir otro logo',
          ),
        ),
      ),
      if (logo != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: saving || picking
                ? null
                : () => setState(() => logo = null),
            child: const Text('Quitar logo'),
          ),
        ),
      const SizedBox(height: 12),
    ],
    _text('Nombre de la tienda', name, 40, minimum: 3),
    _text('Descripción', description, 300, lines: 3),
    _select(
      'Categoría principal',
      categories,
      primary,
      (value) => setState(() {
        primary = value;
        if (secondary == value) secondary = 0;
      }),
    ),
    _select(
      'Segunda categoría (opcional)',
      [
        CatalogOption({'id': 0, 'nombre': 'Ninguna'}),
        ...categories.where((c) => c.id != primary),
      ],
      secondary ?? 0,
      (value) => setState(() => secondary = value),
      required: false,
    ),
    _text('Horario', hours, 100, hint: 'Lun–vie, 08:00–14:00'),
    _select(
      'Punto de entrega habitual',
      deliveryPoints,
      delivery,
      (value) => setState(() => delivery = value),
    ),
    if (store == null) const Text('Tu tienda se publicará con el plan gratis.'),
  ];

  Widget _text(
    String label,
    TextEditingController controller,
    int max, {
    int minimum = 0,
    int lines = 1,
    String? hint,
    TextInputType? keyboard,
    FormFieldValidator<String>? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: controller,
      enabled: !saving,
      maxLines: lines,
      maxLength: max,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label, hintText: hint),
      validator:
          validator ??
          (value) => (value?.trim().characters.length ?? 0) < minimum
              ? 'Escribe al menos $minimum caracteres.'
              : null,
    ),
  );

  Widget _select(
    String label,
    List<CatalogOption> options,
    int? selection,
    ValueChanged<int?> onChanged, {
    bool required = true,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: DropdownButtonFormField<int>(
      key: ValueKey((label, selection)),
      initialValue: options.any((option) => option.id == selection)
          ? selection
          : null,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        for (final option in options)
          DropdownMenuItem(
            value: option.id,
            child: Text(
              option.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      onChanged: saving || options.isEmpty ? null : onChanged,
      validator: (value) =>
          required && value == null ? 'Elige una opción.' : null,
    ),
  );
}

class _ShopError extends StatelessWidget {
  const _ShopError(this.message);
  final String message;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    ),
  );
}
