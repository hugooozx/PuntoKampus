import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../domain/models.dart';
import '../domain/store.dart';

const orange = Color(0xFFC2410C);
const ink = Color(0xFF202622);
const canvas = Color(0xFFFAF8F5);
const line = Color(0xFFE8E4DD);

class StoreScope extends InheritedNotifier<DemoStore> {
  const StoreScope({super.key, required DemoStore store, required super.child})
    : super(notifier: store);
  static DemoStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<StoreScope>()!.notifier!;
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
void handle(BuildContext context, VoidCallback action) {
  try {
    action();
  } on StateError catch (e) {
    toast(context, e.message);
  }
}

Future<bool> confirm(
  BuildContext context,
  String title,
  String content,
  String action,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(action),
          ),
        ],
      ),
    ) ??
    false;
void open(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.width = 1060});
  final List<Widget> children;
  final double width;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(
      MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
      24,
      MediaQuery.sizeOf(context).width < 600 ? 20 : 36,
      36,
    ),
    child: Center(
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
  const TitleBlock(
    this.title, {
    super.key,
    this.subtitle,
    this.back = false,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final bool back;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (back)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              label: const Text('Volver'),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF555D57),
                height: 1.45,
              ),
            ),
          ),
      ],
    ),
  );
}

class Brand extends StatelessWidget {
  const Brand({super.key, this.small = false});
  final bool small;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: small ? 36 : 44,
        height: small ? 36 : 44,
        decoration: BoxDecoration(
          color: orange,
          borderRadius: BorderRadius.circular(11),
        ),
        alignment: Alignment.center,
        child: Text(
          'pk',
          style: TextStyle(
            fontSize: small ? 25 : 29,
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: -2,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PuntoKampus',
                style: TextStyle(
                  fontSize: small ? 19 : 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),
              if (!small)
                const Text(
                  'Comunidad UTB',
                  style: TextStyle(fontSize: 13, color: Color(0xFF555D57)),
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
  });
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: const BorderSide(color: line),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.gold = false});
  final String label;
  final bool gold;
  @override
  Widget build(BuildContext context) {
    final pending = ['Pendiente', 'En revisión', 'pendiente'].contains(label);
    final neutral = [
      'Agotado',
      'Cancelado',
      'Vencido',
      'cancelado',
      'vencido',
    ].contains(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: gold
            ? const Color(0xFFFFEDB5)
            : pending
            ? const Color(0xFFFFEDD5)
            : neutral
            ? const Color(0xFFEEECE8)
            : const Color(0xFFE8F3E7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '${label[0].toUpperCase()}${label.substring(1)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: gold
              ? const Color(0xFF70450D)
              : pending
              ? const Color(0xFF9A3412)
              : neutral
              ? const Color(0xFF555853)
              : const Color(0xFF285D2D),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.title,
    this.message, {
    super.key,
    this.action,
    this.icon = Icons.search_rounded,
  });
  final String title, message;
  final Widget? action;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 12),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0E5),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Icon(icon, size: 48, color: orange),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555D57), height: 1.5),
          ),
        ),
        if (action != null)
          Padding(padding: const EdgeInsets.only(top: 24), child: action!),
      ],
    ),
  );
}

class Label extends StatelessWidget {
  const Label(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 16),
    child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
  );
}

class Fact extends StatelessWidget {
  const Fact(this.icon, this.text, {super.key});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: const Color(0xFF555D57)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, height: 1.4)),
        ),
      ],
    ),
  );
}

class TotalRow extends StatelessWidget {
  const TotalRow(this.amount, {super.key, this.label = 'Total'});
  final int amount;
  final String label;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
        ),
        Text(
          money(amount),
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}

