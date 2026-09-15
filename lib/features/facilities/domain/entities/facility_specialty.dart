// Task 08 - Agaram Care Specialty & Service Entity.
library;

import '../facilities_json_utils.dart';

/// Structured clinical specialty offered by a healthcare facility.
///
/// Avoids relying on free-text strings by pairing a normalized, stable identifier
/// (e.g. "cardiology", "pediatrics") with human-readable localized display names.
class FacilitySpecialty {
  const FacilitySpecialty({
    required this.id,
    required this.name,
    this.nameTa,
    this.nameHi,
    this.description,
  });

  /// Stable machine-readable identifier (e.g. 'cardiology', 'orthopedics', 'general_medicine').
  final String id;

  /// English display name.
  final String name;

  /// Tamil localized name.
  final String? nameTa;

  /// Hindi localized name.
  final String? nameHi;

  /// Optional clinical description or scope.
  final String? description;

  factory FacilitySpecialty.fromJson(Map<String, dynamic> json) {
    return FacilitySpecialty(
      id: requireNonEmpty(json['id'] as String? ?? '', 'id'),
      name: requireNonEmpty(json['name'] as String? ?? '', 'name'),
      nameTa: json['nameTa'] as String?,
      nameHi: json['nameHi'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameTa != null) 'nameTa': nameTa,
    if (nameHi != null) 'nameHi': nameHi,
    if (description != null) 'description': description,
  };
}

/// Structured medical or diagnostic service offered by a healthcare facility.
class FacilityService {
  const FacilityService({
    required this.id,
    required this.name,
    this.nameTa,
    this.nameHi,
    this.category,
    this.is24x7,
  });

  /// Stable machine-readable identifier (e.g. 'ct_scan', 'blood_bank', 'dialysis', 'ultrasound').
  final String id;

  /// English display name.
  final String name;

  /// Tamil localized name.
  final String? nameTa;

  /// Hindi localized name.
  final String? nameHi;

  /// Service category (e.g. 'diagnostics', 'surgical', 'emergency', 'maternity').
  final String? category;

  /// Whether this specific service operates 24/7. `null` means unverified/unknown.
  final bool? is24x7;

  factory FacilityService.fromJson(Map<String, dynamic> json) {
    return FacilityService(
      id: requireNonEmpty(json['id'] as String? ?? '', 'id'),
      name: requireNonEmpty(json['name'] as String? ?? '', 'name'),
      nameTa: json['nameTa'] as String?,
      nameHi: json['nameHi'] as String?,
      category: json['category'] as String?,
      is24x7: json['is24x7'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameTa != null) 'nameTa': nameTa,
    if (nameHi != null) 'nameHi': nameHi,
    if (category != null) 'category': category,
    if (is24x7 != null) 'is24x7': is24x7,
  };
}
