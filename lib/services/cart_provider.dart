import 'package:flutter/foundation.dart';
import 'package:pizza_app_vs_010/services/cart_service.dart';

class CartProvider with ChangeNotifier {
  List<Map<String, dynamic>> _cartItems = [];
  double _subtotal = 0.0;
  int _cartCount = 0;
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get cartItems => _cartItems;
  double get subtotal => _subtotal;
  int get cartCount => _cartCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Load cart items from CartService
  Future<void> loadCart() async {
    try {
      _setLoading(true);
      _clearError();

      List<Map<String, dynamic>> items = await CartService().getCartItems();

      _cartItems = items;
      _calculateSubtotal();
      _updateCartCount();

      _setLoading(false);
    } catch (e) {
      _setError('Không thể tải giỏ hàng: $e');
      _setLoading(false);
      print('Error loading cart: $e');
    }
  }

  // Add item to cart
  Future<bool> addToCart(Map<String, dynamic> foodData) async {
    try {
      _setLoading(true);
      _clearError();

      bool success = await CartService().addToCart(foodData);

      if (success) {
        // Reload cart to get updated data
        await loadCart();
        return true;
      } else {
        _setError('Không thể thêm sản phẩm vào giỏ hàng');
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi thêm vào giỏ hàng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Add item to cart with specific quantity
  Future<bool> addToCartWithQuantity(
    Map<String, dynamic> foodData,
    int quantity,
  ) async {
    try {
      _setLoading(true);
      _clearError();

      bool success = await CartService().addToCartWithQuantity(
        foodData,
        quantity,
      );

      if (success) {
        // Reload cart to get updated data
        await loadCart();
        return true;
      } else {
        _setError('Không thể thêm sản phẩm vào giỏ hàng');
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi thêm vào giỏ hàng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update item quantity
  Future<bool> updateQuantity(String itemId, int newQuantity) async {
    try {
      _setLoading(true);
      _clearError();

      bool success = await CartService().updateQuantity(itemId, newQuantity);

      if (success) {
        // Reload cart to get updated data
        await loadCart();
        return true;
      } else {
        _setError('Không thể cập nhật số lượng');
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi cập nhật số lượng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove item from cart
  Future<bool> removeItem(String itemId) async {
    try {
      _setLoading(true);
      _clearError();

      bool success = await CartService().removeItem(itemId);

      if (success) {
        // Reload cart to get updated data
        await loadCart();
        return true;
      } else {
        _setError('Không thể xóa sản phẩm');
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi xóa sản phẩm: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Clear cart
  Future<bool> clearCart() async {
    try {
      _setLoading(true);
      _clearError();

      bool success = await CartService().clearCart();

      if (success) {
        _cartItems = [];
        _subtotal = 0.0;
        _cartCount = 0;
        notifyListeners();
        return true;
      } else {
        _setError('Không thể xóa giỏ hàng');
        return false;
      }
    } catch (e) {
      _setError('Lỗi khi xóa giỏ hàng: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Calculate subtotal
  void _calculateSubtotal() {
    _subtotal = 0.0;
    print('🧮 Calculating subtotal:');

    for (var item in _cartItems) {
      double price = (item['price'] ?? 0.0).toDouble();
      int quantity = (item['quantity'] ?? 1).toInt();
      double itemTotal = price * quantity;
      _subtotal += itemTotal;

      print('  - ${item['productName']}: \$$price × $quantity = \$$itemTotal');

      // Add options price if any
      if (item['options'] != null) {
        List<dynamic> options = item['options'];
        for (var option in options) {
          double extraPrice = (option['extraPrice'] ?? 0.0).toDouble();
          _subtotal += extraPrice;
          print('    + Option: \$$extraPrice');
        }
      }
    }

    print('  📊 Total subtotal: \$$_subtotal');
  }

  // Update cart count
  void _updateCartCount() {
    _cartCount = 0;
    print('🔢 Calculating cart count:');

    for (var item in _cartItems) {
      int quantity = int.parse((item['quantity'] ?? 1).toString());
      _cartCount += quantity;
      print('  - ${item['productName']}: $quantity items');
    }

    print('  📊 Total items: $_cartCount');
  }

  // Get cart total with shipping and discount
  double getCartTotal({double discount = 0.0, double shippingFee = 5.0}) {
    return _subtotal + shippingFee - discount;
  }

  // Check if cart is empty
  bool get isEmpty => _cartItems.isEmpty;

  // Get item count
  int get itemCount => _cartItems.length;

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Refresh cart data
  Future<void> refresh() async {
    await loadCart();
  }

  // Get current cart ID
  Future<String?> getCurrentCartId() async {
    return await CartService().getCurrentCartId();
  }
}
