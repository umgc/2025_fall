class Camera {
  final int id;
  final String serialNumber;
  final String friendlyName;
  final String roomName;
  final bool isOnline;
  final String model;
  final String version;

  Camera({
    required this.id,
    required this.serialNumber,
    required this.friendlyName,
    required this.roomName,
    required this.isOnline,
    required this.model,
    required this.version,
  });

  factory Camera.fromJson(Map<String, dynamic> json) {
    return Camera(
      id: json['id'],
      serialNumber: json['serial_number'],
      friendlyName: json['friendly_name'],
      roomName: json['room_name'],
      isOnline: json['is_online'],
      model: json['model'],
      version: json['version'],
    );
  }
}