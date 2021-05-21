import 'package:shopping_app/providers/product.dart';

class Order{

  Map<Product,int> productsMap;
  DateTime dateTime;
  
  Order(this.productsMap,this.dateTime);

  double amount(){
    double a=0;
    productsMap.forEach((product, quantity) {
      a+=product.price*quantity;
    });
    return a;
  }

}