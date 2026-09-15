// Task 09 - Agaram Care Facility Matching Engine Unit & Regression Tests.
//
// 25 Comprehensive Tests covering:
// 1. Emergency case prefers emergency-capable facility over closer unsuitable clinic.
// 2. Explicit no-emergency facility is excluded for emergency need.
// 3. Unknown emergency capability is not falsely treated as emergency capable.
// 4. Urgent case ranks clinically suitable facilities before merely nearby unsuitable facilities.
// 5. Routine case supports primary-care / PHC facilities.
// 6. Specialty match improves suitability score.
// 7. Missing specialty remains UNKNOWN and does not trigger a false match.
// 8. Scheme match works when explicitly confirmed (e.g. CMCHIS).
// 9. Unknown scheme does not receive a false positive.
// 10. Distance calculation is deterministic (Haversine formula).
// 11. Pincode/district/taluk geographic relevance works when coordinates are missing.
// 12. Unknown geography does not produce fake distance.
// 13. Provenance is preserved in the match result.
// 14. Synthetic/demo provenance remains distinguishable from official/verified data.
// 15. "Why this facility?" reasons are generated only from actual evidence.
// 16. Clinically unsuitable facilities cannot outrank suitable ones through distance alone.
// 17. Stable deterministic ordering for equivalent matches (tie-breaker by ID).
// 18. Empty facility dataset handled safely without errors.
// 19. Multiple matching facilities returned correctly.
// 20. Original Facility model is not mutated by matching.
// 21. Real NHM dataset: Emergency request filters out day-only dispensaries.
// 22. Real NHM dataset: Emergency request selects verified 24/7 emergency facilities (e.g. Balarengapuram GH).
// 23. Real NHM dataset: Routine request correctly surfaces nearby UPHC clinics.
// 24. Real NHM dataset: Geographic proximity correctly ranks closer verified facilities ahead of distant ones when capabilities are equal.
// 25. PatientCareRequest.fromTriage correctly maps TriageResult to care requirements.

import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/result/triage_disposition_state.dart';
import 'package:agaram_care/features/triage/domain/result/triage_result.dart';
import 'package:agaram_care/features/facilities/domain/facilities.dart';

