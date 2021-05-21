import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/product.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import '../providers/cart_provider.dart';

class CartItem extends StatefulWidget {
  final Product _product;
  final int position;
  int _quantity;
  final GlobalKey<AnimatedListState> listKey;
  final Function removeFromProductsList, restoreProduct;
  final bool forRemoveAnimation;

  CartItem(this._product, this._quantity, this.listKey, this.position,
      {this.removeFromProductsList,
      this.forRemoveAnimation = false,
      this.restoreProduct});

  @override
  _CartItemState createState() => _CartItemState();
}

class _CartItemState extends State<CartItem> {
  AuthProvider authProvider;
  bool isUpdating = false, noInternet=false;

  Future<String> get authToken {
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
    CartProvider cartProvider =
        Provider.of<CartProvider>(context, listen: false);
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    return Column(
      children: [
        SizedBox(height: 10),
        Row(
          children: [
            Container(
              width: 100,
              child: Column(
                children: [
                  Text(
                    widget._product.title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    softWrap: false,
                    overflow: TextOverflow.fade,
                  ),
                  SizedBox(
                    height: 5,
                  ),
                  Text(
                    '\$${widget._product.price}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 50,
            ),
            if (!isUpdating)
              GestureDetector(
                child: Container(
                  margin: EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).primaryColor),
                  child: Padding(
                    padding: EdgeInsets.only(left: 6, right: 6),
                    child: Text(
                      String.fromCharCode(8211),
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onTap: () async {
                  bool wantsToDelete = true;
                  if (widget._quantity - 1 == 0) {
                    Future.delayed(Duration(seconds: 3, milliseconds: 20),
                        () async {
                      if (wantsToDelete) {
                        try{
                          cartProvider
                              .reduceProductQuantity(
                                  widget._product.id, await authToken)
                              .catchError((error) {
                            widget.restoreProduct(widget._product,
                                widget._quantity, widget.position);
                            showErrorToast();
                          });
                        }
                        catch(_){
                          showErrorToast();
                        }
                      }
                    });
                    widget.removeFromProductsList(widget.position);
                    widget.listKey.currentState.removeItem(
                        widget.position,
                        (context, animation) => SizeTransition(
                              sizeFactor: animation,
                              child: CartItem(
                                widget._product,
                                widget._quantity,
                                widget.listKey,
                                widget.position,
                                forRemoveAnimation: true,
                              ),
                            ));
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(SnackBar(
                        content: Text(
                          'Product removed from cart',
                          style: TextStyle(fontSize: 15),
                        ),
                        duration: Duration(seconds: 3),
                        action: SnackBarAction(
                            label: 'Undo',
                            onPressed: () {
                              wantsToDelete = false;
                              widget.restoreProduct(widget._product,
                                  widget._quantity, widget.position);
                            }),
                        behavior: SnackBarBehavior.floating,
                        margin:
                            EdgeInsets.only(bottom: 30, left: 10, right: 10),
                      ));
                  } else {
                    setState(() {
                      isUpdating = true;
                    });
                    try{
                      cartProvider
                          .reduceProductQuantity(
                              widget._product.id, await authToken)
                          .then((value) => setState(() {
                                isUpdating = false;
                                --widget._quantity;
                              }))
                          .catchError((error) {
                        setState(() {
                          isUpdating = false;
                        });
                        showErrorToast();
                      });
                    }
                    catch(_){
                      showErrorToast();
                    }
                  }
                },
              ),
            isUpdating
                ? CircularProgressIndicator()
                : Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      widget._quantity.toString(),
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
            if (!isUpdating)
              GestureDetector(
                child: Container(
                  margin: EdgeInsets.only(left: 2),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Theme.of(context).primaryColor),
                  child: Padding(
                    padding: EdgeInsets.only(left: 6, right: 6),
                    child: Text(
                      '+',
                      style:
                          TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                onTap: () async {
                  setState(() {
                    isUpdating = true;
                  });
                  try{
                    cartProvider
                        .addProductToCart(widget._product.id, await authToken)
                        .then((value) {
                      setState(() {
                        isUpdating = false;
                      });
                    }, onError: (error) {
                      setState(() {
                        isUpdating = true;
                      });
                      showErrorToast();
                    });
                  }
                  catch(_){
                    showErrorToast();
                  }
                },
              ),
            Spacer(),
            Chip(
                label: Text((widget.forRemoveAnimation
                        ? widget._product.price * widget._quantity
                        : cartProvider.price(widget._product))
                    .toStringAsFixed(2))),
            SizedBox(width: 10),
          ],
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

  void showErrorToast() {
    Fluttertoast.showToast(
        msg: noInternet?'No internet connection.':'Some error occurred.\nPlease try again.');
  }
}
