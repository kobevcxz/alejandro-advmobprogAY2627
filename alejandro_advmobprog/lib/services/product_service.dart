import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants.dart';
import '../models/product_model.dart';

class ProductService {
  Future<List<Product>> getProducts({
    required int limit,
    required int skip,
    String? query,
  }) async {
    final path = query == null || query.trim().isEmpty
        ? '$host/products?limit=$limit&skip=$skip'
        : '$host/products/search?q=${Uri.encodeQueryComponent(query)}'
              '&limit=$limit&skip=$skip';

    final response = await http.get(Uri.parse(path));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final productsJson = data['products'] as List? ?? [];

      return productsJson.map((json) => Product.fromJson(json)).toList();
    }

    throw Exception('Failed to load products');
  }

  Future<Product> getProductById(int productId) async {
    final response = await http.get(Uri.parse('$host/products/$productId'));

    if (response.statusCode == 200) {
      return Product.fromJson(jsonDecode(response.body));
    }

    throw Exception('Failed to load product $productId');
  }
}
