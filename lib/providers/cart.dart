import 'package:flutter/foundation.dart';

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.title,
    required this.quantity,
    required this.price,
    this.imageUrl = '',
  });

  final String id;
  final String productId;
  final String title;
  final int quantity;
  final double price;
  final String imageUrl;

  double get total => price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        id: id,
        productId: productId,
        title: title,
        quantity: quantity ?? this.quantity,
        price: price,
        imageUrl: imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'title': title,
        'quantity': quantity,
        'price': price,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: (json['id'] as String?) ?? '',
        productId: (json['productId'] as String?) ?? '',
        title: (json['title'] as String?) ?? '',
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        price: (json['price'] as num?)?.toDouble() ?? 0,
      );
}

/// Items the shopper has added, keyed by product id.
class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  /// Number of different products in the cart.
  int get itemCount => _items.length;

  /// Total number of units across all products.
  int get unitCount => _items.values.fold(0, (sum, i) => sum + i.quantity);

  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.total);

  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  void addItem(String productId, double price, String title,
      {String imageUrl = ''}) {
    final existing = _items[productId];
    if (existing != null) {
      _items[productId] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      _items[productId] = CartItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        productId: productId,
        title: title,
        price: price,
        quantity: 1,
        imageUrl: imageUrl,
      );
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    final existing = _items[productId];
    if (existing == null) return;
    if (existing.quantity > 1) {
      _items[productId] = existing.copyWith(quantity: existing.quantity - 1);
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
