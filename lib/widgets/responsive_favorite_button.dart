import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/screens/auth_screen.dart';
import '../providers/product.dart';

class FavoriteButton extends StatelessWidget {

  AuthProvider authProvider;
  bool noInternet=false;

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

  bool isUpdating=false;
  @override
  Widget build(BuildContext context) {
    // Product product=Provider.of<Product>(context);
    authProvider=Provider.of<AuthProvider>(context,listen: false);
    return Consumer<Product>(
      builder: (ctx,product,child)=>Container(
        width:30,
        height: 30,
        child: FloatingActionButton(
          heroTag: 'btn${product.id}',
          child: Icon(
              product.isFavorite ?
              Icons.favorite : Icons.favorite_border
          ),
          onPressed: () async{
            if(!isUpdating) {
              isUpdating=true;
              try{
                product
                    .changeFav(await authToken(context), authProvider.userId)
                    .then((value) => isUpdating = false,
                        onError: (_) => handleError());
              }
              catch(_){
                handleError();
              }
            }
          },
          backgroundColor: Colors.pink[300],
        ),
      ),
    );
  }

  void handleError(){
    isUpdating = false;
    if(noInternet){
      Fluttertoast.showToast(msg: 'No internet connection');
    }
    else
    Fluttertoast.showToast(msg: 'Some error occurred.\nPlease try again.');
  }

}