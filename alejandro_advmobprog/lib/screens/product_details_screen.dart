import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/product_model.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_text.dart';

class ProductDetailsScreen extends StatelessWidget {
  final Product product;
  final bool showAddToCart;

  const ProductDetailsScreen({
    super.key,
    required this.product,
    this.showAddToCart = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final discountPrice =
        product.price * (1 - product.discountPercentage / 100);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: CustomText(
          text: 'Product Details',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LAB_ACT2 ENHANCEMENT 2:
            // Added a product details page that opens when the user clicks/taps a product card.
            Container(
              width: double.infinity,
              height: 320.h,
              margin: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 0),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(22.r),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22.r),
                child: product.images.isNotEmpty
                    ? PageView.builder(
                        itemCount: product.images.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: EdgeInsets.all(20.r),
                            child: Image.network(
                              product.images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 65.sp,
                                    color: theme.disabledColor,
                                  ),
                                );
                              },
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) {
                                      return child;
                                    }

                                    return Center(
                                      child: SizedBox(
                                        width: 28.w,
                                        height: 28.h,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    );
                                  },
                            ),
                          );
                        },
                      )
                    : Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Image.network(
                          product.thumbnail,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.image_not_supported_outlined,
                                size: 65.sp,
                                color: theme.disabledColor,
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 22.h, 16.w, 30.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // BRAND
                  if (product.brand.isNotEmpty)
                    Text(
                      product.brand.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: colorScheme.primary,
                      ),
                    ),

                  SizedBox(height: 6.h),

                  // TITLE
                  CustomText(
                    text: product.title,
                    fontSize: 25.sp,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.3,
                  ),

                  SizedBox(height: 10.h),

                  // CATEGORY + AVAILABILITY
                  Row(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 16.sp,
                        color: theme.hintColor,
                      ),
                      SizedBox(width: 5.w),
                      Expanded(
                        child: CustomText(
                          text: product.category,
                          fontSize: 13.sp,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _availabilityBadge(context),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // PRICE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        '₱${discountPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 29.sp,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      if (product.discountPercentage > 0)
                        Text(
                          '₱${product.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: theme.disabledColor,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),

                  if (product.discountPercentage > 0)
                    Padding(
                      padding: EdgeInsets.only(top: 7.h),
                      child: Row(
                        children: [
                          Icon(
                            Icons.local_offer_outlined,
                            size: 14.sp,
                            color: colorScheme.error,
                          ),
                          SizedBox(width: 5.w),
                          Text(
                            'Save ₱${(product.price - discountPrice).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.error,
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 7.w,
                              vertical: 3.h,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Text(
                              '${product.discountPercentage.toStringAsFixed(0)}% OFF',
                              style: TextStyle(
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (showAddToCart) ...[
                    SizedBox(height: 20.h),
                    SizedBox(
                      width: double.infinity,
                      height: 54.h,
                      child: ElevatedButton.icon(
                        onPressed: () => _addToCart(context),
                        icon: Icon(Icons.shopping_cart_outlined, size: 20.sp),
                        label: Text(
                          'Add to Cart',
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          elevation: 2,
                          shadowColor: colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                  ],

                  SizedBox(height: 22.h),

                  // RATING + REVIEWS + STOCK
                  _productStats(context),

                  SizedBox(height: 28.h),

                  // TAGS
                  if (product.tags.isNotEmpty) ...[
                    _sectionTitle(context, 'Tags', Icons.local_offer_outlined),
                    SizedBox(height: 10.h),
                    Wrap(
                      spacing: 7.w,
                      runSpacing: 7.h,
                      children: product.tags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 7.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 28.h),
                  ],

                  // DESCRIPTION
                  _sectionTitle(
                    context,
                    'Description',
                    Icons.description_outlined,
                  ),

                  SizedBox(height: 10.h),

                  CustomText(
                    text: product.description,
                    fontSize: 14.sp,
                    letterSpacing: 0.1,
                  ),

                  SizedBox(height: 28.h),

                  // PRODUCT INFORMATION
                  _sectionTitle(
                    context,
                    'Product Information',
                    Icons.inventory_2_outlined,
                  ),

                  SizedBox(height: 10.h),

                  _infoCard(context, [
                    _infoRow(context, 'Product ID', '${product.id}'),
                    _infoRow(context, 'Category', product.category),
                    _infoRow(context, 'Brand', product.brand),
                    _infoRow(context, 'SKU', product.sku),
                    _infoRow(context, 'Stock', '${product.stock}'),
                    _infoRow(
                      context,
                      'Availability',
                      product.availabilityStatus,
                    ),
                    _infoRow(
                      context,
                      'Minimum Order',
                      '${product.minimumOrderQuantity}',
                    ),
                    _infoRow(context, 'Weight', '${product.weight}'),
                  ]),

                  SizedBox(height: 28.h),

                  // DIMENSIONS
                  _sectionTitle(
                    context,
                    'Dimensions',
                    Icons.straighten_outlined,
                  ),

                  SizedBox(height: 10.h),

                  Row(
                    children: [
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Width',
                          product.dimensions.width,
                          Icons.swap_horiz,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Height',
                          product.dimensions.height,
                          Icons.height,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: _dimensionCard(
                          context,
                          'Depth',
                          product.dimensions.depth,
                          Icons.view_in_ar_outlined,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 28.h),

                  // SHIPPING & WARRANTY
                  _sectionTitle(
                    context,
                    'Shipping & Warranty',
                    Icons.local_shipping_outlined,
                  ),

                  SizedBox(height: 10.h),

                  _infoCard(context, [
                    _infoRow(context, 'Warranty', product.warrantyInformation),
                    _infoRow(context, 'Shipping', product.shippingInformation),
                    _infoRow(context, 'Return Policy', product.returnPolicy),
                  ]),

                  SizedBox(height: 28.h),

                  // REVIEWS
                  _sectionTitle(context, 'Reviews', Icons.rate_review_outlined),

                  SizedBox(height: 10.h),

                  if (product.reviews.isEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                      child: Text(
                        'No reviews available.',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: theme.hintColor,
                        ),
                      ),
                    )
                  else
                    ...product.reviews.map(
                      (review) => _reviewCard(context, review),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addToCart(BuildContext context) async {
    try {
      await context.read<CartProvider>().addProduct(product);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Product added to cart'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to add product: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _productStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inStock = product.stock > 0;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              context,
              Icons.star_rounded,
              product.rating.toStringAsFixed(1),
              '${product.reviews.length} reviews',
              Colors.amber,
            ),
          ),
          Container(
            width: 1,
            height: 38.h,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
          Expanded(
            child: _statItem(
              context,
              inStock ? Icons.check_circle_outline : Icons.cancel_outlined,
              '${product.stock}',
              'in stock',
              inStock ? Colors.green : colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: iconColor, size: 21.sp),
        SizedBox(width: 7.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w700),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10.sp, color: theme.hintColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _availabilityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final inStock = product.stock > 0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: inStock
            ? Colors.green.withValues(alpha: 0.1)
            : colorScheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        product.availabilityStatus,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: inStock ? Colors.green : colorScheme.error,
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(7.r),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 18.sp, color: colorScheme.primary),
        ),
        SizedBox(width: 9.w),
        CustomText(text: title, fontSize: 18.sp, fontWeight: FontWeight.bold),
      ],
    );
  }

  Widget _infoCard(BuildContext context, List<Widget> children) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 9.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120.w,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not available' : value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dimensionCard(
    BuildContext context,
    String label,
    double value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 5.w),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        children: [
          Icon(icon, size: 21.sp, color: colorScheme.primary),
          SizedBox(height: 7.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: theme.hintColor),
          ),
          SizedBox(height: 3.h),
          Text(
            value.toString(),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _reviewCard(BuildContext context, ProductReview review) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.all(13.r),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.1,
                ),
                child: Text(
                  review.reviewerName.isNotEmpty
                      ? review.reviewerName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      text: review.reviewerName,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      review.date,
                      style: TextStyle(fontSize: 10.sp, color: theme.hintColor),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return Icon(
                    index < review.rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 16.sp,
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          CustomText(text: review.comment, fontSize: 12.sp),
        ],
      ),
    );
  }
}
