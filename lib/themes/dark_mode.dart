import 'package:flutter/material.dart';

ThemeData darkMode = ThemeData(
    colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark).copyWith(
        secondary: Colors.deepPurple,
        primary: Colors.black,
        surface: Colors.black,
        onSurface: Colors.white));
