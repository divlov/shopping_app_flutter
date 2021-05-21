import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';
import 'package:shopping_app/providers/auth.dart';
import 'package:shopping_app/screens/products_screen.dart';

enum AuthMode { Signup, Login }

class AuthScreen extends StatelessWidget {
  static const routeName = '/auth';
  int wantsToExit = 0;

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    // final transformConfig = Matrix4.rotationZ(-8 * pi / 180);
    // transformConfig.translate(-10.0);
    return WillPopScope(
      onWillPop: () {
        if (wantsToExit == 0) {
          Fluttertoast.showToast(msg: 'Press back 1 more time to exit.');
          wantsToExit++;
          Timer(Duration(seconds: 2), () {
            wantsToExit = 0;
          });
          return Future.value(false);
        } else
          SystemNavigator.pop(animated: true);
        return Future.value(false);
      },
      child: Scaffold(
        // resizeToAvoidBottomInset: false,
        body: Stack(
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(215, 117, 255, 1).withOpacity(0.5),
                    Color.fromRGBO(255, 188, 117, 1).withOpacity(0.9),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  stops: [0, 1],
                ),
              ),
            ),
            SingleChildScrollView(
              child: Container(
                height: deviceSize.height,
                width: deviceSize.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Container(
                        margin: EdgeInsets.only(bottom: 20.0),
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 94.0),
                        transform: Matrix4.rotationZ(-8 * pi / 180)
                          ..translate(-10.0),
                        // ..translate(-10.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: Colors.deepOrange.shade900,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 8,
                              color: Colors.black26,
                              offset: Offset(0, 2),
                            )
                          ],
                        ),
                        child: Text(
                          'MyShop',
                          style: TextStyle(
                            color: Theme.of(context)
                                .accentTextTheme
                                .headline6
                                .color,
                            fontSize: 50,
                            fontFamily: 'Anton',
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                    Flexible(
                      flex: deviceSize.width > 600 ? 2 : 1,
                      child: AuthCard(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthCard extends StatefulWidget {
  const AuthCard({
    Key key,
  }) : super(key: key);

  @override
  _AuthCardState createState() => _AuthCardState();
}

class _AuthCardState extends State<AuthCard>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey();
  AuthMode _authMode = AuthMode.Login;
  Map<String, String> _authData = {
    'email': '',
    'password': '',
  };
  var _isLoading = false;
  var _errorHappened = false;
  var _errorMessage = '';
  final _passwordController = TextEditingController();
  AnimationController _controller;
  Animation<Size> _heightAnimation;

  @override
  void initState() {
    _controller =
        AnimationController(vsync: this, duration: Duration(milliseconds: 350));
    // _controller.addListener(() {setState(() {});});
    _heightAnimation = Tween<Size>(
            begin: Size(double.infinity, 260), end: Size(double.infinity, 320))
        .animate(
            CurvedAnimation(parent: _controller, curve: Curves.fastOutSlowIn));
    super.initState();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState.save();
    setState(() {
      _errorHappened = false;
      _isLoading = true;
    });
    if (_authMode == AuthMode.Login) {
      Provider.of<AuthProvider>(context, listen: false)
          .logIn(_authData['email'], _authData['password'])
          .then((value) {
        final ap = Provider.of<AuthProvider>(context, listen: false);
        if (ap.userId == ap.previousUserId)
          Navigator.of(context).pop();
        else
          Navigator.of(context).pushNamedAndRemoveUntil(
              ProductsScreen.routeName, (route) => false);
      }, onError: (error) {
        print('got error ' + error.toString());

        handleError(error);
      });
    } else {
      Provider.of<AuthProvider>(context, listen: false)
          .signUp(_authData['email'], _authData['password'])
          .then((value) {
        Navigator.of(context).pushNamedAndRemoveUntil(
            ProductsScreen.routeName, (route) => false);
      }, onError: (error) {
        print('got error ' + error.toString());

        handleError(error);
      });
    }
  }

  void handleError(error) {
    switch (error.toString()) {
      case 'EMAIL_EXISTS':
        print('email exists');
        showError('The email address is already in use by another account');
        break;
      case 'TOO_MANY_ATTEMPTS_TRY_LATER':
        showError(
            'We have blocked all requests from this device due to unusual activity. Try again later.');
        break;
      case 'INVALID_EMAIL':
        showError('This is not a valid email address');
        break;
      case 'WEAK_PASSWORD':
        showError('The password is too weak.');
        break;
      case 'INVALID_PASSWORD':
      case 'EMAIL_NOT_FOUND':
        showError('Incorrect email/password entered.');
        break;
      default:
        setState(() {
          _isLoading = false;
        });
        Fluttertoast.showToast(msg: 'An error occurred.\nPlease try again.');
    }
  }

  void showError(String message) {
    setState(() {
      _isLoading = false;
      _errorHappened = true;
      _errorMessage = message;
    });
  }

  void _switchAuthMode() {
    if (_authMode == AuthMode.Login) {
      setState(() {
        _formKey.currentState.reset();
        _authMode = AuthMode.Signup;
      });
      _controller.forward();
    } else {
      setState(() {
        _formKey.currentState.reset();
        _authMode = AuthMode.Login;
      });
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final deviceSize = MediaQuery.of(context).size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          elevation: 8.0,
          //or use AnimatedContainer and change the height and constraints to the commented out one
          //and remove all animation
          child: AnimatedBuilder(
            animation: _heightAnimation,
            builder: (ctx, child) {
              return Container(
                  // height: _authMode==AuthMode.Signup ?320 : 240,
                  height: _heightAnimation.value.height,
                  constraints:
                      BoxConstraints(minHeight: _heightAnimation.value.height),
                  width: deviceSize.width * 0.75,
                  padding: EdgeInsets.all(16.0),
                  child: child);
            },
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      decoration: InputDecoration(labelText: 'E-Mail'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value.isEmpty || !value.contains('@')) {
                          return 'Invalid email!';
                        }
                        return null;
                      },
                      textInputAction: TextInputAction.next,
                      onSaved: (value) {
                        _authData['email'] = value;
                      },
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                      controller: _passwordController,
                      validator: (value) {
                        if (value.isEmpty || value.length < 5) {
                          return 'Password is too short!';
                        }
                        return null;
                      },
                      textInputAction: _authMode == AuthMode.Signup
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted:
                          _authMode == AuthMode.Login ? (_) => _submit : null,
                      onSaved: (value) {
                        _authData['password'] = value;
                      },
                    ),
                    // if (_authMode == AuthMode.Signup)
                      AnimatedContainer(
                        duration: Duration(milliseconds: 350),
                        constraints: BoxConstraints(maxHeight: _authMode==AuthMode.Login?0:70),
                        curve: Curves.fastOutSlowIn,
                        child: FadeTransition(
                          opacity: CurvedAnimation(parent: _controller,curve: Curves.fastOutSlowIn),
                          child: SlideTransition(
                            position: Tween<Offset>(begin: Offset(0, -1.0),end: Offset(0, 0)).animate(CurvedAnimation(parent: _controller,curve: Curves.fastOutSlowIn)),
                            child: TextFormField(
                              enabled: _authMode == AuthMode.Signup,
                              decoration:
                                  InputDecoration(labelText: 'Confirm Password'),
                              obscureText: true,
                              textInputAction: TextInputAction.done,
                              onFieldSubmitted: (_) => _submit(),
                              validator: _authMode == AuthMode.Signup
                                  ? (value) {
                                      if (value != _passwordController.text) {
                                        return 'Passwords do not match!';
                                      }
                                      return null;
                                    }
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: 20,
                    ),
                    if (_isLoading)
                      CircularProgressIndicator()
                    else
                      ElevatedButton(
                        child: Text(
                            _authMode == AuthMode.Login ? 'LOGIN' : 'SIGN UP'),
                        onPressed: _submit,
                        style: ButtonStyle(
                          shape:
                              MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          )),
                          padding: MaterialStateProperty.all(
                              EdgeInsets.symmetric(
                                  horizontal: 30.0, vertical: 8.0)),
                          backgroundColor: MaterialStateProperty.all(
                              Theme.of(context).primaryColor),
                          textStyle: MaterialStateProperty.all(TextStyle(
                              color: Theme.of(context)
                                  .primaryTextTheme
                                  .button
                                  .color)),
                        ),
                      ),
                    TextButton(
                      child: Text(
                        '${_authMode == AuthMode.Login ? 'SIGNUP' : 'LOGIN'}',
                        style: TextStyle(color: Theme.of(context).primaryColor),
                      ),
                      onPressed: _switchAuthMode,
                      style: ButtonStyle(
                        padding: MaterialStateProperty.all(EdgeInsets.symmetric(
                            horizontal: 30.0, vertical: 4)),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_errorHappened)
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey[800])),
            margin: EdgeInsets.all(30),
            width: deviceSize.width * 0.75,
            padding: EdgeInsets.all(10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error,
                  color: Colors.grey[800],
                ),
                SizedBox(width: 5),
                Flexible(
                    child: Text(_errorMessage,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800]))),
              ],
            ),
          ),
      ],
    );
  }
}
