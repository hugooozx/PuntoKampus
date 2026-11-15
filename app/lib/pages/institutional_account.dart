import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../api/account_api.dart';
import '../api/account_session.dart';
import '../api/catalog_api.dart';
import '../ui/kampus_design.dart';

mixin _AccountAction<T extends StatefulWidget> on State<T> {
  bool busy = false;
  String? error;

  Future<bool> run(Future<void> Function() action) async {
    if (busy) return false;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await action();
      return true;
    } on ApiFailure catch (failure) {
      if (mounted) setState(() => error = failure.message);
      return false;
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }
}

class InstitutionalLogin extends StatelessWidget {
  const InstitutionalLogin({super.key, required this.session});
  final AccountSession session;
  @override
  Widget build(BuildContext context) => _CodeFlow(session: session);
}

class DeleteAccountPage extends StatelessWidget {
  const DeleteAccountPage({
    super.key,
    required this.session,
    this.publicPage = false,
  });
  final AccountSession session;
  final bool publicPage;
  @override
  Widget build(BuildContext context) =>
      _CodeFlow(session: session, deleting: true, publicPage: publicPage);
}

class _CodeFlow extends StatefulWidget {
  const _CodeFlow({
    required this.session,
    this.deleting = false,
    this.publicPage = false,
  });
  final AccountSession session;
  final bool deleting, publicPage;
  @override
  State<_CodeFlow> createState() => _CodeFlowState();
}

class _CodeFlowState extends State<_CodeFlow> with _AccountAction<_CodeFlow> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final code = TextEditingController();
  DateTime? resendAt;
  Timer? ticker;
  bool sent = false, deleted = false;
  bool get hasSession => widget.deleting && !widget.publicPage;
  String get address => hasSession
      ? (widget.session.user?['correo'] as String? ?? '')
      : email.text.trim();
  int get seconds =>
      (resendAt?.difference(DateTime.now()).inMilliseconds ?? 0) <= 0
      ? 0
      : (resendAt!.difference(DateTime.now()).inMilliseconds / 1000).ceil();

  @override
  void dispose() {
    ticker?.cancel();
    email.dispose();
    code.dispose();
    super.dispose();
  }

  void cooldown(int seconds) {
    if (!mounted) return;
    setState(() => resendAt = DateTime.now().add(Duration(seconds: seconds)));
    ticker?.cancel();
    ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (this.seconds == 0) timer.cancel();
      if (mounted) setState(() {});
    });
  }

  Future<void> send() async {
    if (!sent && !(form.currentState?.validate() ?? false)) return;
    final ok = await run(() async {
      try {
        if (hasSession) {
          await widget.session.requestDeletion();
        } else {
          await widget.session.api.request(
            'POST',
            widget.deleting ? 'cuentas/codigo-borrado' : 'auth/codigo',
            data: {'correo': address},
          );
        }
      } on AccountFailure catch (failure) {
        if (failure.retryAfter case final int wait) cooldown(wait);
        rethrow;
      }
    });
    if (ok && mounted) {
      setState(() {
        sent = true;
        code.clear();
      });
      cooldown(60);
    }
  }

  Future<void> confirm() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final ok = await run(() async {
      if (!widget.deleting) {
        await widget.session.signIn(address, code.text);
      } else if (widget.publicPage) {
        final currentEmail = widget.session.user?['correo'];
        await widget.session.api.request(
          'DELETE',
          'cuentas',
          data: {'correo': address, 'codigo': code.text},
        );
        if (currentEmail == address.toLowerCase()) await widget.session.clear();
      } else {
        await widget.session.deleteAccount(code.text);
      }
    });
    if (!ok || !mounted) return;
    if (widget.deleting) {
      setState(() => deleted = true);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.deleting ? 'Borrar cuenta' : 'Acceso UTB'),
    ),
    body: SafeArea(
      child: PageBody(
        width: 480,
        children: [
          if (deleted) ...[
            const TitleBlock(
              'Cuenta borrada',
              subtitle: 'La cuenta asociada al correo ya no está activa.',
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.popUntil(context, (route) => route.isFirst),
              child: const Text('Volver a la vitrina'),
            ),
          ] else ...[
            if (!widget.deleting && !sent)
              Align(
                alignment: Alignment.centerLeft,
                child: ExcludeSemantics(
                  child: Container(
                    width: 62,
                    height: 46,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: const BoxDecoration(
                      color: peach,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                  ),
                ),
              ),
            TitleBlock(
              widget.deleting
                  ? 'Borrar mi cuenta'
                  : sent
                  ? 'Revisa tu correo'
                  : 'Entra con tu correo UTB',
              subtitle: sent
                  ? 'Escribe el código de 6 dígitos que enviamos a $address. Vence en 10 minutos.'
                  : widget.deleting
                  ? 'Se borrarán tu perfil, tienda, productos y fotos. El historial de otras personas conservará los pedidos sin tus datos de cuenta. Esta acción es definitiva.'
                  : 'Te enviaremos un código de 6 dígitos para entrar.',
            ),
            Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sent)
                    _Field(
                      label: 'Código de 6 dígitos',
                      controller: code,
                      enabled: !busy,
                      hint: '000000',
                      keyboard: TextInputType.number,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      validator: (value) =>
                          value?.length == 6 ? null : 'Escribe los 6 dígitos.',
                      onSubmitted: (_) => confirm(),
                    )
                  else if (!hasSession)
                    _Field(
                      label: 'Correo institucional',
                      controller: email,
                      enabled: !busy,
                      hint: 'tu.nombre@utb.edu.ec',
                      keyboard: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      validator: (value) {
                        final input = value?.trim() ?? '';
                        return RegExp(
                              r'^[^\s@]+@(?:[a-z0-9-]+\.)*utb\.edu\.ec$',
                              caseSensitive: false,
                            ).hasMatch(input)
                            ? null
                            : 'Usa un correo de la UTB o de una de sus facultades.';
                      },
                      onSubmitted: (_) => send(),
                    ),
                  if (error != null) _Feedback(error!, isError: true),
                  const SizedBox(height: 16),
                  FilledButton(
                    style: widget.deleting && sent
                        ? FilledButton.styleFrom(
                            backgroundColor: Theme.of(context)
                                .colorScheme
                                .error,
                          )
                        : null,
                    onPressed: busy || (!sent && seconds > 0)
                        ? null
                        : sent
                        ? confirm
                        : send,
                    child: Text(
                      busy
                          ? 'Un momento…'
                          : sent
                          ? (widget.deleting
                                ? 'Borrar mi cuenta para siempre'
                                : 'Entrar')
                          : seconds > 0
                          ? 'Espera $seconds s'
                          : widget.deleting
                          ? 'Enviarme el código de confirmación'
                          : 'Enviarme el código',
                    ),
                  ),
                  if (sent) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: busy || seconds > 0 ? null : send,
                      child: Text(
                        seconds > 0
                            ? 'Reenviar en $seconds s'
                            : 'Reenviar código',
                      ),
                    ),
                    if (!hasSession)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() {
                                ticker?.cancel();
                                resendAt = null;
                                sent = false;
                                error = null;
                                code.clear();
                              }),
                        child: const Text('Cambiar correo'),
                      ),
                  ],
                ],
              ),
            ),
            if (!widget.deleting)
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Ver la vitrina'),
              ),
          ],
        ],
      ),
    ),
  );
}

