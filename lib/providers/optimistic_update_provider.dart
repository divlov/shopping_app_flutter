import 'package:flutter/foundation.dart';

class OptimisticUpdateProvider with ChangeNotifier {
  double _total = 0;

  double get total {
    return _total + 1 - 1;
  }

  void notifyTotal() {
    notifyListeners();
  }
}
