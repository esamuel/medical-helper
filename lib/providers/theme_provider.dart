import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _isDarkModeKey = 'isDarkMode';
  bool _isDarkMode = true;

  ThemeProvider() {
    _loadThemePreference();
  }

  bool get isDarkMode => _isDarkMode;

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_isDarkModeKey) ?? true;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, _isDarkMode);
    notifyListeners();
  }

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  static final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00695C),
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: Colors.teal.shade100,
    ),
  );

  static final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primarySwatch: Colors.teal,
    scaffoldBackgroundColor: const Color(0xFF1A1A1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF00695C),
      foregroundColor: Colors.white,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF1A1A1A),
      indicatorColor: Colors.teal.shade700,
    ),
  );
}
