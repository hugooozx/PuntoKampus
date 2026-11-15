import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../api/account_api.dart';
import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/kampus_design.dart';

class PremiumPage extends StatefulWidget {
  const PremiumPage({super.key, required this.session});
  final AccountSession session;

  @override
  State<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends State<PremiumPage> {
  final form = GlobalKey<FormState>();
  final number = TextEditingController();
  final amount = TextEditingController();
  late Future<Json> data = _load();
  Uint8List? photo;
  bool saving = false, picking = false, viewing = false;
  String? error, photoError;

  Future<Json> _load() => widget.session.authorized('GET', 'premium');
  void _refresh() => setState(() => data = _load());

  @override
  void dispose() {
    number.dispose();
    amount.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    setState(() {
      picking = true;
      photoError = null;
    });
    try {
      final image = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        requestFullMetadata: false,
      );
      if (image == null || !mounted) return;
      if (await image.length() > 2 * 1024 * 1024) {
        if (mounted) {
          setState(() => photoError = 'La foto puede pesar hasta 2 MB.');
        }
        return;
      }
      final bytes = await image.readAsBytes();
      if (mounted) setState(() => photo = bytes);
    } on Exception {
      if (mounted) setState(() => photoError = 'No pudimos abrir la foto.');
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _send() async {
    final valid = form.currentState!.validate();
    if (photo == null) {
      setState(() => photoError = 'Adjunta una foto del comprobante.');
    }
    if (!valid || photo == null || saving || picking) return;
    setState(() {
      saving = true;
      error = null;
      photoError = null;
    });
    try {
      await widget.session.authorized(
        'POST',
        'premium/solicitudes',
        image: photo,
        data: {
          'numero_comprobante': number.text.trim(),
          'monto': amount.text.replaceAll(',', '.'),
        },
      );
      if (!mounted) return;
      number.clear();
      amount.clear();
      setState(() {
        photo = null;
        data = _load();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recibimos tu comprobante. Verás el resultado en esta pantalla.',
          ),
        ),
      );
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        photoError = failure is AccountFailure
            ? failure.fields['imagen']
            : null;
        error = photoError == null ? failure.message : null;
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> _showPhoto(Object? id) async {
    setState(() => viewing = true);
    try {
      final result = await widget.session.authorized(
        'GET',
        'premium/solicitudes/$id/foto',
      );
      final bytes = base64Decode(result['imagen'] as String);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Tu comprobante'),
          content: Image.memory(
            bytes,
            fit: BoxFit.contain,
            semanticLabel: 'Foto de tu comprobante',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } on ApiFailure catch (failure) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
      }
    } finally {
      if (mounted) setState(() => viewing = false);
    }
  }

  Widget _form() => Form(
    key: form,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Comprobante de pago',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: number,
          enabled: !saving,
          maxLength: 100,
          maxLengthEnforcement: MaxLengthEnforcement.enforced,
          decoration: const InputDecoration(labelText: 'Número de comprobante'),
          validator: (value) => (value?.trim().isEmpty ?? true)
              ? 'Escribe el número de comprobante.'
              : null,
        ),
        TextFormField(
          controller: amount,
          enabled: !saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            TextInputFormatter.withFunction(
              (old, next) =>
                  RegExp(r'^\d{0,6}(?:[.,]\d{0,2})?$').hasMatch(next.text)
                  ? next
                  : old,
            ),
          ],
          decoration: const InputDecoration(labelText: 'Monto pagado (USD)'),
          validator: (value) {
            final parsed = double.tryParse((value ?? '').replaceAll(',', '.'));
            return parsed == null || parsed <= 0
                ? 'Escribe un importe mayor a cero.'
                : null;
          },
        ),
        const SizedBox(height: 12),
        if (photo case final Uint8List bytes)
          Image.memory(
            bytes,
            height: 128,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) =>
                const Text('No se pudo mostrar la imagen. Selecciona otra.'),
          ),
        OutlinedButton.icon(
          onPressed: picking || saving ? null : _pick,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: Text(photo == null ? 'Adjuntar foto' : 'Cambiar foto'),
        ),
        const Text('JPG, PNG o WebP. Máximo 2 MB.'),
        if (photoError != null || error != null)
          Text(
            photoError ?? error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: saving || picking ? null : _send,
          child: Text(saving ? 'Enviando…' : 'Enviar comprobante'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Mi tienda'),
        actions: [
          IconButton(
            onPressed: saving ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: SafeArea(
        child: PageBody(
          width: 560,
          children: [
            const TitleBlock('Premium'),
            FutureBuilder<Json>(
              future: data,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LinearProgressIndicator(
                    semanticsLabel: 'Cargando el plan',
                  );
                }
                if (!snapshot.hasData) {
                  return StatusPanel(
                    icon: Icons.error_outline,
                    title: 'No pudimos cargar Premium',
                    message: 'Vuelve a intentarlo.',
                    action: OutlinedButton(
                      onPressed: _refresh,
                      child: const Text('Reintentar'),
                    ),
                  );
                }
                final plan = snapshot.data!;
                final active = plan['plan'] == 'premium';
                final payment = plan['pago'] as Json?;
                final last = plan['ultima_solicitud'] as Json?;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      active ? 'Plan Premium' : 'Plan gratis',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (active) Text('Vigente hasta ${plan['premium_hasta']}'),
                    const SizedBox(height: 12),
                    const Text(
                      'Con Premium puedes mostrar la insignia «Sacó 10» y subir tu propia portada. El plan gratis también tiene pedidos sin límite.',
                    ),
                    if (last != null) ...[
                      const Divider(height: 28),
                      Text(switch (last['estado']) {
                        'aprobada' => 'Solicitud aprobada',
                        'rechazada' => 'Solicitud rechazada',
                        _ => 'Comprobante en revisión',
                      }, style: Theme.of(context).textTheme.titleMedium),
                      Text(
                        'Comprobante ${last['numero_comprobante']} · \$${last['monto']}',
                      ),
                      if (last['motivo_rechazo'] case final String reason)
                        Text(reason),
                      if (last['foto_disponible'] == true)
                        TextButton(
                          onPressed: viewing
                              ? null
                              : () => _showPhoto(last['id']),
                          child: const Text('Ver mi comprobante'),
                        ),
                    ],
                    if (!active && last?['estado'] != 'pendiente') ...[
                      const Divider(height: 28),
                      if (payment == null)
                        const Text(
                          'El cobro Premium todavía no está habilitado para tu tienda.',
                        )
                      else ...[
                        Text(
                          '\$${payment['precio']} hasta el ${payment['fin_periodo']}',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Haz el pago fuera de PuntoKampus y adjunta el comprobante.',
                        ),
                        Text('${payment['banco']} · ${payment['tipo_cuenta']}'),
                        SelectableText(
                          '${payment['numero']} · ${payment['titular']}',
                        ),
                        if (payment['usuario_deuna'] case final String account)
                          SelectableText('Deuna: $account'),
                        const Divider(height: 28),
                        _form(),
                      ],
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
