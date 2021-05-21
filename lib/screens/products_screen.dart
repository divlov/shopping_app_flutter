import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/main.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/screens/cart_screen.dart';
import 'package:shopping_app/widgets/badge.dart';
import 'package:shopping_app/widgets/drawer.dart';
import '../providers/product.dart';
import '../providers/products_provider.dart';
import '../widgets/product_tile.dart';
import 'auth_screen.dart';

class ProductsScreen extends StatefulWidget {
  static const routeName = '/products_overview_screen';

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  bool showFavs = false, isLoading = true, errorHappened = false;
  AuthProvider authProvider;
  bool isInitState, noInternet = false;


  @override
  void initState() {
    isInitState=true;
    print('initState called product_screen');
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (isInitState) {
      authProvider = Provider.of<AuthProvider>(context);
      fetchProducts();
      isInitState = false;
    }
    super.didChangeDependencies();
  }

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

  Future<void> fetchProducts() async {
    print('fetchProducts called');
    try {
      String authKey = await authToken;
      await Provider.of<ProductsProvider>(context, listen: false)
          .fetchAndSetProducts(authKey, authProvider.userId);
      await Provider.of<CartProvider>(context, listen: false)
          .fetchAndSetCartProducts(authKey);
      setState(() {
        isLoading = false;
      });
    }
    catch (error) {
      Provider.of<CartProvider>(context,listen: false).clearClient();
        if (noInternet) {
          setState(() {
            isLoading = true;
            noInternet = true;
            errorHappened = true;
          });
        } else
          setState(() {
            isLoading = true;
            noInternet = false;
            errorHappened = true;
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);
    List<Product> products = productsProvider.products;
    if (showFavs) products.retainWhere((element) => element.isFavorite == true);
    return Scaffold(
      appBar: AppBar(
        title: MyApp.title,
        actions: [
          PopupMenuButton(
            itemBuilder: (_) => [
              PopupMenuItem(
                child: Row(
                  children: [
                    Text('Favorites Only'),
                    StatefulBuilder(
                      builder: (ctx, setSta) => Checkbox(
                          value: showFavs,
                          onChanged: (val) {
                            setSta(() => showFavs = val);
                            setState(() {});
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Consumer<CartProvider>(
              builder: (ctx, cartProvider, child) => Badge(
                    child: IconButton(
                        icon: Icon(cartProvider.productIds.isNotEmpty
                            ? Icons.shopping_cart
                            : Icons.shopping_cart_outlined),
                        onPressed: () {
                          Navigator.of(context).pushNamed(CartScreen.routeName);
                        }),
                    value: cartProvider.length.toString(),
                    color: Colors.orange,
                  )),
        ],
      ),
      drawer: CustomDrawer(),
      body: isLoading
          ? SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (!errorHappened) CircularProgressIndicator(),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Text(
                      errorHappened
                          ? noInternet
                              ? 'No internet connection'
                              : 'Some error occurred'
                          : 'Loading products..',
                      style: TextStyle(fontSize: 20),
                    ),
                  ),
                  if (errorHappened)
                    ElevatedButton(
                        onPressed: () {
                          setState(() {
                            errorHappened = false;
                          });
                          fetchProducts();
                        },
                        child: Text(
                          'Try again',
                          style: TextStyle(fontSize: 16),
                        ))
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchProducts,
              child: OrientationBuilder(
                builder: (ctx, orientation) => GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      // maxCrossAxisExtent: 200,
                      crossAxisCount:
                          orientation == Orientation.portrait ? 2 : 3,
                      crossAxisSpacing: 15,
                      mainAxisSpacing: 15,
                      childAspectRatio: 2 / 3,
                    ),
                    itemCount: products.length,
                    padding: EdgeInsets.only(bottom: 20, top: 10),
                    itemBuilder: (ctx, index) {
                      Product product = products[index];
                      return ChangeNotifierProvider<Product>.value(
                        child: ProductTile(),
                        value: product,
                      );
                    }),
              ),
            ),
    );
  }
}
