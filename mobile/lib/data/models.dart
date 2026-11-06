class AppUser {
  const AppUser({
    required this.token,
    required this.username,
    required this.fullName,
    this.email = '',
    this.phone = '',
  });

  final String token;
  final String username;
  final String fullName;
  final String email;
  final String phone;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'username': username,
    'fullName': fullName,
    'email': email,
    'phone': phone,
  };
}

class Incident {
  const Incident({
    required this.id,
    required this.type,
    required this.description,
    required this.location,
    this.latitude,
    this.longitude,
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.createdAt,
    this.imageUrls = const [],
  });

  final String id;
  final String type;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String priority;
  final String status;
  final DateTime? createdAt;
  final List<String> imageUrls;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? 'Incidente',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    priority: json['priority']?.toString() ?? 'MEDIUM',
    status: json['status']?.toString() ?? 'PENDING',
    createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    imageUrls:
        (json['imageUrls'] as List?)?.whereType<String>().toList(
          growable: false,
        ) ??
        const [],
  );

  static double? _asDouble(dynamic value) => value is num
      ? value.toDouble()
      : double.tryParse(value?.toString() ?? '');
}

class EmergencyContact {
  const EmergencyContact({
    required this.name,
    required this.phone,
    required this.type,
    this.address = '',
    this.notes = '',
  });

  final String name;
  final String phone;
  final String type;
  final String address;
  final String notes;

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name']?.toString() ?? 'Contacto de emergencia',
        phone: json['phone']?.toString() ?? '',
        type: json['type']?.toString() ?? 'OTHER',
        address: json['address']?.toString() ?? '',
        notes: json['notes']?.toString() ?? '',
      );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.read,
    this.type = '',
    this.relatedEntityId,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final bool read;
  final String type;
  final String? relatedEntityId;
  final DateTime? createdAt;

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? 'Notificación',
        message: json['message']?.toString() ?? '',
        read: json['read'] == true,
        type: json['type']?.toString() ?? '',
        relatedEntityId: json['relatedEntityId']?.toString(),
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );
}
