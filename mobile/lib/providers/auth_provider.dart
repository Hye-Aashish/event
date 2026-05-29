import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

enum AuthState { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  AuthState _state = AuthState.initial;
  UserModel? _user;
  String? _errorMessage;
  String? _pendingPhone;
  bool _isNewUser = false;

  static const _secureStorage = FlutterSecureStorage();

  AuthState get state => _state;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  String? get pendingPhone => _pendingPhone;
  bool get isAuthenticated => _state == AuthState.authenticated;
  bool get isLoading => _state == AuthState.loading;
  bool get isNewUser => _isNewUser;

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
    _state = AuthState.loading;
    notifyListeners();

    try {
      final token = await ApiService.getToken();
      if (kDebugMode) print('🔐 Auth Check: Token exists: ${token != null}');
      if (token == null) {
        _state = AuthState.unauthenticated;
        notifyListeners();
        return;
      }

      final cachedUser = await _loadUserSecurely();
      if (cachedUser != null) {
        if (kDebugMode) print('💾 Auth Check: Loading user securely from cache');
        _user = cachedUser;
        _state = AuthState.authenticated;
      } else {
        if (kDebugMode) print('☁️ Auth Check: Fetching profile from server');
        final res = await ApiService.getProfile();
        if (res['success'] == true) {
          _user = UserModel.fromJson(res['user'] ?? res);
          await _saveUserSecurely(_user!);
          _state = AuthState.authenticated;
        } else {
          if (kDebugMode) print('❌ Auth Check: Profile fetch failed, clearing token');
          await ApiService.clearToken();
          await _clearUserSecurely();
          _state = AuthState.unauthenticated;
        }
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Auth Check Error: $e');
      _state = AuthState.unauthenticated;
    }

    notifyListeners();
  }

  Future<bool> sendOtp(String phone) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.sendOtp(phone);
      if (kDebugMode) {
        print('send otp res $res');
      }
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

  Future<bool> verifyOtp(String otp) async {
    if (_pendingPhone == null) return false;

    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.verifyOtp(_pendingPhone!, otp);
      if (kDebugMode) print('🔑 Verify OTP Response: $res');
      if (res['success'] == true) {
        final token = res['token'] ?? res['access_token'];
        if (token != null) {
          await ApiService.saveToken(token);
        }
        _isNewUser = res['isNewUser'] ?? false;
        if (res['user'] != null) {
          _user = UserModel.fromJson(res['user']);
          await _saveUserSecurely(_user!);
        }
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Invalid OTP';
        _state = AuthState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      if (kDebugMode) print('⚠️ Verify OTP Error: $e');
      _errorMessage = 'Network error. Please try again.';
      _state = AuthState.error;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register(String name, String email) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      final res =
          await ApiService.updateProfile({'name': name, 'email': email});
      if (res['success'] == true) {
        _user = UserModel.fromJson(res['user'] ?? res);
        await _saveUserSecurely(_user!);
        _isNewUser = false;
        _state = AuthState.authenticated;
        notifyListeners();
        return true;
      } else {
        _errorMessage = res['message'] ?? 'Failed to register';
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

  Future<bool> updateProfile({required String name, required String email}) async {
    try {
      final res = await ApiService.updateProfile({'name': name, 'email': email});
      if (res['success'] == true) {
        _user = UserModel.fromJson(res['user'] ?? res);
        await _saveUserSecurely(_user!);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshProfile() async {
    try {
      final res = await ApiService.getProfile();
      if (res['success'] == true) {
        _user = UserModel.fromJson(res['user'] ?? res);
        await _saveUserSecurely(_user!);
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<void> logout() async {
    if (kDebugMode) print('🚪 User Logout');
    try {
      await ApiService.logout();
    } catch (_) {}
    await _clearUserSecurely();
    await DatabaseHelper.instance.clearTickets();
    _user = null;
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<Map<String, dynamic>> submitVerification(
      String selfiePath, String idCardPath) async {
    _state = AuthState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Upload Selfie
      final selfieRes = await ApiService.uploadImage(selfiePath);
      if (selfieRes['success'] != true) {
        _state = AuthState.authenticated;
        notifyListeners();
        return {
          'success': false,
          'message': 'Selfie upload failed: ${selfieRes['message']}'
        };
      }
      final selfieUrl = selfieRes['url'];

      // 2. Upload ID Card
      final idCardRes = await ApiService.uploadImage(idCardPath);
      if (idCardRes['success'] != true) {
        _state = AuthState.authenticated;
        notifyListeners();
        return {
          'success': false,
          'message': 'ID Card upload failed: ${idCardRes['message']}'
        };
      }
      final idCardUrl = idCardRes['url'];

      // 3. Submit Verification
      final submitRes =
          await ApiService.submitVerification(selfieUrl!, idCardUrl!);
      if (submitRes['success'] == true) {
        if (kDebugMode) {
          print('submit verification res $submitRes');
        }
        _user = UserModel.fromJson(submitRes['user'] ?? submitRes);
        await _saveUserSecurely(_user!);
        _state = AuthState.authenticated;
        notifyListeners();
        return {'success': true};
      } else {
        if (kDebugMode) {
          print('submit verification failed res $submitRes');
        }
        _state = AuthState.authenticated;
        _errorMessage = submitRes['message'] ?? 'Submission failed';
        notifyListeners();
        return {'success': false, 'message': _errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {
        print('submit verification error $e');
      }
      _state = AuthState.authenticated;
      _errorMessage = 'Network error. Please try again.';
      notifyListeners();
      return {'success': false, 'message': _errorMessage};
    }
  }
}
