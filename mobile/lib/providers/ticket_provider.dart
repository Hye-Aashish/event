import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/ticket_model.dart';
import '../services/api_service.dart';
import '../services/database_helper.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _maxTicketsPerOrder = 10;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get maxTicketsPerOrder => _maxTicketsPerOrder;

  List<TicketModel> get activeTickets =>
      _tickets.where((t) => t.status == 'active' && !t.isScanned).toList();
  List<TicketModel> get usedTickets =>
      _tickets.where((t) => t.isScanned || t.status != 'active').toList();

  // ── Helper: get active tickets for a specific event+zone+type ────────────
  List<TicketModel> getActiveTicketsForGroup(
      String eventId, String zoneId, String type) {
    return _tickets
        .where((t) =>
            t.status == 'active' &&
            !t.isScanned &&
            t.eventId == eventId &&
            t.zoneId == zoneId &&
            t.type == type)
        .toList();
  }

  // ── Fetch max tickets per order from settings ────────────────────────────
  Future<void> fetchMaxTicketsPerOrder() async {
    try {
      final res = await ApiService.getMaxTicketsPerOrder();
      if (res['success'] == true && res['maxTicketsPerOrder'] != null) {
        _maxTicketsPerOrder = (res['maxTicketsPerOrder'] as num).toInt();
        notifyListeners();
      }
    } catch (_) {
      // Keep default of 10 on error
    }
  }

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    String? localUserId;
    try {
      const secureStorage = FlutterSecureStorage();
      final userDataStr = await secureStorage.read(key: 'user_data');
      if (userDataStr != null) {
        final userData = jsonDecode(userDataStr);
        localUserId = userData['_id'] ?? userData['id'];
      }
    } catch (_) {}

    try {
      final res = await ApiService.getMyTickets();
      if (res['success'] == true) {
        final list = (res['data'] ?? res['tickets']) as List<dynamic>? ?? [];
        _tickets = list
            .map((t) => TicketModel.fromJson(t as Map<String, dynamic>))
            .toList();
        _tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));

        // Cache tickets to database on successful network fetch
        if (_tickets.isNotEmpty) {
          await DatabaseHelper.instance.saveTickets(_tickets);
        }
      } else {
        _errorMessage = res['message'] ?? 'Failed to load tickets';
        if (localUserId != null) {
          _tickets = await DatabaseHelper.instance.getCachedTickets(localUserId);
        }
      }
    } catch (e) {
      _errorMessage = 'Operating offline. Showing cached passes.';
      if (localUserId != null) {
        _tickets = await DatabaseHelper.instance.getCachedTickets(localUserId);
      } else {
        _errorMessage = 'Network error. Please try again.';
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>> createRazorpayOrder({
    required String eventId,
    required String zoneId,
    required String type,
    required String category,
    required int quantity,
    String? date,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.createOrder({
        'eventId': eventId,
        'zoneId': zoneId,
        'type': type,
        'category': category,
        'quantity': quantity,
        if (date != null) 'date': date,
      });

      if (kDebugMode) {
        print("order created : $res");
      }

      _isLoading = false;
      notifyListeners();
      return res;
    } catch (e) {
      if (kDebugMode) {
        print("order created error : $e");
      }
      _isLoading = false;
      _errorMessage = 'Failed to create order. Try again.';
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.verifyPayment(data);
      if (res['success'] == true) {
        await fetchTickets();
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'message': 'Ticket booked successfully'};
      } else {
        _isLoading = false;
        _errorMessage = res['message'] ?? 'Payment verification failed';
        notifyListeners();
        return res;
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Verification error. Please check your tickets tab.';
      notifyListeners();
      return {
        'success': false,
        'message': 'Connection error during verification'
      };
    }
  }

  // ── Transfer Step 1: Initiate — send OTP to sender's phone ───────────────
  Future<Map<String, dynamic>> initiateTransfer({
    required String ticketId,
    required int quantity,
    required String toPhone,
  }) async {
    try {
      final res = await ApiService.initiateTransfer({
        'ticketId': ticketId,
        'quantity': quantity,
        'toPhone': toPhone,
      });
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Failed to initiate transfer'};
    }
  }

  // ── Transfer Step 2: Confirm — validate OTP and execute transfer ─────────
  Future<Map<String, dynamic>> confirmTransfer({
    required String ticketId,
    required int quantity,
    required String toPhone,
    required String otp,
  }) async {
    try {
      final res = await ApiService.confirmTransfer({
        'ticketId': ticketId,
        'quantity': quantity,
        'toPhone': toPhone,
        'otp': otp,
      });
      if (res['success'] == true) {
        await fetchTickets();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Transfer confirmation failed'};
    }
  }

  // ── Legacy single-ticket transfer (kept for any remaining references) ─────
  Future<Map<String, dynamic>> transferTicket(
      String ticketId, String toPhone) async {
    return initiateTransfer(ticketId: ticketId, quantity: 1, toPhone: toPhone);
  }

  TicketModel? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
