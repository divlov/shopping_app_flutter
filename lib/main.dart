import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/helpers/custom_route.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/cart_provider.dart';
import 'package:shopping_app/providers/optimistic_update_provider.dart';
import 'package:shopping_app/providers/order_provider.dart';
import 'package:shopping_app/providers/products_provider.dart';
import 'package:shopping_app/screens/UserProductsScreen.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import 'package:shopping_app/screens/cart_screen.dart';
import 'package:shopping_app/screens/edit_product_screen.dart';
import 'package:shopping_app/screens/orders_screen.dart';
import 'package:shopping_app/screens/product_details_screen.dart';
import 'package:shopping_app/screens/products_screen.dart';
import 'package:shopping_app/screens/splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  static Text title = Text('My Shop');
  Future _future;

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) => AuthProvider()),
        ChangeNotifierProvider(create: (ctx) => ProductsProvider()),
        ChangeNotifierProvider(create: (ctx) => CartProvider()),
        ChangeNotifierProvider(create: (ctx) => OrderProvider()),
        ChangeNotifierProvider(create: (ctx) => OptimisticUpdateProvider()),
      ],
      child: Consumer<AuthProvider>(
        builder: (ctx, authProvider, _) => MaterialApp(
          theme: ThemeData(
              primarySwatch: Colors.teal,
              fontFamily: 'Lato',
              pageTransitionsTheme: PageTransitionsTheme(builders: {
                TargetPlatform.android: CustomPageTransitionsBuilder(),
                TargetPlatform.iOS: CustomPageTransitionsBuilder(),
              })),
          title: 'My Shop',
          routes: {
            '/': (ctx) => FutureBuilder(
                future: _future ??= authProvider.isUserLoggedIn(),
                builder: (ctx, dataSnapshot) {
                  if (dataSnapshot.connectionState == ConnectionState.waiting)
                    return SplashScreen();
                  else if (dataSnapshot.hasError) {
                    print('error in main.dart');
                    SystemNavigator.pop(animated: true);
                    return null;
                  } else if (dataSnapshot.data == true) {
                    print('dataSnapshot true');
                    return ProductsScreen();
                  } else
                    return AuthScreen();
                }),
            AuthScreen.routeName: (ctx) => AuthScreen(),
            ProductsScreen.routeName: (ctx) => ProductsScreen(),
            ProductDetailsScreen.routeName: (ctx) => ProductDetailsScreen(),
            CartScreen.routeName: (ctx) => CartScreen(),
            OrderScreen.routeName: (ctx) => OrderScreen(),
            UserProductsScreen.routeName: (ctx) => UserProductsScreen(),
            EditProductScreen.routeName: (ctx) => EditProductScreen(),
          },
        ),
      ),
    );
  }
}
