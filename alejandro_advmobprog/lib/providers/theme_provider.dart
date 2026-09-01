import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDark = false;

  bool get isDark => _isDark;

  ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      useMaterial3: true,
      colorSchemeSeed:
          Colors.lightBlue, // Changed from default violet to light blue
    );
  }

  ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      useMaterial3: true,
      colorSchemeSeed:
          Colors.lightBlueAccent, // Consistent light blue accent for dark mode
    );
  }

  void toggleTheme() {
    _isDark = !_isDark;
    notifyListeners();
  }
}
