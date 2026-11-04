import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/api_error.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  User? _user;
  bool _isLoading = false;
  bool _isLoggedIn = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  String? get error => _error;

  Future<void> checkAuth() async {
    final userJson = await StorageService.getUserJson();
    final token = await StorageService.getToken();

    if (userJson == null || token == null || token.isEmpty) {
      _isLoggedIn = false;
      notifyListeners();
      return;
    }

    try {
      _user = User.fromJson(jsonDecode(userJson));
      _isLoggedIn = true;
    } catch (_) {
      _isLoggedIn = false;
      await StorageService.clearAll();
    }

    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.login(username, password);
      final data = res.data as Map<String, dynamic>;
      final userJson = data['user'] as Map<String, dynamic>;

      await StorageService.saveToken(data['token'] as String);
      await StorageService.saveUsername(username);
      await StorageService.saveUserJson(jsonEncode(userJson));

      _user = User.fromJson(userJson);
      _isLoggedIn = true;
      _isLoading = false;
      notifyListeners();

      return true;
    } on DioException catch (e) {
      _isLoading = false;
      _error = parseApiError(e, 'Gagal terhubung ke server.');
      notifyListeners();

      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {}

    await StorageService.clearAll();
    _user = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
