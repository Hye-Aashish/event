// ignore_for_file: empty_catches

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../widgets/app_constant.dart';

class ApiService {
  static const String baseUrl = AppConstant.baseUrl;

  static const _storage = FlutterSecureStorage();

  // ─── Token Management ──────────────────────────────────────────
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

  // ─── Authenticated Headers ───────────────────────────────────
  static Future<Map<String, String>> get _authHeaders async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── Auth APIs ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> sendOtp(String phone) async {
    if (kDebugMode) {
      print('🌐 Request: POST $baseUrl/auth/send-otp | Body: $phone');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> verifyOtp(
      String phone, String otp) async {
    if (kDebugMode) {
      print('🌐 Request: POST $baseUrl/auth/verify-otp | Phone: $phone');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/auth/profile');
    final res = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateProfile(
      Map<String, dynamic> data) async {
    if (kDebugMode) print('🌐 Request: PATCH $baseUrl/auth/profile');
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  // ─── Events APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEvents() async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/events');
    final res = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getEventById(String id) async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/events/$id');
    final res = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getZones(String eventId) async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/zones?eventId=$eventId');
    final res = await http.get(
      Uri.parse('$baseUrl/zones?eventId=$eventId'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  // ─── Tickets APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyTickets() async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/tickets/my');
    final res = await http.get(
      Uri.parse('$baseUrl/tickets/my'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> data) async {
    if (kDebugMode) {
      print('🌐 Request: POST $baseUrl/tickets/order | Data: $data');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/order'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> verifyPayment(
      Map<String, dynamic> data) async {
    if (kDebugMode) print('🌐 Request: POST $baseUrl/tickets/verify-payment');
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/verify-payment'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> transferTicket(
      String ticketId, String toPhone) async {
    if (kDebugMode) {
      print(
          '🌐 Request: POST $baseUrl/tickets/$ticketId/transfer | To: $toPhone');
    }
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/transfer'),
      headers: await _authHeaders,
      body: jsonEncode({'toPhone': toPhone}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    if (kDebugMode) print('🌐 Request: GET $baseUrl/tickets/$ticketId');
    final res = await http.get(
      Uri.parse('$baseUrl/tickets/$ticketId'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  // ─── Scanner APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanQr(String qrData) async {
    if (kDebugMode) print('🌐 Request: POST $baseUrl/gate/verify');
    final res = await http.post(
      Uri.parse('$baseUrl/gate/verify'),
      headers: await _authHeaders,
      body: jsonEncode({'qrData': qrData}),
    );
    return _handleResponse(res);
  }

  // ─── Verification APIs ─────────────────────────────────────────
  static Future<Map<String, dynamic>> uploadImage(String filePath) async {
    try {
      if (kDebugMode) print('📤 Uploading image: $filePath');
      final token = await getToken();
      final uri = Uri.parse('$baseUrl/events/upload');
      var request = http.MultipartRequest('POST', uri);

      if (token != null) request.headers['Authorization'] = 'Bearer $token';

      final file = await http.MultipartFile.fromPath('image', filePath);
      request.files.add(file);

      final streamedResponse =
          await request.send().timeout(const Duration(seconds: 30));
      final response = await http.Response.fromStream(streamedResponse);

      return _handleResponse(response);
    } catch (e) {
      if (kDebugMode) print('❌ Upload error: $e');
      return {'success': false, 'message': 'Upload failed: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> submitVerification(
      String selfieUrl, String idCardUrl) async {
    if (kDebugMode) print('🌐 Request: POST $baseUrl/auth/verify/submit');
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify/submit'),
      headers: await _authHeaders,
      body: jsonEncode({
        'selfieUrl': selfieUrl,
        'idCardUrl': idCardUrl,
      }),
    );
    return _handleResponse(res);
  }

  // ─── Response Handler ─────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response res) {
    if (kDebugMode) {
      print('📥 Response: ${res.statusCode} | ${res.request?.url.path}');
    }

    final dynamic decodedBody = jsonDecode(res.body);
    Map<String, dynamic> body;

    if (decodedBody is List) {
      body = {'data': decodedBody};
    } else {
      body = decodedBody as Map<String, dynamic>;
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (decodedBody is List) return {'success': true, 'data': decodedBody};
      return {'success': true, ...body};
    } else {
      if (kDebugMode) print('❌ Error Response: ${res.body}');
      return {
        'success': false,
        'message': body['message'] ?? 'Something went wrong',
        'statusCode': res.statusCode,
      };
    }
  }
}
