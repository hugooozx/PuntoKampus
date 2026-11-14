import 'package:flutter/foundation.dart';

import 'models.dart';

class DemoStore extends ChangeNotifier {
  DemoStore(this.persistence);
  final DemoPersistence persistence;
  List<Person> people = [];
  List<Shop> shops = [];
  List<Product> products = [];
  List<Purchase> orders = [];
  List<PremiumRequest> premiumRequests = [];
  Map<String, DateTime> reports = {};
  Map<String, int> cart = {};
  String? currentUserId = 'lucia';
  String? storageError;
  int sequence = 124;
  Future<void> _saving = Future.value();
  Person? get user => people.where((e) => e.id == currentUserId).firstOrNull;
  Shop? get ownShop => shops.where((e) => e.owner == currentUserId).firstOrNull;
  Shop shop(String id) => shops.firstWhere((e) => e.id == id);
  Product product(String id) => products.firstWhere((e) => e.id == id);
  List<Product> productsOf(String id) =>
      products.where((e) => e.shopId == id && !e.deleted).toList();
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  int get cartTotal =>
      cart.entries.fold(0, (sum, e) => sum + product(e.key).price * e.value);
  Shop? get cartShop =>
      cart.isEmpty ? null : shop(product(cart.keys.first).shopId);

  Future<void> initialize() async {
    try {
      final data = await persistence.read();
      if (data == null || data['version'] != 1) {
        seed();
      } else {
        people = (data['people'] as List)
            .map((e) => Person.fromJson(e))
            .toList();
        shops = (data['shops'] as List).map((e) => Shop.fromJson(e)).toList();
        products = (data['products'] as List)
            .map((e) => Product.fromJson(e))
            .toList();
        orders = (data['orders'] as List)
            .map((e) => Purchase.fromJson(e))
            .toList();
        premiumRequests = (data['premiumRequests'] as List)
            .map((e) => PremiumRequest.fromJson(e))
            .toList();
        reports = (data['reports'] as Map).map(
          (key, value) => MapEntry(key as String, DateTime.parse(value)),
        );
        currentUserId = data['currentUserId'];
        sequence = data['sequence'];
        cart = Map<String, int>.from(data['cart'] ?? {});
      }
      expireOrders();
    } catch (_) {
      seed();
      storageError = 'No pudimos recuperar la sesión de prueba. Cargamos los ejemplos iniciales.';
    }
    notifyListeners();
  }

  void seed() {
    people = [
      Person('lucia', 'Lucía Torres', 'lucia.demo@utb.edu.ec'),
      Person('ana', 'Ana Pérez', 'ana.demo@utb.edu.ec'),
      Person('mateo', 'Mateo Ruiz', 'mateo.demo@utb.edu.ec'),
      Person('diego', 'Diego Vera', 'diego.demo@utb.edu.ec'),
    ];
    shops = [
      Shop(
        id: 'ana',
        owner: 'ana',
        name: 'Dulces de Ana',
        description: 'Brownies, galletas y empanadas hechas en casa.',
        category: 'Postres y dulces',
        secondary: 'Comida',
        point: 'Biblioteca',
        kind: 'bakery',
      ),
      Shop(
        id: 'pausa',
        owner: 'diego',
        name: 'Pausa Fría',
        description: 'Jugos y café frío para el receso.',
        category: 'Bebidas',
        point: 'Entrada de FAFI',
        kind: 'drink',
      ),
      Shop(
        id: 'papel',
        owner: 'lucia',
        name: 'Papel y Tinta',
        description: 'Cuadernos, separadores e impresiones.',
        category: 'Útiles y papelería',
        secondary: 'Servicios',
        point: 'Biblioteca',
        premium: true,
        kind: 'book',
      ),
      Shop(
        id: 'snack',
        owner: 'javier',
        name: 'Punto Snack',
        description: 'Sánduches y snacks en el campus.',
        category: 'Comida',
        point: 'Entrada de FACIAG',
        kind: 'snack',
      ),
    ];
    products = [
      Product(
        id: 'brownie',
        shopId: 'ana',
        name: 'Brownie de chocolate',
        description: 'Brownie individual de chocolate, hecho en casa.',
        price: 150,
        kind: 'bakery',
      ),
      Product(
        id: 'empanada',
        shopId: 'ana',
        name: 'Empanada de queso',
        description: 'Empanada horneada con queso.',
        price: 125,
        kind: 'snack',
      ),
      Product(
        id: 'galleta',
        shopId: 'ana',
        name: 'Galleta de avena',
        description: 'Galleta individual de avena.',
        price: 75,
        available: false,
        kind: 'cookie',
      ),
      Product(
        id: 'jugo',
        shopId: 'pausa',
        name: 'Jugo de naranja',
        description: 'Jugo natural en botella de 350 ml.',
        price: 100,
        kind: 'drink',
      ),
      Product(
        id: 'cafe',
        shopId: 'pausa',
        name: 'Café frío',
        description: 'Café frío con leche, 350 ml.',
        price: 175,
        kind: 'coffee',
      ),
      Product(
        id: 'cuaderno',
        shopId: 'papel',
        name: 'Cuaderno artesanal',
        description: 'Cuaderno de 60 hojas para tus ideas.',
        price: 350,
        kind: 'book',
      ),
      Product(
        id: 'sanduche',
        shopId: 'snack',
        name: 'Sánduche de pollo',
        description: 'Pan fresco con pollo y vegetales.',
        price: 225,
        kind: 'snack',
      ),
    ];
    final now = DateTime.now();
    orders = [
      Purchase(
        code: 'PK-000123',
        buyerId: 'mateo',
        buyerName: 'Mateo Ruiz',
        shopId: 'papel',
        shopName: 'Papel y Tinta',
        items: [OrderItem('cuaderno', 'Cuaderno artesanal', 350, 1)],
        point: 'Biblioteca',
        delivery: now.add(const Duration(hours: 2)),
        payment: 'Efectivo',
      ),
      Purchase(
        code: 'PK-000102',
        buyerId: 'lucia',
        buyerName: 'Lucía Torres',
        shopId: 'pausa',
        shopName: 'Pausa Fría',
        items: [OrderItem('jugo', 'Jugo de naranja', 100, 1)],
        point: 'Entrada de FAFI',
        delivery: now.subtract(const Duration(days: 1)),
        payment: 'Efectivo',
        status: 'entregado',
      ),
    ];
    premiumRequests = [];
    reports = {};
    cart = {};
    sequence = 124;
    currentUserId = 'lucia';
  }

