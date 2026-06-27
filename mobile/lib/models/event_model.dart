import '../widgets/app_constant.dart';

class EventModel {
  final String id;
  final String name;
  final String description;
  final List<String> eventDates;
  final String venue;
  final String? imageUrl;
  final bool isActive;
  final bool gstEnabled;
  final bool gstInclusive;
  final double gstPercentage;
  final List<ZoneModel> zones;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.eventDates,
    required this.venue,
    this.imageUrl,
    required this.isActive,
    required this.gstEnabled,
    required this.gstInclusive,
    required this.gstPercentage,
    required this.zones,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Event',
      description: json['description'] ?? '',
      eventDates: List<String>.from(json['eventDates'] ?? []),
      venue: json['venue'] ?? 'TBA',
      imageUrl: json['imageUrl'] ?? json['bannerUrl'] ?? json['image'],
      isActive: json['isActive'] ?? true,
      gstEnabled: json['gstEnabled'] ?? false,
      gstInclusive: json['gstInclusive'] ?? false,
      gstPercentage: (json['gstPercentage'] as num?)?.toDouble() ?? 18.0,
      zones: (json['zones'] as List<dynamic>? ?? [])
          .map((z) => ZoneModel.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  DateTime get date => eventDates.isNotEmpty 
      ? DateTime.tryParse(eventDates[0]) ?? DateTime.now() 
      : DateTime.now();

  String get formattedDate {
    if (eventDates.isEmpty) return 'TBA';
    final d = date;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  String? get fullImageUrl {
    if (imageUrl == null || imageUrl!.isEmpty) return null;
    if (imageUrl!.startsWith('http://') || imageUrl!.startsWith('https://')) {
      return imageUrl;
    }
    final serverUrl = AppConstant.baseUrl.replaceAll('/api', '');
    final path = imageUrl!.startsWith('/') ? imageUrl! : '/$imageUrl';
    return '$serverUrl$path';
  }
}

class ZoneModel {
  final String id;
  final String name;
  final String type;
  final double dailyPrice;
  final double seasonPrice;
  final int capacity;
  final int availableSeats;
  final List<String> features;
  final bool isMultipleAllowed;

  ZoneModel({
    required this.id,
    required this.name,
    required this.type,
    required this.dailyPrice,
    required this.seasonPrice,
    required this.capacity,
    required this.availableSeats,
    required this.features,
    required this.isMultipleAllowed,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'daily',
      dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0.0,
      seasonPrice: (json['seasonPrice'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] ?? 0,
      availableSeats: json['availableSeats'] ?? json['available'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
      isMultipleAllowed: json['isMultipleAllowed'] ?? true,
    );
  }

  bool get isAvailable => availableSeats > 0;

  double priceFor(String passType) => passType == 'season' ? seasonPrice : dailyPrice;

  String formattedPriceFor(String passType) => '₹${priceFor(passType).toStringAsFixed(0)}';
}
