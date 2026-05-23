// Tính năng mới: Màn hình POS - Bán hàng tại quầy
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/order_model.dart';
import '../../core/models/product_model.dart';
import '../../core/models/sale_model.dart';
import '../../core/services/firestore_service.dart';
import '../../providers/auth_provider.dart';

class AdminPosScreen extends StatefulWidget {
  const AdminPosScreen({super.key});

  @override
  State<AdminPosScreen> createState() => _AdminPosScreenState();
}

class _AdminPosScreenState extends State<AdminPosScreen> {
  final _db = FirestoreService();
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<String, int> _cart = {}; // productId -> quantity
  Map<String, ProductModel> _productCache = {};
  ProductCategory? _categoryFilter;
  String _searchQuery = '';
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  bool _processing = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  double get _cartTotal => _cart.entries.fold(0, (s, e) {
    final p = _productCache[e.key];
    return s + (p?.price ?? 0) * e.value;
  });

  int get _cartCount => _cart.values.fold(0, (s, q) => s + q);

  void _addToCart(ProductModel p) {
    if (p.isOutOfStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sản phẩm đã hết hàng'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final current = _cart[p.id] ?? 0;
    if (current >= p.stock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chỉ còn ${p.stock} sản phẩm trong kho'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() {
      _cart[p.id] = current + 1;
    });
  }

  void _removeFromCart(String productId) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current <= 1) {
        _cart.remove(productId);
      } else {
        _cart[productId] = current - 1;
      }
    });
  }

  Future<void> _checkout() async {
    if (_cart.isEmpty) return;
    setState(() => _processing = true);

    try {
      final auth = context.read<AuthProvider>();
      final items = _cart.entries.map((e) {
        final p = _productCache[e.key]!;
        return SaleItem(
          productId: p.id,
          productName: p.name,
          quantity: e.value,
          unitPrice: p.price,
        );
      }).toList();

      final sale = SaleModel(
        id: '',
        items: items,
        total: _cartTotal,
        finalAmount: _cartTotal,
        paymentMethod: _paymentMethod,
        staffId: auth.user?.uid,
        staffName: auth.user?.name,
        createdAt: DateTime.now(),
      );

      await _db.createSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tạo đơn thành công: ${NumberFormat.simpleCurrency(locale: 'vi_VN').format(_cartTotal)} - ${items.length} sản phẩm',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        setState(() {
          _cart.clear();
          _processing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: AppColors.error),
        );
        setState(() => _processing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 720;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(
          'POS - Bán Hàng',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  Widget _buildWideLayout() {
    return Row(
      children: [
        Expanded(flex: 2, child: _buildProductPanel()),
        Container(width: 1, color: Colors.white.withValues(alpha: 0.05)),
        SizedBox(width: 360, child: _buildCartPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Stack(
      children: [
        _buildProductPanel(),
        if (_cartCount > 0)
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: AppColors.surface,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    builder: (_) => SizedBox(
                      height: MediaQuery.of(context).size.height * 0.85,
                      child: _buildCartPanel(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shopping_cart_rounded,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_cartCount sản phẩm',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        NumberFormat.simpleCurrency(locale: 'vi_VN').format(_cartTotal),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductPanel() {
    return Column(
      children: [
        // Search + filter
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _searchCtrl,
                onChanged: (v) =>
                    setState(() => _searchQuery = v.toLowerCase()),
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Tìm sản phẩm...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _categoryChip(null, 'Tất cả'),
                    ...ProductCategory.values.map(
                      (c) => _categoryChip(
                        c,
                        ProductModel(
                          id: '',
                          name: '',
                          category: c,
                          price: 0,
                          updatedAt: DateTime.now(),
                        ).categoryLabel,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _db.streamProducts(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              var products = (snap.data ?? [])
                  .where((p) => p.isActive)
                  .toList();

              if (_categoryFilter != null) {
                products = products
                    .where((p) => p.category == _categoryFilter)
                    .toList();
              }
              if (_searchQuery.isNotEmpty) {
                products = products
                    .where((p) => p.name.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              _productCache = {for (final p in products) p.id: p};

              if (products.isEmpty) {
                return const Center(
                  child: Text(
                    'Không có sản phẩm',
                    style: TextStyle(color: AppColors.textHint),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                itemCount: products.length,
                itemBuilder: (_, i) => _ProductCard(
                  product: products[i],
                  inCart: _cart[products[i].id] ?? 0,
                  onTap: () => _addToCart(products[i]),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(ProductCategory? c, String label) {
    final isSelected = _categoryFilter == c;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _categoryFilter = c),
        backgroundColor: AppColors.surfaceLight,
        selectedColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCartPanel() {
    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(
                  Icons.shopping_cart_rounded,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Giỏ Hàng',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (_cart.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _cart.clear()),
                    child: const Text(
                      'Xoá hết',
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: AppColors.textHint,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Giỏ hàng trống',
                          style: TextStyle(color: AppColors.textHint),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: _cart.entries.map((e) {
                      final p = _productCache[e.key];
                      if (p == null) return const SizedBox.shrink();
                      return _CartItem(
                        product: p,
                        quantity: e.value,
                        onIncrease: () => _addToCart(p),
                        onDecrease: () => _removeFromCart(p.id),
                      );
                    }).toList(),
                  ),
          ),
          if (_cart.isNotEmpty) _buildCheckoutPanel(),
        ],
      ),
    );
  }

  Widget _buildCheckoutPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Payment method
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _payChip(
                  PaymentMethod.cash,
                  'Tiền mặt',
                  Icons.payments_outlined,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _payChip(
                  PaymentMethod.transfer,
                  'Chuyển khoản',
                  Icons.account_balance_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              Text(
                NumberFormat.simpleCurrency(locale: 'vi_VN').format(_cartTotal),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _processing ? null : _checkout,
            icon: _processing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(_processing ? 'Đang xử lý...' : 'Hoàn Tất Đơn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _payChip(PaymentMethod m, String label, IconData icon) {
    final isSelected = _paymentMethod == m;
    return InkWell(
      onTap: () => setState(() => _paymentMethod = m),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.15)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final int inCart;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.inCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isOut = product.isOutOfStock;
    final isLow = product.isLowStock && !isOut;

    return InkWell(
      onTap: isOut ? null : onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart > 0
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.05),
            width: inCart > 0 ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon thay cho ảnh
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        _categoryIcon(product.category),
                        color: AppColors.primary.withValues(alpha: 0.6),
                        size: 40,
                      ),
                    ),
                    if (inCart > 0)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '×$inCart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    if (isOut || isLow)
                      Positioned(
                        bottom: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isOut ? AppColors.error : AppColors.warning,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isOut ? 'HẾT HÀNG' : 'CÒN ${product.stock}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              NumberFormat.simpleCurrency(locale: 'vi_VN').format(product.price),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(ProductCategory c) {
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

class _CartItem extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onIncrease;
  final VoidCallback onDecrease;

  const _CartItem({
    required this.product,
    required this.quantity,
    required this.onIncrease,
    required this.onDecrease,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${NumberFormat.simpleCurrency(locale: 'vi_VN').format(product.price)} × $quantity',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.error,
                  size: 22,
                ),
                onPressed: onDecrease,
              ),
              Text(
                '$quantity',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.success,
                  size: 22,
                ),
                onPressed: onIncrease,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
