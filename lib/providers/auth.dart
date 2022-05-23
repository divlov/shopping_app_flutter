import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopping_app/models/http_exception.dart';

class AuthProvider with ChangeNotifier {
  String _token, _refreshToken, _userId, _previousUserId;
  DateTime _expiry;
  final prefs=SharedPreferences.getInstance();
  SharedPreferences sp;

  Future<http.Response> authenticate(
      String email, String password, String urlSegment) {
    _previousUserId=_userId;
    Uri url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=/*TODO: insert google api key*/');
    return http
        .post(url,
            body: json.encode({
              'email': email,
              'password': password,
              'returnSecureToken': true,
            }))
        .then((value) {
      Map<String, dynamic> extractedData = json.decode(value.body);
      if (extractedData['error'] != null) {
        print('extractedData[\'error\'] != null\n'+value.body);
        throw HttpException(extractedData['error']['message']);
      }
      _token = extractedData['idToken'];
      _refreshToken = extractedData['refreshToken'];
      _userId = extractedData['localId'];
      _expiry = DateTime.now()
          .add(Duration(seconds: int.parse(extractedData['expiresIn'])));
      return prefs.then((sp){
        this.sp=sp;
        final userData=jsonEncode({
          'token':_token,
          'refreshToken':_refreshToken,
          'userId':_userId,
          'expiry':_expiry.toIso8601String(),
          'previousUserId':_previousUserId,
        });
        sp.setString('userData', userData);
      return value;
      },onError: (_) => throw _);
    }, onError: (error) {
      print(error);
      throw error;
    });
  }

  Future<http.Response> signUp(String email, String password) {
    return authenticate(email, password, 'signUp');
  }

  Future<http.Response> logIn(String email, String password) {
    return authenticate(email, password, 'signInWithPassword');
  }

  Future<bool> isUserLoggedIn() async{
    print('in isUserLoggedIn');
    try{
      sp = await prefs;
      var source = sp.getString('userData');
      if (source != null) {
        Map<String, dynamic> userData = jsonDecode(source);
        _previousUserId = userData['previousUserId'];
        _expiry = DateTime.parse(userData['expiry']);
        _userId = userData['userId'];
        _refreshToken = userData['refreshToken'];
        _token = userData['token'];
        return true;
      }
      return false;
    }
    catch(error){
      throw error;
    }
  }

  Future<String> get token {
    if (_token != null) {
      if (DateTime.now().isBefore(_expiry.subtract(Duration(seconds: 60))))
        return Future.value(_token + '');
      print(_refreshToken);
      return http.post(
          Uri.parse(
              'https://securetoken.googleapis.com/v1/token?key=AIzaSyBbZNGApW6avSyJQqNs1nEYZDGIDCEuVZw&grant_type=refresh_token&refresh_token=$_refreshToken'),
          // body: json.encode({'grant_type': 'refresh_token', 'refresh_token': _refreshToken}),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded'
          }).then((value) {
        Map<String, dynamic> extractedData = json.decode(value.body);
        if (extractedData['error'] != null) {
          print(value.body);
          // notifyListeners();
          throw value;
        }
        _token = extractedData['id_token'];
        _refreshToken = extractedData['refresh_token'];
        _userId = extractedData['user_id'];
        _expiry = DateTime.now()
            .add(Duration(seconds: int.parse(extractedData['expires_in'])));
        return _token + '';
      }, onError: (error) {
        print(error);
        // notifyListeners();
        throw error;
      });
    }
    else
    {
      // notifyListeners();
      throw HttpException('No user logged in.');
    }
  }

  void logOut(){
    sp.remove('userData');
    _token=null;
    _refreshToken=null;
    _expiry=null;
    _userId=null;
  }

  String get userId{
    return _userId;
  }

  String get previousUserId{
    return _previousUserId;
  }
}
