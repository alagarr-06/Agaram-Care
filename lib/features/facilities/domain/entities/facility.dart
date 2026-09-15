// Task 08 - Agaram Care Healthcare Facility Aggregate Entity.
library;

import '../enums/facility_enums.dart';
import '../facilities_json_utils.dart';
import 'facility_affordability.dart';
import 'facility_capability.dart';
import 'facility_location.dart';
import 'facility_provenance.dart';
import 'facility_specialty.dart';

/// The central domain entity representing a healthcare facility in Agaram Care.
///
/// Designed to support multidimensional, explainable matching in later tasks:
/// clinical capability + patient need + emergency capability + specialty/service +
/// location/travel + affordability/scheme + verification/provenance.
///
/// NOTE: Dynamic operational metrics (live beds, queue times) are explicitly unknown/null
/// where real-time feeds are unavailable.
class Facility {
  Facility({
    required String id,
    required String name,
    this.nameTa,
    this.nameHi,
    required this.facilityType,
    required this.providerCategory,
    required this.location,
    required this.emergencyCapability,
    this.capability = const FacilityCapability(),
    this.affordability = const FacilityAffordability(),
    required this.provenance,
    List<FacilitySpecialty> specialties = const [],
    List<FacilityService> services = const [],
    this.operatingHours,
    this.contactPhone,
    this.emergencyPhone,
    this.website,
    this.isActive = true,
  })  : id = requireNonEmpty(id, 'id'),
        name = requireNonEmpty(name, 'name'),
        specialties = List.unmodifiable(specialties),
        services = List.unmodifiable(services);

  /// Unique canonical facility identifier (e.g. 'fac-cmch-01').
  final String id;

  /// English official name of the facility.
  final String name;

  /// Tamil localized name.
  final String? nameTa;

  /// Hindi localized name.
  final String? nameHi;

  /// Functional facility type (hospital, clinic, PHC, CHC, diagnostic centre, etc.).
  final FacilityType facilityType;

  /// Provider ownership category (government, private, nonprofit, mixed).
  final ProviderCategory providerCategory;

  /// Physical address and optional geographical coordinates.
  final FacilityLocation location;

  /// Emergency care tier (fullEmergency, emergencyAvailable, limitedEmergency, noEmergency, unknown).
  final EmergencyCapability emergencyCapability;

  /// Inpatient, ICU, pharmacy, teleconsult, and diagnostic capabilities.
  final FacilityCapability capability;

  /// Government schemes, affordability tier, and insurance support.
  final FacilityAffordability affordability;

  /// Data provenance, audit date, and trust verification status.
  final FacilityProvenance provenance;

  /// List of verified clinical specialties offered.
  final List<FacilitySpecialty> specialties;

  /// List of verified clinical or diagnostic services offered.
  final List<FacilityService> services;

  /// Standard operating hours description (e.g. "24/7", "8:00 AM - 4:00 PM").
  final String? operatingHours;

  /// Public inquiries / reception telephone number.
  final String? contactPhone;

  /// Direct emergency / casualty telephone number.
  final String? emergencyPhone;

  /// Official web portal URL.
  final String? website;

  /// Whether the facility is currently operational in Agaram Care registry.
  final bool isActive;

  /// Checks whether this facility offers a given specialty by normalized ID.
  bool hasSpecialty(String specialtyId) {
    final needle = specialtyId.trim().toLowerCase();
    return specialties.any((s) => s.id.toLowerCase() == needle);
  }

  /// Checks whether this facility offers a given service by normalized ID.
  bool hasService(String serviceId) {
    final needle = serviceId.trim().toLowerCase();
    return services.any((s) => s.id.toLowerCase() == needle);
  }

  /// Convenience getter for whether this facility provides any confirmed emergency tier.
  bool get hasAnyEmergency =>
      emergencyCapability == EmergencyCapability.fullEmergency ||
      emergencyCapability == EmergencyCapability.emergencyAvailable;

  factory Facility.fromJson(Map<String, dynamic> json) {
    final rawSpecialties = json['specialties'] as List<dynamic>? ?? [];
    final rawServices = json['services'] as List<dynamic>? ?? [];

    return Facility(
      id: requireNonEmpty(json['id'] as String? ?? '', 'id'),
      name: requireNonEmpty(json['name'] as String? ?? '', 'name'),
      nameTa: json['nameTa'] as String?,
      nameHi: json['nameHi'] as String?,
      facilityType: FacilityType.fromJson(json['facilityType']),
      providerCategory: ProviderCategory.fromJson(json['providerCategory']),
      location: FacilityLocation.fromJson(
        json['location'] as Map<String, dynamic>? ?? const {},
      ),
      emergencyCapability: EmergencyCapability.fromJson(json['emergencyCapability']),
      capability: json['capability'] != null
          ? FacilityCapability.fromJson(json['capability'] as Map<String, dynamic>)
          : const FacilityCapability(),
      affordability: json['affordability'] != null
          ? FacilityAffordability.fromJson(json['affordability'] as Map<String, dynamic>)
          : const FacilityAffordability(),
      provenance: FacilityProvenance.fromJson(
        json['provenance'] as Map<String, dynamic>? ?? const {},
      ),
      specialties: [
        for (final item in rawSpecialties)
          if (item is Map<String, dynamic>) FacilitySpecialty.fromJson(item),
      ],
      services: [
        for (final item in rawServices)
          if (item is Map<String, dynamic>) FacilityService.fromJson(item),
      ],
      operatingHours: json['operatingHours'] as String?,
      contactPhone: json['contactPhone'] as String?,
      emergencyPhone: json['emergencyPhone'] as String?,
      website: json['website'] as String?,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (nameTa != null) 'nameTa': nameTa,
    if (nameHi != null) 'nameHi': nameHi,
    'facilityType': facilityType.toJson(),
    'providerCategory': providerCategory.toJson(),
    'location': location.toJson(),
    'emergencyCapability': emergencyCapability.toJson(),
    'capability': capability.toJson(),
    'affordability': affordability.toJson(),
    'provenance': provenance.toJson(),
    'specialties': [for (final s in specialties) s.toJson()],
    'services': [for (final s in services) s.toJson()],
    if (operatingHours != null) 'operatingHours': operatingHours,
    if (contactPhone != null) 'contactPhone': contactPhone,
    if (emergencyPhone != null) 'emergencyPhone': emergencyPhone,
    if (website != null) 'website': website,
    'isActive': isActive,
  };
}
