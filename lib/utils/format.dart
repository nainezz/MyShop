import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config.dart';
import '../providers/orders.dart';
import '../providers/product.dart';

final _money = NumberFormat.decimalPattern('en_US');

/// "KES 45,000" (whole shillings) or "KES 412.50".
String formatMoney(double value) {
  final hasCents = value != value.roundToDouble();
  final text = hasCents
      ? NumberFormat('#,##0.00', 'en_US').format(value)
      : _money.format(value.round());
  return '${AppConfig.currency} $text';
}

String formatDateTime(DateTime value) =>
    DateFormat('d MMM yyyy, HH:mm').format(value);

/// Opens WhatsApp with a ready-made message to the shop.
Future<bool> openWhatsApp(String message) {
  final uri = Uri.parse(
      'https://wa.me/${AppConfig.whatsappNumber}?text=${Uri.encodeComponent(message)}');
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

String productEnquiry(Product p) {
  final specs = p.specs.isEmpty ? '' : ' (${p.specs.join(', ')})';
  return 'Hi, I\'m interested in the ${p.title}$specs for ${formatMoney(p.price)}. Is it available?';
}

String orderMessage(OrderItem order) {
  final lines = [
    'Hi, I just placed order #${order.shortId} on ${AppConfig.shopName}:',
    for (final item in order.products)
      '- ${item.quantity} x ${item.title}: ${formatMoney(item.total)}',
    'Total: ${formatMoney(order.amount)}',
    if (order.phone.isNotEmpty) 'My phone: ${order.phone}',
    if (order.deliveryNote.isNotEmpty) 'Delivery: ${order.deliveryNote}',
  ];
  return lines.join('\n');
}
