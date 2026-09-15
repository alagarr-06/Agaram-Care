// Task 08 - Agaram Care Facility Data Foundation Tests.
//
// Comprehensive tests verifying the domain/data foundation for healthcare facilities:
// 1. Facility creation & field integrity.
// 2. Facility JSON serialization/deserialization round-trip.
// 3. Enum round-trips (FacilityType, ProviderCategory, EmergencyCapability, VerificationStatus, DataSourceType).
// 4. Null/unknown operational values preservation.
// 5. Critical invariant: UNKNOWN != NO (null vs false for ICU, inpatient, teleconsult, etc.).
// 6. Government / private / mixed / nonprofit classification.
// 7. Emergency capability representation & hasAnyEmergency helper.
// 8. Specialty and Service structured serialization & hasSpecialty/hasService lookup.
// 9. Location with coordinates vs un-geocoded location (nullable lat/long).
// 10. Provenance & verification fields (sourceName, verifiedAt, isDemonstration).
// 11. lastUpdated required timestamp serialization & FormatException on invalid.
// 12. Demonstration dataset validity (all 8 facilities valid and complete).
// 13. Demonstration records are explicitly labeled with demonstration provenance.
// 14. Invalid/missing required ID or name throws ArgumentError.
// 15. Forward compatibility: Unrecognized enum values fall back safely to fallback/unknown.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/facilities/domain/facilities.dart';

final _testDate = DateTime.utc(2026, 9, 14, 12, 0, 0);

Facility _createSampleFacility({
  String id = 'fac-sample-01',
  String name = 'Sample Government Hospital',
  String? nameTa = 'மாதிரி அரசு மருத்துவமனை',
  String? nameHi = 'नमूना सरकारी अस्पताल',
  FacilityType facilityType = FacilityType.hospital,
  ProviderCategory providerCategory = ProviderCategory.government,
  EmergencyCapability emergencyCapability = EmergencyCapability.fullEmergency,
  FacilityLocation? location,
  FacilityCapability? capability,
  FacilityAffordability? affordability,
  FacilityProvenance? provenance,
  List<FacilitySpecialty> specialties = const [],
  List<FacilityService> services = const [],
  String? operatingHours = '24/7',
  String? contactPhone = '+91 44 28000000',
  String? emergencyPhone = '+91 44 28000108',
  String? website = 'https://sample.health.gov.in',
  bool isActive = true,
}) {
  return Facility(
    id: id,
    name: name,
    nameTa: nameTa,
    nameHi: nameHi,
    facilityType: facilityType,
    providerCategory: providerCategory,
    emergencyCapability: emergencyCapability,
    location: location ??
        const FacilityLocation(
          addressLine: '100 EVR Periyar Salai',
          area: 'Park Town',
          city: 'Chennai',
          district: 'Chennai',
          state: 'Tamil Nadu',
          pincode: '600003',
          latitude: 13.0827,
          longitude: 80.2707,
        ),
    capability: capability ??
        const FacilityCapability(
          inpatientAvailable: true,
          icuAvailable: true,
          teleconsultAvailable: true,
          pharmacyAvailable: true,
          bloodBankAvailable: true,
          ambulanceAvailable: true,
          burnUnitAvailable: true,
          neonatalIcuAvailable: true,
          ventilatorAvailable: true,
          approxTotalBeds: 500,
        ),
    affordability: affordability ??
        const FacilityAffordability(
          acceptsGovernmentSchemes: true,
          supportedSchemes: ['CMCHIS', 'AB-PMJAY'],
          isFreeCareAvailable: true,
          consultationFeeEstimate: 'Free',
          pricingTier: 'government_free',
          insuranceNotes: '100% public welfare cover',
        ),
    provenance: provenance ??
        FacilityProvenance(
          verificationStatus: VerificationStatus.official,
          dataSourceType: DataSourceType.official,
          sourceName: 'Tamil Nadu Health Registry',
          sourceRegistryId: 'ROHINI-TN-001',
          verifiedAt: _testDate,
          lastUpdated: _testDate,
          verificationNotes: 'Officially verified from state registry',
        ),
    specialties: specialties.isNotEmpty
        ? specialties
        : const [
            FacilitySpecialty(
              id: 'cardiology',
              name: 'Cardiology',
              nameTa: 'இதயவியல்',
              nameHi: 'कार्डियोलॉजी',
            ),
            FacilitySpecialty(
              id: 'emergency_medicine',
              name: 'Emergency Medicine',
              nameTa: 'அவசர சிகிச்சை மருத்துவம்',
            ),
          ],
    services: services.isNotEmpty
        ? services
        : const [
            FacilityService(
              id: 'ct_scan',
              name: 'CT Scan',
              nameTa: 'சிடி ஸ்கேன்',
              is24x7: true,
            ),
            FacilityService(
              id: 'blood_bank',
              name: 'Blood Bank',
              is24x7: true,
            ),
          ],
    operatingHours: operatingHours,
    contactPhone: contactPhone,
    emergencyPhone: emergencyPhone,
    website: website,
    isActive: isActive,
  );
}

