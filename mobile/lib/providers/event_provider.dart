import 'package:flutter/foundation.dart';

import '../models/event_model.dart';
import '../services/api_service.dart';

class EventProvider extends ChangeNotifier {
  List<EventModel> _events = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EventModel> get activeEvents =>
      _events.where((e) => e.isActive).toList();

  Future<void> fetchEvents() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService.getEvents();
      if (kDebugMode) {
        print("events data : $res");
      }
      if (res['success'] == true) {
        final list = res['events'] as List<dynamic>? ??
            (res['data'] as List<dynamic>? ?? []);
        _events = list
            .map((e) => EventModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } else {
        if (kDebugMode) {
          print("events data : $res");
        }
        _errorMessage = res['message'] ?? 'Failed to load events';
      }
    } catch (e) {
      if (kDebugMode) {
        print("events data : $e");
      }
      _errorMessage = 'Network error. Please try again.';
    }

    _isLoading = false;
    notifyListeners();
  }

  EventModel? getEventById(String id) {
    try {
      final event = _events.firstWhere((e) => e.id == id);
      if (kDebugMode) print('📍 Get Event By ID: Found ${event.name}');
      return event;
    } catch (e) {
      if (kDebugMode) print('📍 Get Event By ID: Not found for ID $id');
      return null;
    }
  }
}
