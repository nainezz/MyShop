import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth.dart';
import '../providers/cart.dart';
import '../providers/product.dart';
import '../screens/product_detail_screen.dart';
import '../utils/format.dart';
import 'product_image.dart';
import 'spec_chips.dart';

/// One phone in the shop grid. Expects a [Product] from a ChangeNotifierProvider.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key});

  @override
  Widget build(BuildContext context) {
    final product = context.watch<Product>();
    final auth = context.read<Auth>();
    final cart = context.read<Cart>();
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context)
            .pushNamed(ProductDetailScreen.routeName, arguments: product.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: product.id,
                    child: ProductImage(product.imageUrl),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip: product.isFavorite
                          ? 'Remove from favourites'
                          : 'Add to favourites',
                      icon: Icon(product.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border),
                      color: product.isFavorite ? Colors.redAccent : null,
                      onPressed: () => product.toggleFavoriteStatus(
                          auth.token ?? '', auth.userId ?? ''),
                    ),
                  ),
                  if (!product.inStock)
                    Positioned(
                      left: 8,
                      top: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text('Sold out',
                            style: TextStyle(
                                color: theme.colorScheme.onError,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand == 'Other' ? '' : product.brand,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  if (product.specs.isNotEmpty)
                    SpecChips(product.specs.take(3).toList(), dense: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 4, 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      formatMoney(product.price),
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Add to cart',
                    icon: const Icon(Icons.add_shopping_cart),
                    onPressed: !product.inStock
                        ? null
                        : () {
                            cart.addItem(
                                product.id, product.price, product.title,
                                imageUrl: product.imageUrl);
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.hideCurrentSnackBar();
                            messenger.showSnackBar(SnackBar(
                              content: Text('${product.title} added to cart'),
                              duration: const Duration(seconds: 2),
                              action: SnackBarAction(
                                label: 'UNDO',
                                onPressed: () =>
                                    cart.removeSingleItem(product.id),
                              ),
                            ));
                          },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
