import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/http_exception.dart';
import '../providers/products.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';
import '../widgets/product_image.dart';
import 'edit_product_screen.dart';

/// The seller's own listings: add, edit and delete.
class UserProductsScreen extends StatefulWidget {
  const UserProductsScreen({super.key});

  static const routeName = '/user-products';

  @override
  State<UserProductsScreen> createState() => _UserProductsScreenState();
}

class _UserProductsScreenState extends State<UserProductsScreen> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = context.read<Products>().fetchAndSetProducts();
  }

  Future<void> _refresh() async {
    final future = context.read<Products>().fetchAndSetProducts();
    setState(() => _loading = future);
    await future;
  }

  Future<void> _confirmDelete(String id, String title) async {
    final products = context.read<Products>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete listing?'),
        content: Text('"$title" will be removed from the shop.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await products.deleteProduct(id);
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage my listings')),
      drawer: const AppDrawer(),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add phone'),
        onPressed: () =>
            Navigator.of(context).pushNamed(EditProductScreen.routeName),
      ),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final mine = context.watch<Products>().myItems;
          if (mine.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'You have no listings yet. Tap "Add phone" to list your first one.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: mine.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = mine[i];
                    return Card(
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                              width: 48,
                              height: 48,
                              child: ProductImage(p.imageUrl)),
                        ),
                        title: Text(p.title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text([
                          formatMoney(p.price),
                          ...p.specs.take(2),
                          if (!p.inStock) 'Sold out',
                        ].join(' · ')),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Edit',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => Navigator.of(context).pushNamed(
                                  EditProductScreen.routeName,
                                  arguments: p.id),
                            ),
                            IconButton(
                              tooltip: 'Delete',
                              icon: const Icon(Icons.delete_outline),
                              color: Theme.of(context).colorScheme.error,
                              onPressed: () => _confirmDelete(p.id, p.title),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
