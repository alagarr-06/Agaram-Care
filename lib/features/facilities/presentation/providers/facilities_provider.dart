// Task 10 - Facility Presentation Providers & Repository.
//
// Manages loading and caching of raw/asset facilities and exposes
// deterministic matching results via Riverpod.
//
// INVARIANTS:
// - Uses Task 09 FacilityMatchingEngine (DO NOT recreate or modify matching logic).
// - Preserves UNKNOWN != NO across all data loads.
// - Supports both real NHM Tamil Nadu facilities and demonstration facilities.
library;

import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../domain/facilities.dart';

/// Facility repository interface to load facilities from asset bundle or local filesystem.
class FacilityRepository {
  FacilityRepository({
    FacilityMatchingEngine? matchingEngine,
    FacilityRawNormalizer? normalizer,
  })  : _matchingEngine = matchingEngine ?? const FacilityMatchingEngine(),
        _normalizer = normalizer ?? const FacilityRawNormalizer();

  final FacilityMatchingEngine _matchingEngine;
  final FacilityRawNormalizer _normalizer;

  List<Facility>? _cachedFacilities;

  /// Loads facilities from real dataset, falling back to demonstration facilities if file cannot be read.
  Future<List<Facility>> loadFacilities() async {
    if (_cachedFacilities != null && _cachedFacilities!.isNotEmpty) {
      return _cachedFacilities!;
    }

    // Try reading CSV file from asset or file system
    String? csvContent;
    try {
      // 1. Try file system first (for desktop / tests)
      final localFile = File('data/raw/facilities/tamil_nadu_nhm_facilities.csv');
      if (localFile.existsSync()) {
        final bytes = await localFile.readAsBytes();
        csvContent = utf8.decode(bytes);
      }
    } catch (_) {}

    if (csvContent == null || csvContent.isEmpty) {
      try {
        // 2. Try rootBundle (for mobile / web)
        csvContent = await rootBundle.loadString('data/raw/facilities/tamil_nadu_nhm_facilities.csv');
      } catch (_) {}
    }

    if (csvContent != null && csvContent.trim().isNotEmpty) {
      final facilities = _parseNhmCsv(csvContent);
      if (facilities.isNotEmpty) {
        // Add demonstration facilities tagged with demo provenance so scenarios can be tested
        final combined = <Facility>[...facilities, ...demonstrationFacilities];
        _cachedFacilities = combined;
        return combined;
      }
    }

    // Fallback: Demonstration facilities
    _cachedFacilities = demonstrationFacilities;
    return demonstrationFacilities;
  }

  /// Parses CSV content into normalized [Facility] list.
  List<Facility> _parseNhmCsv(String csvContent) {
    final lines = const LineSplitter().convert(csvContent);
    if (lines.isEmpty) return const [];

    final headers = parseCsvLine(lines.first);
    final headerMap = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      headerMap[headers[i].trim()] = i;
    }

    final list = <Facility>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cols = parseCsvLine(line);
      if (cols.length != headers.length) continue;

      final row = <String, String>{};
      for (final entry in headerMap.entries) {
        row[entry.key] = cols[entry.value].trim();
      }

      final facility = _normalizer.normalizeRecord(row);
      list.add(facility);
    }
    return list;
  }

  /// Evaluates facilities against a patient care request using deterministic matching engine.
  List<FacilityMatchResult> matchFacilities({
    required List<Facility> facilities,
    required PatientCareRequest request,
    int? limit,
  }) {
    return _matchingEngine.matchFacilities(
      facilities: facilities,
      request: request,
      limit: limit,
    );
  }
}

/// Global repository provider.
final facilityRepositoryProvider = Provider<FacilityRepository>((ref) {
  return FacilityRepository();
});

/// Async notifier/provider for loaded facilities.
final allFacilitiesProvider = FutureProvider<List<Facility>>((ref) async {
  final repo = ref.watch(facilityRepositoryProvider);
  return repo.loadFacilities();
});

/// Active care request state. Defaults to standard care request or initialized from triage.
final activeCareRequestProvider = StateProvider<PatientCareRequest?>((ref) => null);

