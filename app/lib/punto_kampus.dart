import 'package:material_ui/material_ui.dart';

import 'domain/store.dart';
import 'pages/account.dart';
import 'pages/catalog.dart';
import 'pages/checkout.dart';
import 'pages/seller.dart';
import 'ui/common.dart';

class PuntoKampusApp extends StatelessWidget {
  const PuntoKampusApp({super.key, required this.store});

  final DemoStore store;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(seedColor: orange).copyWith(
      primary: orange,
      onPrimary: Colors.white,
      surface: canvas,
      onSurface: ink,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: colors);
    final button = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'PuntoKampus',
        debugShowCheckedModeBanner: false,
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: base.copyWith(
          scaffoldBackgroundColor: canvas,
          textTheme: base.textTheme
              .apply(bodyColor: ink, displayColor: ink)
              .copyWith(
                bodyMedium: const TextStyle(fontSize: 16, height: 1.4),
                headlineMedium: const TextStyle(
                  fontSize: 34,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                ),
              ),
          inputDecorationTheme: InputDecorationThemeData(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: line),
            ),
          ),
          filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: button,
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: button,
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              shape: button,
            ),
          ),
          chipTheme: base.chipTheme.copyWith(
            backgroundColor: Colors.white,
            selectedColor: orange,
            labelStyle: WidgetStateTextStyle.resolveWith(
              (states) => TextStyle(
                color: states.contains(WidgetState.selected)
                    ? Colors.white
                    : ink,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            shape: button,
            side: const BorderSide(color: line),
          ),
          segmentedButtonTheme: SegmentedButtonThemeData(
            style: ButtonStyle(
              minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
              shape: WidgetStatePropertyAll(button),
              side: const WidgetStatePropertyAll(BorderSide(color: line)),
              foregroundColor: WidgetStateProperty.resolveWith(
                (states) =>
                    states.contains(WidgetState.selected) ? orange : ink,
              ),
              backgroundColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? const Color(0xFFFFF0E5)
                    : Colors.white,
              ),
            ),
          ),
        ),
        home: const _Shell(),
      ),
    );
  }
}

const _tabs = [
  (label: 'Vitrina', icon: Icons.storefront_outlined, page: CatalogPage()),
  (label: 'Mis pedidos', icon: Icons.shopping_bag_outlined, page: OrdersPage()),
  (
    label: 'Mi tienda',
    icon: Icons.store_mall_directory_outlined,
    page: MyShopPage(),
  ),
  (label: 'Cuenta', icon: Icons.person_outline, page: AccountPage()),
];

class _Shell extends StatefulWidget {
  const _Shell();

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  int tab = 0;
  String? previousUser;
  bool readSession = false;
  bool exploredLink = false;
  final navigatorKeys = List.generate(
    _tabs.length,
    (_) => GlobalKey<NavigatorState>(),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = StoreScope.of(context);
    if (readSession &&
        previousUser != null &&
        store.currentUserId != previousUser) {
      tab = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        for (final key in navigatorKeys) {
          key.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
    previousUser = store.currentUserId;
    readSession = true;
    if (exploredLink) return;
    exploredLink = true;
    final uri = Uri.base;
    final path = uri.fragment.isNotEmpty ? uri.fragment : uri.path;
    final slug = RegExp(r'^/t/([a-z0-9-]+)$').firstMatch(path)?.group(1);
    if (slug != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final shop = store.shops
            .where((s) => s.active && s.slug == slug)
            .firstOrNull;
        navigatorKeys.first.currentState?.push(
          MaterialPageRoute(
            builder: (_) => shop != null
                ? ShopPage(shop.id)
                : const PageBody(
                    children: [
                      TitleBlock('Esta tienda no está disponible', back: true),
                    ],
                  ),
          ),
        );
      });
    }
  }

  void select(int index) {
    if (tab == index) {
      navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    }
    setState(() => tab = index);
  }

  void enter() {
    navigatorKeys[0].currentState?.push(
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    final signedIn = store.user != null;
    final desktop = MediaQuery.sizeOf(context).width >= 1000;
    final content = IndexedStack(
      index: tab,
      children: [
        for (var i = 0; i < _tabs.length; i++)
          NavigatorPopHandler<Object?>(
            enabled: tab == i,
            onPopWithResult: (result) =>
                navigatorKeys[i].currentState?.pop(result),
            child: Navigator(
              key: navigatorKeys[i],
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => Scaffold(body: _tabs[i].page),
              ),
            ),
          ),
      ],
    );
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        bottom: false,
        child: Row(
          children: [
            if (desktop)
              Container(
                width: 248,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(right: BorderSide(color: line)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 12, bottom: 24),
                      child: Brand(),
                    ),
                    for (var i = 0; i < (signedIn ? _tabs.length : 1); i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Material(
                          color: tab == i
                              ? const Color(0xFFFFF0E5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: ListTile(
                            leading: Icon(_tabs[i].icon),
                            title: Text(
                              _tabs[i].label,
                              style: TextStyle(
                                fontWeight: tab == i
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                            selected: tab == i,
                            selectedColor: orange,
                            selectedTileColor: const Color(0xFFFFF0E5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onTap: () => select(i),
                          ),
                        ),
                      ),
                    const Spacer(),
                    const Divider(color: line),
                    if (store.user case final user?)
                      Material(
                        color: Colors.white,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFFFF0E5),
                            child: Icon(Icons.person_outline, color: orange),
                          ),
                          title: Text(
                            user.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: const Text('Mi cuenta'),
                          onTap: () => select(3),
                        ),
                      )
                    else
                      FilledButton(
                        onPressed: enter,
                        child: const Text('Entrar'),
                      ),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      horizontal: desktop ? 32 : 20,
                      vertical: desktop ? 10 : 8,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: line)),
                    ),
                    child: Row(
                      children: [
                        if (!desktop) const Expanded(child: Brand(small: true)),
                        if (desktop) const Spacer(),
                        const Text(
                          'Modo demo',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6E4A38),
                          ),
                        ),
                        if (!desktop && !signedIn)
                          TextButton(
                            onPressed: enter,
                            child: const Text('Entrar'),
                          ),
                      ],
                    ),
                  ),
                  if (store.storageError case final error?)
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(error),
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !desktop && signedIn
          ? NavigationBar(
              height: 70,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFFFFF0E5),
              selectedIndex: tab,
              onDestinationSelected: select,
              destinations: [
                for (final item in _tabs)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    label: item.label,
                  ),
              ],
            )
          : null,
    );
  }
}