Future<bool> ensureInstitutionalProfile(
  BuildContext context,
  AccountSession session,
) async {
  if (!session.signedIn) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InstitutionalLogin(session: session),
      ),
    );
  }
  if (!context.mounted || !session.signedIn) return false;
  if (session.needsProfile) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Acceso UTB')),
          body: SafeArea(
            child: ProfileForm(
              session: session,
              onCompleted: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
  return context.mounted && session.signedIn && !session.needsProfile;
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key, required this.session, this.onCompleted});
  final AccountSession session;
  final VoidCallback? onCompleted;
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm>
    with _AccountAction<ProfileForm> {
  final form = GlobalKey<FormState>();
  late final names = TextEditingController(
    text: widget.session.user?['nombres'] as String?,
  );
  late bool? whatsapp = widget.session.user?['mostrar_whatsapp'] as bool?;
  bool accepted = false;
  String? success;

  @override
  void dispose() {
    names.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    final completing = widget.session.needsProfile;
    setState(() => success = null);
    final ok = await run(
      () => widget.session.saveProfile(
        names.text.trim(),
        consent: completing ? accepted : null,
        whatsapp: completing ? null : whatsapp,
      ),
    );
    if (!ok || !mounted) return;
    if (completing) {
      widget.onCompleted?.call();
    } else {
      setState(() => success = 'Cambios guardados.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.session.needsProfile;
    final user = widget.session.user!;
    return PageBody(
      width: 520,
      children: [
        TitleBlock(
          isNew ? 'Completa tu perfil' : 'Cuenta',
          subtitle: isNew
              ? 'Usa los nombres con los que te conocen en el campus.'
              : null,
        ),
        Text(user['correo'] as String, style: const TextStyle(color: muted)),
        const SizedBox(height: 20),
        Form(
          key: form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Field(
                label: 'Nombres',
                controller: names,
                enabled: !busy,
                hint: 'Escribe tus nombres',
                keyboard: TextInputType.name,
                formatters: [LengthLimitingTextInputFormatter(150)],
                validator: (value) => (value?.trim().isEmpty ?? true)
                    ? 'Escribe tus nombres.'
                    : null,
              ),
              if (isNew) ...[
                const SizedBox(height: 12),
                FormField<bool>(
                  initialValue: accepted,
                  validator: (value) => value == true
                      ? null
                      : 'Acepta la política para continuar.',
                  builder: (field) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: accepted,
                        title: const Text('Acepto la política de privacidad'),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: busy
                            ? null
                            : (value) => setState(() {
                                accepted = value ?? false;
                                field.didChange(accepted);
                              }),
                      ),
                      if (field.errorText != null)
                        _Feedback(field.errorText!, isError: true),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/privacidad'),
                    child: const Text('Leer la política de privacidad'),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: whatsapp ?? false,
                  title: const Text('Mostrar mi WhatsApp en mi tienda'),
                  subtitle: whatsapp == null
                      ? const Text(
                          'Disponible cuando tengas un perfil de vendedor.',
                        )
                      : null,
                  onChanged: busy || whatsapp == null
                      ? null
                      : (value) => setState(() => whatsapp = value),
                ),
              ],
              if (error != null) _Feedback(error!, isError: true),
              if (success != null) _Feedback(success!),
              if (!widget.session.persisted)
                const _Feedback(
                  'La sesión se cerrará al salir de este navegador o aplicación.',
                ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: busy ? null : save,
                child: Text(
                  busy
                      ? 'Un momento…'
                      : isNew
                      ? 'Continuar'
                      : 'Guardar cambios',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Divider(),
        if (!isNew)
          TextButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/privacidad'),
            icon: const Icon(Icons.description_outlined),
            label: const Text('Política de privacidad'),
          ),
        OutlinedButton(
          onPressed: busy ? null : () => run(widget.session.signOut),
          child: const Text('Salir'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: busy
              ? null
              : () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          DeleteAccountPage(session: widget.session),
                    ),
                  );
                },
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const Text('Borrar mi cuenta'),
        ),
      ],
    );
  }
}

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key, required this.api});
  final AccountApi api;
  @override
  State<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  late Future<Json> contact = widget.api.request('GET', 'privacidad');

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Privacidad')),
    body: SafeArea(
      child: PageBody(
        width: 660,
        children: [
          const TitleBlock('Política de privacidad de PuntoKampus'),
          FutureBuilder<Json>(
            future: contact,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(
                  semanticsLabel: 'Cargando datos de contacto',
                );
              }
              if (snapshot.hasError) {
                return OutlinedButton(
                  onPressed: () => setState(
                    () => contact = widget.api.request('GET', 'privacidad'),
                  ),
                  child: const Text('Reintentar cargar el contacto'),
                );
              }
              final data = snapshot.data;
              if (data?['responsable'] == null || data?['contacto'] == null) {
                return const _Feedback(
                  'Borrador para revisión. El responsable y el contacto se definirán antes del piloto.',
                );
              }
              return Text(
                'Responsable de los datos: ${data!['responsable']}.\nContacto: ${data['contacto']}.',
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'PuntoKampus es una plataforma estudiantil para la comunidad de la Universidad Técnica de Babahoyo. Guardamos tu correo institucional y tus nombres para identificar tu cuenta y permitirte entrar.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Si creas una tienda, usamos tus datos académicos y tu número de WhatsApp para gestionar la tienda y coordinar pedidos. El público solo ve tu número si lo activas. El equipo usa tus datos para administrar el servicio.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Los pedidos guardan la información necesaria para que el comprador y el vendedor coordinen la entrega. Si solicitas Premium, el equipo revisa el comprobante de forma privada y conserva el número y el monto del pago.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Puedes consultar y corregir tus datos en Cuenta. Al borrar tu cuenta se eliminan el perfil, la tienda y sus archivos. Los pedidos de otras personas mantienen su historial sin tus datos de cuenta.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Si la política cambia, te avisaremos en la aplicación antes de que el cambio entre en vigor.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => Navigator.pushNamed(context, '/borrar-cuenta'),
              child: const Text('Solicitar el borrado de mi cuenta'),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.controller,
    required this.enabled,
    this.hint,
    this.keyboard,
    this.formatters,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
  });
  final String label;
  final TextEditingController controller;
  final bool enabled;
  final String? hint;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Semantics(
        label: label,
        child: TextFormField(
          controller: controller,
          enabled: enabled,
          decoration: InputDecoration(hintText: hint),
          keyboardType: keyboard,
          inputFormatters: formatters,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          autofillHints: autofillHints,
          autocorrect: false,
          enableSuggestions: false,
        ),
      ),
    ],
  );
}

class _Feedback extends StatelessWidget {
  const _Feedback(this.text, {this.isError = false});
  final String text;
  final bool isError;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Semantics(
      liveRegion: true,
      child: Text(
        text,
        style: TextStyle(
          color: isError ? Theme.of(context).colorScheme.error : greenInk,
        ),
      ),
    ),
  );
}
