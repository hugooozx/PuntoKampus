import 'dart:convert';

const categories = [
  'Comida',
  'Postres y dulces',
  'Bebidas',
  'Ropa y accesorios',
  'Tecnología',
  'Útiles y papelería',
  'Servicios',
  'Otros',
];
const deliveryPoints = [
  'Biblioteca',
  'Entrada de FAFI',
  'Entrada de FACIAG',
  'Entrada de Ciencias de la Salud',
];

String normalized(String value) {
  const accents = {
    'á': 'a',
    'é': 'e',
    'í': 'i',
    'ó': 'o',
    'ú': 'u',
    'ü': 'u',
    'ñ': 'n',
  };
  var result = value.toLowerCase().trim();
  accents.forEach((key, value) => result = result.replaceAll(key, value));
  return result;
}

String money(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';
String day(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
String clock(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
String dateTime(DateTime date) => '${day(date)} · ${clock(date)}';

class Person {
  Person(
    this.id,
    this.name,
    this.email, {
    this.showPhone = false,
    this.seller = const {},
  });
  final String id;
  String name;
  final String email;
  bool showPhone;
  Map<String, String> seller;
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'showPhone': showPhone,
    'seller': seller,
  };
  factory Person.fromJson(Map<String, dynamic> data) => Person(
    data['id'],
    data['name'],
    data['email'],
    showPhone: data['showPhone'] ?? false,
    seller: Map<String, String>.from(data['seller'] ?? {}),
  );
}

class Shop {
  Shop({
    required this.id,
    required this.owner,
    required this.name,
    required this.description,
    required this.category,
    required this.point,
    this.secondary = '',
    this.hours = 'Lun–vie, 08:00–14:00',
    this.premium = false,
    this.active = true,
    this.kind = 'shop',
  });
  final String id;
  final String owner;
  String name, description, category, secondary, point, hours, kind;
  bool premium, active;
  String get badge => premium ? 'Sacó 10' : 'Matriculado';
  String get slug =>
      normalized(name)
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          .replaceAll(RegExp(r'^-|-$'), '');
  Map<String, dynamic> toJson() => {
    'id': id,
    'owner': owner,
    'name': name,
    'description': description,
    'category': category,
    'secondary': secondary,
    'point': point,
    'hours': hours,
    'premium': premium,
    'active': active,
    'kind': kind,
  };
  factory Shop.fromJson(Map<String, dynamic> d) => Shop(
    id: d['id'],
    owner: d['owner'],
    name: d['name'],
    description: d['description'],
    category: d['category'],
    secondary: d['secondary'] ?? '',
    point: d['point'],
    hours: d['hours'],
    premium: d['premium'],
    active: d['active'],
    kind: d['kind'],
  );
}

class Product {
  Product({
    required this.id,
    required this.shopId,
    required this.name,
    required this.description,
    required this.price,
    this.available = true,
    this.deleted = false,
    this.kind = 'product',
  });
  final String id, shopId;
  String name, description, kind;
  int price;
  bool available, deleted;
  Map<String, dynamic> toJson() => {
    'id': id,
    'shopId': shopId,
    'name': name,
    'description': description,
    'price': price,
    'available': available,
    'deleted': deleted,
    'kind': kind,
  };
  factory Product.fromJson(Map<String, dynamic> d) => Product(
    id: d['id'],
    shopId: d['shopId'],
    name: d['name'],
    description: d['description'],
    price: d['price'],
    available: d['available'],
    deleted: d['deleted'],
    kind: d['kind'],
  );
}

class OrderItem {
  OrderItem(this.productId, this.name, this.price, this.quantity);
  final String productId, name;
  final int price, quantity;
  int get subtotal => price * quantity;
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'name': name,
    'price': price,
    'quantity': quantity,
  };
  factory OrderItem.fromJson(Map<String, dynamic> d) =>
      OrderItem(d['productId'], d['name'], d['price'], d['quantity']);
}

class Purchase {
  Purchase({
    required this.code,
    required this.buyerId,
    required this.buyerName,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.point,
    required this.delivery,
    required this.payment,
    this.note = '',
    this.status = 'pendiente',
  });
  final String code, buyerId, buyerName, shopId, shopName, point, payment, note;
  final DateTime delivery;
  final List<OrderItem> items;
  String status;
  int get total => items.fold(0, (total, item) => total + item.subtotal);
  Map<String, dynamic> toJson() => {
    'code': code,
    'buyerId': buyerId,
    'buyerName': buyerName,
    'shopId': shopId,
    'shopName': shopName,
    'items': items.map((e) => e.toJson()).toList(),
    'point': point,
    'delivery': delivery.toIso8601String(),
    'payment': payment,
    'note': note,
    'status': status,
  };
  factory Purchase.fromJson(Map<String, dynamic> d) => Purchase(
    code: d['code'],
    buyerId: d['buyerId'],
    buyerName: d['buyerName'],
    shopId: d['shopId'],
    shopName: d['shopName'],
    items: (d['items'] as List).map((e) => OrderItem.fromJson(e)).toList(),
    point: d['point'],
    delivery: DateTime.parse(d['delivery']),
    payment: d['payment'],
    note: d['note'],
    status: d['status'],
  );
  String get message =>
      'Hola, soy $buyerName. Te hice un pedido por PuntoKampus ($code):\n${items.map((e) => '- ${e.quantity} x ${e.name}: ${money(e.subtotal)}').join('\n')}\nTotal: ${money(total)}\nEntrega: $point, ${dateTime(delivery)}\nPago: $payment${note.isEmpty ? '' : '\nNota: $note'}';
}

class PremiumRequest {
  PremiumRequest(
    this.shopId,
    this.number,
    this.amount,
    this.receiptName, {
    this.status = 'pendiente',
  });
  final String shopId, number, receiptName;
  final int amount;
  String status;
  Map<String, dynamic> toJson() => {
    'shopId': shopId,
    'number': number,
    'amount': amount,
    'receiptName': receiptName,
    'status': status,
  };
  factory PremiumRequest.fromJson(Map<String, dynamic> d) => PremiumRequest(
    d['shopId'],
    d['number'],
    d['amount'],
    d['receiptName'],
    status: d['status'],
  );
}

abstract interface class DemoPersistence {
  Future<Map<String, dynamic>?> read();
  Future<void> write(Map<String, dynamic> data);
}

class MemoryPersistence implements DemoPersistence {
  Map<String, dynamic>? data;
  @override
  Future<Map<String, dynamic>?> read() async => data;
  @override
  Future<void> write(Map<String, dynamic> value) async =>
      data = jsonDecode(jsonEncode(value));
}
