import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/providers/product.dart';
import 'package:shopping_app/providers/products_provider.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import 'package:shopping_app/screens/edit_product_screen.dart';

class UserProductItem extends StatelessWidget {
  final Product _product;
  final int _position, _length;
  final GlobalKey<AnimatedListState> listKey;
  final Function restoreProduct, removeProductFromList;
  bool wantsToDelete = true, noInternet=false;
  AuthProvider authProvider;

  UserProductItem(this._product, this._position, this._length, this.listKey,
      this.restoreProduct, this.removeProductFromList);

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
    authProvider = Provider.of(context, listen: false);
    final productsProvider =
        Provider.of<ProductsProvider>(context, listen: false);
    return Column(
      children: [
        SizedBox(
          height: 10,
        ),
        ListTile(
          title: Text(
            _product.title,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(_product.imageUrl),
            radius: 40,
          ),
          trailing: Container(
            width: 100,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.grey[700],
                    ),
                    onPressed: () {
                      Navigator.of(context).pushNamed(
                          EditProductScreen.routeName,
                          arguments: {'product': _product, 'listKey': listKey});
                    }),
                IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).errorColor,
                    ),
                    onPressed: () {
                      showDialog(
                          context: context,
                          builder: (ctx) {
                            return AlertDialog(
                              title: Text('Delete ${_product.title}?',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              // content: Text(_product.title),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: Text('CANCEL',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                                TextButton(
                                    onPressed: () {
                                      HapticFeedback.selectionClick();
                                      bool isInCart = Provider.of<CartProvider>(
                                              context,
                                              listen: false)
                                          .productIds
                                          .contains(_product.id);
                                      // bool isInAnOrder = true;
                                      // Provider.of<OrderProvider>(context,
                                      //         listen: false)
                                      //     .orders
                                      //     .firstWhere(
                                      //         (order) => order.productsMap
                                      //             .containsKey(_product.id),
                                      //         orElse: () {
                                      //   isInAnOrder = false;
                                      //   return null;
                                      // });
                                      if (isInCart) {
                                        Navigator.of(ctx).pop();
                                        showDialog(
                                            context: context,
                                            builder: (ctx) {
                                              return AlertDialog(
                                                title: Text('Not deletable',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                content: Text(
                                                    '${_product.title} is not deletable since it\'s added in cart.'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.of(ctx)
                                                              .pop(),
                                                      child: Text('OK'))
                                                ],
                                              );
                                            });
                                       }
                                      //  else if (isInAnOrder) {
                                      //   Navigator.of(ctx).pop();
                                      //   showDialog(
                                      //       context: context,
                                      //       builder: (ctx) {
                                      //         return AlertDialog(
                                      //           title: Text('Not deletable',
                                      //               style: TextStyle(
                                      //                   fontWeight:
                                      //                       FontWeight.bold)),
                                      //           content: Text(
                                      //               '${_product.title} is not deletable since it\'s in an order.'),
                                      //           actions: [
                                      //             TextButton(
                                      //                 onPressed: () =>
                                      //                     Navigator.of(ctx)
                                      //                         .pop(),
                                      //                 child: Text('OK'))
                                      //           ],
                                      //         );
                                      //       });
                                      // }
                                        else {
                                        removeProductFromList(_position);
                                        Navigator.of(ctx).pop();
                                        listKey.currentState.removeItem(
                                            _position,
                                            (context, animation) =>
                                                SizeTransition(
                                                    sizeFactor: animation,
                                                    child: UserProductItem(
                                                        _product,
                                                        _position,
                                                        _length,
                                                        listKey,
                                                        restoreProduct,
                                                        removeProductFromList)));
                                        Future.delayed(Duration(seconds: 3),
                                            () async {
                                          if (wantsToDelete) {
                                            try{
                                              productsProvider
                                                  .remove(_product,
                                                      await authToken(context))
                                                  .catchError((error) {
                                                listKey.currentState
                                                    .insertItem(_position);
                                                showErrorToast();
                                                HapticFeedback.selectionClick();
                                              });
                                            }
                                            catch(_){
                                              showErrorToast();
                                            }
                                          } else
                                            wantsToDelete = true;
                                        });

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('Product deleted'),
                                          behavior: SnackBarBehavior.floating,
                                          duration: Duration(seconds: 3),
                                          action: SnackBarAction(
                                            label: 'Undo',
                                            onPressed: () {
                                              wantsToDelete = false;
                                              restoreProduct(
                                                  _position, _product);
                                            },
                                          ),
                                        ));
                                      }
                                    },
                                    child: Text('DELETE',
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold))),
                              ],
                            );
                          });
                    })
              ],
            ),
          ),
        ),
        SizedBox(
          height: 10,
        ),
        if (_position < _length - 1) Divider(),
      ],
    );
  }

  void showErrorToast() {
    Fluttertoast.showToast(
        msg:
            noInternet?'No internet connection.':'Some error occurred.\nPlease try again.');
  }
}
