import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import '../providers/product.dart';
import 'package:shopping_app/screens/product_details_screen.dart';
import 'package:shopping_app/widgets/responsive_favorite_button.dart';

class ProductTile extends StatelessWidget {
  AuthProvider authProvider;
  bool isUpdating = false, noInternet=false;

  Future<String> authToken(BuildContext context) {
    return authProvider.token.then((value) {
      if (value == null) throw value;
      noInternet = false;
      return value;
    }).catchError((error) {
      return Connectivity().checkConnectivity().then((value) {
        if (value == ConnectivityResult.none) {
          noInternet=true;
          throw error;
        }
        else {
          authProvider.logOut();
          Navigator.of(context).pushNamed(AuthScreen.routeName);
          Fluttertoast.showToast(msg: 'Token expired.\nPlease login again.');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    Product _product = Provider.of<Product>(context, listen: false);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    return GestureDetector(
      onTap: () {
        Navigator.of(context)
            .pushNamed(ProductDetailsScreen.routeName, arguments: _product);
      },
      child: Card(
        elevation: 15,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15))),
        child:
        // _product==null?
        //     Column(
        //       children: [
        //         Container(
        //           decoration: BoxDecoration(borderRadius: BorderRadius.only(
        //               topLeft: Radius.circular(15), topRight: Radius.circular(15))),
        //           height: 100,
        //           color: Colors.grey[700],
        //         ),
        //         SizedBox(height: 10,),
        //         Align(
        //           alignment: Alignment.centerLeft,
        //           child: Container(
        //             width: 50,
        //             height: 15,
        //             color: Colors.grey[700],
        //           ),
        //         ),
        //         SizedBox(height: 10,),
        //         Container(
        //           height: 15,
        //           color: Colors.grey[700],
        //         )
        //       ],
        //     ):
        Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15), topRight: Radius.circular(15)),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 2 / 2,
                    child: Hero(
                      tag: 'productImage${_product.id}',
                      child: Image.network(
                        _product.imageUrl,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  Positioned(
                    child: FavoriteButton(),
                    right: 15,
                    bottom: 15,
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: 10, top: 10),
                child: Text(
                  '\$${_product.price}',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.only(left: 6, right: 5, bottom: 5),
              child: Consumer<CartProvider>(
                builder: (ctx, cartProvider, child) {
                  bool productInCart =
                      cartProvider.productIds.contains(_product.id);
                  return Row(
                    children: [
                      child,
                      Spacer(),
                      if (productInCart)
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).primaryColor),
                            child: Padding(
                              padding: EdgeInsets.only(left: 6, right: 6),
                              child: Text(
                                String.fromCharCode(8211),
                                style: TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          onTap: () async {
                            if (isUpdating) return;
                            isUpdating = true;
                            try{
                              cartProvider
                                  .reduceProductQuantity(
                                      _product.id, await authToken(context))
                                  .then((reducedQuantity) {
                                if (reducedQuantity == 0) {
                                  ScaffoldMessenger.of(context)
                                      .hideCurrentSnackBar();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text(
                                      'Product removed from cart',
                                      style: TextStyle(fontSize: 15),
                                    ),
                                    duration: Duration(seconds: 1),
                                  ));
                                }

                                isUpdating = false;
                              }, onError: (error) {
                                showErrorToast();
                              });
                            }
                            catch(_){
                              showErrorToast();
                            }
                          },
                        ),
                      productInCart
                          ? Text(
                              cartProvider.cartProductsMap[_product.id]
                                  .toString(),
                              style: TextStyle(
                                  fontSize: 19, fontWeight: FontWeight.bold),
                            )
                          : IconButton(
                              icon: productInCart == true
                                  ? Icon(Icons.shopping_cart)
                                  : Icon(Icons.shopping_cart_outlined),
                              onPressed: () async {
                                if (isUpdating) return;
                                isUpdating = true;
                                try{
                                  cartProvider
                                      .addProductToCart(
                                          _product.id, await authToken(context))
                                      .then((value) {
                                    ScaffoldMessenger.of(context)
                                      ..hideCurrentSnackBar()
                                      ..showSnackBar(SnackBar(
                                        content: Text(
                                          'Product added in cart',
                                          style: TextStyle(fontSize: 15),
                                        ),
                                        duration: Duration(seconds: 1),
                                      ));
                                    isUpdating = false;
                                  }, onError: (error) {
                                    showErrorToast();
                                  });
                                }
                                catch(_){
                                  showErrorToast();
                                }
                              }),
                      if (productInCart)
                        GestureDetector(
                          child: Container(
                            margin: EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Theme.of(context).primaryColor),
                            child: Padding(
                              padding: EdgeInsets.only(left: 6, right: 6),
                              child: Text(
                                '+',
                                style: TextStyle(
                                    fontSize: 21, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          onTap: () async {
                            if (isUpdating) return;
                            isUpdating = true;
                            try{
                              cartProvider
                                  .addProductToCart(
                                      _product.id, await authToken(context))
                                  .then((value) => isUpdating = false,
                                      onError: (error) {
                                showErrorToast();
                              });
                            }
                            catch(_){
                              showErrorToast();
                            }
                          },
                        ),
                    ],
                  );
                },
                child: Expanded(
                  child: Text(
                    _product.title,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showErrorToast() async{
    isUpdating = false;
    if( noInternet){
    Fluttertoast.showToast(msg: 'No internet connection');
    }
    else
    Fluttertoast.showToast(msg: 'Some error occurred.\nPlease try again.');
  }
}
