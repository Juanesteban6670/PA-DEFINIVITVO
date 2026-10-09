class AppUser {
  const AppUser({
    required this.token,
    required this.username,
    required this.fullName,
    this.email = '',
  });

  final String token;
  final String username;
  final String fullName;
  final String email;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      token: json['token']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'username': username,
    'fullName': fullName,
    'email': email,
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
  });

  final String id;
  final String type;
  final String description;
  final String location;
  final double? latitude;
  final double? longitude;
  final String priority;
  final String status;

  factory Incident.fromJson(Map<String, dynamic> json) => Incident(
    id: json['id']?.toString() ?? '',
    type: json['type']?.toString() ?? 'Incidente',
    description: json['description']?.toString() ?? '',
    location: json['location']?.toString() ?? '',
    latitude: _asDouble(json['latitude']),
    longitude: _asDouble(json['longitude']),
    priority: json['priority']?.toString() ?? 'MEDIUM',
    status: json['status']?.toString() ?? 'PENDING',
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
