import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/providers/product.dart';
import 'package:shopping_app/providers/products_provider.dart';
import 'package:http/http.dart' as http;

import 'auth_screen.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = '/edit-product-screen';
  GlobalKey<AnimatedListState> listKey;

  EditProductScreen({this.listKey});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final imageURLController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();
  final titleController = TextEditingController();
  Product product;
  AuthProvider authProvider;

  final imageURLFocusNode = FocusNode();

  bool isImageURL = false, emptyURL = true, isInit, isLoading = false, noInternet=false;

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
  void initState() {
    imageURLFocusNode.addListener(() {
      imageUrlListener();
    });
    super.initState();
    isInit = true;
  }

  void imageUrlListener() {
    if (!imageURLFocusNode.hasFocus) {
      if (imageURLController.text.isNotEmpty) {
        setState(() {
          emptyURL = false;
        });
      } else {
        setState(() {
          emptyURL = true;
        });
      }
    }
  }

  @override
  void didChangeDependencies() {
    if (isInit) {
      final args = ModalRoute.of(context).settings.arguments as Map<String,dynamic>;
      if(args!=null){
        product = args['product'];
        widget.listKey = args['listKey'];
      }
      if (product != null) {
        emptyURL = false;
        imageURLController.value = TextEditingValue(text: product.imageUrl);
        priceController.value =
            TextEditingValue(text: product.price.toString());
        descriptionController.value =
            TextEditingValue(text: product.description);
        titleController.value = TextEditingValue(text: product.title);
      }
    }
    isInit = false;
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    authProvider=Provider.of<AuthProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Product'),
      ),
      body: Stack(
        children: [
          if (isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Title'),
                          textInputAction: TextInputAction.next,
                          controller: titleController,
                          validator: (text) {
                            if (text.isEmpty) return 'Please enter title';
                            return null;
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Price'),
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          controller: priceController,
                          validator: (text) {
                            if (text.isEmpty) return 'Please enter title';
                            try {
                              double p = double.parse(text);
                              if (p <= 0.0)
                                return 'Please enter a price greater than zero';
                              return null;
                            } catch (_) {
                              return 'Please enter a number only';
                            }
                          },
                        ),
                        TextFormField(
                          decoration: InputDecoration(labelText: 'Description'),
                          keyboardType: TextInputType.multiline,
                          maxLines: 3,
                          textInputAction: TextInputAction.newline,
                          controller: descriptionController,
                          validator: (text) {
                            if (text.isEmpty) return 'Please enter description';
                            return null;
                          },
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              height: 100,
                              width: 100,
                              decoration: BoxDecoration(
                                  border:
                                      Border.all(width: 1, color: Colors.grey)),
                              child: !emptyURL
                                  ? AspectRatio(
                                      aspectRatio: 1 / 1,
                                      child: Image.network(
                                          imageURLController.text,
                                          fit: BoxFit.fill))
                                  : Center(
                                      child: Padding(
                                      padding: const EdgeInsets.all(4.0),
                                      child: Text('Please enter image\'s URL'),
                                    )),
                            ),
                            SizedBox(
                              width: 10,
                            ),
                            Flexible(
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Image URL',
                                ),
                                controller: imageURLController,
                                focusNode: imageURLFocusNode,
                                textInputAction: TextInputAction.done,
                                validator: (text) {
                                  if (text.isEmpty) return 'Please enter URL';
                                  if (!isImageURL) {
                                    return 'Please enter a correct URL';
                                  } else {
                                    return null;
                                  }
                                },
                                // onSaved: (_) {},
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                        onPressed: () {
                          http
                              .get(Uri.parse(imageURLController.text))
                              .then((value) {
                                if(value.statusCode<400)
                            isImageURL = value.headers['content-type']
                                .startsWith('image/');
                                else
                                  isImageURL=false;
                                print(value.headers);
                            validate(context);
                          },
                          onError: (error){
                                isImageURL=false;
                                validate(context);
                          });
                        },
                        child: Text('Save Product')),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void validate(BuildContext context) async {
    if (_formKey.currentState.validate()) {
      setState(() {
        isLoading = true;
      });
      ProductsProvider productsProvider =
          Provider.of<ProductsProvider>(context,
              listen: false);
      if (product == null) {
        Product newProduct = Product(
            id: null,
            imageUrl: imageURLController.text,
            description: descriptionController.text,
            title: titleController.text,
            price: double.parse(priceController.text),
            isFavorite: false);
        try{
          productsProvider
              .add(newProduct, await authToken, authProvider.userId)
              .then((value) {
            widget.listKey.currentState
                .insertItem(productsProvider.userProductsLength - 1);
            Fluttertoast.showToast(msg: 'Product Saved!');
            Navigator.of(context).pop();
          }, onError: (error) {
            showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text(
                      'Some error occurred!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text('Please try again.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text('OK'))
                    ],
                  );
                });
          });
        }
        catch(_){
          showErrorToast();
        }
      } else {
        Product newProduct = Product(
            id: product.id,
            imageUrl: imageURLController.text,
            description: descriptionController.text,
            title: titleController.text,
            price: double.parse(priceController.text),
            isFavorite: product.isFavorite);
        try{
          productsProvider.set(product.id, newProduct, await authToken).then(
              (value) {
            // widget.listKey.currentState.setState();
            Fluttertoast.showToast(msg: 'Product Saved!');
            Navigator.of(context).pop();
          }, onError: (error) {
            showDialog(
                context: context,
                builder: (ctx) {
                  return AlertDialog(
                    title: Text(
                      'Some error occurred!',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    content: Text('Please try again.'),
                    actions: [
                      TextButton(
                          onPressed: () {
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.pop(ctx);
                          },
                          child: Text('OK'))
                    ],
                  );
                });
          });
        }
        catch(_){
          showErrorToast();
        }
      }
    }
  }

  void showErrorToast() {
    if(noInternet)
      Fluttertoast.showToast(msg: 'No internet connection');
    else
      Fluttertoast.showToast(msg: 'Some error occurred.\nPlease try again.');
  }

  @override
  void dispose() {
    imageURLFocusNode.removeListener(imageUrlListener);
    imageURLController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    super.dispose();
  }
}
