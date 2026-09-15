// Task 08 — Agaram Care Facility Enums.
//
// Small, explicit enums modeling facility category, provider type,
// emergency capability, verification level, and data provenance.
library;

/// The primary functional type of a healthcare facility.
enum FacilityType {
  hospital,
  clinic,
  primaryHealthCentre,
  communityHealthCentre,
  diagnosticCentre,
  pharmacy,
  telemedicineCentre,
  other;

  String toJson() => name;

  static FacilityType fromJson(Object? value) {
    for (final type in FacilityType.values) {
      if (type.name == value) return type;
    }
    return FacilityType.other;
  }
}

/// The administrative / ownership category of a healthcare provider.
enum ProviderCategory {
  government,
  private,
  mixed,
  nonprofit,
  unknown;

  String toJson() => name;

  static ProviderCategory fromJson(Object? value) {
    for (final cat in ProviderCategory.values) {
      if (cat.name == value) return cat;
    }
    return ProviderCategory.unknown;
  }
}

/// The emergency care capability tier of a facility.
///
/// SAFETY BOUNDARY:
/// Differentiates 24/7 comprehensive emergency centers from clinics with
/// limited or no emergency support, and preserves 'unknown' when capability
/// has not been verified.
enum EmergencyCapability {
  fullEmergency,
  emergencyAvailable,
  limitedEmergency,
  noEmergency,
  unknown;

  String toJson() => name;

  static EmergencyCapability fromJson(Object? value) {
    for (final cap in EmergencyCapability.values) {
      if (cap.name == value) return cap;
    }
    return EmergencyCapability.unknown;
  }
}

/// The verification level of a facility record in Agaram Care.
enum VerificationStatus {
  official,
  verified,
  facilityProvided,
  demonstration,
  unknown;

  String toJson() => name;

  static VerificationStatus fromJson(Object? value) {
    for (final status in VerificationStatus.values) {
      if (status.name == value) return status;
    }
    return VerificationStatus.unknown;
  }
}

/// The origin / provenance category of the facility dataset.
enum DataSourceType {
  official,
  verifiedRegistry,
  facilityProvided,
  demonstration,
  unknown;

  String toJson() => name;

  static DataSourceType fromJson(Object? value) {
    for (final src in DataSourceType.values) {
      if (src.name == value) return src;
    }
    return DataSourceType.unknown;
  }
}
