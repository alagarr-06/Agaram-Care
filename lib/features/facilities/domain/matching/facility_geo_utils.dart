// Task 09 - Deterministic Geographic Utilities for Facility Matching.
library;

import 'dart:math' as math;

import '../entities/facility_location.dart';

/// Deterministic geographic proximity and distance calculation.
class FacilityGeoUtils {
  const FacilityGeoUtils();

  /// Earth's mean radius in kilometers (WGS-84 sphere approximation).
  static const double earthRadiusKm = 6371.0;

  /// Calculates the great-circle distance between two coordinate pairs using
  /// the Haversine formula. Returns distance in kilometers, or `null` if any
  /// coordinate is null or invalid.
  static double? calculateHaversineKm({
    required double? lat1,
    required double? lon1,
    required double? lat2,
    required double? lon2,
  }) {
    if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
      return null;
    }
    if (lat1 < -90 || lat1 > 90 || lat2 < -90 || lat2 > 90) return null;
    if (lon1 < -180 || lon1 > 180 || lon2 < -180 || lon2 > 180) return null;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Calculates distance between a patient location and a facility location.
  static double? distanceBetween(FacilityLocation loc1, FacilityLocation loc2) {
    return calculateHaversineKm(
      lat1: loc1.latitude,
      lon1: loc1.longitude,
      lat2: loc2.latitude,
      lon2: loc2.longitude,
    );
  }

  /// Evaluates geographic administrative match between patient and facility locations.
  /// Returns a normalized hierarchy match score between 0.0 and 1.0.
  static double calculateHierarchyRelevance({
    required FacilityLocation patientLoc,
    required FacilityLocation facilityLoc,
  }) {
    // Exact PIN match = highest local community confidence
    if (patientLoc.pincode.isNotEmpty &&
        facilityLoc.pincode.isNotEmpty &&
        patientLoc.pincode.trim() == facilityLoc.pincode.trim()) {
      return 1.0;
    }

    // Exact District match = high district hospital confidence
    if (patientLoc.district.isNotEmpty &&
        facilityLoc.district.isNotEmpty &&
        patientLoc.district.trim().toLowerCase() ==
            facilityLoc.district.trim().toLowerCase()) {
      return 0.7;
    }

    // State match = baseline state network
    if (patientLoc.state.isNotEmpty &&
        facilityLoc.state.isNotEmpty &&
        patientLoc.state.trim().toLowerCase() ==
            facilityLoc.state.trim().toLowerCase()) {
      return 0.3;
    }

    return 0.0;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);
}
