import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants.dart';
import '../models/user.dart';

class UserService {
  static const String _userDataKey = 'userData';

  Future<User> loginUser(String username, String password) async {
    final response = await http.post(
      Uri.parse('$host/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'expiresInMins': 60,
      }),
    );

    final Map<String, dynamic> responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      final user = User.fromJson(responseData);

      await saveUserData(user);

      return user;
    }

    throw Exception(
      responseData['message'] ?? 'Unable to sign in. Please try again.',
    );
  }

  Future<void> saveUserData(User user) async {
    final preferences = await SharedPreferences.getInstance();

    await preferences.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  Future<User?> getUserData() async {
    final preferences = await SharedPreferences.getInstance();
    final savedUser = preferences.getString(_userDataKey);

    if (savedUser == null || savedUser.isEmpty) {
      return null;
    }

    try {
      final Map<String, dynamic> userData = jsonDecode(savedUser);
      return User.fromJson(userData);
    } catch (_) {
      await preferences.remove(_userDataKey);
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getUserData();

    return user != null && user.accessToken.isNotEmpty;
  }

  Future<void> logout() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_userDataKey);
  }
}
