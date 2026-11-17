import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/http_exception.dart';
import 'cart.dart';

/// Where an order is in its life. Stored as the enum name in Firebase.
enum OrderStatus { pending, confirmed, delivered, cancelled }

extension OrderStatusLabel on OrderStatus {
  String get label => switch (this) {
        OrderStatus.pending => 'Pending',
        OrderStatus.confirmed => 'Confirmed',
        OrderStatus.delivered => 'Delivered',
        OrderStatus.cancelled => 'Cancelled',
      };

  static OrderStatus parse(String? value) => OrderStatus.values.firstWhere(
        (s) => s.name == value,
        orElse: () => OrderStatus.pending,
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.amount,
    required this.products,
    required this.dateTime,
    this.status = OrderStatus.pending,
    this.phone = '',
    this.deliveryNote = '',
  });

  final String id;
  final double amount;
  final List<CartItem> products;
  final DateTime dateTime;
  final OrderStatus status;
  final String phone;
  final String deliveryNote;

  int get unitCount => products.fold(0, (sum, p) => sum + p.quantity);

  /// Order number shown to the customer: the last 6 characters of the id.
  String get shortId =>
      id.length > 6 ? id.substring(id.length - 6).toUpperCase() : id;

  factory OrderItem.fromJson(String id, Map<String, dynamic> json) {
    final products = (json['products'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(CartItem.fromJson)
        .toList();
    return OrderItem(
      id: id,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      dateTime: DateTime.tryParse((json['dateTime'] as String?) ?? '') ??
          DateTime.now(),
      products: products,
      status: OrderStatusLabel.parse(json['status'] as String?),
      phone: (json['phone'] as String?) ?? '',
      deliveryNote: (json['deliveryNote'] as String?) ?? '',
    );
  }
}

class Orders with ChangeNotifier {
  String? _authToken;
  String? _userId;
  List<OrderItem> _orders = [];

  void updateAuth(String? token, String? userId) {
    if (userId != _userId) {
      _orders = [];
    }
    _authToken = token;
    _userId = userId;
  }

  List<OrderItem> get orders => [..._orders];

  Uri get _url => Uri.parse(
      '${AppConfig.databaseUrl}/orders/$_userId.json?auth=$_authToken');

  Future<void> fetchAndSetOrders() async {
    final response = await http.get(_url);
    if (response.statusCode >= 400) {
      throw HttpException('Could not load your orders.');
    }
    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      _orders = [];
      notifyListeners();
      return;
    }
    final loaded = data.entries
        .where((e) => e.value is Map<String, dynamic>)
        .map((e) => OrderItem.fromJson(e.key, e.value as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.dateTime.compareTo(a.dateTime));
    _orders = loaded;
    notifyListeners();
  }

  /// Saves the order and returns it, so the app can offer to send it on WhatsApp.
  Future<OrderItem> addOrder(
    List<CartItem> cartProducts,
    double total, {
    String phone = '',
    String deliveryNote = '',
  }) async {
    final timestamp = DateTime.now();
    final response = await http.post(
      _url,
      body: json.encode({
        'amount': total,
        'dateTime': timestamp.toIso8601String(),
        'status': OrderStatus.pending.name,
        'phone': phone,
        'deliveryNote': deliveryNote,
        'products': cartProducts.map((cp) => cp.toJson()).toList(),
      }),
    );
    if (response.statusCode >= 400) {
      throw HttpException('Could not place the order. Please try again.');
    }
    final order = OrderItem(
      id: json.decode(response.body)['name'] as String,
      amount: total,
      dateTime: timestamp,
      products: cartProducts,
      phone: phone,
      deliveryNote: deliveryNote,
    );
    _orders.insert(0, order);
    notifyListeners();
    return order;
  }
}
