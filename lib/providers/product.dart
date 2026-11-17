import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

/// A phone listed in the shop.
///
/// Older products saved before the phone fields existed still load:
/// missing fields fall back to empty values and the brand "Other".
class Product with ChangeNotifier {
  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    this.brand = 'Other',
    this.storage = '',
    this.grade = '',
    this.origin = '',
    this.batteryHealth,
    this.inStock = true,
    this.creatorId = '',
    this.createdAt,
    this.isFavorite = false,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final String brand;
  final String storage;
  final String grade;
  final String origin;
  final int? batteryHealth;
  final bool inStock;
  final String creatorId;
  final DateTime? createdAt;
  bool isFavorite;

  factory Product.fromJson(String id, Map<String, dynamic> json,
      {bool isFavorite = false}) {
    // Tolerant readers: older records may hold numbers as text and so on.
    String text(String key, [String fallback = '']) =>
        json[key]?.toString() ?? fallback;
    double? number(String key) {
      final v = json[key];
      if (v is num) return v.toDouble();
      return double.tryParse(v?.toString().replaceAll(',', '') ?? '');
    }

    return Product(
      id: id,
      title: text('title', 'Untitled'),
      description: text('description'),
      price: number('price') ?? 0,
      imageUrl: text('imageUrl'),
      brand: text('brand', 'Other'),
      storage: text('storage'),
      grade: text('grade'),
      origin: text('origin'),
      batteryHealth: number('batteryHealth')?.round(),
      inStock: json['inStock'] is bool ? json['inStock'] as bool : true,
      creatorId: text('creatorId'),
      createdAt: DateTime.tryParse(text('createdAt')),
      isFavorite: isFavorite,
    );
  }

  /// Fields saved to Firebase. The id is the database key, not a field.
  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'brand': brand,
        'storage': storage,
        'grade': grade,
        'origin': origin,
        'batteryHealth': batteryHealth,
        'inStock': inStock,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  Product copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    String? imageUrl,
    String? brand,
    String? storage,
    String? grade,
    String? origin,
    int? batteryHealth,
    bool clearBatteryHealth = false,
    bool? inStock,
    String? creatorId,
    DateTime? createdAt,
    bool? isFavorite,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      brand: brand ?? this.brand,
      storage: storage ?? this.storage,
      grade: grade ?? this.grade,
      origin: origin ?? this.origin,
      batteryHealth:
          clearBatteryHealth ? null : (batteryHealth ?? this.batteryHealth),
      inStock: inStock ?? this.inStock,
      creatorId: creatorId ?? this.creatorId,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  /// Short spec line, e.g. "128GB · Grade A · ex-UK".
  List<String> get specs => [
        if (storage.isNotEmpty) storage,
        if (grade.isNotEmpty) 'Grade $grade',
        if (origin.isNotEmpty) origin == 'UK' ? 'ex-UK' : 'ex-USA',
        if (batteryHealth != null) 'Battery $batteryHealth%',
      ];

  /// Flips the favourite flag straight away and saves it; undoes it if saving fails.
  Future<void> toggleFavoriteStatus(String token, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();
    final url = Uri.parse(
        '${AppConfig.databaseUrl}/userFavorites/$userId/$id.json?auth=$token');
    try {
      final response = await http.put(url, body: json.encode(isFavorite));
      if (response.statusCode >= 400) {
        isFavorite = oldStatus;
        notifyListeners();
      }
    } catch (_) {
      isFavorite = oldStatus;
      notifyListeners();
    }
  }
}
