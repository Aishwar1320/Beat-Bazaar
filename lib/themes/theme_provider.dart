import 'package:beat_bazaar/themes/dark_mode.dart';
import 'package:beat_bazaar/themes/light_mode.dart';
import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  //initially light mode
  ThemeData _themeData = lightMode;

  //get theme

  ThemeData get themeData => _themeData;

  //is dark mode

  bool get isDarkMode => _themeData == darkMode;

  //set theme

  set themeData(ThemeData themeData) {
    _themeData = themeData;

    //update ui
    notifyListeners();
  }

  //toggletheme

  void toggletheme() {
    if (_themeData == lightMode) {
      themeData = darkMode;
    } else {
      themeData = lightMode;
    }
  }
}
