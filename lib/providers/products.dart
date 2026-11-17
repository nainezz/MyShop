import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/http_exception.dart';
import '../models/phone_options.dart';
import 'product.dart';

/// The shop's product list, plus the search, filter and sort the shopper picked.
class Products with ChangeNotifier {
  String? _authToken;
  String? _userId;
  List<Product> _items = [];

  // Shopper's current view of the list.
  String _query = '';
  String? _brand;
  String? _origin;
  bool _favoritesOnly = false;
  SortOrder _sort = SortOrder.newest;

  /// Called by the provider whenever the login changes.
  void updateAuth(String? token, String? userId) {
    final userChanged = userId != _userId;
    _authToken = token;
    _userId = userId;
    if (userChanged) {
      _items = [];
    }
  }

  List<Product> get items => [..._items];

  String get query => _query;
  String? get brand => _brand;
  String? get origin => _origin;
  bool get favoritesOnly => _favoritesOnly;
  SortOrder get sort => _sort;

  bool get hasActiveFilters =>
      _query.isNotEmpty || _brand != null || _origin != null || _favoritesOnly;

  /// Brands that actually appear in the shop, in the standard order.
  List<String> get availableBrands {
    final present = _items.map((p) => p.brand).toSet();
    return PhoneOptions.brands.where(present.contains).toList();
  }

  /// The list after search, filters and sorting.
  List<Product> get visibleItems {
    final q = _query.trim().toLowerCase();
    final result = _items.where((p) {
      if (_favoritesOnly && !p.isFavorite) return false;
      if (_brand != null && p.brand != _brand) return false;
      if (_origin != null && p.origin != _origin) return false;
      if (q.isNotEmpty) {
        final haystack =
            '${p.title} ${p.brand} ${p.storage} ${p.description}'.toLowerCase();
        if (!haystack.contains(q)) return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case SortOrder.newest:
        result.sort((a, b) => (b.createdAt ?? DateTime(2000))
            .compareTo(a.createdAt ?? DateTime(2000)));
      case SortOrder.priceLowToHigh:
        result.sort((a, b) => a.price.compareTo(b.price));
      case SortOrder.priceHighToLow:
        result.sort((a, b) => b.price.compareTo(a.price));
    }
    return result;
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setBrand(String? value) {
    _brand = value;
    notifyListeners();
  }

  void setOrigin(String? value) {
    _origin = value;
    notifyListeners();
  }

  void setFavoritesOnly(bool value) {
    _favoritesOnly = value;
    notifyListeners();
  }

  void setSort(SortOrder value) {
    _sort = value;
    notifyListeners();
  }

  void clearFilters() {
    _query = '';
    _brand = null;
    _origin = null;
    _favoritesOnly = false;
    notifyListeners();
  }

  Product findById(String id) => _items.firstWhere((p) => p.id == id);

  /// Adds a product locally without saving it. For tests only.
  @visibleForTesting
  void debugAdd(Product product) {
    _items.add(product);
    notifyListeners();
  }

  /// Products created by the logged-in seller.
  List<Product> get myItems =>
      _items.where((p) => p.creatorId == _userId).toList();

  Uri _url(String path, [String extra = '']) => Uri.parse(
      '${AppConfig.databaseUrl}/$path.json?auth=$_authToken$extra');

  /// Loads every product and the user's favourites.
  Future<void> fetchAndSetProducts() async {
    final response = await http.get(_url('products'));
    if (response.statusCode >= 400) {
      throw HttpException('Could not load products (${response.statusCode}).');
    }
    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      _items = [];
      notifyListeners();
      return;
    }

    final favResponse = await http.get(_url('userFavorites/$_userId'));
    final favData = json.decode(favResponse.body);
    final favorites =
        favData is Map<String, dynamic> ? favData : const <String, dynamic>{};

    _items = data.entries
        .where((e) => e.value is Map<String, dynamic>)
        .map((e) => Product.fromJson(
              e.key,
              e.value as Map<String, dynamic>,
              isFavorite: favorites[e.key] == true,
            ))
        .toList();
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final now = DateTime.now();
    final body = {
      ...product.copyWith(createdAt: now).toJson(),
      'creatorId': _userId,
    };
    final response =
        await http.post(_url('products'), body: json.encode(body));
    if (response.statusCode >= 400) {
      throw HttpException('Could not save the product.');
    }
    final id = json.decode(response.body)['name'] as String;
    _items.add(product.copyWith(id: id, creatorId: _userId, createdAt: now));
    notifyListeners();
  }

  Future<void> updateProduct(String id, Product updated) async {
    final index = _items.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final response = await http.patch(
      _url('products/$id'),
      body: json.encode(updated.toJson()),
    );
    if (response.statusCode >= 400) {
      throw HttpException('Could not update the product.');
    }
    _items[index] = updated;
    notifyListeners();
  }

  /// Removes the product straight away; puts it back if the delete fails.
  Future<void> deleteProduct(String id) async {
    final index = _items.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final existing = _items.removeAt(index);
    notifyListeners();
    final response = await http.delete(_url('products/$id'));
    if (response.statusCode >= 400) {
      _items.insert(index, existing);
      notifyListeners();
      throw HttpException('Could not delete the product.');
    }
  }
}