void main() {
  group('Task 09 - Facility Matching Engine Tests', () {
    const engine = FacilityMatchingEngine();
    const normalizer = FacilityRawNormalizer();

    final testTimestamp = DateTime.utc(2026, 9, 14, 12, 0, 0);

    // Reusable facility fixtures
    final emergencyHospital = Facility(
      id: 'fac-gh-01',
      name: 'Government District Headquarters Hospital',
      facilityType: FacilityType.hospital,
      providerCategory: ProviderCategory.government,
      location: const FacilityLocation(
        addressLine: 'Hospital Road',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625001',
        latitude: 9.9200,
        longitude: 78.1200,
      ),
      emergencyCapability: EmergencyCapability.fullEmergency,
      capability: const FacilityCapability(
        inpatientAvailable: true,
        icuAvailable: true,
        ambulanceAvailable: true,
        approxTotalBeds: 350,
      ),
      specialties: const [
        FacilitySpecialty(id: 'general_medicine', name: 'General Medicine'),
        FacilitySpecialty(id: 'cardiology', name: 'Cardiology'),
        FacilitySpecialty(id: 'emergency_medicine', name: 'Emergency Medicine'),
      ],
      affordability: const FacilityAffordability(
        acceptsGovernmentSchemes: true,
        supportedSchemes: ['cmchis', 'pmjay'],
        isFreeCareAvailable: true,
      ),
      provenance: FacilityProvenance(
        sourceRegistryId: 'nhm-madurai-01',
        verificationStatus: VerificationStatus.verified,
        dataSourceType: DataSourceType.verifiedRegistry,
        sourceName: 'National Health Mission Tamil Nadu',
        lastUpdated: testTimestamp,
      ),
    );

    final clinicNoEmergency = Facility(
      id: 'fac-clinic-02',
      name: 'City Care Day Dispensary',
      facilityType: FacilityType.clinic,
      providerCategory: ProviderCategory.private,
      location: const FacilityLocation(
        addressLine: 'Main Bazaar',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625001',
        latitude: 9.9210, // closer to user
        longitude: 78.1210,
      ),
      emergencyCapability: EmergencyCapability.noEmergency,
      capability: const FacilityCapability(
        inpatientAvailable: false,
        icuAvailable: false,
      ),
      provenance: FacilityProvenance(
        verificationStatus: VerificationStatus.verified,
        dataSourceType: DataSourceType.verifiedRegistry,
        sourceName: 'National Health Mission Tamil Nadu',
        lastUpdated: testTimestamp,
      ),
    );

    final clinicUnknownEmergency = Facility(
      id: 'fac-clinic-03',
      name: 'Neighborhood Community Clinic',
      facilityType: FacilityType.clinic,
      providerCategory: ProviderCategory.private,
      location: const FacilityLocation(
        addressLine: 'South Street',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625001',
        latitude: 9.9205, // very close
        longitude: 78.1205,
      ),
      emergencyCapability: EmergencyCapability.unknown,
      capability: const FacilityCapability(),
      provenance: FacilityProvenance(
        verificationStatus: VerificationStatus.facilityProvided,
        dataSourceType: DataSourceType.facilityProvided,
        sourceName: 'Self Registry',
        lastUpdated: testTimestamp,
      ),
    );

    final primaryHealthCentre = Facility(
      id: 'fac-phc-04',
      name: 'Madurai Urban Primary Health Centre',
      facilityType: FacilityType.primaryHealthCentre,
      providerCategory: ProviderCategory.government,
      location: const FacilityLocation(
        addressLine: 'PHC Road',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625001',
        latitude: 9.9220,
        longitude: 78.1220,
      ),
      emergencyCapability: EmergencyCapability.limitedEmergency,
      capability: const FacilityCapability(
        inpatientAvailable: false,
        pharmacyAvailable: true,
      ),
      specialties: const [
        FacilitySpecialty(id: 'general_medicine', name: 'General Medicine'),
      ],
      affordability: const FacilityAffordability(
        acceptsGovernmentSchemes: true,
        supportedSchemes: ['cmchis'],
        isFreeCareAvailable: true,
      ),
      provenance: FacilityProvenance(
        verificationStatus: VerificationStatus.verified,
        dataSourceType: DataSourceType.verifiedRegistry,
        sourceName: 'National Health Mission Tamil Nadu',
        lastUpdated: testTimestamp,
      ),
    );

    // 1. Emergency case prefers emergency-capable facility over closer unsuitable clinic
    test('1. Emergency case prefers emergency-capable facility over closer unsuitable clinic', () {
      final request = PatientCareRequest(
        urgency: TriageUrgency.emergency,
        isEmergencyCareRequired: true,
        patientLocation: const FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
          latitude: 9.9208,
          longitude: 78.1208,
        ),
      );

      final matches = engine.matchFacilities(
        request: request,
        facilities: [clinicNoEmergency, emergencyHospital, clinicUnknownEmergency],
      );

      expect(matches, isNotEmpty);
      expect(matches.first.facility.id, equals(emergencyHospital.id));
      expect(matches.first.isSuitable, isTrue);
      expect(matches.first.isEmergencyCapable, isTrue);
    });

    // 2. Explicit no-emergency facility is excluded for emergency need
    test('2. Explicit no-emergency facility is excluded for emergency need', () {
      final request = const PatientCareRequest(
        urgency: TriageUrgency.emergency,
        isEmergencyCareRequired: true,
      );

      final result = engine.evaluateFacility(facility: clinicNoEmergency, request: request);
      expect(result.isSuitable, isFalse);
      expect(result.exclusionReason, contains('confirmed to have no emergency care capability'));
    });

    // 3. Unknown emergency capability is not falsely treated as emergency capable
    test('3. Unknown emergency capability is not falsely treated as emergency capable', () {
      final request = const PatientCareRequest(
        urgency: TriageUrgency.emergency,
        isEmergencyCareRequired: true,
      );

      final result = engine.evaluateFacility(facility: clinicUnknownEmergency, request: request);
      expect(result.isSuitable, isFalse);
      expect(result.isEmergencyCapable, isFalse);
      expect(result.exclusionReason, contains('unknown / unverified (insufficient evidence'));
    });

    // 4. Urgent case ranks clinically suitable facilities before merely nearby unsuitable facilities
    test('4. Urgent case ranks clinically suitable facilities before merely nearby unsuitable facilities', () {
      final request = const PatientCareRequest(
        urgency: TriageUrgency.urgent,
        requiresInpatient: true,
        patientLocation: FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
          latitude: 9.9209,
          longitude: 78.1209,
        ),
      );

      final matches = engine.matchFacilities(
        request: request,
        facilities: [clinicNoEmergency, emergencyHospital],
      );

      expect(matches.length, equals(1));
      expect(matches.first.facility.id, equals(emergencyHospital.id));
      expect(matches.first.isSuitable, isTrue);

      final unsuitableResult = engine.evaluateFacility(facility: clinicNoEmergency, request: request);
      expect(unsuitableResult.isSuitable, isFalse);
      expect(unsuitableResult.exclusionReason, contains('inpatient admission beds'));
    });

    // 5. Routine case supports primary-care / PHC facilities
    test('5. Routine case supports primary-care / PHC facilities', () {
      final request = const PatientCareRequest(
        urgency: TriageUrgency.routine,
        preferredFacilityType: FacilityType.primaryHealthCentre,
      );

      final matches = engine.matchFacilities(
        request: request,
        facilities: [emergencyHospital, primaryHealthCentre],
      );

      // Both should be suitable, PHC matches preferredFacilityType
      expect(matches.every((m) => m.isSuitable), isTrue);
      final phcMatch = matches.firstWhere((m) => m.facility.id == primaryHealthCentre.id);
      expect(phcMatch.matchReasons, anyElement(contains('Matches requested facility level')));
    });

    // 6. Specialty match improves suitability score
    test('6. Specialty match improves suitability score', () {
      const requestWithSpecialty = PatientCareRequest(
        urgency: TriageUrgency.urgent,
        requiredSpecialtyId: 'cardiology',
      );
      const requestWithoutSpecialty = PatientCareRequest(
        urgency: TriageUrgency.urgent,
      );

      final result1 = engine.evaluateFacility(facility: emergencyHospital, request: requestWithSpecialty);
      final result2 = engine.evaluateFacility(facility: emergencyHospital, request: requestWithoutSpecialty);

      expect(result1.hasSpecialtyMatch, isTrue);
      expect(result1.suitabilityScore, greaterThan(result2.suitabilityScore));
      expect(result1.matchReasons, anyElement(contains('Cardiology')));
    });

    // 7. Missing specialty remains UNKNOWN and does not trigger a false match
    test('7. Missing specialty remains UNKNOWN and does not trigger a false match', () {
      const request = PatientCareRequest(
        urgency: TriageUrgency.urgent,
        requiredSpecialtyId: 'neurology',
      );

      final result = engine.evaluateFacility(facility: emergencyHospital, request: request);
      expect(result.hasSpecialtyMatch, isFalse);
      expect(result.matchReasons.where((r) => r.contains('Neurology')), isEmpty);
    });

    // 8. Scheme match works when explicitly confirmed (e.g. CMCHIS)
    test('8. Scheme match works when explicitly confirmed (e.g. CMCHIS)', () {
      const request = PatientCareRequest(
        urgency: TriageUrgency.routine,
        requiredScheme: 'cmchis',
      );

      final result = engine.evaluateFacility(facility: emergencyHospital, request: request);
      expect(result.hasSchemeMatch, isTrue);
      expect(result.matchReasons, anyElement(contains('cmchis')));
    });

    // 9. Unknown scheme does not receive a false positive
    test('9. Unknown scheme does not receive a false positive', () {
      const request = PatientCareRequest(
        urgency: TriageUrgency.routine,
        requiredScheme: 'cmchis',
      );

      final result = engine.evaluateFacility(facility: clinicUnknownEmergency, request: request);
      expect(result.hasSchemeMatch, isFalse);
    });

    // 10. Distance calculation is deterministic (Haversine formula)
    test('10. Distance calculation is deterministic (Haversine formula)', () {
      // Distance between Madurai (9.9252, 78.1198) and Chennai (13.0827, 80.2707)
      final dist1 = FacilityGeoUtils.calculateHaversineKm(
        lat1: 9.9252,
        lon1: 78.1198,
        lat2: 13.0827,
        lon2: 80.2707,
      );
      final dist2 = FacilityGeoUtils.calculateHaversineKm(
        lat1: 9.9252,
        lon1: 78.1198,
        lat2: 13.0827,
        lon2: 80.2707,
      );

      expect(dist1, isNotNull);
      expect(dist1, equals(dist2));
      // Expected ~420-430 km
      expect(dist1!, greaterThan(410.0));
      expect(dist1, lessThan(440.0));
    });

    // 11. Pincode/district/taluk geographic relevance works when coordinates are missing
    test('11. Pincode/district/taluk geographic relevance works when coordinates are missing', () {
      final facNoCoords = Facility(
        id: 'fac-no-coords',
        name: 'Rural PHC without GPS',
        facilityType: FacilityType.primaryHealthCentre,
        providerCategory: ProviderCategory.government,
        location: const FacilityLocation(
          addressLine: 'Village Center',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
        emergencyCapability: EmergencyCapability.limitedEmergency,
        provenance: FacilityProvenance(
          verificationStatus: VerificationStatus.verified,
          dataSourceType: DataSourceType.verifiedRegistry,
          lastUpdated: testTimestamp,
        ),
      );

      const requestPinMatch = PatientCareRequest(
        urgency: TriageUrgency.routine,
        patientLocation: FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
      );
      const requestDistrictMatch = PatientCareRequest(
        urgency: TriageUrgency.routine,
        patientLocation: FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625020',
        ),
      );

      final resPin = engine.evaluateFacility(facility: facNoCoords, request: requestPinMatch);
      final resDist = engine.evaluateFacility(facility: facNoCoords, request: requestDistrictMatch);

      expect(resPin.distanceKm, isNull);
      expect(resPin.suitabilityScore, greaterThan(resDist.suitabilityScore));
      expect(resPin.matchReasons, anyElement(contains('625001')));
    });

    // 12. Unknown geography does not produce fake distance
    test('12. Unknown geography does not produce fake distance', () {
      final facNoCoords = Facility(
        id: 'fac-no-coords',
        name: 'Facility with no coordinates',
        facilityType: FacilityType.clinic,
        providerCategory: ProviderCategory.government,
        location: const FacilityLocation(
          addressLine: 'Unknown Street',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
        emergencyCapability: EmergencyCapability.limitedEmergency,
        provenance: FacilityProvenance(
          verificationStatus: VerificationStatus.verified,
          dataSourceType: DataSourceType.verifiedRegistry,
          lastUpdated: testTimestamp,
        ),
      );
      const requestNoCoords = PatientCareRequest(
        urgency: TriageUrgency.routine,
        patientLocation: FacilityLocation(
          addressLine: 'Patient House',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
      );

      final result = engine.evaluateFacility(facility: facNoCoords, request: requestNoCoords);
      expect(result.distanceKm, isNull);
    });

    // 13. Provenance is preserved in the match result
    test('13. Provenance is preserved in the match result', () {
      const request = PatientCareRequest(urgency: TriageUrgency.routine);
      final result = engine.evaluateFacility(facility: emergencyHospital, request: request);
      expect(result.isProvenanceVerified, isTrue);
      expect(result.matchReasons, anyElement(contains('Verified official health registry data')));
    });

    // 14. Synthetic/demo provenance remains distinguishable from official/verified data
    test('14. Synthetic/demo provenance remains distinguishable from official/verified data', () {
      final demoFac = demonstrationFacilities.first;
      expect(demoFac.provenance.isDemonstration, isTrue);

      const request = PatientCareRequest(urgency: TriageUrgency.routine);
      final result = engine.evaluateFacility(facility: demoFac, request: request);
      expect(result.isProvenanceVerified, isFalse);
    });

    // 15. "Why this facility?" reasons are generated only from actual evidence
    test('15. "Why this facility?" reasons are generated only from actual evidence', () {
      final request = PatientCareRequest(
        urgency: TriageUrgency.emergency,
        isEmergencyCareRequired: true,
        patientLocation: const FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
          latitude: 9.9200,
          longitude: 78.1200,
        ),
      );

      final result = engine.evaluateFacility(facility: emergencyHospital, request: request);
      for (final reason in result.matchReasons) {
        expect(reason, isNotEmpty);
        expect(reason.toLowerCase(), isNot(contains('best hospital')));
        expect(reason.toLowerCase(), isNot(contains('top ranked')));
      }
      expect(result.matchReasons, anyElement(contains('24/7 emergency')));
    });

    // 16. Clinically unsuitable facilities cannot outrank suitable ones through distance alone
    test('16. Clinically unsuitable facilities cannot outrank suitable ones through distance alone', () {
      final request = PatientCareRequest(
        urgency: TriageUrgency.emergency,
        isEmergencyCareRequired: true,
        patientLocation: const FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
          latitude: 9.9210,
          longitude: 78.1210, // 0 meters from clinicNoEmergency
        ),
      );

      final matches = engine.matchFacilities(
        request: request,
        facilities: [clinicNoEmergency, emergencyHospital],
      );

      // Only clinically suitable facilities are returned
      expect(matches.length, equals(1));
      expect(matches.first.facility.id, equals(emergencyHospital.id));
      expect(matches.first.isSuitable, isTrue);

      final clinicEval = engine.evaluateFacility(facility: clinicNoEmergency, request: request);
      expect(clinicEval.isSuitable, isFalse);
    });

    // 17. Stable deterministic ordering for equivalent matches
    test('17. Stable deterministic ordering for equivalent matches', () {
      final facA = Facility(
        id: 'fac-a',
        name: 'Alpha Clinic',
        facilityType: FacilityType.clinic,
        providerCategory: ProviderCategory.government,
        location: const FacilityLocation(
          addressLine: 'A Street',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
        emergencyCapability: EmergencyCapability.limitedEmergency,
        provenance: FacilityProvenance(
          verificationStatus: VerificationStatus.verified,
          dataSourceType: DataSourceType.verifiedRegistry,
          lastUpdated: testTimestamp,
        ),
      );
      final facB = Facility(
        id: 'fac-b',
        name: 'Beta Clinic',
        facilityType: FacilityType.clinic,
        providerCategory: ProviderCategory.government,
        location: const FacilityLocation(
          addressLine: 'B Street',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
        emergencyCapability: EmergencyCapability.limitedEmergency,
        provenance: FacilityProvenance(
          verificationStatus: VerificationStatus.verified,
          dataSourceType: DataSourceType.verifiedRegistry,
          lastUpdated: testTimestamp,
        ),
      );

      const request = PatientCareRequest(urgency: TriageUrgency.routine);
      final matches1 = engine.matchFacilities(request: request, facilities: [facB, facA]);
      final matches2 = engine.matchFacilities(request: request, facilities: [facA, facB]);

      expect(matches1.map((m) => m.facility.id).toList(), equals(['fac-a', 'fac-b']));
      expect(matches2.map((m) => m.facility.id).toList(), equals(['fac-a', 'fac-b']));
    });

    // 18. Empty facility dataset handled safely without errors
    test('18. Empty facility dataset handled safely without errors', () {
      const request = PatientCareRequest(urgency: TriageUrgency.emergency, isEmergencyCareRequired: true);
      final matches = engine.matchFacilities(request: request, facilities: []);
      expect(matches, isEmpty);
    });

    // 19. Multiple matching facilities returned correctly
    test('19. Multiple matching facilities returned correctly', () {
      const request = PatientCareRequest(urgency: TriageUrgency.routine);
      final matches = engine.matchFacilities(
        request: request,
        facilities: [emergencyHospital, primaryHealthCentre, clinicNoEmergency],
      );
      expect(matches.length, equals(3));
    });

    // 20. Original Facility model is not mutated by matching
    test('20. Original Facility model is not mutated by matching', () {
      final originalBedCount = emergencyHospital.capability.approxTotalBeds;
      final originalSpecialtiesCount = emergencyHospital.specialties.length;

      const request = PatientCareRequest(
        urgency: TriageUrgency.urgent,
        requiredSpecialtyId: 'cardiology',
      );
      engine.evaluateFacility(facility: emergencyHospital, request: request);

      expect(emergencyHospital.capability.approxTotalBeds, equals(originalBedCount));
      expect(emergencyHospital.specialties.length, equals(originalSpecialtiesCount));
    });

    // -------------------------------------------------------------------------
    // REAL DATASET TESTS (using data/raw/facilities/tamil_nadu_nhm_facilities.csv)
    // -------------------------------------------------------------------------
    group('Real NHM Facility Dataset Tests', () {
      final rawFile = File('data/raw/facilities/tamil_nadu_nhm_facilities.csv');
      final realFacilities = <Facility>[];

      setUpAll(() {
        expect(rawFile.existsSync(), isTrue, reason: 'Raw NHM facility file must exist');
        final lines = const LineSplitter().convert(rawFile.readAsStringSync());
        expect(lines.length, greaterThan(1));

        final headers = parseCsvLine(lines.first);
        for (var i = 1; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) continue;
          final cols = parseCsvLine(line);
          final rowMap = <String, String>{};
          for (var j = 0; j < headers.length && j < cols.length; j++) {
            rowMap[headers[j]] = cols[j];
          }
          realFacilities.add(normalizer.normalizeRecord(rowMap));
        }

        expect(realFacilities.length, equals(2398));
      });

      // 21. Real NHM dataset: Emergency request filters out facilities with unknown/no emergency
      test('21. Real NHM dataset: Emergency request filters out facilities without emergency capability', () {
        final request = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          patientLocation: const FacilityLocation(
            addressLine: 'Madurai Central',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252,
            longitude: 78.1198,
          ),
        );

        final matches = engine.matchFacilities(request: request, facilities: realFacilities, limit: 10);
        expect(matches, isNotEmpty);
        for (final match in matches) {
          if (match.isSuitable) {
            expect(match.isEmergencyCapable, isTrue);
            expect(
              [EmergencyCapability.emergencyAvailable, EmergencyCapability.fullEmergency],
              contains(match.facility.emergencyCapability),
            );
          }
        }
      });

      // 22. Real NHM dataset: Emergency request selects verified emergency facility (e.g. Balarengapuram GH)
      test('22. Real NHM dataset: Emergency request selects verified emergency facilities', () {
        final request = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          patientLocation: const FacilityLocation(
            addressLine: 'Madurai Central',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252,
            longitude: 78.1198,
          ),
        );

        final matches = engine.matchFacilities(request: request, facilities: realFacilities, limit: 5);
        final topSuitable = matches.where((m) => m.isSuitable).toList();
        expect(topSuitable, isNotEmpty);

        final first = topSuitable.first;
        expect(first.isEmergencyCapable, isTrue);
        expect(first.distanceKm, isNotNull);
        expect(first.distanceKm!, lessThan(10.0)); // In Madurai urban area
      });

      // 23. Real NHM dataset: Routine request correctly surfaces nearby clinics/PHCs
      test('23. Real NHM dataset: Routine request correctly surfaces nearby clinics and primary centres', () {
        final request = PatientCareRequest(
          urgency: TriageUrgency.routine,
          patientLocation: const FacilityLocation(
            addressLine: 'Madurai Central',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252,
            longitude: 78.1198,
          ),
        );

        final matches = engine.matchFacilities(request: request, facilities: realFacilities, limit: 10);
        expect(matches, isNotEmpty);
        expect(matches.first.isSuitable, isTrue);
        expect(
          [
            FacilityType.primaryHealthCentre,
            FacilityType.communityHealthCentre,
            FacilityType.clinic,
            FacilityType.hospital,
          ],
          contains(matches.first.facility.facilityType),
        );
      });

      // 24. Real NHM dataset: Proximity ranking for equal capabilities
      test('24. Real NHM dataset: Proximity ranking for equal capabilities', () {
        final request = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          patientLocation: const FacilityLocation(
            addressLine: 'Madurai Central',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252,
            longitude: 78.1198,
          ),
        );

        final matches = engine.matchFacilities(request: request, facilities: realFacilities, limit: 20);
        final suitable = matches.where((m) => m.isSuitable).toList();
        expect(suitable.length, greaterThanOrEqualTo(2));

        // When suitability score is identical, closer facility should rank ahead
        for (int i = 0; i < suitable.length - 1; i++) {
          if (suitable[i].suitabilityScore == suitable[i + 1].suitabilityScore) {
            if (suitable[i].distanceKm != null && suitable[i + 1].distanceKm != null) {
              expect(suitable[i].distanceKm!, lessThanOrEqualTo(suitable[i + 1].distanceKm!));
            }
          }
        }
      });
    });

    // 25. PatientCareRequest.fromTriage correctly maps TriageResult to care requirements
    test('25. PatientCareRequest.fromTriage correctly maps TriageResult to care requirements', () {
      final emergencyTriage = TriageResult(
        sourceSessionId: 'sess-001',
        urgency: TriageUrgency.emergency,
        state: TriageDispositionState.emergency,
        title: 'Emergency Care Required',
        explanation: 'Severe crushing chest pain with breathing difficulty',
        needsFollowUp: false,
        requiresHumanReview: true,
        triggeredRuleIds: const ['chest_pain_or_pressure'],
        completedAt: testTimestamp,
      );

      final reqEmergency = PatientCareRequest.fromTriage(
        triageResult: emergencyTriage,
        patientLocation: const FacilityLocation(
          addressLine: 'Patient Home',
          city: 'Madurai',
          district: 'Madurai',
          state: 'Tamil Nadu',
          pincode: '625001',
        ),
      );
      expect(reqEmergency.urgency, equals(TriageUrgency.emergency));
      expect(reqEmergency.isEmergencyCareRequired, isTrue);
      expect(reqEmergency.patientLocation?.district, equals('Madurai'));

      final routineTriage = TriageResult(
        sourceSessionId: 'sess-002',
        urgency: TriageUrgency.routine,
        state: TriageDispositionState.assessed,
        title: 'Routine Care Recommended',
        explanation: 'Mild cold symptoms for 2 days',
        needsFollowUp: false,
        requiresHumanReview: false,
        triggeredRuleIds: const [],
        completedAt: testTimestamp,
      );

      final reqRoutine = PatientCareRequest.fromTriage(triageResult: routineTriage);
      expect(reqRoutine.urgency, equals(TriageUrgency.routine));
      expect(reqRoutine.isEmergencyCareRequired, isFalse);
    });

    // -------------------------------------------------------------------------
    // FOCUSED SAFETY LOGIC REGRESSION TESTS (Section 25 Review Items)
    // -------------------------------------------------------------------------
    group('Focused Safety Logic Regression Tests', () {
      // 26. Unknown emergency capability is not converted to noEmergency
      test('26. Unknown emergency capability is not converted to noEmergency', () {
        const emergencyReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
        );

        final unknownResult = engine.evaluateFacility(facility: clinicUnknownEmergency, request: emergencyReq);
        final noEmergencyResult = engine.evaluateFacility(facility: clinicNoEmergency, request: emergencyReq);

        expect(unknownResult.isSuitable, isFalse);
        expect(noEmergencyResult.isSuitable, isFalse);

        // Invariant check: UNKNOWN != NO
        expect(clinicUnknownEmergency.emergencyCapability, equals(EmergencyCapability.unknown));
        expect(clinicNoEmergency.emergencyCapability, equals(EmergencyCapability.noEmergency));
        expect(clinicUnknownEmergency.emergencyCapability, isNot(equals(clinicNoEmergency.emergencyCapability)));

        // Reasons clearly distinguish unverified/insufficient evidence from explicit negative capability
        expect(unknownResult.exclusionReason, contains('unknown / unverified (insufficient evidence'));
        expect(noEmergencyResult.exclusionReason, contains('confirmed to have no emergency care capability'));
        expect(unknownResult.exclusionReason, isNot(equals(noEmergencyResult.exclusionReason)));
      });

      // 27. Unknown emergency capability is not presented as confirmed emergency capability
      test('27. Unknown emergency capability is not presented as confirmed emergency capability', () {
        const emergencyReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
        );

        final result = engine.evaluateFacility(facility: clinicUnknownEmergency, request: emergencyReq);
        expect(result.isEmergencyCapable, isFalse);
        expect(result.isSuitable, isFalse);
        expect(result.matchReasons, isEmpty);
      });

      // 28. Unknown emergency capability cannot receive the same emergency suitability score as confirmed emergency capability
      test('28. Unknown emergency capability cannot receive the same emergency suitability score as confirmed emergency capability', () {
        const emergencyReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
        );

        final confirmedResult = engine.evaluateFacility(facility: emergencyHospital, request: emergencyReq);
        final unknownResult = engine.evaluateFacility(facility: clinicUnknownEmergency, request: emergencyReq);

        expect(confirmedResult.isSuitable, isTrue);
        expect(confirmedResult.isEmergencyCapable, isTrue);
        expect(confirmedResult.suitabilityScore, greaterThanOrEqualTo(50.0));

        expect(unknownResult.isSuitable, isFalse);
        expect(unknownResult.suitabilityScore, equals(0.0));
      });

      // 29. Explicit noEmergency is excluded
      test('29. Explicit noEmergency is excluded', () {
        const emergencyReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
        );

        final result = engine.evaluateFacility(facility: clinicNoEmergency, request: emergencyReq);
        expect(result.isSuitable, isFalse);
        expect(result.exclusionReason, contains('no emergency care capability'));
      });

      // 30. Full emergency outranks limited emergency for generic emergency need
      test('30. Full emergency outranks limited emergency for generic emergency need', () {
        const genericEmergencyReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
        );

        final fullResult = engine.evaluateFacility(facility: emergencyHospital, request: genericEmergencyReq);
        final limitedResult = engine.evaluateFacility(facility: primaryHealthCentre, request: genericEmergencyReq);

        expect(fullResult.isSuitable, isTrue);
        expect(fullResult.isEmergencyCapable, isTrue);
        expect(fullResult.suitabilityScore, greaterThan(0.0));

        // For generic emergency need without allowsLimitedEmergency, limited is excluded from full emergency care
        expect(limitedResult.isSuitable, isFalse);
        expect(limitedResult.exclusionReason, contains('limited emergency stabilization'));
      });

      // 31. Limited emergency is only considered suitable when structured care requirement permits it
      test('31. Limited emergency is only considered suitable when structured care requirement permits it', () {
        const genericReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          allowsLimitedEmergency: false,
        );
        const permittedReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          allowsLimitedEmergency: true,
        );

        final rejected = engine.evaluateFacility(facility: primaryHealthCentre, request: genericReq);
        final accepted = engine.evaluateFacility(facility: primaryHealthCentre, request: permittedReq);

        expect(rejected.isSuitable, isFalse);
        expect(accepted.isSuitable, isTrue);
        expect(accepted.isEmergencyCapable, isTrue);
        expect(accepted.matchReasons, anyElement(contains('Limited emergency stabilization available')));
      });

      // 32. Distance cannot cause an unknown/clinically unsuitable facility to outrank a confirmed clinically suitable one
      test('32. Distance cannot cause an unknown/clinically unsuitable facility to outrank a confirmed clinically suitable one', () {
        // Patient is literally at the door of clinicUnknownEmergency (distance ~ 0 km)
        // and 20 km away from emergencyHospital
        final distantHospital = Facility(
          id: 'fac-gh-distant',
          name: 'Regional Trauma Centre',
          facilityType: FacilityType.hospital,
          providerCategory: ProviderCategory.government,
          location: const FacilityLocation(
            addressLine: 'Trauma Wing',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625020',
            latitude: 10.1000,
            longitude: 78.3000, // ~25 km away
          ),
          emergencyCapability: EmergencyCapability.fullEmergency,
          capability: const FacilityCapability(inpatientAvailable: true, icuAvailable: true),
          provenance: FacilityProvenance(
            verificationStatus: VerificationStatus.verified,
            dataSourceType: DataSourceType.verifiedRegistry,
            lastUpdated: testTimestamp,
          ),
        );

        final patientReq = PatientCareRequest(
          urgency: TriageUrgency.emergency,
          isEmergencyCareRequired: true,
          patientLocation: const FacilityLocation(
            addressLine: 'Patient Home',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9205, // Identical to clinicUnknownEmergency
            longitude: 78.1205,
          ),
        );

        final matches = engine.matchFacilities(
          request: patientReq,
          facilities: [clinicUnknownEmergency, clinicNoEmergency, distantHospital],
        );

        expect(matches.length, equals(1));
        expect(matches.first.facility.id, equals(distantHospital.id));
        expect(matches.first.isSuitable, isTrue);

        final unknownEval = engine.evaluateFacility(facility: clinicUnknownEmergency, request: patientReq);
        expect(unknownEval.isSuitable, isFalse);
      });
    });
  });
}
