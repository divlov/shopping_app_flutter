import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:shopping_app/providers/product.dart';
import '../models/Order.dart';
import 'package:http/http.dart' as http;

class OrderProvider with ChangeNotifier {
  List<Order> _orders = [];
  Uri url = Uri.parse(
      'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/orders.json');

  Future<http.Response> add(Order order, String authToken, String userId) {
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    List<Map<String, dynamic>> uploadData = [];
    order.productsMap.forEach((product, quantity) {
      Map<String, dynamic> map = {
        'id': product.id,
        'title': product.title,
        'description': product.description,
        'imageUrl': product.imageUrl,
        'price': product.price,
        'quantity': quantity
      };
      uploadData.add(map);
    });
    return http
        .post(url,
            body: json.encode(
              {
                'productsMap': uploadData,
                'dateTime': order.dateTime.toIso8601String(),
              },
            ))
        .then((value) {
      if (value.statusCode < 400) {
        print('ordering successful');
        _orders.insert(0,order);
        notifyListeners();
        return value;
      } else {
        print('ordering failed' + value.body);
        throw value;
      }
    }, onError: (error) {
      print('ordering failed' + error.toString());
      throw error;
    });
  }

  Future<Response> fetchAndSetOrders(String authToken, String userId) {
    Uri url = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/orders/$userId.json?auth=$authToken');
    List<Order> orders2=[];
    return http.get(url).then((response) {
      if (response.statusCode < 400) {
        Map<String, dynamic> extractedData = json.decode(response.body);
        if(extractedData!=null){
          extractedData.forEach((orderId, uploadedData) {
            List<dynamic> productsMapList = uploadedData['productsMap'];
            DateTime dateTime = DateTime.parse(uploadedData['dateTime']);
            Map<Product, int> productsMap = {};
            productsMapList.forEach((productsMap1) {
              Product product = Product(
                  id: productsMap1['id'],
                  imageUrl: productsMap1['imageUrl'],
                  description: productsMap1['description'],
                  title: productsMap1['title'],
                  price: productsMap1['price']);
              int quantity = productsMap1['quantity'];
              productsMap[product] = quantity;
            });
            orders2.insert(0,Order(productsMap, dateTime));
          });
        }
        _orders = orders2;
        return response;
      } else {
        print(response.body + ' statuscode>=400');
        throw response;
      }
    }).catchError((error) {
      print(error.toString());
      throw error;
    });
  }

  List<Order> get orders {
    return [..._orders];
  }

  int length() {
    return _orders.length;
  }
}
