import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }
enum AuthResult { success, newUser, failure }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _pendingPhone;

  static const _secureStorage = FlutterSecureStorage();

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingPhone => _pendingPhone;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;

  AuthProvider() {
    _checkAuth();
  }

  Future<void> _saveUserSecurely(UserModel user) async {
    await _secureStorage.write(key: 'user_data', value: jsonEncode(user.toJson()));
  }

  Future<UserModel?> _loadUserSecurely() async {
    final data = await _secureStorage.read(key: 'user_data');
    if (data == null) return null;
    return UserModel.fromJson(jsonDecode(data));
  }

  Future<void> _clearUserSecurely() async {
    await _secureStorage.delete(key: 'user_data');
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

      final cachedUser = await _loadUserSecurely();
      if (cachedUser != null) {
        _user = cachedUser;
        _state = AuthState.authenticated;
      } else {
        final res = await ApiService.getProfile();
        if (res['success'] == true) {
          _user = UserModel.fromJson(res['user'] ?? res);
          await _saveUserSecurely(_user!);
          _state = AuthState.authenticated;
        } else {
          await ApiService.clearToken();
          await _clearUserSecurely();
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
          await _saveUserSecurely(_user!);
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
          await _saveUserSecurely(_user!);
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

  Future<void> logout({bool remote = true}) async {
    debugPrint('AuthProvider.logout() called (remote: $remote)');
    if (remote) {
      try {
        await ApiService.logout();
      } catch (_) {}
    }
    await _clearUserSecurely();
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
        await _saveUserSecurely(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }
}
