import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import '../widgets/custom_text.dart';
import 'product_details_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  late final Future<List<Product>> _productsFuture;

  final TextEditingController _searchController = TextEditingController();

  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService().getAllProducts();
  }

  // ENHANCEMENT 1: SEARCH PRODUCTS
  void _filterProducts(String query) {
    final searchQuery = query.toLowerCase();

    setState(() {
      _filteredProducts = _allProducts.where((product) {
        return product.title.toLowerCase().contains(searchQuery) ||
            product.category.toLowerCase().contains(searchQuery) ||
            product.description.toLowerCase().contains(searchQuery);
      }).toList();
    });
  }

  // ENHANCEMENT 2: OPEN PRODUCT DETAILS (Where Add to Cart is located)
  void _openProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ENHANCEMENT 1: SEARCH BAR
          TextField(
            controller: _searchController,
            onChanged: _filterProducts,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),

          SizedBox(height: 16.h),

          FutureBuilder<List<Product>>(
            future: _productsFuture,
            builder: (context, snapshot) {
              // LOADING
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: const CircularProgressIndicator(),
                  ),
                );
              }

              // ERROR
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.r),
                    child: CustomText(
                      text: 'Error: ${snapshot.error}',
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }

              // LOAD PRODUCTS
              if (snapshot.hasData && _allProducts.isEmpty) {
                _allProducts = snapshot.data ?? [];
                _filteredProducts = _allProducts;
              }

              final products = _filteredProducts;

              // NO PRODUCTS
              if (products.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.r),
                    child: CustomText(
                      text: 'No products found.',
                      fontSize: 14.sp,
                    ),
                  ),
                );
              }

              // PRODUCT GRID
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio:
                      0.75, // Restored original aspect ratio since button is removed
                ),
                itemBuilder: (context, index) {
                  final product = products[index];

                  return InkWell(
                    borderRadius: BorderRadius.circular(12.r),
                    onTap: () => _openProductDetails(product),
                    child: Card(
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PRODUCT IMAGE
                          Expanded(
                            child: Image.network(
                              product.thumbnail,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return Center(
                                      child: Icon(Icons.image, size: 40.sp),
                                    );
                                  },
                            ),
                          ),

                          // PRODUCT INFORMATION
                          Padding(
                            padding: EdgeInsets.all(8.r),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CustomText(
                                  text: product.title,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 4.h),

                                CustomText(
                                  text: '₱${product.price.toStringAsFixed(2)}',
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
