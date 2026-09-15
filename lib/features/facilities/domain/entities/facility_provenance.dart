// Task 08 - Agaram Care Facility Provenance Entity.
library;

import '../enums/facility_enums.dart';
import '../facilities_json_utils.dart';

/// Trust, verification, and origin metadata for a healthcare facility record.
///
/// Answers the core trust question: "Why should Agaram Care trust this information?"
///
/// Differentiates official health registries from facility-reported data and
/// synthetic demonstration data.
class FacilityProvenance {
  const FacilityProvenance({
    required this.verificationStatus,
    required this.dataSourceType,
    required this.lastUpdated,
    this.sourceName,
    this.sourceRegistryId,
    this.verifiedAt,
    this.verificationNotes,
  });

  /// Verification grade of this facility entry.
  final VerificationStatus verificationStatus;

  /// Source category (official, verifiedRegistry, facilityProvided, demonstration).
  final DataSourceType dataSourceType;

  /// Name of the authority or source providing this data (e.g. "NHM Tamil Nadu", "Synthetic Demo").
  final String? sourceName;

  /// Canonical registry identifier (e.g. ROHINI ID, NIN, PMJAY Hospital ID).
  final String? sourceRegistryId;

  /// Timestamp when the entry was officially audited or verified. `null` if unverified.
  final DateTime? verifiedAt;

  /// Last modification timestamp in Agaram Care.
  final DateTime lastUpdated;

  /// Optional provenance comments or verification scope remarks.
  final String? verificationNotes;

  /// Returns true if this record is tagged as demonstration/synthetic data.
  bool get isDemonstration =>
      verificationStatus == VerificationStatus.demonstration ||
      dataSourceType == DataSourceType.demonstration;

  factory FacilityProvenance.fromJson(Map<String, dynamic> json) {
    return FacilityProvenance(
      verificationStatus: VerificationStatus.fromJson(json['verificationStatus']),
      dataSourceType: DataSourceType.fromJson(json['dataSourceType']),
      sourceName: json['sourceName'] as String?,
      sourceRegistryId: json['sourceRegistryId'] as String?,
      verifiedAt: parseOptionalTimestamp(json['verifiedAt']),
      lastUpdated: parseRequiredTimestamp(json['lastUpdated'], 'lastUpdated'),
      verificationNotes: json['verificationNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'verificationStatus': verificationStatus.toJson(),
    'dataSourceType': dataSourceType.toJson(),
    if (sourceName != null) 'sourceName': sourceName,
    if (sourceRegistryId != null) 'sourceRegistryId': sourceRegistryId,
    if (verifiedAt != null) 'verifiedAt': verifiedAt!.toIso8601String(),
    'lastUpdated': lastUpdated.toIso8601String(),
    if (verificationNotes != null) 'verificationNotes': verificationNotes,
  };
}