/// Filter options state in the Facility UI.
class FacilityFilterState {
  const FacilityFilterState({
    this.emergencyOnly = false,
    this.governmentOnly = false,
    this.withCoordinatesOnly = false,
    this.searchQuery = '',
    this.selectedDistrict,
  });

  final bool emergencyOnly;
  final bool governmentOnly;
  final bool withCoordinatesOnly;
  final String searchQuery;
  final String? selectedDistrict;

  FacilityFilterState copyWith({
    bool? emergencyOnly,
    bool? governmentOnly,
    bool? withCoordinatesOnly,
    String? searchQuery,
    String? selectedDistrict,
    bool clearDistrict = false,
  }) {
    return FacilityFilterState(
      emergencyOnly: emergencyOnly ?? this.emergencyOnly,
      governmentOnly: governmentOnly ?? this.governmentOnly,
      withCoordinatesOnly: withCoordinatesOnly ?? this.withCoordinatesOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDistrict: clearDistrict ? null : (selectedDistrict ?? this.selectedDistrict),
    );
  }
}

final facilityFilterProvider = StateProvider<FacilityFilterState>((ref) => const FacilityFilterState());

/// Matched and filtered facilities provider.
final matchedFacilitiesProvider = Provider<AsyncValue<List<FacilityMatchResult>>>((ref) {
  final facilitiesAsync = ref.watch(allFacilitiesProvider);
  final careRequest = ref.watch(activeCareRequestProvider);
  final filter = ref.watch(facilityFilterProvider);
  final repo = ref.watch(facilityRepositoryProvider);

  return facilitiesAsync.whenData((facilities) {
    // 1. If care request is provided, run Task 09 matching engine
    List<FacilityMatchResult> results;
    if (careRequest != null) {
      results = repo.matchFacilities(
        facilities: facilities,
        request: careRequest,
      );
    } else {
      // Default: show active facilities as standard match results
      results = facilities
          .where((f) => f.isActive)
          .map((f) => FacilityMatchResult(
                facility: f,
                isSuitable: true,
                suitabilityScore: 50.0,
                matchReasons: ['Registered operational healthcare facility in Tamil Nadu'],
                isEmergencyCapable: f.emergencyCapability == EmergencyCapability.fullEmergency ||
                    f.emergencyCapability == EmergencyCapability.emergencyAvailable,
                hasSchemeMatch: f.affordability.acceptsGovernmentSchemes,
                isProvenanceVerified: f.provenance.verificationStatus == VerificationStatus.official ||
                    f.provenance.verificationStatus == VerificationStatus.verified,
              ))
          .toList();
    }

    // 2. Apply UI interactive filters
    return results.where((item) {
      final f = item.facility;

      if (filter.emergencyOnly) {
        final isEmerg = f.emergencyCapability == EmergencyCapability.fullEmergency ||
            f.emergencyCapability == EmergencyCapability.emergencyAvailable;
        if (!isEmerg) return false;
      }

      if (filter.governmentOnly) {
        if (f.providerCategory != ProviderCategory.government) return false;
      }

      if (filter.withCoordinatesOnly) {
        if (!f.location.hasCoordinates) return false;
      }

      if (filter.selectedDistrict != null && filter.selectedDistrict!.isNotEmpty) {
        if (f.location.district.toLowerCase() != filter.selectedDistrict!.toLowerCase()) {
          return false;
        }
      }

      if (filter.searchQuery.trim().isNotEmpty) {
        final q = filter.searchQuery.trim().toLowerCase();
        final matchName = f.name.toLowerCase().contains(q) ||
            (f.nameTa?.toLowerCase().contains(q) ?? false) ||
            (f.nameHi?.toLowerCase().contains(q) ?? false);
        final matchDistrict = f.location.district.toLowerCase().contains(q);
        final matchCity = f.location.city.toLowerCase().contains(q);
        final matchPincode = f.location.pincode.contains(q);
        if (!matchName && !matchDistrict && !matchCity && !matchPincode) {
          return false;
        }
      }

      return true;
    }).toList();
  });
});
