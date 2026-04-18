class TicketModel {
  final String id;
  final String userId;
  final String eventId;
  final String zoneId;
  final String ticketType;
  final String status;
  final double pricePaid;
  final String qrCode;
  final bool isTransferred;
  final bool isScanned;
  final DateTime? scannedAt;
  final DateTime purchasedAt;
  final String? eventName;
  final String? zoneName;
  final String? zoneType;
  final String? eventDate;
  final String? eventVenue;

  TicketModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.zoneId,
    required this.ticketType,
    required this.status,
    required this.pricePaid,
    required this.qrCode,
    required this.isTransferred,
    required this.isScanned,
    this.scannedAt,
    required this.purchasedAt,
    this.eventName,
    this.zoneName,
    this.zoneType,
    this.eventDate,
    this.eventVenue,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final event = json['eventId'] is Map ? json['eventId'] as Map<String, dynamic> : null;
    final zone = json['zoneId'] is Map ? json['zoneId'] as Map<String, dynamic> : null;

    return TicketModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map
          ? (json['userId'] as Map)['_id'] ?? ''
          : json['userId'] ?? '',
      eventId: event?['_id'] ?? json['eventId'] ?? '',
      zoneId: zone?['_id'] ?? json['zoneId'] ?? '',
      ticketType: json['ticketType'] ?? 'single',
      status: json['status'] ?? 'active',
      pricePaid: (json['pricePaid'] as num?)?.toDouble() ?? 0.0,
      qrCode: json['qrCode'] ?? '',
      isTransferred: json['isTransferred'] ?? false,
      isScanned: json['isScanned'] ?? false,
      scannedAt: json['scannedAt'] != null
          ? DateTime.tryParse(json['scannedAt'])
          : null,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.tryParse(json['purchasedAt']) ?? DateTime.now()
          : DateTime.now(),
      eventName: event?['name'] ?? json['eventName'],
      zoneName: zone?['name'] ?? json['zoneName'],
      zoneType: zone?['type'] ?? json['zoneType'],
      eventDate: event?['date'] ?? json['eventDate'],
      eventVenue: event?['venue'] ?? json['eventVenue'],
    );
  }

  bool get isActive => status == 'active' && !isScanned;

  bool get isSeasonPass => ticketType == 'season';

  String get formattedPrice => '₹${pricePaid.toStringAsFixed(0)}';

  String get statusDisplay {
    if (isScanned) return 'Used';
    if (status == 'active') return 'Valid';
    if (status == 'cancelled') return 'Cancelled';
    if (status == 'transferred') return 'Transferred';
    return status;
  }

  String get formattedDate {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${purchasedAt.day} ${months[purchasedAt.month - 1]} ${purchasedAt.year}';
  }
}
