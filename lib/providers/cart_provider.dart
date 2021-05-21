import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shopping_app/models/http_exception.dart';
import 'package:shopping_app/providers/products_provider.dart';
import './product.dart';
import 'package:http/http.dart' as http;

class CartProvider with ChangeNotifier {
  Map<String, int> _cartProducts = {};

  Map<String, int> get cartProductsMap {
    return {..._cartProducts};
  }

  List<String> _cartProductIds = [];

  List<String> get productIds {
    return [..._cartProducts.keys];
  }

  Future<void> fetchAndSetCartProducts(String authToken) {
    _cartProducts.clear();
    _cartProductIds.clear();
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart.json?auth=$authToken');
    return http.get(url).then((value) {
      Map<String, dynamic> extractedData = jsonDecode(value.body);
      if (extractedData == null) return;
      if (extractedData['error'] != null) {
        print(value.body);
        throw HttpException(extractedData['error']['message']);
      }
      extractedData.forEach((id, map) {
        _cartProductIds.add(id);
        _cartProducts[map['productId']] = map['quantity'];
      });
    }, onError: (error) {
      throw error;
    });
  }

  Future<http.Response> addProductToCart(String id, String authToken) {
    if (_cartProducts[id] == null) {
      _cartProducts[id]=1;
      notifyListeners();
      Uri url = Uri.parse(
          'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart.json?auth=$authToken');
      return http
          .post(url, body: json.encode({'productId': id, 'quantity': 1}))
          .then((value) {
        Map<String, dynamic> extractedData = json.decode(value.body);
        if (extractedData['error'] != null) {
          _cartProducts.remove(id);
          notifyListeners();
          print(value.body);
          throw HttpException(extractedData['error']['message']);
        }
        _cartProductIds.add(extractedData['name']);
        return value;
      }, onError: (error) {
        _cartProducts.remove(id);
        notifyListeners();
        print(error);
        throw error;
      });
    }
    _cartProducts.update(id, (value) => ++value);
    notifyListeners();
    int index = -1;
    for (MapEntry me in _cartProducts.entries) {
      index++;
      if (me.key == id) break;
    }
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart/${_cartProductIds[index]}.json?auth=$authToken');
    return http
        .patch(url, body: json.encode({'quantity': _cartProducts[id] + 1}))
        .then((value) {
      Map<String, dynamic> extractedData = json.decode(value.body);
      if (extractedData['error'] != null) {
        _cartProducts.update(id, (value) => --value);
        notifyListeners();
        print(value.body);
        throw HttpException(extractedData['error']['message']);
      }
      return value;
    }, onError: (error) {
      _cartProducts.update(id, (value) => --value);
      notifyListeners();
      print(error);
      throw error;
    });
  }

  // void restoreProduct(String id, int quantity, int position) {
  //   Map<String, int> cartProducts2 = {};
  //   if (position == 0) {
  //     cartProducts2[id] = quantity;
  //     cartProducts2.addAll(_cartProducts);
  //     _cartProducts.clear();
  //     _cartProducts.addAll(cartProducts2);
  //   } else if (position == _cartProducts.length) {
  //     _cartProducts[id] = quantity;
  //   } else {
  //     int i = 0;
  //     _cartProducts.forEach((key, value) {
  //       if (i == position) {
  //         cartProducts2[id] = quantity;
  //       }
  //       cartProducts2[key] = value;
  //       i++;
  //     });
  //     _cartProducts.clear();
  //     _cartProducts.addAll(cartProducts2);
  //   }
  //   notifyListeners();
  // }

  int get length {
    return _cartProducts.length;
  }

  Future<int> reduceProductQuantity(String id, String authToken) {
    int index = -1;
    for (MapEntry me in _cartProducts.entries) {
      index++;
      if (me.key == id) break;
    }
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart/${_cartProductIds[index]}.json?auth=$authToken');
    if (_cartProducts[id] == 1) {
      return http.delete(url).then((_) {
        _cartProducts.remove(id);
        _cartProductIds.removeAt(index);
        notifyListeners();
        return 0;
      }, onError: (error) {
        debugPrint(error);
        throw error;
      });
    } else {
      int val;
      _cartProducts.update(id, (value) {
        val = value - 1;
        return --value;
      });
      notifyListeners();
      return http
          .patch(url, body: jsonEncode({'quantity': cartProductsMap[id] - 1}))
          .then((value) {
        var extractedData = jsonDecode(value.body);
        if (extractedData['error'] != null) {
          _cartProducts.update(id, (value) {
            return ++value;
          });
          notifyListeners();
          debugPrint('error here');
          print(value.body);
          throw HttpException(extractedData['error']['message']);
        }
        return val;
      }, onError: (error) {
        _cartProducts.update(id, (value) {
          return ++value;
        });
        notifyListeners();
        print('error caught in onError');
        print(error);
        throw error;
      });
    }
  }

  Future<void> removeProductFromCart(String id, String authToken) {
    int index = -1;
    for (MapEntry me in _cartProducts.entries) {
      index++;
      if (me.key == id) break;
    }
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart/${_cartProductIds[index]}.json?auth=$authToken');
    return http.delete(url).then((value) {
      _cartProducts.remove(id);
      _cartProductIds.removeAt(index);
      notifyListeners();
    }, onError: (error) {
      throw error;
    });
  }

  double price(Product product) {
    if (_cartProducts[product.id] == null) return null;
    return _cartProducts[product.id] * product.price;
  }

  double total(ProductsProvider productsProvider) {
    double t = 0;
    _cartProducts.forEach((id, quantity) {
      t += productsProvider.products
              .where((element) => element.id == id)
              .first
              .price *
          quantity;
    });
    return t;
  }

  int quantity(String id) {
    return _cartProducts[id];
  }

  Future<void> clear(String authToken) {
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/cart.json?auth=$authToken');
    return http.delete(url).then((value) {
      _cartProducts.clear();
      _cartProductIds.clear();
      notifyListeners();
    }, onError: (error) {
      throw error;
    });
  }

  void clearClient() {
    _cartProducts.clear();
    _cartProductIds.clear();
  }

}