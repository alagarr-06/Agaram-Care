// Task 09 - Agaram Care Deterministic Facility Matching Engine.
//
// Matches a PatientCareRequest against normalized Facility records using explicit,
// explainable clinical suitability criteria.
//
// CRITICAL MATCHING PRINCIPLES:
// 1. SAFETY & CLINICAL SUITABILITY DOMINATE DISTANCE.
// 2. UNKNOWN != NO (missing source data is never assumed false/unavailable).
// 3. NO "BEST HOSPITAL" LANGUAGE (ranks by suitability for current care need).
// 4. DETERMINISTIC & EXPLAINABLE ("Why this facility?" reasons from actual evidence).
library;

import '../../../triage/domain/enums/triage_urgency.dart';
import '../entities/facility.dart';
import '../enums/facility_enums.dart';
import 'facility_geo_utils.dart';
import 'facility_match_result.dart';
import 'patient_care_request.dart';

class FacilityMatchingEngine {
  const FacilityMatchingEngine();

  /// Evaluates and ranks a list of facilities against a patient care request.
  /// Returns only suitable facilities, ordered from highest suitability to lowest.
  List<FacilityMatchResult> matchFacilities({
    required List<Facility> facilities,
    required PatientCareRequest request,
    int? limit,
  }) {
    if (facilities.isEmpty) return const [];

    final results = <FacilityMatchResult>[];

    for (final facility in facilities) {
      // 1. Inactive facilities are immediately excluded
      if (!facility.isActive) continue;

      final matchResult = evaluateFacility(facility: facility, request: request);
      if (matchResult.isSuitable) {
        results.add(matchResult);
      }
    }

    // 2. Deterministic sorting:
    // Primary: Suitability score (descending)
    // Secondary: Distance (ascending, nullable distances placed after known distances)
    // Tertiary: Facility ID (stable tie-breaker)
    results.sort((a, b) {
      // Primary: Score difference
      final scoreDiff = b.suitabilityScore.compareTo(a.suitabilityScore);
      if (scoreDiff.abs() > 0.001) return scoreDiff;

      // Secondary: Distance
      if (a.distanceKm != null && b.distanceKm != null) {
        final distDiff = a.distanceKm!.compareTo(b.distanceKm!);
        if (distDiff.abs() > 0.001) return distDiff;
      } else if (a.distanceKm != null && b.distanceKm == null) {
        return -1;
      } else if (a.distanceKm == null && b.distanceKm != null) {
        return 1;
      }

      // Tertiary: Stable tie-breaker by ID
      return a.facility.id.compareTo(b.facility.id);
    });

    if (limit != null && limit > 0 && results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  /// Evaluates a single facility against a patient care request.
  FacilityMatchResult evaluateFacility({
    required Facility facility,
    required PatientCareRequest request,
  }) {
    final reasons = <String>[];
    double score = 0.0;
    bool isEmergencyCapable = false;
    bool hasSpecialtyMatch = false;
    bool hasServiceMatch = false;
    bool hasSchemeMatch = false;

    // -------------------------------------------------------------------------
    // STAGE 1: SAFETY & CLINICAL SUITABILITY (Dominant Factor: up to 50 pts)
    // -------------------------------------------------------------------------

    if (request.isEmergencyCareRequired) {
      // Confirmed Unsuitable: Explicit no-emergency capability cannot accept an emergency case
      if (facility.emergencyCapability == EmergencyCapability.noEmergency) {
        return FacilityMatchResult(
          facility: facility,
          isSuitable: false,
          suitabilityScore: 0.0,
          matchReasons: const [],
          exclusionReason: 'Facility is confirmed to have no emergency care capability',
        );
      }

      // Insufficient Evidence: Unknown emergency capability cannot be assumed or recommended as confirmed emergency
      // UNKNOWN != NO: It is not treated as explicit "noEmergency", but as unverified/insufficient evidence.
      if (facility.emergencyCapability == EmergencyCapability.unknown) {
        return FacilityMatchResult(
          facility: facility,
          isSuitable: false,
          suitabilityScore: 0.0,
          matchReasons: const [],
          exclusionReason: 'Emergency capability is unknown / unverified (insufficient evidence to confirm emergency suitability)',
        );
      }

      // Confirmed emergency capability tiers
      if (facility.emergencyCapability == EmergencyCapability.fullEmergency) {
        score += 50.0;
        isEmergencyCapable = true;
        reasons.add('Comprehensive 24/7 emergency care capability confirmed');
      } else if (facility.emergencyCapability == EmergencyCapability.emergencyAvailable) {
        score += 45.0;
        isEmergencyCapable = true;
        reasons.add('Emergency casualty care confirmed and operational');
      } else if (facility.emergencyCapability == EmergencyCapability.limitedEmergency) {
        // Limited emergency (e.g. daytime stabilization / first-aid PHC)
        // Only considered suitable when the structured care request explicitly permits limited stabilization
        // (or non-inpatient first response), rather than treating every limited emergency facility as suitable for all emergencies.
        if (request.allowsLimitedEmergency || (!request.requiresInpatient && request.urgency != TriageUrgency.emergency)) {
          score += 25.0;
          isEmergencyCapable = true;
          reasons.add('Limited emergency stabilization available (structured need permits limited stabilization)');
        } else {
          return FacilityMatchResult(
            facility: facility,
            isSuitable: false,
            suitabilityScore: 0.0,
            matchReasons: const [],
            exclusionReason: 'Facility has only limited emergency stabilization and is not equipped for full emergency care',
          );
        }
      }
    } else {
      // Non-emergency: Baseline general care suitability
      score += 20.0;
      if (facility.emergencyCapability == EmergencyCapability.fullEmergency ||
          facility.emergencyCapability == EmergencyCapability.emergencyAvailable) {
        score += 5.0;
      }
    }

    // -------------------------------------------------------------------------
    // STAGE 2: REQUIRED SPECIALTY & SERVICE (up to 25 pts)
    // -------------------------------------------------------------------------

    if (request.requiredSpecialtyId != null && request.requiredSpecialtyId!.trim().isNotEmpty) {
      final specId = request.requiredSpecialtyId!.trim();
      if (facility.hasSpecialty(specId)) {
        score += 20.0;
        hasSpecialtyMatch = true;
        final specName = facility.specialties
            .firstWhere((s) => s.id.toLowerCase() == specId.toLowerCase())
            .name;
        reasons.add('Confirmed clinical specialty: $specName');
      } else {
        // Specialty is not confirmed.
        // If the facility has a verified specialties list and it is explicitly absent, dock points
        if (facility.specialties.isNotEmpty) {
          score -= 10.0;
        }
      }
    }

    if (request.requiredServiceId != null && request.requiredServiceId!.trim().isNotEmpty) {
      final srvId = request.requiredServiceId!.trim();
      if (facility.hasService(srvId)) {
        score += 15.0;
        hasServiceMatch = true;
        final srvName = facility.services
            .firstWhere((s) => s.id.toLowerCase() == srvId.toLowerCase())
            .name;
        reasons.add('Confirmed service available: $srvName');
      }
    }

    // Inpatient requirement
    if (request.requiresInpatient) {
      if (facility.capability.inpatientAvailable == true) {
        score += 10.0;
        reasons.add('Inpatient bed ward available');
      } else if (facility.capability.inpatientAvailable == false) {
        return FacilityMatchResult(
          facility: facility,
          isSuitable: false,
          suitabilityScore: 0.0,
          matchReasons: const [],
          exclusionReason: 'Facility explicitly lacks inpatient admission beds',
        );
      }
    }

    // -------------------------------------------------------------------------
    // STAGE 3: FACILITY TYPE APPROPRIATENESS (up to 10 pts)
    // -------------------------------------------------------------------------

    if (request.preferredFacilityType != null) {
      if (facility.facilityType == request.preferredFacilityType) {
        score += 10.0;
        reasons.add('Matches requested facility level: ${facility.facilityType.name}');
      }
    } else {
      // Natural alignment based on urgency:
      // Emergency -> Hospital
      // Non-urgent -> Primary Health Centre / Clinic
      if (request.isEmergencyCareRequired) {
        if (facility.facilityType == FacilityType.hospital) {
          score += 10.0;
        }
      } else {
        if (facility.facilityType == FacilityType.primaryHealthCentre ||
            facility.facilityType == FacilityType.communityHealthCentre ||
            facility.facilityType == FacilityType.clinic) {
          score += 8.0;
          reasons.add('Primary care tier appropriate for routine assessment');
        } else if (facility.facilityType == FacilityType.hospital) {
          score += 5.0;
        }
      }
    }

    // -------------------------------------------------------------------------
    // STAGE 4: AFFORDABILITY & SCHEME COMPATIBILITY (up to 10 pts)
    // -------------------------------------------------------------------------

    if (request.requiredScheme != null && request.requiredScheme!.trim().isNotEmpty) {
      final reqScheme = request.requiredScheme!.trim().toLowerCase();
      final hasScheme = facility.affordability.supportedSchemes.any(
        (s) => s.toLowerCase().contains(reqScheme),
      );

      if (hasScheme) {
        score += 10.0;
        hasSchemeMatch = true;
        reasons.add('Empaneled for scheme: ${request.requiredScheme}');
      } else if (!facility.affordability.acceptsGovernmentSchemes) {
        // Does not accept government schemes
        score -= 5.0;
      }
    } else {
      if (facility.affordability.isFreeCareAvailable == true) {
        score += 5.0;
        reasons.add('Free public health services provided');
      }
    }

    // -------------------------------------------------------------------------
    // STAGE 5: GEOGRAPHIC PROXIMITY & RELEVANCE (up to 10 pts max)
    // Safety & capability dominate: max distance bonus is 10 points.
    // -------------------------------------------------------------------------

    double? distanceKm;
    if (request.patientLocation != null) {
      if (request.patientLocation!.hasCoordinates && facility.location.hasCoordinates) {
        distanceKm = FacilityGeoUtils.distanceBetween(
          request.patientLocation!,
          facility.location,
        );

        if (distanceKm != null) {
          if (distanceKm <= 5.0) {
            score += 10.0;
            reasons.add('Nearby location (${distanceKm.toStringAsFixed(1)} km)');
          } else if (distanceKm <= 15.0) {
            score += 7.0;
            reasons.add('Accessible distance (${distanceKm.toStringAsFixed(1)} km)');
          } else if (distanceKm <= 35.0) {
            score += 4.0;
            reasons.add('District travel range (${distanceKm.toStringAsFixed(1)} km)');
          } else {
            score += 1.0;
          }
        }
      } else {
        // Fallback to geographic administrative hierarchy (PIN -> District -> State)
        final geoRel = FacilityGeoUtils.calculateHierarchyRelevance(
          patientLoc: request.patientLocation!,
          facilityLoc: facility.location,
        );
        if (geoRel >= 0.9) {
          score += 8.0;
          reasons.add('Located in patient\'s postal area (${facility.location.pincode})');
        } else if (geoRel >= 0.6) {
          score += 5.0;
          reasons.add('Located in patient\'s revenue district (${facility.location.district})');
        } else if (geoRel >= 0.2) {
          score += 2.0;
        }
      }
    }

    // -------------------------------------------------------------------------
    // STAGE 6: DATA PROVENANCE & AUDIT TRUST (up to 5 pts)
    // -------------------------------------------------------------------------

    final isVerified = facility.provenance.verificationStatus == VerificationStatus.official ||
        facility.provenance.verificationStatus == VerificationStatus.verified ||
        facility.provenance.dataSourceType == DataSourceType.official ||
        facility.provenance.dataSourceType == DataSourceType.verifiedRegistry;

    if (isVerified) {
      score += 5.0;
      reasons.add('Verified official health registry data');
    } else if (facility.provenance.isDemonstration) {
      reasons.add('Demonstration record (test dataset)');
    }

    // Normalized bounds
    if (score < 0.0) score = 0.0;
    if (score > 100.0) score = 100.0;

    return FacilityMatchResult(
      facility: facility,
      isSuitable: true,
      suitabilityScore: double.parse(score.toStringAsFixed(1)),
      matchReasons: List.unmodifiable(reasons),
      distanceKm: distanceKm != null ? double.parse(distanceKm.toStringAsFixed(2)) : null,
      isEmergencyCapable: isEmergencyCapable,
      hasSpecialtyMatch: hasSpecialtyMatch,
      hasServiceMatch: hasServiceMatch,
      hasSchemeMatch: hasSchemeMatch,
      isProvenanceVerified: isVerified,
    );
  }
}
