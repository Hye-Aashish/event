import 'package:flutter/material.dart';
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
        final list = res['tickets'] as List<dynamic>? ?? [];
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

  Future<Map<String, dynamic>> buyTicket({
    required String eventId,
    required String zoneId,
    required String ticketType,
    required double pricePaid,
    Map<String, dynamic>? extra,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await ApiService.purchaseTicket({
        'eventId': eventId,
        'zoneId': zoneId,
        'ticketType': ticketType,
        'pricePaid': pricePaid,
        ...?extra,
      });

      if (res['success'] == true) {
        await fetchTickets(); // Refresh the list
        _isLoading = false;
        notifyListeners();
        return {'success': true, 'ticket': res['ticket']};
      } else {
        _isLoading = false;
        notifyListeners();
        return {'success': false, 'message': res['message'] ?? 'Purchase failed'};
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': 'Network error during purchase'};
    }
  }

  Future<Map<String, dynamic>> transferTicket(String ticketId, String toPhone) async {
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
