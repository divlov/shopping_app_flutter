import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/order_provider.dart';
import 'package:shopping_app/providers/product.dart';
import '../models/Order.dart';
import 'auth_screen.dart';

class OrderScreen extends StatefulWidget {
  static String routeName = '/orders';

  @override
  _OrderScreenState createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> with SingleTickerProviderStateMixin{
  bool isLoading = true, errorHappened = false, isInitState, noInternet = false;
  AuthProvider authProvider;
  Future _future;
  AnimationController _controller;
  Animation<Offset> _slideAnimation;

  @override
  void initState() {
    isInitState = true;
    _controller=AnimationController(vsync: this,duration: Duration(milliseconds: 300));
    _slideAnimation=Tween<Offset>(begin: Offset(0,-1),end: Offset(0,0)).animate(CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));
    super.initState();
  }

  @override
  void didChangeDependencies() {
    if (isInitState) {
      authProvider = Provider.of<AuthProvider>(context);
      _future = fetchOrders();
      isInitState = false;
    }
    super.didChangeDependencies();
  }

  Future fetchOrders() {
    return authToken.then(
        (value) => Provider.of<OrderProvider>(context, listen: false)
            .fetchAndSetOrders(value, authProvider.userId)
            .then((value) => null), onError: (_) {
      throw _;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    OrderProvider orderProvider = Provider.of<OrderProvider>(context);
    return Scaffold(
        appBar: AppBar(
          title: Text('My Shop'),
        ),
        body: FutureBuilder(
            future: _future,
            builder: (context, dataSnapshot) {
              List<Order> orders = orderProvider.orders;
              if (dataSnapshot.connectionState == ConnectionState.waiting) {
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
                          'Loading orders..',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                    ],
                  )),
                );
              } else if (dataSnapshot.error != null) {
                return Center(
                  child: SizedBox.expand(
                      child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          noInternet?'No internet connection':'Some error occurred',
                          style: TextStyle(fontSize: 20),
                        ),
                      ),
                      ElevatedButton(
                          onPressed: (){
                            setState(() {
                              _future = fetchOrders();
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
                return (orders.length > 0)
                    ? ListView.builder(
                        padding: EdgeInsets.only(bottom: 15),
                        itemBuilder: (ctx, position) {
                          bool _expanded = false;
                          Order order = orders[position];
                          List<Product> products =
                              order.productsMap.keys.toList();
                          return StatefulBuilder(
                            builder: (ctx, setState) {
                              return Card(
                                elevation: 2,
                                margin: EdgeInsets.all(10),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _expanded = !_expanded;
                                    });
                                  },
                                  child: Column(
                                    children: [
                                      ListTile(
                                        title: Text(
                                          order.productsMap.length.toString() +
                                              (order.productsMap.length > 1
                                                  ? ' items'
                                                  : ' item'),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                        subtitle: Text(DateFormat(
                                                DateTime.now().year !=
                                                        order.dateTime.year
                                                    ? 'dd MMM yyyy'
                                                    : 'dd MMM')
                                            .format(order.dateTime)),
                                        trailing: Text(
                                          '\$' +
                                              orders[position]
                                                  .amount()
                                                  .toStringAsFixed(2),
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18),
                                        ),
                                      ),
                                      // if (_expanded)
                                      AnimatedContainer(
                                        duration: Duration(milliseconds: 300),
                                        curve: Curves.fastOutSlowIn,
                                          height: _expanded?products.length > 2
                                              ? (2 * 60.0) + 47 + 30
                                              : (products.length * 60.0) + 47:0,
                                          child: ListView.builder(
                                            itemBuilder: (ctx, _position) {
                                              Product _product =
                                                  products[_position];
                                              int _quantity =
                                                  order.productsMap[_product];
                                              print(_product.title +
                                                  _quantity.toString());
                                              return Padding(
                                                padding:
                                                    EdgeInsets.only(left: 6),
                                                child: Column(
                                                  children: [
                                                    SizedBox(
                                                        height: _position == 0
                                                            ? 20
                                                            : 10),
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 100,
                                                          child: Column(
                                                            children: [
                                                              Text(
                                                                _product.title,
                                                                style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                    fontSize:
                                                                        16),
                                                                softWrap: false,
                                                                overflow:
                                                                    TextOverflow
                                                                        .fade,
                                                              ),
                                                              SizedBox(
                                                                height: 5,
                                                              ),
                                                              Text(
                                                                '\$${_product.price}',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                            .grey[
                                                                        700]),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                        SizedBox(
                                                          width: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              4.7,
                                                        ),
                                                        Padding(
                                                          padding: EdgeInsets
                                                              .symmetric(
                                                                  horizontal:
                                                                      5),
                                                          child: Text(
                                                            _quantity
                                                                    .toString() +
                                                                'x',
                                                            style: TextStyle(
                                                                fontSize: 17,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold),
                                                          ),
                                                        ),
                                                        Spacer(),
                                                        Chip(
                                                            label: Text(
                                                          (_product.price *
                                                                  _quantity)
                                                              .toStringAsFixed(
                                                                  2),
                                                          softWrap: false,
                                                          overflow:
                                                              TextOverflow.fade,
                                                        )),
                                                        SizedBox(width: 10),
                                                      ],
                                                    ),
                                                    SizedBox(
                                                      height: 20,
                                                    )
                                                  ],
                                                ),
                                              );
                                            },
                                            itemCount: products.length,
                                          ),
                                        ),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Padding(
                                          padding: EdgeInsets.all(7),
                                          child: Icon(_expanded
                                              ? Icons.expand_less
                                              : Icons.expand_more),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          );
                        },
                        itemCount: orders.length,
                      )
                    : Center(
                        child: Text(
                        'No orders placed, yet.',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            color: Colors.grey),
                      ));
              }
            }));
  }
}