class Quantity extends StatelessWidget {
  const Quantity(this.value, this.onChanged, {super.key});
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton.outlined(
        tooltip: 'Reducir cantidad',
        onPressed: value > 1 ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove),
      ),
      SizedBox(
        width: 48,
        child: Text(
          '$value',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
      IconButton.outlined(
        tooltip: 'Aumentar cantidad',
        onPressed: value < 20 ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add),
      ),
    ],
  );
}

class ProductArt extends StatelessWidget {
  const ProductArt(
    this.kind, {
    super.key,
    this.size = 64,
    this.expanded = false,
  });
  final String kind;
  final double size;
  final bool expanded;
  @override
  Widget build(BuildContext context) {
    final asset = {
      'bakery': 'brownie.png',
      'cookie': 'cookie.png',
      'coffee': 'coffee.png',
    }[kind];
    return Semantics(
      label: 'Imagen de ejemplo',
      image: true,
      child: Container(
        width: expanded ? null : size,
        height: expanded ? null : size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: kind == 'book'
              ? const Color(0xFFE7F0E7)
              : const Color(0xFFFFEBDC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: AspectRatio(
          aspectRatio: expanded ? 1.5 : 1,
          child: expanded && asset != null
              ? Image.asset(
                  'assets/images/$asset',
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) =>
                      CustomPaint(painter: _ArtPainter(kind)),
                )
              : CustomPaint(painter: _ArtPainter(kind)),
        ),
      ),
    );
  }
}

class _ArtPainter extends CustomPainter {
  _ArtPainter(this.kind);
  final String kind;
  @override
  void paint(Canvas c, Size s) {
    c.save();
    c.translate(s.width * .5, s.height * .5);
    final scale = math.min(s.width, s.height) / 100;
    c.scale(scale);
    final p = Paint();
    void box(
      double x,
      double y,
      double w,
      double h,
      int color, [
      double r = 5,
    ]) {
      p.color = Color(color);
      c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, y, w, h), Radius.circular(r)),
        p,
      );
    }

    p.color = const Color(0x14000000);
    c.drawOval(const Rect.fromLTWH(-31, 28, 62, 9), p);
    if (kind == 'book') {
      c.rotate(-.12);
      box(-27, -31, 49, 62, 0xFF3B8176);
      box(-21, -27, 39, 52, 0xFF9EC5A7);
      box(-17, -18, 26, 3, 0xFFE6F0DF);
      box(-17, -11, 19, 3, 0xFFE6F0DF);
      c.rotate(.5);
      box(22, -28, 6, 55, 0xFFE5A735, 1);
      box(22, -28, 6, 7, 0xFFEAB6A0, 1);
    } else if (kind == 'drink') {
      box(-23, -23, 46, 52, 0xFFF9BD62, 8);
      box(-20, -20, 40, 9, 0xFFFFD993);
      box(-26, -29, 52, 7, 0xFF3E6255, 4);
      box(7, -44, 5, 30, 0xFF3E6255, 2);
      box(-15, -5, 5, 24, 0x77FFFFFF, 2);
    } else if (kind == 'snack') {
      box(-33, -22, 66, 21, 0xFFE5A94F, 12);
      box(-35, -6, 70, 8, 0xFF4F804C, 4);
      box(-31, 3, 62, 8, 0xFFB65E37);
      box(-34, 11, 68, 16, 0xFFE5A94F, 7);
      for (var i = 0; i < 5; i++) {
        box(-23 + i * 10, -17, 3, 2, 0xFFFFE9C1, 1);
      }
    } else {
      c.rotate(-.08);
      box(-31, -24, 62, 51, 0xFF6E3D29, 7);
      box(-31, -27, 62, 40, 0xFF925433, 7);
      for (var i = 0; i < 9; i++) {
        box(
          -21 + (i % 3) * 19.0,
          -18 + (i ~/ 3) * 12.0,
          7,
          6,
          i.isEven ? 0xFFC99B60 : 0xFF4D2C23,
          2,
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant _ArtPainter oldDelegate) =>
      kind != oldDelegate.kind;
}
