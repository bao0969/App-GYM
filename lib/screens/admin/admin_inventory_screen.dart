// Tính năng mới: Quản lý kho - sản phẩm bán hàng
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/product_model.dart';
import '../../core/services/firestore_service.dart';

class AdminInventoryScreen extends StatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  State<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends State<AdminInventoryScreen> {
  final _db = FirestoreService();
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Quản Lý Kho',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductForm(),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Thêm SP',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          // Stats summary
          StreamBuilder<List<ProductModel>>(
            stream: _db.streamProducts(),
            builder: (context, snap) {
              final all = snap.data ?? [];
              final total = all.length;
              final lowStock = all.where((p) => p.isLowStock).length;
              final outOfStock = all.where((p) => p.isOutOfStock).length;
              final totalValue = all.fold<double>(
                0,
                (s, p) => s + p.price * p.stock,
              );

              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A1A28), Color(0xFF141420)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _statBox(
                          'Tổng SP',
                          total.toString(),
                          Icons.inventory_2_outlined,
                          AppColors.accent,
                        ),
                      ),
                      Expanded(
                        child: _statBox(
                          'Sắp hết',
                          lowStock.toString(),
                          Icons.warning_amber_rounded,
                          AppColors.warning,
                        ),
                      ),
                      Expanded(
                        child: _statBox(
                          'Hết hàng',
                          outOfStock.toString(),
                          Icons.cancel_outlined,
                          AppColors.error,
                        ),
                      ),
                      Expanded(
                        child: _statBox(
                          'Giá trị',
                          '${(totalValue / 1000000).toStringAsFixed(1)}M',
                          Icons.savings_outlined,
                          AppColors.success,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _filterChip('all', 'Tất cả'),
                _filterChip('low', 'Sắp hết'),
                _filterChip('out', 'Hết hàng'),
                _filterChip('inactive', 'Ngừng bán'),
              ],
            ),
          ),
          // List
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _db.streamProducts(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }
                var products = snap.data ?? [];
                products = _applyFilter(products);

                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'Không có sản phẩm',
                      style: TextStyle(color: AppColors.textHint),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: products.length,
                  itemBuilder: (_, i) => _ProductTile(
                    product: products[i],
                    onAdjust: (delta) => _db.adjustStock(products[i].id, delta),
                    onEdit: () => _showProductForm(existing: products[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final isSelected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _filter = value),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }

  List<ProductModel> _applyFilter(List<ProductModel> all) {
    switch (_filter) {
      case 'low':
        return all.where((p) => p.isLowStock && !p.isOutOfStock).toList();
      case 'out':
        return all.where((p) => p.isOutOfStock).toList();
      case 'inactive':
        return all.where((p) => !p.isActive).toList();
      default:
        return all;
    }
  }

  void _showProductForm({ProductModel? existing}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _ProductForm(
          existing: existing,
          onSubmit: (product) async {
            if (existing == null) {
              await _db.addProduct(product);
            } else {
              await _db.updateProduct(existing.id, product.toJson());
            }
          },
          onDelete: existing != null
              ? () async {
                  await _db.deleteProduct(existing.id);
                }
              : null,
        ),
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  final ProductModel product;
  final void Function(int delta) onAdjust;
  final VoidCallback onEdit;

  const _ProductTile({
    required this.product,
    required this.onAdjust,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    Color stockColor;
    if (product.isOutOfStock) {
      stockColor = AppColors.error;
    } else if (product.isLowStock) {
      stockColor = AppColors.warning;
    } else {
      stockColor = AppColors.success;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(product.category), color: stockColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!product.isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.textHint.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Ngừng',
                              style: TextStyle(
                                color: AppColors.textHint,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          product.categoryLabel,
                          style: const TextStyle(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                        Text(
                          NumberFormat.simpleCurrency(locale: 'vi_VN').format(product.price),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Stock control
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: stockColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, size: 16, color: stockColor),
                const SizedBox(width: 6),
                Text(
                  'Tồn: ${product.stock}',
                  style: TextStyle(
                    color: stockColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: AppColors.error,
                    size: 22,
                  ),
                  onPressed: product.stock > 0 ? () => onAdjust(-1) : null,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: AppColors.success,
                    size: 22,
                  ),
                  onPressed: () => onAdjust(1),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_box_outlined,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  tooltip: 'Nhập 10',
                  onPressed: () => onAdjust(10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconFor(ProductCategory c) {
    switch (c) {
      case ProductCategory.drink:
        return Icons.local_drink_rounded;
      case ProductCategory.supplement:
        return Icons.medication_rounded;
      case ProductCategory.apparel:
        return Icons.checkroom_rounded;
      case ProductCategory.accessory:
        return Icons.fitness_center_rounded;
      case ProductCategory.other:
        return Icons.shopping_bag_rounded;
    }
  }
}

class _ProductForm extends StatefulWidget {
  final ProductModel? existing;
  final Future<void> Function(ProductModel) onSubmit;
  final VoidCallback? onDelete;

  const _ProductForm({this.existing, required this.onSubmit, this.onDelete});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _costCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _thresholdCtrl;
  late TextEditingController _descCtrl;
  late ProductCategory _category;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _priceCtrl = TextEditingController(text: p?.price.toInt().toString() ?? '');
    _costCtrl = TextEditingController(
      text: p?.costPrice?.toInt().toString() ?? '',
    );
    _stockCtrl = TextEditingController(text: p?.stock.toString() ?? '0');
    _thresholdCtrl = TextEditingController(
      text: p?.lowStockThreshold.toString() ?? '5',
    );
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _category = p?.category ?? ProductCategory.drink;
    _isActive = p?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _thresholdCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final product = ProductModel(
      id: widget.existing?.id ?? '',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      price: double.tryParse(_priceCtrl.text) ?? 0,
      costPrice: _costCtrl.text.isEmpty
          ? null
          : double.tryParse(_costCtrl.text),
      stock: int.tryParse(_stockCtrl.text) ?? 0,
      lowStockThreshold: int.tryParse(_thresholdCtrl.text) ?? 5,
      isActive: _isActive,
      updatedAt: DateTime.now(),
    );

    await widget.onSubmit(product);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textHint,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                widget.existing == null ? 'Thêm Sản Phẩm' : 'Sửa Sản Phẩm',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _field(
                _nameCtrl,
                'Tên sản phẩm',
                validator: (v) => v == null || v.isEmpty ? 'Nhập tên SP' : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Loại',
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProductCategory.values.map((c) {
                  final isSelected = _category == c;
                  final label = ProductModel(
                    id: '',
                    name: '',
                    category: c,
                    price: 0,
                    updatedAt: DateTime.now(),
                  ).categoryLabel;
                  return ChoiceChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) => setState(() => _category = c),
                    backgroundColor: AppColors.surfaceLight,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _priceCtrl,
                      'Giá bán (VNĐ)',
                      keyboardType: TextInputType.number,
                      validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0
                          ? 'Nhập giá'
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      _costCtrl,
                      'Giá nhập',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: _field(
                      _stockCtrl,
                      'Tồn kho',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _field(
                      _thresholdCtrl,
                      'Ngưỡng cảnh báo',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              _field(_descCtrl, 'Mô tả (tuỳ chọn)', maxLines: 2),
              SwitchListTile(
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                title: const Text(
                  'Đang bán',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppColors.success,
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Lưu',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
              ),
              if (widget.onDelete != null) ...[
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    widget.onDelete!();
                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  label: const Text(
                    'Xoá sản phẩm',
                    style: TextStyle(color: AppColors.error),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: const TextStyle(color: AppColors.textPrimary),
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AppColors.textHint, fontSize: 12),
          filled: true,
          fillColor: AppColors.surfaceLight,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
