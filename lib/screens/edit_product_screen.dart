import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config.dart';
import '../models/http_exception.dart';
import '../models/phone_options.dart';
import '../providers/product.dart';
import '../providers/products.dart';
import '../widgets/product_image.dart';

/// Add a new phone, or edit one when opened with a product id.
class EditProductScreen extends StatefulWidget {
  const EditProductScreen({super.key});

  static const routeName = '/edit-product';

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _battery = TextEditingController();
  final _imageUrl = TextEditingController();
  final _description = TextEditingController();

  Product? _editing;
  String _brand = PhoneOptions.brands.first;
  String? _storage;
  String? _grade;
  String? _origin;
  bool _inStock = true;
  bool _isSaving = false;
  bool _initialised = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialised) return;
    _initialised = true;
    final id = ModalRoute.of(context)?.settings.arguments as String?;
    if (id == null) return;
    final p = context.read<Products>().findById(id);
    _editing = p;
    _title.text = p.title;
    _price.text = p.price == p.price.roundToDouble()
        ? p.price.toStringAsFixed(0)
        : p.price.toString();
    _battery.text = p.batteryHealth?.toString() ?? '';
    _imageUrl.text = p.imageUrl;
    _description.text = p.description;
    _brand = PhoneOptions.brands.contains(p.brand) ? p.brand : 'Other';
    _storage = PhoneOptions.storages.contains(p.storage) ? p.storage : null;
    _grade = PhoneOptions.grades.contains(p.grade) ? p.grade : null;
    _origin = PhoneOptions.origins.contains(p.origin) ? p.origin : null;
    _inStock = p.inStock;
  }

  @override
  void dispose() {
    for (final c in [_title, _price, _battery, _imageUrl, _description]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final products = context.read<Products>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final battery = int.tryParse(_battery.text.trim());
    final base = _editing ??
        Product(id: '', title: '', description: '', price: 0, imageUrl: '');
    final product = base.copyWith(
      title: _title.text.trim(),
      price: double.parse(_price.text.replaceAll(',', '').trim()),
      imageUrl: _imageUrl.text.trim(),
      description: _description.text.trim(),
      brand: _brand,
      storage: _storage ?? '',
      grade: _grade ?? '',
      origin: _origin ?? '',
      batteryHealth: battery,
      clearBatteryHealth: battery == null,
      inStock: _inStock,
    );

    try {
      if (_editing == null) {
        await products.addProduct(product);
      } else {
        await products.updateProduct(_editing!.id, product);
      }
      navigator.pop();
    } on HttpException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
          content: Text('Could not save. Check your connection.')));
    }
    if (mounted) setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing == null ? 'Add a phone' : 'Edit listing'),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _brand,
                  decoration: const InputDecoration(labelText: 'Brand'),
                  items: [
                    for (final b in PhoneOptions.brands)
                      DropdownMenuItem(value: b, child: Text(b)),
                  ],
                  onChanged: (v) => setState(() => _brand = v ?? 'Other'),
                ),
                gap,
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(
                      labelText: 'Model', hintText: 'e.g. iPhone 13 Pro'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter the model name.' : null,
                ),
                gap,
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _storage,
                        decoration: const InputDecoration(labelText: 'Storage'),
                        items: [
                          for (final s in PhoneOptions.storages)
                            DropdownMenuItem(value: s, child: Text(s)),
                        ],
                        onChanged: (v) => setState(() => _storage = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _grade,
                        decoration: const InputDecoration(labelText: 'Grade'),
                        items: [
                          for (final g in PhoneOptions.grades)
                            DropdownMenuItem(
                              value: g,
                              child: Text(
                                  '$g · ${PhoneOptions.gradeLabels[g]}'),
                            ),
                        ],
                        onChanged: (v) => setState(() => _grade = v),
                      ),
                    ),
                  ],
                ),
                gap,
                Text('Imported from',
                    style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 6),
                SegmentedButton<String>(
                  emptySelectionAllowed: true,
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(value: 'UK', label: Text('ex-UK')),
                    ButtonSegment(value: 'USA', label: Text('ex-USA')),
                  ],
                  selected: {if (_origin != null) _origin!},
                  onSelectionChanged: (s) =>
                      setState(() => _origin = s.isEmpty ? null : s.first),
                ),
                gap,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(
                            labelText: 'Price',
                            prefixText: '${AppConfig.currency} '),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          final n = double.tryParse(
                              (v ?? '').replaceAll(',', '').trim());
                          if (n == null) return 'Enter a number.';
                          if (n <= 0) return 'Price must be above zero.';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _battery,
                        decoration: const InputDecoration(
                            labelText: 'Battery health (optional)',
                            suffixText: '%'),
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if ((v ?? '').trim().isEmpty) return null;
                          final n = int.tryParse(v!.trim());
                          if (n == null || n < 1 || n > 100) {
                            return 'Enter 1 to 100.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                gap,
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(
                      labelText: 'Photo link (optional)',
                      hintText: 'https://...'),
                  keyboardType: TextInputType.url,
                  onChanged: (_) => setState(() {}),
                  validator: (v) {
                    final t = (v ?? '').trim();
                    if (t.isEmpty) return null;
                    return t.startsWith('http://') || t.startsWith('https://')
                        ? null
                        : 'Use a link starting with http:// or https://';
                  },
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      height: 180, child: ProductImage(_imageUrl.text)),
                ),
                gap,
                TextFormField(
                  controller: _description,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Condition, colour, what is in the box, warranty...',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                ),
                gap,
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('In stock'),
                  subtitle: const Text('Turn off to show it as sold out.'),
                  value: _inStock,
                  onChanged: (v) => setState(() => _inStock = v),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5))
                : Text(_editing == null ? 'Add to shop' : 'Save changes'),
          ),
        ),
      ),
    );
  }
}
