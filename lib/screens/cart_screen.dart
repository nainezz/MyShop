import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/http_exception.dart';
import '../providers/cart.dart';
import '../providers/orders.dart';
import '../utils/format.dart';
import '../widgets/product_image.dart';
import 'orders_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static const routeName = '/cart';

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<Cart>();
    final theme = Theme.of(context);
    final items = cart.items.entries.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 56, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text('Your cart is empty',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Browse phones'),
                  ),
                ],
              ),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final productId = items[i].key;
                    final item = items[i].value;
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(Icons.delete_outline,
                            color: theme.colorScheme.onError),
                      ),
                      onDismissed: (_) => cart.removeItem(productId),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: SizedBox(
                                  width: 64,
                                  height: 64,
                                  child: ProductImage(item.imageUrl),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.title,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w700)),
                                    Text(formatMoney(item.price),
                                        style: TextStyle(
                                            color: theme.colorScheme
                                                .onSurfaceVariant)),
                                  ],
                                ),
                              ),
                              IconButton(
                                tooltip: 'One less',
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () =>
                                    cart.removeSingleItem(productId),
                              ),
                              Text('${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
                              IconButton(
                                tooltip: 'One more',
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => cart.addItem(
                                    productId, item.price, item.title,
                                    imageUrl: item.imageUrl),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total (${cart.unitCount} items)',
                              style: theme.textTheme.bodySmall),
                          Text(formatMoney(cart.totalAmount),
                              style: theme.textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                    FilledButton(
                      onPressed: () => _checkout(context),
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _checkout(BuildContext context) async {
    final cart = context.read<Cart>();
    final orders = context.read<Orders>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final details = await showDialog<(String, String)>(
      context: context,
      builder: (_) => const _CheckoutDialog(),
    );
    if (details == null) return;

    try {
      final order = await orders.addOrder(
        cart.items.values.toList(),
        cart.totalAmount,
        phone: details.$1,
        deliveryNote: details.$2,
      );
      cart.clear();
      if (!context.mounted) return;
      final sendNow = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, size: 40),
          title: Text('Order #${order.shortId} placed'),
          content: const Text(
              'Send the order on WhatsApp so we can confirm availability and delivery.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Later')),
            FilledButton.icon(
              onPressed: () => Navigator.of(ctx).pop(true),
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Send on WhatsApp'),
            ),
          ],
        ),
      );
      if (sendNow == true) {
        await openWhatsApp(orderMessage(order));
      }
      navigator.pushReplacementNamed(OrdersScreen.routeName);
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not place the order. Check your connection.')));
    }
  }
}

/// Asks for a phone number and delivery details before placing the order.
class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog();

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _phone = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delivery details'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone number',
                hintText: '07XX XXX XXX',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
                return digits.length < 9 ? 'Enter a valid phone number.' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Delivery location or note (optional)',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context)
                  .pop((_phone.text.trim(), _note.text.trim()));
            }
          },
          child: const Text('Place order'),
        ),
      ],
    );
  }
}