  Map<String, dynamic> snapshot() => {
    'version': 1,
    'people': people.map((e) => e.toJson()).toList(),
    'shops': shops.map((e) => e.toJson()).toList(),
    'products': products.map((e) => e.toJson()).toList(),
    'orders': orders.map((e) => e.toJson()).toList(),
    'premiumRequests': premiumRequests.map((e) => e.toJson()).toList(),
    'reports': reports.map(
      (key, value) => MapEntry(key, value.toIso8601String()),
    ),
    'cart': Map.of(cart),
    'currentUserId': currentUserId,
    'sequence': sequence,
  };
  void changed() {
    final data = snapshot();
    _saving = _saving.then((_) => persistence.write(data)).catchError((
      Object _,
    ) {
      storageError = 'Los cambios siguen disponibles en esta sesión, pero no pudimos guardarlos en este dispositivo.';
      notifyListeners();
    });
    notifyListeners();
  }

  Future<void> get saved => _saving;
  void switchPerson(String? id) {
    if (id != null && !people.any((person) => person.id == id)) return;
    if (currentUserId != null && currentUserId != id) cart.clear();
    currentUserId = id;
    changed();
  }

  void reset() {
    seed();
    storageError = null;
    changed();
  }

  List<Shop> findShops(String query, String category) => shops
      .where(
        (s) =>
            s.active &&
            (category.isEmpty ||
                s.category == category ||
                s.secondary == category) &&
            normalized(
              '${s.name} ${s.description} ${productsOf(s.id).map((p) => '${p.name} ${p.description}').join(' ')}',
            ).contains(normalized(query)),
      )
      .toList();
  List<Product> findProducts(String query, String category) =>
      products.where((p) {
        final s = shop(p.shopId);
        return !p.deleted &&
            s.active &&
            (category.isEmpty ||
                s.category == category ||
                s.secondary == category) &&
            normalized('${p.name} ${p.description} ${s.name} ${s.description}')
                .contains(normalized(query));
      }).toList();
  bool needsCartReplacement(Product p) =>
      cartShop != null && cartShop!.id != p.shopId;
  void addToCart(Product p, int quantity, {bool replace = false}) {
    if (!p.available || p.deleted || !shop(p.shopId).active) {
      throw StateError('Este producto ya no está disponible.');
    }
    if (shop(p.shopId).owner == currentUserId) {
      throw StateError('No puedes pedir a tu propia tienda.');
    }
    if (quantity < 1 || quantity > 20) {
      throw StateError('Elige una cantidad de 1 a 20.');
    }
    if (needsCartReplacement(p)) {
      if (!replace) {
        throw StateError('Tu carrito tiene productos de otra tienda.');
      }
      cart.clear();
    }
    final totalQuantity = (cart[p.id] ?? 0) + quantity;
    if (totalQuantity > 20) {
      throw StateError('Puedes llevar hasta 20 unidades de cada producto.');
    }
    cart[p.id] = totalQuantity;
    changed();
  }

