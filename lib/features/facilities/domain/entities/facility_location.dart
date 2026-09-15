// Task 08 - Agaram Care Facility Location Entity.
library;

/// Reusable physical address and geocoordinates for a healthcare facility.
///
/// Coordinates are nullable (can be null for facilities where GPS location
/// has not yet been geocoded or verified).
class FacilityLocation {
  const FacilityLocation({
    required this.addressLine,
    required this.city,
    required this.district,
    required this.state,
    required this.pincode,
    this.area,
    this.latitude,
    this.longitude,
  });

  /// Primary street address or landmark line.
  final String addressLine;

  /// Neighborhood, village, or locality if applicable.
  final String? area;

  /// City, town, or taluk.
  final String city;

  /// Revenue district (e.g., Chennai, Madurai, Salem, Coimbatore).
  final String district;

  /// State (e.g., Tamil Nadu).
  final String state;

  /// 6-digit postal code or pin code.
  final String pincode;

  /// WGS-84 latitude coordinate, nullable if not geocoded.
  final double? latitude;

  /// WGS-84 longitude coordinate, nullable if not geocoded.
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory FacilityLocation.fromJson(Map<String, dynamic> json) {
    return FacilityLocation(
      addressLine: json['addressLine'] as String? ?? '',
      area: json['area'] as String?,
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      state: json['state'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
    'addressLine': addressLine,
    if (area != null) 'area': area,
    'city': city,
    'district': district,
    'state': state,
    'pincode': pincode,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };
}
