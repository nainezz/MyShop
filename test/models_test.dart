import 'package:flutter_test/flutter_test.dart';
import 'package:myshop/models/phone_options.dart';
import 'package:myshop/providers/cart.dart';
import 'package:myshop/providers/orders.dart';
import 'package:myshop/providers/product.dart';
import 'package:myshop/providers/products.dart';
import 'package:myshop/utils/format.dart';

void main() {
  group('Product', () {
    test('loads an old product saved before the phone fields existed', () {
      final p = Product.fromJson('p1', {
        'title': 'Red Shirt',
        'description': 'A red shirt',
        'price': 30,
        'imageUrl': '',
      });
      expect(p.brand, 'Other');
      expect(p.price, 30.0);
      expect(p.inStock, isTrue);
      expect(p.specs, isEmpty);
    });

    test('reads prices and numbers stored as text', () {
      final p = Product.fromJson('p2', {
        'title': 'Old item',
        'price': '29.99',
        'batteryHealth': '87',
        'inStock': 'yes',
      });
      expect(p.price, 29.99);
      expect(p.batteryHealth, 87);
      expect(p.inStock, isTrue);
    });

    test('round-trips phone fields through JSON', () {
      final p = Product(
        id: 'x',
        title: 'iPhone 13',
        description: '',
        price: 58000,
        imageUrl: '',
        brand: 'iPhone',
        storage: '128GB',
        grade: 'A',
        origin: 'UK',
        batteryHealth: 88,
      );
      final back = Product.fromJson('x', p.toJson());
      expect(back.brand, 'iPhone');
      expect(back.batteryHealth, 88);
      expect(back.specs, ['128GB', 'Grade A', 'ex-UK', 'Battery 88%']);
    });
  });

  group('Cart', () {
    test('adds, counts and removes items', () {
      final cart = Cart()
        ..addItem('a', 1000, 'Phone A')
        ..addItem('a', 1000, 'Phone A')
        ..addItem('b', 500, 'Phone B');
      expect(cart.itemCount, 2);
      expect(cart.unitCount, 3);
      expect(cart.totalAmount, 2500);
      cart.removeSingleItem('a');
      expect(cart.quantityOf('a'), 1);
      cart.removeSingleItem('a');
      expect(cart.quantityOf('a'), 0);
    });
  });

  group('Products filters', () {
    Products seeded() {
      final products = Products();
      // Uses fetch-free seeding through the public API surface.
      for (final p in [
        Product(id: '1', title: 'iPhone 13', description: '', price: 58000, imageUrl: '', brand: 'iPhone', origin: 'UK', storage: '128GB'),
        Product(id: '2', title: 'Galaxy S22', description: '', price: 42000, imageUrl: '', brand: 'Samsung', origin: 'USA', storage: '256GB'),
        Product(id: '3', title: 'Pixel 7', description: '', price: 35500, imageUrl: '', brand: 'Pixel', origin: 'UK', storage: '128GB'),
      ]) {
        products.debugAdd(p);
      }
      return products;
    }

    test('search, brand, origin and sort combine', () {
      final products = seeded();
      products.setSort(SortOrder.priceLowToHigh);
      expect(products.visibleItems.map((p) => p.id), ['3', '2', '1']);
      products.setOrigin('UK');
      expect(products.visibleItems.map((p) => p.id), ['3', '1']);
      products.setQuery('128');
      products.setBrand('iPhone');
      expect(products.visibleItems.map((p) => p.id), ['1']);
      products.clearFilters();
      expect(products.visibleItems.length, 3);
      expect(products.availableBrands, ['iPhone', 'Samsung', 'Pixel']);
    });
  });

  group('Orders and formatting', () {
    test('old orders without a status load as pending', () {
      final o = OrderItem.fromJson('-Nabc123xyz', {
        'amount': 1200,
        'dateTime': '2022-10-01T10:00:00.000',
        'products': [
          {'id': '1', 'title': 'Shirt', 'quantity': 2, 'price': 600}
        ],
      });
      expect(o.status, OrderStatus.pending);
      expect(o.unitCount, 2);
      expect(o.shortId, '123XYZ');
    });

    test('formats Kenyan shillings', () {
      expect(formatMoney(45000), 'KES 45,000');
      expect(formatMoney(412.5), 'KES 412.50');
    });
  });
}
