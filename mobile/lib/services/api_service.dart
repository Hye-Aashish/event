import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // Windows/Localhost
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator 

  static const _storage = FlutterSecureStorage();

  // ─── Token Management (Web-Compatible) ────────────────────────
  static Future<String?> getToken() async {
    try {
      return await _storage.read(key: 'auth_token');
    } catch (e) {
      // Fallback to local storage for web
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
    final res = await http.post(
      Uri.parse('$baseUrl/auth/send-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'phone': phone, 'otp': otp}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/auth/profile'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  // ─── Events APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getEvents() async {
    final res = await http.get(
      Uri.parse('$baseUrl/events'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getEventById(String id) async {
    final res = await http.get(
      Uri.parse('$baseUrl/events/$id'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getZones(String eventId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/zones?eventId=$eventId'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  // ─── Tickets APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getMyTickets() async {
    final res = await http.get(
      Uri.parse('$baseUrl/tickets/my'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> purchaseTicket(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/purchase'),
      headers: await _authHeaders,
      body: jsonEncode(data),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> transferTicket(String ticketId, String toPhone) async {
    final res = await http.post(
      Uri.parse('$baseUrl/tickets/$ticketId/transfer'),
      headers: await _authHeaders,
      body: jsonEncode({'toPhone': toPhone}),
    );
    return _handleResponse(res);
  }

  static Future<Map<String, dynamic>> getTicketById(String ticketId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/tickets/$ticketId'),
      headers: await _authHeaders,
    );
    return _handleResponse(res);
  }

  // ─── Scanner APIs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> scanQr(String qrData) async {
    final res = await http.post(
      Uri.parse('$baseUrl/scanner/scan'),
      headers: await _authHeaders,
      body: jsonEncode({'qrData': qrData}),
    );
    return _handleResponse(res);
  }

  // ─── Response Handler ─────────────────────────────────────────
  static Map<String, dynamic> _handleResponse(http.Response res) {
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
      return {
        'success': false,
        'message': body['message'] ?? 'Something went wrong',
        'statusCode': res.statusCode,
      };
    }
  }
}
