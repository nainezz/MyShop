/// Fixed choices used by the product form and the shop filters.
class PhoneOptions {
  static const brands = [
    'iPhone',
    'Samsung',
    'Pixel',
    'OnePlus',
    'Motorola',
    'Sony',
    'Huawei',
    'Infinix',
    'Other',
  ];

  static const storages = ['32GB', '64GB', '128GB', '256GB', '512GB', '1TB'];

  static const grades = ['A+', 'A', 'B'];

  static const gradeLabels = {
    'A+': 'Like new',
    'A': 'Excellent',
    'B': 'Good',
  };

  static const origins = ['UK', 'USA'];

  static String originLabel(String origin) =>
      origin == 'UK' ? 'ex-UK' : origin == 'USA' ? 'ex-USA' : origin;
}

enum SortOrder { newest, priceLowToHigh, priceHighToLow }

extension SortOrderLabel on SortOrder {
  String get label => switch (this) {
        SortOrder.newest => 'Newest first',
        SortOrder.priceLowToHigh => 'Price: low to high',
        SortOrder.priceHighToLow => 'Price: high to low',
      };
}
