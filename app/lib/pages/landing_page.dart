import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/link.dart';

import '../api/account_session.dart';
import '../ui/kampus_design.dart';
import 'institutional_account.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key, required this.session});
  final AccountSession session;

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  final guide = GlobalKey();
  bool entering = false;

  void _explore() => Navigator.pushNamed(context, '/vitrina');

  Future<void> _enter({bool seller = false}) async {
    final session = widget.session;
    if (entering || session.restoring) return;
    if (session.signedIn && !session.needsProfile && !seller) {
      await Navigator.pushNamed(context, '/cuenta');
      return;
    }
    setState(() => entering = true);
    try {
      if (await ensureInstitutionalProfile(
            context,
            session,
            seller: seller,
            browseOnExit: true,
          ) &&
          mounted) {
        await Navigator.pushNamed(context, seller ? '/mi-tienda' : '/vitrina');
      }
    } finally {
      if (mounted) setState(() => entering = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) {
      final session = widget.session;
      final canEnter = !entering && !session.restoring;
      final screenWidth = MediaQuery.sizeOf(context).width;
      final gutter = screenWidth >= 840 ? 48.0 : 20.0;
      return Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1400),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: gutter),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          children: [
                            const Expanded(child: Brand()),
                            if (screenWidth >= 720) ...[
                              TextButton(
                                onPressed: _explore,
                                child: const Text('Vitrina'),
                              ),
                              TextButton(
                                onPressed: () => Scrollable.ensureVisible(
                                  guide.currentContext!,
                                  duration:
                                      MediaQuery.disableAnimationsOf(context)
                                      ? Duration.zero
                                      : const Duration(milliseconds: 220),
                                ),
                                child: const Text('Cómo funciona'),
                              ),
                              const SizedBox(width: 12),
                            ],
                            OutlinedButton(
                              onPressed: canEnter ? _enter : null,
                              child: Text(
                                session.signedIn ? 'Mi cuenta' : 'Entrar',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      const SizedBox(height: 22),
                      if (session.restoreError case final String error) ...[
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 12,
                          children: [
                            Text(error),
                            TextButton(
                              onPressed: session.restore,
                              child: const Text('Reintentar sesión'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                      ],
                      _LandingHero(
                        onExplore: _explore,
                        onSell: canEnter ? () => _enter(seller: true) : null,
                      ),
                      const SizedBox(height: 50),
                      _BuyingGuide(key: guide),
                      const SizedBox(height: 40),
                      const Divider(height: 1),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          const Text(
                            'PuntoKampus · Comunidad UTB',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Wrap(
                            spacing: 4,
                            children: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/privacidad'),
                                child: const Text('Privacidad'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  '/borrar-cuenta',
                                ),
                                child: const Text('Borrar cuenta'),
                              ),
                              Link(
                                uri: session.api.catalog.baseUrl.resolve(
                                  '/admin',
                                ),
                                target: LinkTarget.blank,
                                builder: (context, followLink) => TextButton(
                                  onPressed: followLink,
                                  child: const Text('Administración'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _LandingHero extends StatelessWidget {
  const _LandingHero({required this.onExplore, required this.onSell});
  final VoidCallback onExplore;
  final VoidCallback? onSell;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide =
          constraints.maxWidth >= 850 &&
          MediaQuery.textScalerOf(context).scale(16) < 24;
      final titleSize =
          (wide
                  ? (constraints.maxWidth / 19).clamp(46, 68)
                  : (constraints.maxWidth / 10.2).clamp(26, 49))
              .toDouble();
      final titleStyle = Theme.of(context).textTheme.headlineMedium!.copyWith(
        fontSize: titleSize,
        height: 1.04,
        letterSpacing: wide ? -3.8 : -1.9,
      );
      final actions = [
        FilledButton.icon(
          onPressed: onExplore,
          icon: const Icon(Icons.storefront_outlined),
          label: const Text('Explorar la Vitrina'),
        ),
        OutlinedButton(onPressed: onSell, child: const Text('Quiero vender')),
      ];
      final headline = Padding(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 42 : 18,
          vertical: wide ? 38 : 25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Universidad Técnica de Babahoyo',
              style: TextStyle(color: orange, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            Semantics(
              header: true,
              child: Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(text: 'Tu campus, '),
                    TextSpan(
                      text: 'tus emprendimientos.',
                      style: TextStyle(color: orange),
                    ),
                  ],
                ),
                style: titleStyle,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Descubre lo que crean los estudiantes de la UTB. Encuentra productos, haz tu pedido y coordina la entrega en el campus.',
              style: TextStyle(fontSize: 17, color: muted, height: 1.5),
            ),
            const SizedBox(height: 24),
            if (constraints.maxWidth < 520)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  actions.first,
                  const SizedBox(height: 10),
                  actions.last,
                ],
              )
            else
              Wrap(spacing: 10, runSpacing: 10, children: actions),
          ],
        ),
      );
      final photograph = Padding(
        padding: wide
            ? const EdgeInsets.fromLTRB(0, 12, 12, 12)
            : const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(17),
          child: AspectRatio(
            aspectRatio: wide ? 1.13 : 1.26,
            child: Image.asset(
              'assets/images/portada-campus.webp',
              semanticLabel:
                  'Dos estudiantes en un puesto de repostería de un campus',
              fit: BoxFit.cover,
              alignment: Alignment(0, wide ? -0.14 : -0.23),
              errorBuilder: (_, _, _) => const ColoredBox(
                color: peach,
                child: Center(
                  child: Icon(
                    Icons.storefront_outlined,
                    color: orange,
                    size: 72,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFF9F1), Color(0xFFFFEEE1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(25),
        ),
        child: wide
            ? Row(
                children: [
                  Expanded(flex: 52, child: headline),
                  Expanded(flex: 48, child: photograph),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [headline, photograph],
              ),
      );
    },
  );
}

class _BuyingGuide extends StatelessWidget {
  const _BuyingGuide({super.key});
  static const steps = [
    (
      icon: Icons.search,
      title: 'Encuentra algo que te guste',
      detail: 'Explora las tiendas de estudiantes o busca un producto en la Vitrina.',
    ),
    (
      icon: Icons.shopping_bag_outlined,
      title: 'Arma tu pedido',
      detail: 'Confirma con tu correo UTB y elige el punto de entrega, el día y la forma de pago.',
    ),
    (
      icon: Icons.place_outlined,
      title: 'Recoge tu compra',
      detail: 'Coordina con la tienda por WhatsApp y recoge el pedido en el campus.',
    ),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns =
          constraints.maxWidth >= 790 &&
              MediaQuery.textScalerOf(context).scale(16) < 24
          ? 3
          : 1;
      const gap = 14.0;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              'Cómo funciona',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final step in steps)
                Container(
                  width: width,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: peach,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(step.icon, color: orange),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        step.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(step.detail, style: const TextStyle(color: muted)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      );
    },
  );
}
