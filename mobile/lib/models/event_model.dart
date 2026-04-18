class EventModel {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String venue;
  final String? imageUrl;
  final bool isActive;
  final List<ZoneModel> zones;

  EventModel({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.venue,
    this.imageUrl,
    required this.isActive,
    required this.zones,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    // Determine the first date safely
    DateTime parsedDate = DateTime.now();
    if (json['eventDates'] != null && (json['eventDates'] as List).isNotEmpty) {
      parsedDate = DateTime.tryParse(json['eventDates'][0]) ?? DateTime.now();
    } else if (json['date'] != null) {
      parsedDate = DateTime.tryParse(json['date']) ?? DateTime.now();
    }

    return EventModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? 'Unnamed Event',
      description: json['description'] ?? '',
      date: parsedDate,
      venue: json['venue'] ?? 'TBA',
      imageUrl: json['imageUrl'] ?? json['bannerUrl'] ?? json['image'],
      isActive: json['isActive'] ?? true,
      zones: (json['zones'] as List<dynamic>? ?? [])
          .map((z) => ZoneModel.fromJson(z as Map<String, dynamic>))
          .toList(),
    );
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get dayOfWeek {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }
}

class ZoneModel {
  final String id;
  final String name;
  final String type;
  final double price;
  final int capacity;
  final int availableSeats;
  final List<String> features;

  ZoneModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.capacity,
    required this.availableSeats,
    required this.features,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> json) {
    return ZoneModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'general',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      capacity: json['capacity'] ?? 0,
      availableSeats: json['availableSeats'] ?? json['available'] ?? 0,
      features: List<String>.from(json['features'] ?? []),
    );
  }

  bool get isAvailable => availableSeats > 0;

  String get formattedPrice => '₹${price.toStringAsFixed(0)}';
}
