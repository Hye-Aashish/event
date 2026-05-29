// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dio_client.dart';

class ApiService {
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://localhost:3000/api',
  );

  static const _storage = FlutterSecureStorage();

  // ─── Token Management (Web-Compatible) ────────────────────────
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveToken(String token) async {
    try {
      await _storage.write(key: 'auth_token', value: token);
    } catch (e) {}
  }

  static Future<void> clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
    } catch (e) {}
  }

  static Future<Map<String, dynamic>> logout() async {
    try {
      final res = await DioClient.instance.dio.post('/auth/logout');
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    } finally {
      await clearToken();
    }
  }

  // ─── Auth APIs ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    try {
      final res = await DioClient.instance.dio.post(
        '/auth/send-otp',
        data: {'phone': phone},
      );
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    try {
      final res = await DioClient.instance.dio.post(
        '/auth/verify-otp',
        data: {'phone': phone, 'otp': otp},
      );
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await DioClient.instance.dio.get('/auth/profile');
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    try {
      final res =
          await DioClient.instance.dio.patch('/auth/profile', data: data);
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── Events APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEvents() async {
    try {
      final res = await DioClient.instance.dio.get('/events');
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getEventById(String id) async {
    try {
      final res = await DioClient.instance.dio.get('/events/$id');
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getZones(String eventId) async {
    try {
      final res = await DioClient.instance.dio
          .get('/zones', queryParameters: {'eventId': eventId});
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── Tickets APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final res = await DioClient.instance.dio.get('/tickets/my');
      return {'success': true, 'data': res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> purchaseTicket(
      Map<String, dynamic> data) async {
    try {
      final res =
          await DioClient.instance.dio.post('/tickets/purchase', data: data);
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> transferTicket(
      String ticketId, String toPhone) async {
    try {
      final res = await DioClient.instance.dio.post(
        '/tickets/$ticketId/transfer',
        data: {'toPhone': toPhone},
      );
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  static Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    try {
      final res = await DioClient.instance.dio.get('/tickets/$ticketId');
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── Scanner APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanQr(String qrData) async {
    try {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(qrData);
      } catch (e) {
        payload = {'qrData': qrData};
      }

      final res = await DioClient.instance.dio.post(
        '/gate/scan',
        data: payload,
      );
      return {'success': true, ...res.data};
    } on DioException catch (e) {
      return _handleDioError(e);
    }
  }

  // ─── Unified Error Handler ──────────────────────────────────────
  static Map<String, dynamic> _handleDioError(DioException e) {
    String message = 'Something went wrong';
    if (e.response != null && e.response?.data is Map) {
      message = e.response?.data['message'] ?? message;
    } else if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please try again.';
    } else if (e.type == DioExceptionType.connectionError) {
      message = 'No internet connection.';
    }
    return {
      'success': false,
      'message': message,
      'statusCode': e.response?.statusCode,
    };
  }
}
