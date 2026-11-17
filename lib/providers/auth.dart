import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import '../models/http_exception.dart';

/// Sign-up, login, auto-login and auto-logout with Firebase Auth (REST API).
class Auth with ChangeNotifier {
  String? _token;
  DateTime? _expiryDate;
  String? _userId;
  String? _email;
  Timer? _authTimer;

  static const _prefsKey = 'userData';

  bool get isAuth => token != null;

  String? get token {
    final expiry = _expiryDate;
    if (expiry != null && expiry.isAfter(DateTime.now())) {
      return _token;
    }
    return null;
  }

  String? get userId => _userId;
  String? get email => _email;

  Future<void> _authenticate(
      String email, String password, String urlSegment) async {
    final url = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:$urlSegment?key=${AppConfig.firebaseApiKey}');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final data = json.decode(response.body) as Map<String, dynamic>;
    final error = data['error'];
    if (error != null) {
      throw HttpException.fromAuthCode(
          (error as Map<String, dynamic>)['message'] as String? ?? '');
    }
    _token = data['idToken'] as String;
    _userId = data['localId'] as String;
    _email = data['email'] as String? ?? email;
    _expiryDate = DateTime.now()
        .add(Duration(seconds: int.parse(data['expiresIn'] as String)));
    _autoLogout();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      json.encode({
        'token': _token,
        'userId': _userId,
        'email': _email,
        'expiryDate': _expiryDate!.toIso8601String(),
      }),
    );
  }

  Future<void> signup(String email, String password) =>
      _authenticate(email, password, 'signUp');

  Future<void> login(String email, String password) =>
      _authenticate(email, password, 'signInWithPassword');

  /// Restores a saved session if it has not expired yet.
  Future<bool> tryAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    if (saved == null) return false;

    final data = json.decode(saved) as Map<String, dynamic>;
    final expiry = DateTime.tryParse(data['expiryDate'] as String? ?? '');
    if (expiry == null || expiry.isBefore(DateTime.now())) return false;

    _token = data['token'] as String?;
    _userId = data['userId'] as String?;
    _email = data['email'] as String?;
    _expiryDate = expiry;
    notifyListeners();
    _autoLogout();
    return true;
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _email = null;
    _expiryDate = null;
    _authTimer?.cancel();
    _authTimer = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  void _autoLogout() {
    _authTimer?.cancel();
    final expiry = _expiryDate;
    if (expiry == null) return;
    _authTimer = Timer(expiry.difference(DateTime.now()), logout);
  }
}
