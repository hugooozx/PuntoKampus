import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/link.dart';

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
  const InstitutionalLogin({
    super.key,
    required this.session,
    this.seller = false,
    this.browseOnExit = false,
  });
  final AccountSession session;
  final bool seller, browseOnExit;
  @override
  Widget build(BuildContext context) =>
      _CodeFlow(session: session, seller: seller, browseOnExit: browseOnExit);
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
    this.seller = false,
    this.browseOnExit = false,
  });
  final AccountSession session;
  final bool deleting, publicPage, seller, browseOnExit;
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
    appBar: AppBar(title: widget.deleting ? const Text('Borrar cuenta') : null),
    body: SafeArea(
      child: widget.deleting
          ? PageBody(width: 480, children: _content())
          : _AccessCard(children: _content()),
    ),
  );

  List<Widget> _content() => [
    if (deleted) ...[
      const TitleBlock(
        'Cuenta borrada',
        subtitle: 'La cuenta asociada al correo ya no está activa.',
      ),
      FilledButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/vitrina',
          (_) => false,
        ),
        child: const Text('Volver a la vitrina'),
      ),
    ] else ...[
      if (widget.deleting)
        TitleBlock(
          'Borrar mi cuenta',
          subtitle: sent
              ? 'Escribe el código de 6 dígitos que enviamos a $address. Vence en 10 minutos.'
              : 'Se borrarán tu perfil, tienda, productos y fotos. El historial de otras personas conservará los pedidos sin tus datos de cuenta. Esta acción es definitiva.',
        )
      else
        _AccessHeading(
          icon: sent ? Icons.mail_outline : Icons.school_outlined,
          title: sent ? 'Revisa tu correo' : 'Entra con tu correo UTB',
          description: sent
              ? 'Enviamos un código de 6 dígitos a'
              : widget.seller
              ? 'Recibe un código para crear o gestionar tu tienda.'
              : 'Recibe un código de 6 dígitos para entrar.',
          address: sent ? address : null,
        ),
      Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sent)
              _VerificationCodeField(
                controller: code,
                enabled: !busy,
                onSubmitted: confirm,
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
                      backgroundColor: Theme.of(context).colorScheme.error,
                    )
                  : null,
              onPressed: busy || (!sent && seconds > 0)
                  ? null
                  : sent
                  ? confirm
                  : send,
              child: Text(
                busy
                    ? sent
                          ? 'Verificando código…'
                          : 'Solicitando código…'
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
                  seconds > 0 ? 'Reenviar en $seconds s' : 'Reenviar código',
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
      if (!widget.deleting && widget.browseOnExit)
        TextButton(
          onPressed: busy
              ? null
              : () {
                  Navigator.pushReplacementNamed(context, '/vitrina');
                },
          child: const Text('Ver la vitrina'),
        ),
    ],
  ];
}

Future<bool> ensureInstitutionalProfile(
  BuildContext context,
  AccountSession session, {
  bool seller = false,
  bool browseOnExit = false,
}) async {
  if (!session.signedIn) {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => InstitutionalLogin(
          session: session,
          seller: seller,
          browseOnExit: browseOnExit,
        ),
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
              onSignedOut: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
    );
  }
  return context.mounted && session.signedIn && !session.needsProfile;
}

