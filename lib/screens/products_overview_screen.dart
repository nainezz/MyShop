import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/http_exception.dart';
import '../models/phone_options.dart';
import '../providers/cart.dart';
import '../providers/products.dart';
import '../widgets/app_drawer.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductsOverviewScreen extends StatefulWidget {
  const ProductsOverviewScreen({super.key});

  @override
  State<ProductsOverviewScreen> createState() => _ProductsOverviewScreenState();
}

class _ProductsOverviewScreenState extends State<ProductsOverviewScreen> {
  late Future<void> _loading;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loading = context.read<Products>().fetchAndSetProducts();
    _searchController.text = context.read<Products>().query;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final future = context.read<Products>().fetchAndSetProducts();
    setState(() => _loading = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.shopName),
        actions: [
          Consumer<Cart>(
            builder: (_, cart, __) => IconButton(
              tooltip: 'Cart',
              onPressed: () =>
                  Navigator.of(context).pushNamed(CartScreen.routeName),
              icon: Badge(
                isLabelVisible: cart.unitCount > 0,
                label: Text('${cart.unitCount}'),
                child: const Icon(Icons.shopping_cart_outlined),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return _Message(
              icon: Icons.cloud_off,
              title: 'Could not load phones',
              body: error is HttpException
                  ? error.message
                  : 'Check your connection and try again.',
              action: FilledButton(
                  onPressed: _refresh, child: const Text('Try again')),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _ShopBody(searchController: _searchController),
          );
        },
      ),
    );
  }
}

class _ShopBody extends StatelessWidget {
  const _ShopBody({required this.searchController});

  final TextEditingController searchController;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<Products>();
    final visible = products.visibleItems;
    final theme = Theme.of(context);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SearchBar(
                  controller: searchController,
                  hintText: 'Search phones, e.g. "13 Pro" or "256GB"',
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  trailing: [
                    if (products.query.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          searchController.clear();
                          products.setQuery('');
                        },
                      ),
                  ],
                  onChanged: products.setQuery,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _choice(context, 'All brands', products.brand == null,
                          () => products.setBrand(null)),
                      for (final b in products.availableBrands)
                        _choice(context, b, products.brand == b,
                            () => products.setBrand(products.brand == b ? null : b)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(value: 'all', label: Text('All')),
                        ButtonSegment(value: 'UK', label: Text('ex-UK')),
                        ButtonSegment(value: 'USA', label: Text('ex-USA')),
                      ],
                      selected: {products.origin ?? 'all'},
                      onSelectionChanged: (s) => products
                          .setOrigin(s.first == 'all' ? null : s.first),
                    ),
                    FilterChip(
                      avatar: Icon(
                        products.favoritesOnly
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                      ),
                      label: const Text('Favourites'),
                      selected: products.favoritesOnly,
                      showCheckmark: false,
                      onSelected: products.setFavoritesOnly,
                    ),
                    MenuAnchor(
                      builder: (context, controller, _) => ActionChip(
                        avatar: const Icon(Icons.sort, size: 18),
                        label: Text(products.sort.label),
                        onPressed: () => controller.isOpen
                            ? controller.close()
                            : controller.open(),
                      ),
                      menuChildren: [
                        for (final s in SortOrder.values)
                          MenuItemButton(
                            leadingIcon: Icon(products.sort == s
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked),
                            onPressed: () => products.setSort(s),
                            child: Text(s.label),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${visible.length} ${visible.length == 1 ? 'phone' : 'phones'}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                    if (products.hasActiveFilters)
                      TextButton(
                        onPressed: () {
                          searchController.clear();
                          products.clearFilters();
                        },
                        child: const Text('Clear filters'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (visible.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: products.items.isEmpty
                ? const _Message(
                    icon: Icons.inventory_2_outlined,
                    title: 'No phones listed yet',
                    body:
                        'Add your first phone from the menu: Manage my listings.',
                  )
                : const _Message(
                    icon: Icons.search_off,
                    title: 'No matches',
                    body: 'Try another search or clear the filters.',
                  ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 280,
                mainAxisExtent: 340,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => ChangeNotifierProvider.value(
                  value: visible[i],
                  child: const ProductCard(),
                ),
                childCount: visible.length,
              ),
            ),
          ),
      ],
    );
  }

  Widget _choice(
      BuildContext context, String label, bool selected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message(
      {required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(title,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
