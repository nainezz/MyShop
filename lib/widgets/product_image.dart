import 'package:flutter/material.dart';

/// Product photo with a neutral phone icon when there is no image or it fails to load.
class ProductImage extends StatelessWidget {
  const ProductImage(this.url, {super.key, this.fit = BoxFit.cover});

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.smartphone,
          size: 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
    if (url.trim().isEmpty) return placeholder;
    return Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : placeholder,
    );
  }
}
