import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/models/http_exception.dart';
import '../providers/product.dart';
import 'package:http/http.dart' as http;

class ProductsProvider with ChangeNotifier {
  List<Product> _products = [];
  List<Product> _userProducts = [];

  Product tempProduct;
  int tempLocation;

  List<Product> get products => [..._products];
  List<Product> get userProducts => [..._userProducts];

  Future<void> fetchAndSetProducts(String authToken, String userId) async {
    _products.clear();
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/products.json?auth=$authToken');
    try {
      var response = await http.get(url);
      url = Uri.parse(
          'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url);
      var extractedData = json.decode(response.body) as Map<String, dynamic>;
      var favoriteData =
          json.decode(favoriteResponse.body) as Map<String, dynamic>;
      if (extractedData['error'] != null) {
        print(response.body + 'error here');
        throw HttpException(extractedData['error']['message']);
      }
      List<Product> loadedProducts = [];
      extractedData.forEach((id, productData) {
        loadedProducts.add(Product(
            id: id,
            imageUrl: productData['imageUrl'],
            description: productData['description'],
            title: productData['title'],
            price: productData['price'],
            isFavorite:
                favoriteData == null ? false : favoriteData[id] ?? false));
      });
      _products = loadedProducts;
      // notifyListeners();
    } catch (error) {
      print(error);
      throw error;
    }
  }


  Future<void> fetchAndSetUserProducts(String authToken, String userId) async {
    _userProducts.clear();
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/products.json?auth=$authToken&orderBy="creatorId"&equalTo="$userId"');
    try {
      var response = await http.get(url);
      url = Uri.parse(
          'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/userFavorites/$userId.json?auth=$authToken');
      final favoriteResponse = await http.get(url);
      var extractedData = json.decode(response.body) as Map<String, dynamic>;
      var favoriteData =
      json.decode(favoriteResponse.body) as Map<String, dynamic>;
      if (extractedData['error'] != null) {
        print(response.body + 'error here');
        throw HttpException(extractedData['error']['message']);
      }
      List<Product> loadedProducts = [];
      extractedData.forEach((id, productData) {
        loadedProducts.add(Product(
            id: id,
            imageUrl: productData['imageUrl'],
            description: productData['description'],
            title: productData['title'],
            price: productData['price'],
            isFavorite:
            favoriteData == null ? false : favoriteData[id] ?? false
            ));
      });
      _userProducts = loadedProducts;
    } catch (error) {
      print(error);
      throw error;
    }
  }

  Future<http.Response> add(Product product, String authToken, String userId) {
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/products.json?auth=$authToken');
    return http
        .post(url,
            body: json.encode({
              'title': product.title,
              'description': product.description,
              'imageUrl': product.imageUrl,
              'price': product.price,
              'isFavorite': false,
              'creatorId': userId
            }))
        .then((response) {
      product.id = json.decode(response.body)['name'];
      _products.add(product);
      _userProducts.add(product);
      notifyListeners();
      return Future.value(response);
    }, onError: (error) {
      throw error;
    });
  }

  void removeFromClient(Product product){
    _userProducts.remove(product);
    _products.remove(product);
    notifyListeners();
  }

  void insertToClient(Product product){

  }

  Future<void> set(String id, Product product, String authToken) async {
    Uri patchUrl = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/products/$id.json?auth=$authToken');
    try {
      await http.patch(patchUrl,
          body: json.encode({
            'description': product.description,
            'title': product.title,
            'imageUrl': product.imageUrl,
            'price': product.price
          }));
    } catch (error) {
      throw error;
    }
    _products[_products.indexWhere((element) => element.id == id)] = product;
    _userProducts[_userProducts.indexWhere((element) => element.id == id)] = product;
    notifyListeners();
  }

  // void insert(int index, Product product) {
  //   _products.insert(index, product);
  //
  //   notifyListeners();
  // }

  //optimistic update
  Future<http.Response> remove(Product product, String authToken) async {
    int existingIndex = _products.indexOf(product);
    int existingUserIndex = _userProducts.indexOf(product);
    final existingProduct = product;
    _products.remove(product);
    _userProducts.remove(product);
    notifyListeners();
    Uri deleteUrl = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/products/${product.id}.json?auth=$authToken');
    final response = await http.delete(deleteUrl);
    if (response.statusCode >= 400) {
      _products.insert(existingIndex, existingProduct);
      _userProducts.insert(existingUserIndex, existingProduct);
      notifyListeners();
      throw response;
    }
    return response;
  }

  int get length {
    return _products.length;
  }

  int get userProductsLength {
    return _userProducts.length;
  }
}
