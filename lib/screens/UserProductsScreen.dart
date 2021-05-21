import 'package:animations/animations.dart';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/product.dart';
import 'package:shopping_app/providers/products_provider.dart';
import 'package:shopping_app/screens/edit_product_screen.dart';
import 'package:shopping_app/widgets/user_product_item.dart';

import 'auth_screen.dart';

class UserProductsScreen extends StatefulWidget {
  static const routeName = '/user-products-screen';

  @override
  _UserProductsScreenState createState() => _UserProductsScreenState();
}

class _UserProductsScreenState extends State<UserProductsScreen> {
  GlobalKey<AnimatedListState> listKey = GlobalKey<AnimatedListState>();

  List<Product> productsList;

  AuthProvider authProvider;

  bool isInitState = true, noInternet = false;

  Future _future;

  Future<String> get authToken {
    return authProvider.token.then((value) {
      if (value == null) throw value;
      noInternet = false;
      return value;
    }).catchError((error) {
      return Connectivity().checkConnectivity().then((value) {
        if (value == ConnectivityResult.none) {
          noInternet = true;
          throw error;
        } else {
          authProvider.logOut();
          Navigator.of(context).pushNamed(AuthScreen.routeName);
          Fluttertoast.showToast(msg: 'Token expired.\nPlease login again.');
        }
      });
    });
  }

  Future<void> fetchUserProducts() async {
    try {
      String authKey = await authToken;
      return Provider.of<ProductsProvider>(context, listen: false)
          .fetchAndSetUserProducts(authKey, authProvider.userId)
          .then((_) {
        return;
      }, onError: (error) {
        print(error.toString());
        throw error;
      });
    } catch (_) {
      throw _;
    }
  }

  @override
  void didChangeDependencies() {
    if (isInitState) {
      authProvider = Provider.of<AuthProvider>(context);
      _future = fetchUserProducts();
      isInitState = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Products'),
      ),
      floatingActionButton: OpenContainer(
        transitionDuration: Duration(milliseconds: 400),
        closedShape: CircleBorder(side: BorderSide(width: 0.0)),
        tappable: true,
        closedBuilder: (ctx, closedBuilder) => FloatingActionButton(
          child: Icon(Icons.add),
          // onPressed: (){
          //   Navigator.of(context).pushNamed(EditProductScreen.routeName);
          // },
        ),
        openBuilder: (ctx, openBuilder) => EditProductScreen(
          listKey: listKey,
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () {
          setState(() {
          _future = fetchUserProducts();
          });
          return _future;
        },
        child:
            Consumer<ProductsProvider>(builder: (ctx, productsProvider, child) {
          return FutureBuilder(
              future: _future,
              builder: (ctx, snapShot) {
                productsList = productsProvider.userProducts;
                if (snapShot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SizedBox.expand(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            'Loading products..',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                      ],
                    )),
                  );
                } else if (snapShot.hasError) {
                  print(snapShot.error);
                  return Center(
                    child: SizedBox.expand(
                        child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: Text(
                            noInternet
                                ? 'No internet connection'
                                : 'Some error occurred',
                            style: TextStyle(fontSize: 20),
                          ),
                        ),
                        ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _future = fetchUserProducts();
                              });
                            },
                            child: Text(
                              'Try again',
                              style: TextStyle(fontSize: 16),
                            ))
                      ],
                    )),
                  );
                } else {
                  return productsList.length == 0
                      ? Center(
                          child: Text(
                          'No products created by you, yet.',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                              color: Colors.grey),
                        ))
                      : AnimatedList(
                          key: listKey,
                          initialItemCount: productsProvider.userProductsLength,
                          padding: EdgeInsets.only(top: 20),
                          itemBuilder: (ctx, position, animation) {
                            if (position >= productsProvider.userProductsLength)
                              return null;
                            return SizeTransition(
                                sizeFactor: animation,
                                child: UserProductItem(
                                    productsList[position],
                                    position,
                                    productsProvider.userProductsLength,
                                    listKey,
                                    restoreProduct,
                                    removeProductFromList));
                          });
                }
              });
        }),
      ),
    );
  }

  void removeProductFromList(int index) {
    productsList.removeAt(index);
  }

  void addProductToList(Product product) {
    productsList.add(product);
  }

  void restoreProduct(int _position, Product _product) {
    productsList.insert(_position, _product);
    listKey.currentState.insertItem(_position);
    HapticFeedback.selectionClick();
  }
}
