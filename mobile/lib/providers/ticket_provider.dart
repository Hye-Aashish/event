import 'package:flutter/foundation.dart';

import '../models/ticket_model.dart';
import '../services/api_service.dart';

class TicketProvider extends ChangeNotifier {
  List<TicketModel> _tickets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<TicketModel> get tickets => _tickets;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<TicketModel> get activeTickets =>
      _tickets.where((t) => t.status == 'active' && !t.isScanned).toList();
  List<TicketModel> get usedTickets =>
      _tickets.where((t) => t.isScanned || t.status != 'active').toList();

  Future<void> fetchTickets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getMyTickets();
      if (res['success'] == true) {
        final list = (res['data'] ?? res['tickets']) as List<dynamic>? ?? [];
        _tickets = list
            .map((t) => TicketModel.fromJson(t as Map<String, dynamic>))
            .toList();
        _tickets.sort((a, b) => b.purchasedAt.compareTo(a.purchasedAt));
      } else {
        _errorMessage = res['message'] ?? 'Failed to load tickets';
      }
    } catch (e) {
      _errorMessage = 'Network error. Please try again.';
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
        // Ticket book ho gaya, list refresh karo
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

  Future<Map<String, dynamic>> transferTicket(
      String ticketId, String toPhone) async {
    try {
      final res = await ApiService.transferTicket(ticketId, toPhone);
      if (res['success'] == true) {
        await fetchTickets();
      }
      return res;
    } catch (e) {
      return {'success': false, 'message': 'Transfer failed'};
    }
  }

  TicketModel? getTicketById(String id) {
    try {
      return _tickets.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }
}
