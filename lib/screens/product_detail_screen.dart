import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/phone_options.dart';
import '../providers/auth.dart';
import '../providers/cart.dart';
import '../providers/product.dart';
import '../providers/products.dart';
import '../utils/format.dart';
import '../widgets/product_image.dart';
import 'cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  static const routeName = '/product-detail';

  @override
  Widget build(BuildContext context) {
    final productId = ModalRoute.of(context)!.settings.arguments as String;
    final product = context.read<Products>().findById(productId);
    return ChangeNotifierProvider.value(
      value: product,
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final product = context.watch<Product>();
    final auth = context.read<Auth>();
    final cart = context.watch<Cart>();
    final theme = Theme.of(context);
    final inCart = cart.quantityOf(product.id);

    final specRows = <(String, String)>[
      if (product.brand != 'Other') ('Brand', product.brand),
      if (product.storage.isNotEmpty) ('Storage', product.storage),
      if (product.grade.isNotEmpty)
        (
          'Grade',
          '${product.grade} · ${PhoneOptions.gradeLabels[product.grade] ?? ''}'
        ),
      if (product.origin.isNotEmpty)
        ('Imported from', PhoneOptions.originLabel(product.origin)),
      if (product.batteryHealth != null)
        ('Battery health', '${product.batteryHealth}%'),
      ('Availability', product.inStock ? 'In stock' : 'Sold out'),
    ];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 360,
            pinned: true,
            actions: [
              IconButton(
                tooltip: product.isFavorite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                icon: Icon(
                    product.isFavorite ? Icons.favorite : Icons.favorite_border),
                color: product.isFavorite ? Colors.redAccent : null,
                onPressed: () => product.toggleFavoriteStatus(
                    auth.token ?? '', auth.userId ?? ''),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Hero(
                tag: product.id,
                child: ProductImage(product.imageUrl),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product.brand != 'Other')
                        Text(product.brand,
                            style: theme.textTheme.labelLarge
                                ?.copyWith(color: theme.colorScheme.primary)),
                      Text(product.title,
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      Text(formatMoney(product.price),
                          style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary)),
                      const SizedBox(height: 20),
                      Card(
                        child: Column(
                          children: [
                            for (final (label, value) in specRows)
                              ListTile(
                                dense: true,
                                title: Text(label,
                                    style: TextStyle(
                                        color: theme
                                            .colorScheme.onSurfaceVariant)),
                                trailing: Text(value,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700)),
                              ),
                          ],
                        ),
                      ),
                      if (product.origin.isNotEmpty || product.brand != 'Other')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            icon: const Icon(Icons.price_check),
                            label: const Text(
                                'Compare ex-UK and ex-USA prices for this model'),
                            onPressed: () =>
                                openLink(AppConfig.priceCheckerUrl),
                          ),
                        ),
                      if (product.description.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text('About this phone',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(product.description,
                            style: theme.textTheme.bodyLarge),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_outlined),
                  label: const Text('Ask on WhatsApp'),
                  onPressed: () => openWhatsApp(productEnquiry(product)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  icon: Icon(inCart > 0
                      ? Icons.shopping_cart
                      : Icons.add_shopping_cart),
                  label: Text(!product.inStock
                      ? 'Sold out'
                      : inCart > 0
                          ? 'In cart ($inCart) · View'
                          : 'Add to cart'),
                  onPressed: !product.inStock
                      ? null
                      : () {
                          if (inCart > 0) {
                            Navigator.of(context)
                                .pushNamed(CartScreen.routeName);
                          } else {
                            cart.addItem(
                                product.id, product.price, product.title,
                                imageUrl: product.imageUrl);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
