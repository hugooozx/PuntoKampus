import 'package:material_ui/material_ui.dart';

// Tokens compartidos de las láminas aprobadas. Solo se ofrece tema claro.
const orange = Color(0xFFB94700);
const ink = Color(0xFF171916);
const canvas = Color(0xFFFAF8F5);
const line = Color(0xFFD7D2CB);
const muted = Color(0xFF595B56);
const peach = Color(0xFFFFEBDD);
const softGreen = Color(0xFFE0F0DF);
const greenInk = Color(0xFF28522A);
const softGold = Color(0xFFFFEBB5);
const goldInk = Color(0xFF68420E);
const softGray = Color(0xFFEBEAE7);

ThemeData kampusTheme() => ThemeData(
  useMaterial3: true,
  fontFamily: 'Inter',
  visualDensity: VisualDensity.standard,
  colorScheme: ColorScheme.fromSeed(seedColor: orange).copyWith(
    primary: orange,
    onPrimary: Colors.white,
    surface: canvas,
    onSurface: ink,
    outline: line,
  ),
  scaffoldBackgroundColor: canvas,
  textTheme: const TextTheme(
    bodyMedium: TextStyle(fontSize: 16, height: 1.45, color: ink),
    bodyLarge: TextStyle(fontSize: 16, height: 1.45, color: ink),
    titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    headlineMedium: TextStyle(
      fontSize: 32,
      height: 1.12,
      fontWeight: FontWeight.w900,
      letterSpacing: -1,
      color: ink,
    ),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    titleTextStyle: TextStyle(fontFamily: 'Inter', fontSize: 16, color: ink),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      side: const BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      textStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
  ),
  inputDecorationTheme: InputDecorationThemeData(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    hintStyle: const TextStyle(color: muted, fontSize: 16),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: orange, width: 2),
    ),
  ),
  dividerTheme: const DividerThemeData(color: line, thickness: 1, space: 24),
);

class Brand extends StatelessWidget {
  const Brand({super.key});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      ExcludeSemantics(
        child: Container(
          width: 42,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFD6650B), orange],
            ),
          ),
          child: const Text(
            'pk',
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              height: 1,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.5,
            ),
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PuntoKampus',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.9,
              ),
            ),
            const Text(
              'Comunidad UTB',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
          ],
        ),
      ),
    ],
  );
}

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.width = 1080});
  final List<Widget> children;
  final double width;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? 16 : 40,
      20,
      MediaQuery.sizeOf(context).width < 600 ? 16 : 40,
      32,
    ),
    child: Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}

class TitleBlock extends StatelessWidget {
  const TitleBlock(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(subtitle!, style: const TextStyle(fontSize: 16, height: 1.45)),
        ],
      ],
    ),
  );
}

class KampusBadge extends StatelessWidget {
  const KampusBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
  });
  const KampusBadge.plan({super.key, required bool premium})
    : label = premium ? 'Sacó 10' : 'Matriculado',
      background = premium ? softGold : softGreen,
      foreground = premium ? goldInk : greenInk;
  const KampusBadge.availability({super.key, required bool available})
    : label = available ? 'Disponible' : 'Agotado',
      background = available ? softGreen : softGray,
      foreground = available ? greenInk : muted;
  final String label;
  final Color background, foreground;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: foreground,
        fontSize: 13,
        height: 1.2,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class CatalogSwitch extends StatelessWidget {
  const CatalogSwitch({
    super.key,
    required this.products,
    required this.onChanged,
  });
  final bool products;
  final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFF0EDE9),
          border: Border.all(color: line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            for (final value in [false, true])
              Expanded(
                child: Semantics(
                  selected: products == value,
                  child: TextButton(
                    onPressed: () => onChanged(value),
                    style: TextButton.styleFrom(
                      backgroundColor: products == value
                          ? Colors.white
                          : Colors.transparent,
                      foregroundColor: products == value ? orange : ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(11),
                        side: BorderSide(
                          color: products == value
                              ? orange
                              : Colors.transparent,
                        ),
                      ),
                      textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: products == value
                            ? FontWeight.w700
                            : FontWeight.w400,
                      ),
                    ),
                    child: Text(value ? 'Productos' : 'Tiendas'),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

class StatusPanel extends StatelessWidget {
  const StatusPanel({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.busy = false,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  final bool busy;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 32),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          children: [
            if (busy)
              const CircularProgressIndicator(semanticsLabel: 'Cargando')
            else
              ExcludeSemantics(
                child: SizedBox(
                  width: 140,
                  height: 104,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        left: 8,
                        bottom: 0,
                        child: Container(
                          width: 100,
                          height: 76,
                          decoration: BoxDecoration(
                            color: peach,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 6,
                        child: Icon(
                          icon,
                          size: 80,
                          color: const Color(0xFF334A3C),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            Semantics(
              liveRegion: true,
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 26,
                      height: 1.2,
                      letterSpacing: -0.6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: muted),
                  ),
                ],
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 24),
              SizedBox(width: double.infinity, child: action!),
            ],
          ],
        ),
      ),
    ),
  );
}
