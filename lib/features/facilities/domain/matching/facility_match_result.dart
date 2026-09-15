// Task 09 - Agaram Care Facility Match Result Model.
library;

import '../entities/facility.dart';

/// Detailed result of evaluating a single [Facility] against a [PatientCareRequest].
///
/// Contains structured, explainable criteria rather than an opaque numerical score alone.
/// Answers the core question: "Which facilities are appropriate, and WHY?"
class FacilityMatchResult {
  const FacilityMatchResult({
    required this.facility,
    required this.isSuitable,
    required this.suitabilityScore,
    required this.matchReasons,
    this.exclusionReason,
    this.distanceKm,
    this.isEmergencyCapable = false,
    this.hasSpecialtyMatch = false,
    this.hasServiceMatch = false,
    this.hasSchemeMatch = false,
    this.isProvenanceVerified = false,
  });

  /// The evaluated facility entity.
  final Facility facility;

  /// Whether the facility satisfies all clinical suitability and safety filters.
  final bool isSuitable;

  /// Transparent weighted suitability score (0.0 to 100.0).
  /// Clinical and safety suitability dominate distance.
  final double suitabilityScore;

  /// Human-readable, structured explanations answering "Why this facility?".
  /// Derived ONLY from confirmed data evidence.
  final List<String> matchReasons;

  /// Rationale if the facility was excluded from clinical suitability.
  final String? exclusionReason;

  /// Great-circle Haversine distance in kilometers from patient, if coordinates available.
  final double? distanceKm;

  /// Whether facility has confirmed emergency capability matching need.
  final bool isEmergencyCapable;

  /// Whether requested clinical specialty is explicitly confirmed.
  final bool hasSpecialtyMatch;

  /// Whether requested diagnostic/clinical service is explicitly confirmed.
  final bool hasServiceMatch;

  /// Whether requested welfare scheme is explicitly accepted.
  final bool hasSchemeMatch;

  /// Whether data provenance is verified or official.
  final bool isProvenanceVerified;

  /// Formats distance as human-readable string (e.g. "2.4 km").
  String? get formattedDistance {
    if (distanceKm == null) return null;
    if (distanceKm! < 1.0) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }

  Map<String, dynamic> toJson() => {
    'facilityId': facility.id,
    'facilityName': facility.name,
    'isSuitable': isSuitable,
    'suitabilityScore': suitabilityScore,
    'matchReasons': matchReasons,
    if (exclusionReason != null) 'exclusionReason': exclusionReason,
    if (distanceKm != null) 'distanceKm': distanceKm,
    'isEmergencyCapable': isEmergencyCapable,
    'hasSpecialtyMatch': hasSpecialtyMatch,
    'hasServiceMatch': hasServiceMatch,
    'hasSchemeMatch': hasSchemeMatch,
    'isProvenanceVerified': isProvenanceVerified,
    'provenance': facility.provenance.toJson(),
  };
}