  void setQuantity(String id, int value) {
    if (value < 1 || value > 20) return;
    cart[id] = value;
    changed();
  }

  void removeFromCart(String id) {
    cart.remove(id);
    changed();
  }

  static String? validateDelivery(DateTime date, DateTime now) {
    if (date.isBefore(now.add(const Duration(minutes: 30)))) {
      return 'Elige una hora al menos 30 minutos después de ahora.';
    }
    if (date.isAfter(now.add(const Duration(days: 7)))) {
      return 'Elige una fecha dentro de los próximos 7 días.';
    }
    return null;
  }

  Purchase checkout(
    String point,
    DateTime delivery,
    String payment,
    String note, {
    DateTime? now,
  }) {
    if (user == null) throw StateError('Entra con tu cuenta para continuar.');
    if (cart.isEmpty) throw StateError('Tu carrito está vacío.');
    final validation = validateDelivery(delivery, now ?? DateTime.now());
    if (validation != null) throw StateError(validation);
    if (!deliveryPoints.contains(point) ||
        !['Efectivo', 'Transferencia', 'Deuna'].contains(payment) ||
        note.length > 200) {
      throw StateError('Revisa los datos de entrega y pago.');
    }
    final s = cartShop!;
    if (!s.active || s.owner == currentUserId) {
      throw StateError('No puedes pedir a esta tienda.');
    }
    final items = cart.entries.map((e) {
      final p = product(e.key);
      if (!p.available || p.deleted) {
        throw StateError(
          '${p.name} se agotó mientras armabas tu pedido. Quítalo del carrito para continuar.',
        );
      }
      return OrderItem(p.id, p.name, p.price, e.value);
    }).toList();
    final order = Purchase(
      code: 'PK-${(sequence++).toString().padLeft(6, '0')}',
      buyerId: user!.id,
      buyerName: user!.name,
      shopId: s.id,
      shopName: s.name,
      items: items,
      point: point,
      delivery: delivery,
      payment: payment,
      note: note.trim(),
    );
    orders.insert(0, order);
    cart.clear();
    changed();
    return order;
  }

  void changeOrder(Purchase order, String status) {
    expireOrders();
    final seller = shop(order.shopId).owner == currentUserId;
    if (order.status != 'pendiente' ||
        !['entregado', 'cancelado'].contains(status) ||
        (!seller &&
            !(order.buyerId == currentUserId && status == 'cancelado'))) {
      throw StateError('Este pedido ya no se puede cambiar.');
    }
    order.status = status;
    changed();
  }

  void expireOrders() {
    for (final order in orders) {
      if (order.status == 'pendiente' &&
          DateTime.now().isAfter(
            order.delivery.add(const Duration(hours: 24)),
          )) {
        order.status = 'vencido';
      }
    }
  }

  void submitReport(Shop s, String reason, String detail) {
    if (user == null || s.owner == currentUserId) {
      throw StateError('No puedes reportar esta tienda.');
    }
    if (![
      'Producto prohibido',
      'No entregó el pedido',
      'Información falsa',
      'Trato inadecuado',
      'Otro',
    ].contains(reason)) {
      throw StateError('Elige un motivo.');
    }
    if (reason == 'Otro' && detail.trim().isEmpty) {
      throw StateError('Cuéntanos qué pasó para enviar el reporte.');
    }
    if (detail.length > 300) {
      throw StateError('El detalle admite hasta 300 caracteres.');
    }
    final key = '${user!.id}:${s.id}';
    if (reports[key] != null &&
        DateTime.now().difference(reports[key]!) < const Duration(hours: 24)) {
      throw StateError(
        'Ya reportaste esta tienda hoy. Puedes volver a hacerlo en 24 horas.',
      );
    }
    reports[key] = DateTime.now();
    changed();
  }

  PremiumRequest? get currentPremiumRequest =>
      premiumRequests.where((e) => e.shopId == ownShop?.id).firstOrNull;
  void requestPremium(String number, int amount, String receipt) {
    if (ownShop == null) throw StateError('Primero crea tu tienda.');
    if (currentPremiumRequest?.status == 'pendiente') {
      throw StateError('Ya tienes un comprobante en revisión.');
    }
    if (number.trim().isEmpty || amount <= 0 || receipt.isEmpty) {
      throw StateError('Completa todos los datos del comprobante.');
    }
    premiumRequests.insert(
      0,
      PremiumRequest(ownShop!.id, number.trim(), amount, receipt),
    );
    changed();
  }
}
