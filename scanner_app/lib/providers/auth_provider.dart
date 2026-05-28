import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }
enum AuthResult { success, newUser, failure }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _pendingPhone;

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingPhone => _pendingPhone;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    debugPrint('AuthProvider._checkAuth() called');
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (token == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final userData = prefs.getString('user_data');
      if (userData != null) {
        _user = UserModel.fromJson(jsonDecode(userData));
        _state = AuthState.authenticated;
      } else {
        final res = await ApiService.getProfile();
        if (res['success'] == true) {
          _user = UserModel.fromJson(res['user'] ?? res);
          await prefs.setString('user_data', jsonEncode(_user!.toJson()));
          _state = AuthState.authenticated;
        } else {
          await ApiService.clearToken();
          _state = AuthState.unauthenticated;
        }
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    debugPrint('AuthProvider.sendOtp() called for $phone');
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.sendOtp(phone);
      if (res['success'] == true) {
        _pendingPhone = phone;
        _state = AuthState.unauthenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to send OTP';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please check your connection.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<AuthResult> verifyOtp(String otp) async {
    if (_pendingPhone == null) return AuthResult.failure;

    debugPrint('AuthProvider.verifyOtp() called for $_pendingPhone');
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyOtp(_pendingPhone!, otp);
      if (res['success'] == true) {
        final token = res['token'] ?? res['access_token'];
        if (token != null) {
          await ApiService.saveToken(token);
        }
        if (res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        }
        _state = AuthState.authenticated;
        notifyListeners();
        return res['isNewUser'] == true ? AuthResult.newUser : AuthResult.success;
      } else {
        _errorMessage = res['message'] ?? 'Invalid OTP';
        _state = AuthState.error;
        notifyListeners();
        return AuthResult.failure;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _state = AuthState.error;
      notifyListeners();
      return AuthResult.failure;
    }
  }

  Future<bool> registerScanner({required String name, required String email}) async {
    debugPrint('AuthProvider.registerScanner() called for $email');
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.updateProfile({
        'name': name,
        'email': email,
        'role': 'scanner',
      });

      if (res['success'] == true) {
        if (res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        }
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Registration failed';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    debugPrint('AuthProvider.logout() called');
    await ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_data');
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    debugPrint('AuthProvider.refreshProfile() called');
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true) {
        _user = UserModel.fromJson(res['user'] ?? res);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(_user!.toJson()));
        notifyListeners();
      }
    } catch (_) {}
  }
}
