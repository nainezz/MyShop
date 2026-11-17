import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../providers/auth.dart';
import '../screens/orders_screen.dart';
import '../screens/user_products_screen.dart';
import '../theme.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<Auth>();
    return NavigationDrawer(
      children: [
        Container(
          color: brandInk,
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppConfig.shopName,
                style: TextStyle(
                    color: Colors.white, fontFamily: 'Anton', fontSize: 28),
              ),
              const SizedBox(height: 4),
              Text(
                auth.email ?? '',
                style: const TextStyle(color: Color(0xFF8B93A1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: const Text('Shop'),
          onTap: () => Navigator.of(context).pushReplacementNamed('/'),
        ),
        ListTile(
          leading: const Icon(Icons.receipt_long_outlined),
          title: const Text('My orders'),
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(OrdersScreen.routeName),
        ),
        ListTile(
          leading: const Icon(Icons.inventory_2_outlined),
          title: const Text('Manage my listings'),
          onTap: () => Navigator.of(context)
              .pushReplacementNamed(UserProductsScreen.routeName),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Log out'),
          onTap: () {
            final authProvider = context.read<Auth>();
            Navigator.of(context).popUntil((route) => route.isFirst);
            authProvider.logout();
          },
        ),
      ],
    );
  }
}
