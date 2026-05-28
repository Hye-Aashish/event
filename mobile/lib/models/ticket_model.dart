class TicketModel {
  final String id;
  final String userId;
  final String eventId;
  final String zoneId;
  final String type; // 'regular' or 'season'
  final String? date; // YYYY-MM-DD for regular passes
  final String status;
  final double basePrice;
  final double gstAmount;
  final double totalAmount;
  final String qrHash;
  final bool isScanned;
  final DateTime? lastScannedAt;
  final DateTime createdAt;
  final String? eventName;
  final String? zoneName;
  final String? zoneType;
  final String? eventVenue;

  TicketModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.zoneId,
    required this.type,
    this.date,
    required this.status,
    required this.basePrice,
    required this.gstAmount,
    required this.totalAmount,
    required this.qrHash,
    required this.isScanned,
    this.lastScannedAt,
    required this.createdAt,
    this.eventName,
    this.zoneName,
    this.zoneType,
    this.eventVenue,
  });

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    final event =
        json['eventId'] is Map ? json['eventId'] as Map<String, dynamic> : null;
    final zone =
        json['zoneId'] is Map ? json['zoneId'] as Map<String, dynamic> : null;

    return TicketModel(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] is Map
          ? (json['userId'] as Map)['_id'] ?? ''
          : json['userId'] ?? '',
      eventId: event?['_id'] ?? json['eventId'] ?? '',
      zoneId: zone?['_id'] ?? json['zoneId'] ?? '',
      type: json['type'] ?? 'regular',
      date: json['date'],
      status: json['status'] ?? 'active',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      qrHash: json['qrHash'] ?? '',
      isScanned: json['isScanned'] ?? false,
      lastScannedAt: json['lastScannedAt'] != null
          ? DateTime.tryParse(json['lastScannedAt'])
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      eventName: event?['name'] ?? json['eventName'],
      zoneName: zone?['name'] ?? json['zoneName'],
      zoneType: zone?['type'] ?? json['zoneType'],
      eventVenue: event?['venue'] ?? json['eventVenue'],
    );
  }

  // Legacy mappings for backward compatibility with existing screens
  String get ticketType => type;
  double get pricePaid => totalAmount;
  String get qrCode => qrHash;
  bool get isTransferred => status == 'transferred';
  DateTime? get scannedAt => lastScannedAt;
  DateTime get purchasedAt => createdAt;

  bool get isActive => status == 'active' && !isScanned;

  bool get isSeasonPass => type == 'season';

  String get formattedPrice => '₹${totalAmount.toStringAsFixed(0)}';

  String get statusDisplay {
    if (isScanned) return 'Used';
    if (status == 'active') return 'Valid';
    if (status == 'cancelled') return 'Cancelled';
    if (status == 'transferred') return 'Transferred';
    return status;
  }

  String get formattedDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${purchasedAt.day} ${months[purchasedAt.month - 1]} ${purchasedAt.year}';
  }
}
