import 'package:flutter/foundation.dart';

class SupplierProvider extends ChangeNotifier {
  String? _location;
  String? _category;

  String? get location => _location;
  String? get category => _category;

  void setFilters({String? location, String? category}) {
    _location = location;
    _category = category;
    notifyListeners();
  }
}


