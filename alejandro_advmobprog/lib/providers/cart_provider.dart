import 'package:flutter/foundation.dart';

import '../models/cart.dart';
import '../models/product_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  final int userId;

  Cart? _cart;
  Future<void>? _loadFuture;

  CartProvider({this.userId = 2});

  Cart? get cart => _cart;

  Future<void> loadCart() {
    return _loadFuture ??= _loadCart();
  }

  Future<void> _loadCart() async {
    _cart = await _cartService.getCartByUserId(userId);
    notifyListeners();
  }

  Future<void> addProduct(Product product) async {
    final serverResponseCart = await _cartService.addToCart(
      userId: userId,
      products: [
        {'id': product.id, 'quantity': 1},
      ],
    );

    final activeCartItemList = List<CartProduct>.from(_cart?.products ?? []);
    final matchedProductIndex = activeCartItemList.indexWhere(
      (item) => item.id == product.id,
    );

    final newItemEntry = CartProduct(
      id: product.id,
      title: product.title,
      price: product.price,
      quantity: 1,
      total: product.price,
      discountPercentage: product.discountPercentage,
      discountedTotal: product.price * (1 - product.discountPercentage / 100),
      thumbnail: product.thumbnail,
    );

    if (matchedProductIndex >= 0) {
      final existingItem = activeCartItemList[matchedProductIndex];
      activeCartItemList[matchedProductIndex] = _withQuantity(
        newItemEntry,
        existingItem.quantity + 1,
      );
    } else {
      activeCartItemList.add(newItemEntry);
    }

    _cart = Cart(
      id: _cart?.id ?? serverResponseCart.id,
      products: activeCartItemList,
      total: _total(activeCartItemList, discounted: false),
      discountedTotal: _total(activeCartItemList, discounted: true),
      userId: userId,
      totalProducts: activeCartItemList.length,
      totalQuantity: activeCartItemList.fold(
        0,
        (sum, item) => sum + item.quantity,
      ),
    );
    notifyListeners();
  }

  void updateQuantity(CartProduct item, int change) {
    if (_cart == null) {
      return;
    }

    final itemList = List<CartProduct>.from(_cart!.products);
    final targetIndex = itemList.indexOf(item);
    if (targetIndex < 0) {
      return;
    }

    final updatedQuantity = item.quantity + change;
    if (updatedQuantity <= 0) {
      itemList.removeAt(targetIndex);
    } else {
      itemList[targetIndex] = _withQuantity(item, updatedQuantity);
    }

    _cart = Cart(
      id: _cart!.id,
      products: itemList,
      total: _total(itemList, discounted: false),
      discountedTotal: _total(itemList, discounted: true),
      userId: _cart!.userId,
      totalProducts: itemList.length,
      totalQuantity: itemList.fold(0, (sum, product) => sum + product.quantity),
    );
    notifyListeners();
  }

  CartProduct _withQuantity(CartProduct item, int quantity) {
    final netUnitPrice = item.price * (1 - item.discountPercentage / 100);
    return CartProduct(
      id: item.id,
      title: item.title,
      price: item.price,
      quantity: quantity,
      total: item.price * quantity,
      discountPercentage: item.discountPercentage,
      discountedTotal: netUnitPrice * quantity,
      thumbnail: item.thumbnail,
    );
  }

  double _total(List<CartProduct> products, {required bool discounted}) {
    double accumulatedSum = 0;
    for (var item in products) {
      accumulatedSum += discounted ? item.discountedTotal : item.total;
    }
    return accumulatedSum;
  }
}
