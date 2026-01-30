class LocationPoint {
  final double latitude;
  final double longitude;
  final String displayName;

  const LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.displayName,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'displayName': displayName,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      latitude: map['latitude']?.toDouble() ?? 0.0,
      longitude: map['longitude']?.toDouble() ?? 0.0,
      displayName: map['displayName'] ?? '',
    );
  }

  @override
  String toString() => displayName;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;
}
