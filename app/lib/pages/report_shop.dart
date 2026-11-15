import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../api/account_api.dart';
import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/kampus_design.dart';
import 'institutional_account.dart';

const _reasons = {
  'prohibido': 'Producto prohibido',
  'no_entrego': 'No entregó el pedido',
  'informacion_falsa': 'Información falsa',
  'trato_inadecuado': 'Trato inadecuado',
  'otro': 'Otro',
};

class ReportShopButton extends StatefulWidget {
  const ReportShopButton({
    super.key,
    required this.shop,
    required this.session,
  });
  final CatalogEntry shop;
  final AccountSession session;

  @override
  State<ReportShopButton> createState() => _ReportShopButtonState();
}

class _ReportShopButtonState extends State<ReportShopButton> {
  bool opening = false;
  bool get ownShop =>
      (widget.session.user?['tienda'] as Json?)?['id'] == widget.shop.id;

  Future<void> _open() async {
    setState(() => opening = true);
    try {
      if (!await ensureInstitutionalProfile(context, widget.session) ||
          !mounted ||
          ownShop) {
        return;
      }
      final sent = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        showDragHandle: true,
        isDismissible: false,
        enableDrag: false,
        constraints: const BoxConstraints(maxWidth: 560),
        builder: (_) => _ReportForm(shop: widget.shop, session: widget.session),
      );
      if (sent == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reporte enviado. El equipo lo revisará.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) => ownShop
        ? const SizedBox.shrink()
        : Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: opening || widget.session.restoring ? null : _open,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Reportar'),
            ),
          ),
  );
}

class _ReportForm extends StatefulWidget {
  const _ReportForm({required this.shop, required this.session});
  final CatalogEntry shop;
  final AccountSession session;

  @override
  State<_ReportForm> createState() => _ReportFormState();
}

class _ReportFormState extends State<_ReportForm> {
  final form = GlobalKey<FormState>();
  final detail = TextEditingController();
  String? reason, error, detailError;
  bool saving = false, attempted = false, blocked = false;

  @override
  void dispose() {
    detail.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (saving || blocked) return;
    if (!attempted) setState(() => attempted = true);
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
      detailError = null;
    });
    try {
      await widget.session.authorized(
        'POST',
        'tiendas/${widget.shop.id}/reportes',
        data: {'motivo': reason, 'detalle': detail.text.trim()},
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiFailure catch (failure) {
      if (!mounted) return;
      setState(() {
        detailError = failure is AccountFailure
            ? failure.fields['detalle']
            : null;
        if (detailError == null) error = failure.message;
        blocked = const [401, 403, 404, 429].contains(failure.status);
      });
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Form(
            key: form,
            autovalidateMode: attempted
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TitleBlock('Reportar tienda', subtitle: widget.shop.name),
                FormField<String>(
                  validator: (value) =>
                      value == null ? 'Selecciona un motivo.' : null,
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Motivo',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      RadioGroup<String>(
                        groupValue: reason,
                        onChanged: (value) {
                          if (saving || blocked) return;
                          field.didChange(value);
                          setState(() {
                            reason = value;
                            detailError = null;
                          });
                        },
                        child: Column(
                          children: [
                            for (final entry in _reasons.entries)
                              RadioListTile<String>(
                                contentPadding: EdgeInsets.zero,
                                enabled: !saving && !blocked,
                                value: entry.key,
                                title: Text(entry.value),
                              ),
                          ],
                        ),
                      ),
                      if (field.hasError)
                        Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: detail,
                  enabled: !saving && !blocked,
                  maxLength: 300,
                  maxLengthEnforcement: MaxLengthEnforcement.enforced,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: reason == 'otro'
                        ? 'Detalle (obligatorio)'
                        : 'Detalle (opcional)',
                    errorText: detailError,
                  ),
                  onChanged: (_) {
                    if (detailError != null) setState(() => detailError = null);
                  },
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (reason == 'otro' && text.isEmpty) {
                      return 'Describe lo que ocurrió.';
                    }
                    if (text.runes.length > 300) {
                      return 'El detalle puede tener hasta 300 caracteres.';
                    }
                    return null;
                  },
                ),
                if (error != null)
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: saving || blocked ? null : _send,
                  child: Text(saving ? 'Enviando…' : 'Enviar reporte'),
                ),
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(context),
                  child: const Text('Volver'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
