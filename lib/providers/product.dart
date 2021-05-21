import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  String id;
  String imageUrl;
  String description;
  String title;
  double price;
  bool isFavorite;

  Product({
    @required this.id,
    @required this.imageUrl,
    @required this.description,
    @required this.title,
    @required this.price,
    this.isFavorite = false,
  });

  Future<http.Response> changeFav(String authToken, String userId) async {
    isFavorite = !isFavorite;
    notifyListeners();
    Uri patchUrl = Uri.parse(
        'https://flutter-shoppingapp-c1193-default-rtdb.firebaseio.com/userFavorites/$userId/$id.json?auth=$authToken');
    try{
      final response = await http.put(patchUrl, body: json.encode(isFavorite));
      if (response.statusCode < 400) return response;
      isFavorite = !isFavorite;
      notifyListeners();
      throw response;
    }
    catch(error){
      throw error;
    }
  }
}
