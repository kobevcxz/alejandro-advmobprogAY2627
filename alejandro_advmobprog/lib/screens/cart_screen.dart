import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/cart.dart';
import '../services/cart_service.dart';
import '../providers/cart_provider.dart';
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
      body: FutureBuilder<void>(
        future: cartProvider.loadCart(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: _accentBlue));
          }

          if (snapshot.hasError) {
            return _message('Unable to load your cart.');
          }

          final cart = cartProvider.cart;

          if (cart == null || cart.products.isEmpty) {
            return _message('Your cart is empty.');
          }

          return ListView(
            padding: EdgeInsets.fromLTRB(14.w, 16.h, 14.w, 28.h),
            children: [
              ...cart.products.map(_cartItem),

              SizedBox(height: 6.h),

              _orderSummary(cart),

              SizedBox(height: 24.h),

              SizedBox(
                height: 50.h,
                child: ElevatedButton(
                  onPressed: () => _confirmOrder(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentBlue,
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
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
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(10.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: Colors.lightBlue.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14.r),
        onTap: () async {
          final product = await CartService().getProductById(item.id);

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailsScreen(
                  product: product,
                  showAddToCart: false,
                ),
              ),
            );
          }
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 88.w,
              height: 88.h,
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: _lightBlueBg.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Image.network(
                item.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.image_not_supported_outlined,
                  size: 26.sp,
                  color: theme.disabledColor,
                ),
              ),
            ),

            SizedBox(width: 12.w),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    text: item.title,
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w600,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  SizedBox(height: 5.h),

                  Row(
                    children: [
                      // Fixed: Used standard Text widget with TextStyle color instead of CustomText
                      Text(
                        '₱${discountedPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14.5.sp,
                          fontWeight: FontWeight.bold,
                          color: _accentBlue,
                        ),
                      ),

                      if (item.discountPercentage > 0) ...[
                        SizedBox(width: 6.w),
                        Text(
                          '₱${item.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: theme.disabledColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (item.discountPercentage > 0) ...[
                    SizedBox(height: 3.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 5.w,
                        vertical: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(4.r),
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

                  SizedBox(height: 8.h),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _quantityControl(item),

                      SizedBox(width: 6.w),

                      Flexible(
                        child: Text(
                          '₱${(discountedPrice * item.quantity).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5.sp,
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
    );
  }

  Widget _quantityControl(CartProduct item) {
    final theme = Theme.of(context);

    return Container(
      height: 32.h,
      padding: EdgeInsets.symmetric(horizontal: 3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
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
          SizedBox(width: 6.w),
          SizedBox(
            width: 20.w,
            child: Center(
              child: CustomText(
                text: '${item.quantity}',
                fontSize: 12.5.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          SizedBox(width: 6.w),
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
          width: 24.w,
          height: 24.h,
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

    final discount = cart.products.fold<double>(
      0,
      (sum, item) =>
          sum + (item.price * item.quantity * item.discountPercentage / 100),
    );

    final total = subtotal - discount;

    return Container(
      margin: EdgeInsets.only(top: 4.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16.r),
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
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),

          SizedBox(height: 12.h),

          _summaryRow('Subtotal', subtotal),

          SizedBox(height: 8.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_offer_outlined,
                    size: 15.sp,
                    color: Colors.red.shade600,
                  ),
                  SizedBox(width: 6.w),
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

          SizedBox(height: 12.h),

          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: _lightBlueBg.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12.r),
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
                Text(
                  '₱${total.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                    color: _accentBlue,
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
      builder: (context) => AlertDialog(
        title: const Text('Confirm Order'),
        content: const Text('Are you sure you want to place this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _accentBlue),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Order confirmed successfully!'),
          backgroundColor: _accentBlue,
        ),
      );
    }
  }

  Widget _message(String text) {
    return Center(
      child: CustomText(text: text, fontSize: 15.sp),
    );
  }
}
