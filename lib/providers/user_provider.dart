import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

// [LATIHAN 4b]: Menggunakan ChangeNotifier untuk State Management
class UserProvider extends ChangeNotifier {
  User _user = User(name: '', email: '');
  bool _isLoading = true;
  bool _isDarkMode = false;

  User get user => _user;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;

  UserProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('user_name') ?? '';
    final email = prefs.getString('user_email') ?? '';
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final isDarkMode = prefs.getBool('is_dark_mode') ?? false;

    _user = User(name: name, email: email, isLoggedIn: isLoggedIn);
    _isDarkMode = isDarkMode;
    _isLoading = false;
    notifyListeners(); // [LATIHAN 4a]: Memberitahu listener saat data awal selesai dimuat
  }

  Future<void> updateUser(User newUser) async {
    _isLoading = true;
    notifyListeners(); // [LATIHAN 4a]: Memberitahu UI bahwa proses loading dimulai

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', newUser.name);
    await prefs.setString('user_email', newUser.email);
    await prefs.setBool('is_logged_in', newUser.isLoggedIn);

    _user = newUser;
    _isLoading = false;
    notifyListeners(); // [LATIHAN 4a]: Memberitahu UI bahwa data user telah diperbarui
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.setBool('is_logged_in', false);

    _user = _user.copyWith(name: '', email: '', isLoggedIn: false);
    notifyListeners(); // [LATIHAN 4a]: Memberitahu UI saat status logout terjadi
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners(); // [LATIHAN 4a]: Memberitahu UI saat tema berubah
  }
}