void main() {
  group('Task 08 - Facility Domain Foundation Tests', () {
    // 1. Facility creation & field integrity
    test('1. Facility creation preserves all fields and immutability', () {
      final fac = _createSampleFacility();

      expect(fac.id, equals('fac-sample-01'));
      expect(fac.name, equals('Sample Government Hospital'));
      expect(fac.nameTa, equals('மாதிரி அரசு மருத்துவமனை'));
      expect(fac.nameHi, equals('नमूना सरकारी अस्पताल'));
      expect(fac.facilityType, equals(FacilityType.hospital));
      expect(fac.providerCategory, equals(ProviderCategory.government));
      expect(fac.emergencyCapability, equals(EmergencyCapability.fullEmergency));
      expect(fac.location.city, equals('Chennai'));
      expect(fac.capability.approxTotalBeds, equals(500));
      expect(fac.affordability.supportedSchemes, contains('CMCHIS'));
      expect(fac.specialties.length, equals(2));
      expect(fac.services.length, equals(2));
      expect(fac.isActive, isTrue);

      // Verify immutability
      expect(() => (fac.specialties as dynamic).add(
        const FacilitySpecialty(id: 'neurology', name: 'Neurology'),
      ), throwsUnsupportedError);
      expect(() => (fac.services as dynamic).add(
        const FacilityService(id: 'mri', name: 'MRI'),
      ), throwsUnsupportedError);
    });

    // 2. Facility JSON serialization/deserialization round-trip
    test('2. Facility JSON serialization and deserialization is lossless', () {
      final fac = _createSampleFacility();
      final json = fac.toJson();
      final restored = Facility.fromJson(json);

      expect(restored.id, equals(fac.id));
      expect(restored.name, equals(fac.name));
      expect(restored.nameTa, equals(fac.nameTa));
      expect(restored.nameHi, equals(fac.nameHi));
      expect(restored.facilityType, equals(fac.facilityType));
      expect(restored.providerCategory, equals(fac.providerCategory));
      expect(restored.emergencyCapability, equals(fac.emergencyCapability));
      expect(restored.location.addressLine, equals(fac.location.addressLine));
      expect(restored.location.latitude, equals(fac.location.latitude));
      expect(restored.location.longitude, equals(fac.location.longitude));
      expect(restored.capability.icuAvailable, equals(fac.capability.icuAvailable));
      expect(restored.affordability.acceptsGovernmentSchemes, equals(fac.affordability.acceptsGovernmentSchemes));
      expect(restored.affordability.supportedSchemes, equals(fac.affordability.supportedSchemes));
      expect(restored.provenance.verificationStatus, equals(fac.provenance.verificationStatus));
      expect(restored.provenance.lastUpdated, equals(fac.provenance.lastUpdated));
      expect(restored.specialties.first.id, equals('cardiology'));
      expect(restored.services.first.id, equals('ct_scan'));
      expect(restored.services.first.is24x7, isTrue);
      expect(restored.operatingHours, equals(fac.operatingHours));
      expect(restored.contactPhone, equals(fac.contactPhone));
      expect(restored.emergencyPhone, equals(fac.emergencyPhone));
      expect(restored.website, equals(fac.website));
      expect(restored.isActive, equals(fac.isActive));
    });

    // 3. Enum round-trips
    test('3. Enums serialize to stable string names and deserialize accurately', () {
      // FacilityType
      for (final type in FacilityType.values) {
        expect(FacilityType.fromJson(type.toJson()), equals(type));
      }

      // ProviderCategory
      for (final cat in ProviderCategory.values) {
        expect(ProviderCategory.fromJson(cat.toJson()), equals(cat));
      }

      // EmergencyCapability
      for (final cap in EmergencyCapability.values) {
        expect(EmergencyCapability.fromJson(cap.toJson()), equals(cap));
      }

      // VerificationStatus
      for (final status in VerificationStatus.values) {
        expect(VerificationStatus.fromJson(status.toJson()), equals(status));
      }

      // DataSourceType
      for (final src in DataSourceType.values) {
        expect(DataSourceType.fromJson(src.toJson()), equals(src));
      }
    });

    // 4. Null/unknown operational values preservation
    test('4. Null operational values remain null and are not fabricated', () {
      const cap = FacilityCapability();

      expect(cap.inpatientAvailable, isNull);
      expect(cap.icuAvailable, isNull);
      expect(cap.teleconsultAvailable, isNull);
      expect(cap.pharmacyAvailable, isNull);
      expect(cap.bloodBankAvailable, isNull);
      expect(cap.ambulanceAvailable, isNull);
      expect(cap.burnUnitAvailable, isNull);
      expect(cap.neonatalIcuAvailable, isNull);
      expect(cap.ventilatorAvailable, isNull);
      expect(cap.approxTotalBeds, isNull);

      final json = cap.toJson();
      expect(json.isEmpty, isTrue);

      final restored = FacilityCapability.fromJson(json);
      expect(restored.inpatientAvailable, isNull);
      expect(restored.icuAvailable, isNull);
    });

    // 5. UNKNOWN != NO
    test('5. UNKNOWN != NO: explicit false is distinguishable from null/unknown', () {
      const capUnknown = FacilityCapability(
        inpatientAvailable: null,
        icuAvailable: null,
      );
      const capExplicitNo = FacilityCapability(
        inpatientAvailable: false,
        icuAvailable: false,
      );
      const capExplicitYes = FacilityCapability(
        inpatientAvailable: true,
        icuAvailable: true,
      );

      // Unknown is not false
      expect(capUnknown.inpatientAvailable == false, isFalse);
      expect(capUnknown.icuAvailable == false, isFalse);

      // Explicit No is false
      expect(capExplicitNo.inpatientAvailable, isFalse);
      expect(capExplicitNo.icuAvailable, isFalse);

      // Explicit Yes is true
      expect(capExplicitYes.inpatientAvailable, isTrue);
      expect(capExplicitYes.icuAvailable, isTrue);

      // Serialized representation preserves explicit false
      final noJson = capExplicitNo.toJson();
      expect(noJson['inpatientAvailable'], isFalse);
      expect(noJson['icuAvailable'], isFalse);

      final restoredNo = FacilityCapability.fromJson(noJson);
      expect(restoredNo.inpatientAvailable, isFalse);
      expect(restoredNo.icuAvailable, isFalse);
    });

    // 6. Provider category classification
    test('6. Government, private, nonprofit, and mixed classifications are supported', () {
      final govt = _createSampleFacility(providerCategory: ProviderCategory.government);
      final pvt = _createSampleFacility(providerCategory: ProviderCategory.private);
      final nonp = _createSampleFacility(providerCategory: ProviderCategory.nonprofit);
      final mixed = _createSampleFacility(providerCategory: ProviderCategory.mixed);
      final unk = _createSampleFacility(providerCategory: ProviderCategory.unknown);

      expect(govt.providerCategory, equals(ProviderCategory.government));
      expect(pvt.providerCategory, equals(ProviderCategory.private));
      expect(nonp.providerCategory, equals(ProviderCategory.nonprofit));
      expect(mixed.providerCategory, equals(ProviderCategory.mixed));
      expect(unk.providerCategory, equals(ProviderCategory.unknown));
    });

    // 7. Emergency capability representation & hasAnyEmergency helper
    test('7. Emergency capabilities and hasAnyEmergency evaluate correctly', () {
      final fullEmerg = _createSampleFacility(emergencyCapability: EmergencyCapability.fullEmergency);
      final availEmerg = _createSampleFacility(emergencyCapability: EmergencyCapability.emergencyAvailable);
      final limEmerg = _createSampleFacility(emergencyCapability: EmergencyCapability.limitedEmergency);
      final noEmerg = _createSampleFacility(emergencyCapability: EmergencyCapability.noEmergency);
      final unkEmerg = _createSampleFacility(emergencyCapability: EmergencyCapability.unknown);

      expect(fullEmerg.hasAnyEmergency, isTrue);
      expect(availEmerg.hasAnyEmergency, isTrue);
      expect(limEmerg.hasAnyEmergency, isFalse);
      expect(noEmerg.hasAnyEmergency, isFalse);
      expect(unkEmerg.hasAnyEmergency, isFalse);
    });

    // 8. Specialty & Service structured representation & lookups
    test('8. Structured specialties and services support exact ID lookup and localization', () {
      final fac = _createSampleFacility(
        specialties: const [
          FacilitySpecialty(
            id: 'cardiology',
            name: 'Cardiology',
            nameTa: 'இதயவியல்',
            nameHi: 'हृदय रोग',
            description: 'Advanced cardiac care unit',
          ),
          FacilitySpecialty(
            id: 'pediatrics',
            name: 'Pediatrics',
            nameTa: 'குழந்தைகள் நலம்',
          ),
        ],
        services: const [
          FacilityService(
            id: 'blood_bank',
            name: 'Blood Bank',
            nameTa: 'இரத்த வங்கி',
            category: 'laboratory',
            is24x7: true,
          ),
          FacilityService(
            id: 'ecg',
            name: 'Electrocardiogram',
            is24x7: false,
          ),
        ],
      );

      // Case-insensitive ID lookup
      expect(fac.hasSpecialty('cardiology'), isTrue);
      expect(fac.hasSpecialty('Cardiology'), isTrue);
      expect(fac.hasSpecialty('CARDIOLOGY'), isTrue);
      expect(fac.hasSpecialty('pediatrics'), isTrue);
      expect(fac.hasSpecialty('neurology'), isFalse);

      expect(fac.hasService('blood_bank'), isTrue);
      expect(fac.hasService('Blood_Bank'), isTrue);
      expect(fac.hasService('ecg'), isTrue);
      expect(fac.hasService('mri_scan'), isFalse);

      // Localization and attributes
      expect(fac.specialties.first.nameTa, equals('இதயவியல்'));
      expect(fac.specialties.first.description, equals('Advanced cardiac care unit'));
      expect(fac.services.first.is24x7, isTrue);
      expect(fac.services[1].is24x7, isFalse);
    });

    // 9. Location with coordinates vs un-geocoded location
    test('9. Location correctly handles nullable coordinates and hasCoordinates flag', () {
      const locWithCoords = FacilityLocation(
        addressLine: '1 Main Rd',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625001',
        latitude: 9.9252,
        longitude: 78.1198,
      );

      const locNoCoords = FacilityLocation(
        addressLine: 'Village Sub-centre',
        city: 'Usilampatti',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625532',
        latitude: null,
        longitude: null,
      );

      expect(locWithCoords.hasCoordinates, isTrue);
      expect(locNoCoords.hasCoordinates, isFalse);

      // JSON roundtrip
      final jsonWith = locWithCoords.toJson();
      expect(jsonWith['latitude'], equals(9.9252));
      expect(jsonWith['longitude'], equals(78.1198));

      final jsonNo = locNoCoords.toJson();
      expect(jsonNo.containsKey('latitude'), isFalse);
      expect(jsonNo.containsKey('longitude'), isFalse);

      final restoredWith = FacilityLocation.fromJson(jsonWith);
      expect(restoredWith.hasCoordinates, isTrue);
      expect(restoredWith.latitude, equals(9.9252));

      final restoredNo = FacilityLocation.fromJson(jsonNo);
      expect(restoredNo.hasCoordinates, isFalse);
      expect(restoredNo.latitude, isNull);
    });

    // 10. Provenance & verification fields
    test('10. Provenance correctly captures trust attributes and isDemonstration flag', () {
      final officialProv = FacilityProvenance(
        verificationStatus: VerificationStatus.official,
        dataSourceType: DataSourceType.official,
        sourceName: 'TN Govt Health Portal',
        sourceRegistryId: 'NIN-100293',
        verifiedAt: _testDate,
        lastUpdated: _testDate,
      );

      final demoProv = FacilityProvenance(
        verificationStatus: VerificationStatus.demonstration,
        dataSourceType: DataSourceType.demonstration,
        sourceName: 'Agaram Care Demo Generator',
        lastUpdated: _testDate,
      );

      expect(officialProv.isDemonstration, isFalse);
      expect(demoProv.isDemonstration, isTrue);

      final json = officialProv.toJson();
      expect(json['sourceRegistryId'], equals('NIN-100293'));
      expect(json['verifiedAt'], equals(_testDate.toIso8601String()));

      final restored = FacilityProvenance.fromJson(json);
      expect(restored.verificationStatus, equals(VerificationStatus.official));
      expect(restored.verifiedAt, equals(_testDate));
      expect(restored.isDemonstration, isFalse);
    });

    // 11. lastUpdated required timestamp serialization & FormatException on invalid
    test('11. Provenance lastUpdated requires valid ISO-8601 and rejects invalid timestamps', () {
      // Valid timestamp parses correctly
      final validJson = {
        'verificationStatus': 'official',
        'dataSourceType': 'official',
        'lastUpdated': '2026-09-14T12:00:00.000Z',
      };
      final prov = FacilityProvenance.fromJson(validJson);
      expect(prov.lastUpdated.year, equals(2026));

      // Missing or corrupt lastUpdated throws FormatException
      final corruptJson = {
        'verificationStatus': 'official',
        'dataSourceType': 'official',
        'lastUpdated': 'not-a-timestamp',
      };
      expect(() => FacilityProvenance.fromJson(corruptJson), throwsFormatException);

      final missingJson = {
        'verificationStatus': 'official',
        'dataSourceType': 'official',
      };
      expect(() => FacilityProvenance.fromJson(missingJson), throwsFormatException);
    });

    // 12. Demonstration dataset validity
    test('12. Demonstration dataset contains exactly 8 diverse facilities with valid structures', () {
      expect(demonstrationFacilities.length, equals(8));

      for (final fac in demonstrationFacilities) {
        expect(fac.id.trim(), isNotEmpty);
        expect(fac.name.trim(), isNotEmpty);
        expect(fac.location.city.trim(), isNotEmpty);
        expect(fac.location.district.trim(), isNotEmpty);
        expect(fac.location.state, equals('Tamil Nadu'));
        expect(fac.provenance.lastUpdated, isNotNull);

        // Ensure JSON serialization of each demo record works without throwing
        final json = fac.toJson();
        expect(json['id'], equals(fac.id));
        final restored = Facility.fromJson(json);
        expect(restored.id, equals(fac.id));
        expect(restored.name, equals(fac.name));
      }
    });

    // 13. Demonstration records are explicitly labeled demonstration
    test('13. ALL demonstration facilities are explicitly marked with demonstration provenance', () {
      for (final fac in demonstrationFacilities) {
        expect(
          fac.provenance.verificationStatus,
          equals(VerificationStatus.demonstration),
          reason: '${fac.id} must have verificationStatus = demonstration',
        );
        expect(
          fac.provenance.dataSourceType,
          equals(DataSourceType.demonstration),
          reason: '${fac.id} must have dataSourceType = demonstration',
        );
        expect(
          fac.provenance.isDemonstration,
          isTrue,
          reason: '${fac.id} must report isDemonstration = true',
        );
      }
    });

    // 14. Invalid/missing required ID or name throws ArgumentError
    test('14. Missing or whitespace ID or name throws ArgumentError', () {
      expect(() => _createSampleFacility(id: ''), throwsArgumentError);
      expect(() => _createSampleFacility(id: '   '), throwsArgumentError);
      expect(() => _createSampleFacility(name: ''), throwsArgumentError);
      expect(() => _createSampleFacility(name: '   '), throwsArgumentError);

      // Missing in JSON
      final invalidJson = _createSampleFacility().toJson();
      invalidJson['id'] = '';
      expect(() => Facility.fromJson(invalidJson), throwsArgumentError);

      invalidJson['id'] = 'valid-id';
      invalidJson['name'] = '   ';
      expect(() => Facility.fromJson(invalidJson), throwsArgumentError);
    });

    // 15. Forward compatibility: Unrecognized enum values fall back safely
    test('15. Unrecognized enum strings gracefully fall back to safe unknown/other defaults', () {
      expect(FacilityType.fromJson('super_specialty_future_type'), equals(FacilityType.other));
      expect(FacilityType.fromJson(null), equals(FacilityType.other));

      expect(ProviderCategory.fromJson('cooperative_society'), equals(ProviderCategory.unknown));
      expect(ProviderCategory.fromJson(null), equals(ProviderCategory.unknown));

      expect(EmergencyCapability.fromJson('level_4_future'), equals(EmergencyCapability.unknown));
      expect(EmergencyCapability.fromJson(null), equals(EmergencyCapability.unknown));

      expect(VerificationStatus.fromJson('community_crowdsourced'), equals(VerificationStatus.unknown));
      expect(VerificationStatus.fromJson(null), equals(VerificationStatus.unknown));

      expect(DataSourceType.fromJson('ai_web_crawler'), equals(DataSourceType.unknown));
      expect(DataSourceType.fromJson(null), equals(DataSourceType.unknown));

      // Deserializing a facility with an unknown future provider category
      final json = _createSampleFacility().toJson();
      json['facilityType'] = 'unknown_future_drone_clinic';
      json['providerCategory'] = 'futuristic_telecom_provider';
      json['emergencyCapability'] = 'unclassified_level';

      final restored = Facility.fromJson(json);
      expect(restored.facilityType, equals(FacilityType.other));
      expect(restored.providerCategory, equals(ProviderCategory.unknown));
      expect(restored.emergencyCapability, equals(EmergencyCapability.unknown));
    });
  });
}
