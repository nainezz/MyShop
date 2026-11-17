import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/orders.dart';
import '../utils/format.dart';
import '../widgets/app_drawer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  static const routeName = '/orders';

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<void> _loading;

  @override
  void initState() {
    super.initState();
    _loading = context.read<Orders>().fetchAndSetOrders();
  }

  Future<void> _refresh() async {
    final future = context.read<Orders>().fetchAndSetOrders();
    setState(() => _loading = future);
    await future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My orders')),
      drawer: const AppDrawer(),
      body: FutureBuilder<void>(
        future: _loading,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your orders.'),
                  const SizedBox(height: 12),
                  FilledButton(
                      onPressed: _refresh, child: const Text('Try again')),
                ],
              ),
            );
          }
          final orders = context.watch<Orders>().orders;
          if (orders.isEmpty) {
            return const Center(child: Text('You have no orders yet.'));
          }
          return RefreshIndicator(
            onRefresh: _refresh,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _OrderTile(orders[i]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile(this.order);

  final OrderItem order;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Text('Order #${order.shortId}',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            _StatusChip(order.status),
          ],
        ),
        subtitle: Text(
            '${formatDateTime(order.dateTime)} · ${order.unitCount} items · ${formatMoney(order.amount)}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final p in order.products)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(child: Text(p.title)),
                  Text('${p.quantity} × ${formatMoney(p.price)}',
                      style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          if (order.deliveryNote.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  const Icon(Icons.place_outlined, size: 18),
                  const SizedBox(width: 6),
                  Expanded(child: Text(order.deliveryNote)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              icon: const Icon(Icons.chat_outlined),
              label: const Text('Ask about this order'),
              onPressed: () => openWhatsApp(orderMessage(order)),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip(this.status);

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg) = switch (status) {
      OrderStatus.pending => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      OrderStatus.confirmed => (scheme.secondaryContainer, scheme.onSecondaryContainer),
      OrderStatus.delivered => (scheme.primaryContainer, scheme.onPrimaryContainer),
      OrderStatus.cancelled => (scheme.errorContainer, scheme.onErrorContainer),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(status.label,
          style:
              TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
    );
  }
}
