import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/main.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/optimistic_update_provider.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import '../models/Order.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/providers/order_provider.dart';
import 'package:shopping_app/providers/product.dart';
import 'package:shopping_app/providers/products_provider.dart';
import 'package:shopping_app/widgets/cart_item.dart';

class CartScreen extends StatefulWidget {
  static String routeName = '/cart';

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  bool noInternet=false;

  List<Product> productsList;

  CartProvider cartProvider;

  ProductsProvider productsProvider;

  AuthProvider authProvider;

  bool isOrdering = false;

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
    cartProvider = Provider.of<CartProvider>(context);
    productsProvider = Provider.of<ProductsProvider>(context);
    List<String> productIds = cartProvider.productIds;
    productsList = [];
    productIds.forEach((id) {
      productsList.add(
          productsProvider.products.where((element) => element.id == id).first);
    });
    // print(productsList);
    authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: MyApp.title,
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Text('Total',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 22)),
                    Consumer<OptimisticUpdateProvider>(
                      builder: (ctx, optimisticUpdateProvider, child) {
                        double t = 0;
                        var tempMap = cartProvider.cartProductsMap;
                        productsList.forEach((product) {
                          t += product.price * tempMap[product.id];
                        });
                        return Text(
                          '\$' +
                              t
                                  .toStringAsFixed(2),
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 22),
                        );
                      },
                    ),
                  ],
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                ),
              ),
            ),
            if (productsList.length > 0)
              Flexible(
                  child: Card(
                child: Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: AnimatedList(
                    key: listKey,
                    itemBuilder: (ctx, position, animation) {
                      if(position>=productsList.length)
                        return null;
                      Product product = productsList[position];
                      int quantitty = cartProvider.cartProductsMap[product.id];
                      return Dismissible(
                        key: ValueKey(product.id),
                        onDismissed: (_) {
                          bool wantsToDelete = true;
                          Future.delayed(Duration(seconds: 3, milliseconds: 20),
                              () {
                            if (wantsToDelete) {
                              authToken.then((value) => cartProvider
                                      .removeProductFromCart(product.id, value)
                                      .catchError((error) {
                                    restoreProduct(
                                        product, quantitty, position);
                                    showErrorToast();
                                  }),onError: (_)=>showErrorToast());
                            }
                          });
                          removeFromProductsList(position);
                          listKey.currentState
                              .removeItem(position, (_, __) => Container());
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(
                              'Product removed from cart',
                              style: TextStyle(fontSize: 15),
                            ),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () {
                                wantsToDelete = false;
                                restoreProduct(product, quantitty, position);
                              },
                            ),
                            duration: Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                            margin: EdgeInsets.only(
                                bottom: 30, left: 10, right: 10),
                          ));
                        },
                        confirmDismiss: (dismissDirection) {
                          HapticFeedback.selectionClick();
                          return Future.value(true);
                        },
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Theme.of(context).errorColor,
                          child: Icon(
                            Icons.delete,
                            size: 38,
                            color: Colors.white,
                          ),
                          alignment: Alignment.centerRight,
                          padding: EdgeInsets.only(right: 20),
                        ),
                        child: SizeTransition(
                          sizeFactor: animation,
                          child: CartItem(
                            product,
                            quantitty,
                            listKey,
                            position,
                            removeFromProductsList: removeFromProductsList,
                            restoreProduct: restoreProduct,
                          ),
                        ),
                      );
                    },
                    initialItemCount: productsList.length,
                    shrinkWrap: true,
                    padding: EdgeInsets.only(left: 7),
                  ),
                ),
              )),
            SizedBox(
              height: 8,
            ),
            Align(
              child: isOrdering
                  ? Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: CircularProgressIndicator(),
                    )
                  : ElevatedButton(
                      onPressed: cartProvider.length == 0
                          ? null
                          : () async {
                              setState(() {
                                isOrdering = true;
                              });
                              try{
                                Provider.of<OrderProvider>(context,
                                        listen: false)
                                    .add(
                                        Order(cartProvider.cartProductsMap
                                            .map((key, value) {
                                          Product pro = productsProvider
                                              .products
                                              .where((element) =>
                                                  element.id == key)
                                              .first;
                                          return MapEntry(pro, value);
                                        }), DateTime.now()),
                                        await authToken,
                                        authProvider.userId)
                                    .then((value) async {
                                  Fluttertoast.showToast(
                                      msg: 'Order Placed!',
                                      toastLength: Toast.LENGTH_LONG);
                                  setState(() {
                                    isOrdering = false;
                                  });
                                  try {
                                    await cartProvider.clear(await authToken);
                                    listKey.currentState.setState(() {
                                      productsList.clear();
                                    });
                                  } catch (_) {
                                    showErrorToast();
                                    /* not handling error */
                                  }
                                }, onError: (error) {
                                  showErrorToast();
                                  setState(() {
                                    isOrdering = false;
                                  });
                                });
                              }
                              catch(_){
                                showErrorToast();
                              }
                            },
                      child: Text('Order Now'),
                    ),
              alignment: Alignment.centerRight,
            ),
          ],
        ),
      ),
    );
  }

  void showErrorToast() {
    if( noInternet){
      Fluttertoast.showToast(msg: 'No internet connection');
    }
    Fluttertoast.showToast(msg: 'Some error occurred.\nPlease try again.');
  }

  void removeFromProductsList(int position) {
    productsList.removeAt(position);
    Provider.of<OptimisticUpdateProvider>(context,listen: false).notifyTotal();
  }

  void restoreProduct(Product product, int quantitty, int position) {
    // cartProvider.restoreProduct(product.id, quantitty, position);
    productsList.insert(position, product);
    Provider.of<OptimisticUpdateProvider>(context,listen: false).notifyTotal();
    listKey.currentState.insertItem(position);
    HapticFeedback.selectionClick();
  }
}
