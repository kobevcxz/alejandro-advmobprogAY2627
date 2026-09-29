import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../services/cart_service.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class CartScreen extends StatefulWidget {
  final int userId;

  const CartScreen({super.key, this.userId = 1});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Color _accentBlue = Colors.lightBlue.shade600;
  final Color _lightBlueBg = Colors.lightBlue.shade50;

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () {
            Navigator.maybePop(context);
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          'Cart',
          style: TextStyle(fontSize: 19.sp, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.h),
          child: Divider(height: 1, color: Colors.grey.withValues(alpha: 0.2)),
        ),
      ),
      body: FutureBuilder<void>(
        future: cartProvider.loadCart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _accentBlue));
          }

          if (snapshot.hasError) {
            return _message(
              icon: Icons.error_outline,
              title: 'Unable to load your cart',
              description: 'Please check your connection and try again.',
            );
          }

          final cart = cartProvider.cart;

          if (cart == null || cart.products.isEmpty) {
            return _message(
              icon: Icons.shopping_cart_outlined,
              title: 'Your cart is empty',
              description: 'Add products from the shop to see them here.',
            );
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(18.w, 22.h, 18.w, 38.h),
            children: [
              Text(
                '${cart.totalQuantity} ${cart.totalQuantity == 1 ? 'item' : 'items'}',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 14.h),
              ...cart.products.map(_cartItem),
              SizedBox(height: 8.h),
              _orderSummary(cart),
              SizedBox(height: 26.h),
              SizedBox(
                width: double.infinity,
                height: 54.h,
                child: ElevatedButton(
                  onPressed: () {
                    _confirmOrder(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                  child: Text(
                    'Proceed to Checkout',
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _cartItem(CartProduct item) {
    final theme = Theme.of(context);
    final discountedPrice = _discountedUnitPrice(item);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.lightBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () async {
          final product = await CartService().getProductById(item.id);

          if (!mounted) return;

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) {
                return ProductDetailsScreen(
                  product: product,
                  showAddToCart: false,
                );
              },
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(14.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 92.w,
                height: 92.w,
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: _lightBlueBg.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(13.r),
                ),
                child: Image.network(
                  item.thumbnail,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) {
                    return Icon(
                      Icons.image_not_supported_outlined,
                      size: 28.sp,
                      color: theme.disabledColor,
                    );
                  },
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: item.title,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 7.h),
                    Row(
                      children: [
                        Text(
                          '₱${discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.bold,
                            color: _accentBlue,
                          ),
                        ),
                        if (item.discountPercentage > 0) ...[
                          SizedBox(width: 7.w),
                          Flexible(
                            child: Text(
                              '₱${item.price.toStringAsFixed(2)}',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: theme.disabledColor,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.discountPercentage > 0) ...[
                      SizedBox(height: 5.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 7.w,
                          vertical: 3.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(5.r),
                        ),
                        child: Text(
                          '${item.discountPercentage.toStringAsFixed(0)}% OFF',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 9.5.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _quantityControl(item),
                        SizedBox(width: 8.w),
                        Flexible(
                          child: Text(
                            '₱${(discountedPrice * item.quantity).toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quantityControl(CartProduct item) {
    final theme = Theme.of(context);

    return Container(
      height: 34.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.3),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(
            icon: Icons.remove,
            onPressed: () {
              context.read<CartProvider>().updateQuantity(item, -1);
            },
          ),
          SizedBox(width: 7.w),
          SizedBox(
            width: 22.w,
            child: Center(
              child: CustomText(
                text: '${item.quantity}',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 7.w),
          _quantityButton(
            icon: Icons.add,
            onPressed: () {
              context.read<CartProvider>().updateQuantity(item, 1);
            },
          ),
        ],
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: _lightBlueBg,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 25.w,
          height: 25.h,
          child: Icon(icon, size: 14.sp, color: _accentBlue),
        ),
      ),
    );
  }

  Widget _orderSummary(Cart cart) {
    final theme = Theme.of(context);

    final subtotal = cart.products.fold<double>(
      0,
      (sum, item) => sum + item.price * item.quantity,
    );

    final discount = cart.products.fold<double>(0, (sum, item) {
      return sum + (item.price * item.quantity * item.discountPercentage / 100);
    });

    final total = subtotal - discount;

    return Container(
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(17.r),
        border: Border.all(
          color: Colors.lightBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(height: 17.h),
          _summaryRow('Subtotal', subtotal),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 16.sp,
                    color: Colors.red.shade600,
                  ),
                  SizedBox(width: 7.w),
                  Text(
                    'Discount',
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              Text(
                '-₱${discount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ),
          SizedBox(height: 17.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: _lightBlueBg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(width: 12.w),
                Flexible(
                  child: Text(
                    '₱${total.toStringAsFixed(2)}',
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w800,
                      color: _accentBlue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double amount) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13.5.sp,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '₱${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 13.5.sp,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  double _discountedUnitPrice(CartProduct item) {
    if (item.quantity == 0) {
      return 0;
    }

    return item.discountedTotal / item.quantity;
  }

  Future<void> _confirmOrder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Order'),
          content: const Text('Are you sure you want to place this order?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _accentBlue,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order confirmed successfully!'),
          backgroundColor: _accentBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _message({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 30.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: Colors.grey.shade400),
            SizedBox(height: 16.h),
            CustomText(
              text: title,
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 7.h),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