class ProfileForm extends StatefulWidget {
  const ProfileForm({
    super.key,
    required this.session,
    this.onCompleted,
    this.onSignedOut,
    this.onSignOut,
  });
  final AccountSession session;
  final VoidCallback? onCompleted;
  final VoidCallback? onSignedOut;
  final Future<void> Function()? onSignOut;
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
  bool closing = false;
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
    final children = <Widget>[
      if (isNew)
        const _AccessHeading(
          icon: Icons.person_outline,
          title: 'Completa tu perfil',
          description: 'Usa los nombres con los que te conocen en el campus.',
        )
      else ...[
        const TitleBlock('Cuenta'),
        Text(user['correo'] as String, style: const TextStyle(color: muted)),
        const SizedBox(height: 20),
      ],
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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: accepted,
                title: const Text('Acepto la política de privacidad'),
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: busy
                    ? null
                    : (value) => setState(() => accepted = value ?? false),
              ),
              if (!accepted)
                const Text(
                  'Acepta la política para continuar.',
                  style: TextStyle(color: muted, fontSize: 14),
                ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/privacidad'),
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
              onPressed: busy || (isNew && !accepted) ? null : save,
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
      if (isNew)
        const SizedBox(height: 12)
      else ...[
        const SizedBox(height: 20),
        const Divider(),
      ],
      if (!isNew)
        TextButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/privacidad'),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Política de privacidad'),
        ),
      OutlinedButton.icon(
        onPressed: busy
            ? null
            : () async {
                setState(() => closing = true);
                final closed = await run(
                  widget.onSignOut ?? widget.session.signOut,
                );
                if (mounted) {
                  setState(() => closing = false);
                  if (closed) widget.onSignedOut?.call();
                }
              },
        icon: const Icon(Icons.logout),
        label: Text(closing ? 'Cerrando sesión…' : 'Cerrar sesión'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: busy
            ? null
            : () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DeleteAccountPage(session: widget.session),
                  ),
                );
              },
        style: TextButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
        child: const Text('Borrar mi cuenta'),
      ),
    ];
    return isNew
        ? _AccessCard(children: children)
        : PageBody(width: 520, children: children);
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
          const TitleBlock(
            'Política de privacidad de PuntoKampus',
            subtitle: 'PuntoKampus es una plataforma estudiantil para la comunidad de la Universidad Técnica de Babahoyo.',
          ),
          FutureBuilder<Json>(
            future: contact,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LinearProgressIndicator(
                  semanticsLabel: 'Cargando datos de contacto',
                );
              }
              if (snapshot.hasError) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Feedback(
                      'No pudimos cargar los datos de contacto.',
                      isError: true,
                    ),
                    OutlinedButton(
                      onPressed: () => setState(
                        () => contact = widget.api.request('GET', 'privacidad'),
                      ),
                      child: const Text('Reintentar cargar el contacto'),
                    ),
                  ],
                );
              }
              final responsible =
                  (snapshot.data?['responsable'] as String? ?? '').trim();
              final email = (snapshot.data?['contacto'] as String? ?? '')
                  .trim();
              final publication = DateTime.tryParse(
                snapshot.data?['actualizada_en'] as String? ?? '',
              );
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (responsible.isEmpty ||
                      email.isEmpty ||
                      publication == null)
                    const _Feedback(
                      'Borrador para revisión del equipo de PuntoKampus.',
                    ),
                  if (publication != null)
                    Text(
                      'Última actualización: ${MaterialLocalizations.of(context).formatFullDate(publication)}',
                      style: const TextStyle(color: muted),
                    ),
                  if (responsible.isNotEmpty)
                    Text('Responsable de los datos: $responsible'),
                  if (email.isNotEmpty)
                    Link(
                      uri: Uri(scheme: 'mailto', path: email),
                      builder: (_, followLink) => TextButton.icon(
                        onPressed: followLink,
                        icon: const Icon(Icons.email_outlined),
                        label: Text(email),
                      ),
                    ),
                ],
              );
            },
          ),
          const _PrivacySection(
            'Qué datos guardamos',
            'Guardamos tu correo institucional y tus nombres. Si creas una tienda, también guardamos tu código de estudiante, carrera, semestre y número de WhatsApp. Registramos tus pedidos y los reportes que envías. Si solicitas Premium, guardamos la foto del comprobante, el número y el monto del pago.',
          ),
          const _PrivacySection(
            'Para qué los usamos',
            'Usamos estos datos para verificar el acceso, publicar tu tienda, coordinar pedidos, revisar reportes y comprobar pagos de Premium. También podemos medir el funcionamiento del piloto con datos agrupados sin nombres.',
          ),
          const _PrivacySection(
            'Quién puede verlos',
            'El vendedor ve tu nombre y tu pedido cuando compras. Si vendes, quien te hace un pedido recibe tu número de WhatsApp y el público solo puede verlo si activas esa opción. El equipo autorizado administra el servicio. La foto del comprobante está disponible para el vendedor que la envió y para administración.',
          ),
          const _PrivacySection(
            'Tus derechos',
            'Puedes consultar y corregir tus datos en Cuenta. Usa el contacto de esta política para pedir una copia o solicitar una corrección. Puedes solicitar el borrado desde Cuenta o desde esta página.',
          ),
          const _PrivacySection(
            'Cuánto tiempo los guardamos',
            'Guardamos tus datos mientras mantengas la cuenta. Al borrarla se eliminan el perfil, la tienda y sus archivos. La otra parte conserva el historial sin el nombre de la cuenta o tienda eliminada. La foto de un comprobante se retira al vencer el plazo de conservación contado desde la revisión. El número y el monto del pago aprobado se conservan como registro.',
          ),
          const _PrivacySection(
            'Cambios a esta política',
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

class _PrivacySection extends StatelessWidget {
  const _PrivacySection(this.title, this.body);
  final String title, body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        const SizedBox(height: 6),
        Text(body, style: const TextStyle(height: 1.5)),
      ],
    ),
  );
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, viewport) => SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: (viewport.maxHeight - 32).clamp(0.0, double.infinity),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 494),
            child: Material(
              color: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 4,
              shadowColor: ink.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(
                side: const BorderSide(color: line),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: EdgeInsets.all(viewport.maxWidth >= 530 ? 32 : 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(width: 245, child: Brand()),
                    ),
                    const Divider(height: 36),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AccessHeading extends StatelessWidget {
  const _AccessHeading({
    required this.icon,
    required this.title,
    required this.description,
    this.address,
  });
  final IconData icon;
  final String title, description;
  final String? address;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ExcludeSemantics(
        child: Container(
          width: 64,
          height: 58,
          decoration: BoxDecoration(
            color: peach,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(icon, color: orange, size: 32),
        ),
      ),
      const SizedBox(height: 14),
      Semantics(
        header: true,
        child: Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        description,
        style: const TextStyle(color: muted),
        textAlign: TextAlign.center,
      ),
      if (address case final email?) ...[
        const SizedBox(height: 4),
        Text(
          email,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text('Vence en 10 minutos.', style: TextStyle(color: muted)),
      ],
      const SizedBox(height: 24),
    ],
  );
}

class _VerificationCodeField extends StatefulWidget {
  const _VerificationCodeField({
    required this.controller,
    required this.enabled,
    required this.onSubmitted,
  });
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSubmitted;

  @override
  State<_VerificationCodeField> createState() => _VerificationCodeFieldState();
}

class _VerificationCodeFieldState extends State<_VerificationCodeField> {
  final focus = FocusNode();

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const codeStyle = TextStyle(
      fontSize: 22,
      height: 1,
      fontWeight: FontWeight.w800,
    );
    final digitsHeight = MediaQuery.textScalerOf(context).scale(22);
    final height = digitsHeight + 30;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Código de 6 dígitos',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: height,
              child: ExcludeSemantics(
                child: ListenableBuilder(
                  listenable: Listenable.merge([focus, widget.controller]),
                  builder: (context, _) {
                    final value = widget.controller.value;
                    final active = focus.hasFocus
                        ? value.selection.extentOffset.clamp(0, 5)
                        : -1;
                    return Row(
                      spacing: 6,
                      children: [
                        for (var i = 0; i < 6; i++)
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: i == active ? peach : canvas,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: i == active ? orange : line,
                                ),
                              ),
                              child: Text(
                                i < value.text.length ? value.text[i] : '',
                                style: codeStyle,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Semantics(
              label: 'Código de 6 dígitos',
              child: TextFormField(
                controller: widget.controller,
                focusNode: focus,
                enabled: widget.enabled,
                showCursor: false,
                textAlign: TextAlign.center,
                style: codeStyle.copyWith(color: Colors.transparent),
                decoration: const InputDecoration(
                  filled: false,
                  constraints: BoxConstraints(minHeight: 52),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                  border: InputBorder.none,
                  errorMaxLines: 3,
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.go,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                autofillHints: const [AutofillHints.oneTimeCode],
                autocorrect: false,
                enableSuggestions: false,
                validator: (value) =>
                    value?.length == 6 ? null : 'Escribe los 6 dígitos.',
                onFieldSubmitted: (_) => widget.onSubmitted(),
              ),
            ),
          ],
        ),
      ],
    );
  }
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
