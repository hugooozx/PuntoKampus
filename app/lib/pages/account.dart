import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../ui/common.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  String? error;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  void enter() {
    final store = StoreScope.of(context);
    final requested = email.text.trim().toLowerCase();
    final person = store.people
        .where((value) => value.email == requested)
        .firstOrNull;
    if (person == null) {
      setState(() => error = 'Selecciona uno de los perfiles de prueba.');
      return;
    }
    store.switchPerson(person.id);
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    final people = StoreScope.of(context).people;
    return PageBody(
      width: 480,
      children: [
        const TitleBlock('Entrar a PuntoKampus', back: true),
        const Center(child: Brand()),
        const SizedBox(height: 24),
        Center(
          child: ExcludeSemantics(
            child: Container(
              height: 76,
              width: 82,
              decoration: const BoxDecoration(
                color: orange,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.elliptical(60, 48),
                  topRight: Radius.elliptical(44, 52),
                  bottomLeft: Radius.elliptical(40, 36),
                  bottomRight: Radius.elliptical(52, 45),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Tu campus, tus emprendimientos',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        const Text(
          'Acceso de demostración. Elige un perfil ficticio para probar la app.',
        ),
        const Label('Correo institucional'),
        TextField(
          controller: email,
          keyboardType: TextInputType.emailAddress,
          onSubmitted: (_) => enter(),
          onChanged: (_) {
            if (error != null) setState(() => error = null);
          },
          decoration: InputDecoration(
            hintText: 'lucia.demo@utb.edu.ec',
            errorText: error,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final person in people)
              ActionChip(
                label: Text(person.name),
                onPressed: () => setState(() {
                  email.text = person.email;
                  error = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 20),
        FilledButton(onPressed: enter, child: const Text('Entrar a la demo')),
      ],
    );
  }
}

class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  Future<void> editName(BuildContext context, Person person) async {
    final store = StoreScope.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(person.name),
    );
    if (result != null && context.mounted) {
      person.name = result;
      store.changed();
      toast(context, 'Cambios guardados.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final user = store.user;
    if (user == null) return const LoginPage();
    return PageBody(
      width: 620,
      children: [
        const TitleBlock('Cuenta'),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Label('Correo institucional'),
              Text(user.email),
              TextButton(
                onPressed: () => editName(context, user),
                child: const Text('Editar nombre'),
              ),
              if (store.ownShop != null)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mostrar mi WhatsApp en mi tienda'),
                  value: user.showPhone,
                  onChanged: (value) {
                    user.showPhone = value;
                    store.changed();
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Perfiles de demostración',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: ValueKey(user.id),
                initialValue: user.id,
                isExpanded: true,
                items: [
                  for (final person in store.people)
                    DropdownMenuItem(
                      value: person.id,
                      child: Text(person.name),
                    ),
                ],
                onChanged: (id) {
                  if (id != null && id != user.id) store.switchPerson(id);
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => store.switchPerson(null),
                child: const Text('Salir'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () async {
            final yes = await confirm(
              context,
              '¿Restablecer la demostración?',
              'Los pedidos y cambios locales se reemplazarán por los ejemplos iniciales.',
              'Restablecer',
            );
            if (yes && context.mounted) store.reset();
          },
          child: const Text('Restablecer la demo'),
        ),
        const SizedBox(height: 12),
        const Text(
          'Usa datos de prueba. Los cambios se guardan en este navegador o dispositivo.',
        ),
      ],
    );
  }
}

class _NameDialog extends StatefulWidget {
  const _NameDialog(this.name);

  final String name;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final name = TextEditingController(text: widget.name);

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Editar nombre'),
    content: TextField(
      controller: name,
      maxLength: 80,
      autofocus: true,
      decoration: const InputDecoration(labelText: 'Nombres'),
      onChanged: (_) => setState(() {}),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Volver'),
      ),
      FilledButton(
        onPressed: name.text.trim().isEmpty
            ? null
            : () => Navigator.pop(context, name.text.trim()),
        child: const Text('Guardar'),
      ),
    ],
  );
}
