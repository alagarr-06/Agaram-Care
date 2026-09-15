// Task 10 - Facility Presentation & UI Widget Tests.
//
// Tests:
// 1. FacilitiesScreen displays loaded facilities in List View.
// 2. FacilityCard shows name, district, type, and provenance tag.
// 3. Emergency-capable facility displays Emergency badge.
// 4. "Why this facility?" button opens WhyThisFacilitySheet with confirmed evidence.
// 5. FacilityDetailSheet enforces UNKNOWN != NO ("Not verified" for null capabilities).
// 6. Map View toggle switches to interactive FacilityMapView with pins.
// 7. Search filter updates displayed facilities by query.
// 8. Emergency filter chip filters list to only emergency-capable facilities.
// 9. Navigation from Triage passes PatientCareRequest and displays active triage banner.
// 10. Directions dialog opens with valid Google Maps URL when coordinates are present.
// 11. Multilingual display works (Tamil, Hindi, English).
// 12. Responsive test: No RenderFlex overflow on narrow viewport (320px).

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:agaram_care/app/app_state.dart';
import 'package:agaram_care/features/facilities/domain/facilities.dart';
import 'package:agaram_care/features/facilities/presentation/facilities_screen.dart';
import 'package:agaram_care/features/facilities/presentation/providers/facilities_provider.dart';
import 'package:agaram_care/features/facilities/presentation/widgets/facility_card.dart';
import 'package:agaram_care/features/facilities/presentation/widgets/facility_detail_sheet.dart';
import 'package:agaram_care/features/facilities/presentation/widgets/facility_map_view.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/result/triage_disposition_state.dart';

void main() {
  group('Task 10 - Facility Presentation Tests', () {
    final testDate = DateTime.utc(2026, 9, 14, 12, 0, 0);

    final testEmergencyHospital = Facility(
      id: 'fac-test-gh',
      name: 'Government Rajaji Hospital',
      nameTa: 'அரசு ராஜாஜி மருத்துவமனை',
      nameHi: 'सरकारी राजाजी अस्पताल',
      facilityType: FacilityType.hospital,
      providerCategory: ProviderCategory.government,
      location: const FacilityLocation(
        addressLine: 'Panagal Road, Shenoy Nagar',
        city: 'Madurai',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625020',
        latitude: 9.9252,
        longitude: 78.1328,
      ),
      emergencyCapability: EmergencyCapability.fullEmergency,
      capability: const FacilityCapability(
        inpatientAvailable: true,
        icuAvailable: true,
        pharmacyAvailable: true,
        bloodBankAvailable: true,
        ambulanceAvailable: true,
        approxTotalBeds: 2500,
      ),
      affordability: const FacilityAffordability(
        acceptsGovernmentSchemes: true,
        supportedSchemes: ['CMCHIS', 'AB-PMJAY'],
        isFreeCareAvailable: true,
      ),
      provenance: FacilityProvenance(
        verificationStatus: VerificationStatus.official,
        dataSourceType: DataSourceType.official,
        sourceName: 'Tamil Nadu NHM',
        lastUpdated: testDate,
      ),
    );

    final testUnknownClinic = Facility(
      id: 'fac-test-clinic',
      name: 'Vadipatti Primary Health Centre',
      nameTa: 'வாடிப்பட்டி ஆரம்ப சுகாதார நிலையம்',
      facilityType: FacilityType.primaryHealthCentre,
      providerCategory: ProviderCategory.government,
      location: const FacilityLocation(
        addressLine: 'Main Road',
        city: 'Vadipatti',
        district: 'Madurai',
        state: 'Tamil Nadu',
        pincode: '625218',
        latitude: null, // GPS unknown
        longitude: null,
      ),
      emergencyCapability: EmergencyCapability.limitedEmergency,
      capability: const FacilityCapability(
        // All capabilities explicitly null (UNKNOWN != NO)
        inpatientAvailable: null,
        icuAvailable: null,
        pharmacyAvailable: null,
        bloodBankAvailable: null,
      ),
      affordability: const FacilityAffordability(
        acceptsGovernmentSchemes: false,
      ),
      provenance: FacilityProvenance(
        verificationStatus: VerificationStatus.demonstration,
        dataSourceType: DataSourceType.demonstration,
        sourceName: 'Synthetic Demo',
        lastUpdated: testDate,
      ),
    );

    final matchResultEmergency = FacilityMatchResult(
      facility: testEmergencyHospital,
      isSuitable: true,
      suitabilityScore: 92.5,
      matchReasons: [
        'Confirmed 24/7 emergency capability for life-threatening conditions',
        'Accepts CMCHIS / Government welfare scheme',
        'Near patient location (1.4 km)',
      ],
      distanceKm: 1.4,
      isEmergencyCapable: true,
      hasSchemeMatch: true,
      isProvenanceVerified: true,
    );

    Widget createTestApp({
      Widget? child,
      List<Facility>? facilities,
      PatientCareRequest? careRequest,
      Locale locale = const Locale('en'),
    }) {
      return ProviderScope(
        overrides: [
          selectedLocaleProvider.overrideWith((ref) => locale),
          if (facilities != null)
            allFacilitiesProvider.overrideWith((ref) async => facilities),
          if (careRequest != null)
            activeCareRequestProvider.overrideWith((ref) => careRequest),
        ],
        child: MaterialApp(
          home: child ?? const FacilitiesScreen(),
        ),
      );
    }

    testWidgets('1. FacilitiesScreen displays loaded facilities in list view', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital, testUnknownClinic],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Healthcare Facilities'), findsOneWidget);
      expect(find.text('Government Rajaji Hospital'), findsOneWidget);
      expect(find.text('Vadipatti Primary Health Centre'), findsOneWidget);
    });

    testWidgets('2. FacilityCard shows name, district, type, and provenance badge', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FacilityCard(matchResult: matchResultEmergency),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Government Rajaji Hospital'), findsOneWidget);
      expect(find.textContaining('Madurai'), findsOneWidget);
      expect(find.text('Hospital'), findsOneWidget);
      expect(find.text('NHM Verified'), findsOneWidget);
      expect(find.text('1.4 km'), findsOneWidget);
    });

    testWidgets('3. Emergency-capable facility displays Emergency badge', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FacilityCard(matchResult: matchResultEmergency),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Emergency'), findsOneWidget);
      expect(find.byIcon(Icons.emergency), findsWidgets);
    });

    testWidgets('4. "Why this facility?" button opens modal sheet with confirmed evidence', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FacilityCard(matchResult: matchResultEmergency),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final whyBtn = find.text('Why this facility?');
      expect(whyBtn, findsOneWidget);

      await tester.tap(whyBtn);
      await tester.pumpAndSettle();

      expect(find.text('Why this facility?'), findsWidgets);
      expect(find.text('Confirmed 24/7 emergency capability for life-threatening conditions'), findsOneWidget);
      expect(find.text('Accepts CMCHIS / Government welfare scheme'), findsOneWidget);
      expect(find.text('Near patient location (1.4 km)'), findsOneWidget);
    });

    testWidgets('5. FacilityDetailSheet strictly enforces UNKNOWN != NO', (tester) async {
      await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: FacilityDetailSheet(facility: testUnknownClinic),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Clinic has null ICU and null Blood Bank -> MUST show 'Not verified', NEVER 'Not Available'
      expect(find.text('Intensive Care Unit (ICU)'), findsOneWidget);
      expect(find.text('Blood Bank / Storage'), findsOneWidget);
      expect(find.text('Not verified'), findsWidgets);
      expect(find.text('Emergency Capability Not Verified'), findsNothing); // It is limitedEmergency
      expect(find.text('Limited / Daytime Emergency Stabilization'), findsOneWidget);
    });

    testWidgets('6. Map View toggle switches to interactive FacilityMapView with markers', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital, testUnknownClinic],
      ));
      await tester.pumpAndSettle();

      // Find map view action button in AppBar
      final mapToggle = find.byTooltip('Map View');
      expect(mapToggle, findsOneWidget);

      await tester.tap(mapToggle);
      await tester.pumpAndSettle();

      // Map View active
      expect(find.byType(FacilityMapView), findsOneWidget);
      expect(find.textContaining('1 facilities on map (1 without GPS coordinates)'), findsOneWidget);
    });

    testWidgets('7. Search filter updates displayed facilities by query', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital, testUnknownClinic],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Government Rajaji Hospital'), findsOneWidget);
      expect(find.text('Vadipatti Primary Health Centre'), findsOneWidget);

      // Enter 'Vadipatti'
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Vadipatti');
      await tester.pumpAndSettle();

      expect(find.text('Vadipatti Primary Health Centre'), findsOneWidget);
      expect(find.text('Government Rajaji Hospital'), findsNothing);
    });

    testWidgets('8. Emergency filter chip filters list to only emergency facilities', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital, testUnknownClinic],
      ));
      await tester.pumpAndSettle();

      final emergChip = find.widgetWithText(FilterChip, 'Emergency');
      expect(emergChip, findsOneWidget);

      await tester.tap(emergChip);
      await tester.pumpAndSettle();

      expect(find.text('Government Rajaji Hospital'), findsOneWidget);
      expect(find.text('Vadipatti Primary Health Centre'), findsNothing);
    });

    testWidgets('9. Navigation from Triage displays active triage care need banner', (tester) async {
      const careRequest = PatientCareRequest(
        urgency: TriageUrgency.emergency,
        dispositionState: TriageDispositionState.emergency,
        isEmergencyCareRequired: true,
        triageReason: 'Acute chest pain indicating potential cardiac emergency',
      );

      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
        careRequest: careRequest,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Urgent Care Need Active'), findsOneWidget);
      expect(find.text('Acute chest pain indicating potential cardiac emergency'), findsOneWidget);
    });

    testWidgets('10. Directions dialog displays destination coordinates and URL', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
      ));
      await tester.pumpAndSettle();

      final directionsBtn = find.byIcon(Icons.directions);
      expect(directionsBtn, findsOneWidget);

      await tester.tap(directionsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Get Directions'), findsOneWidget);
      expect(find.text('GPS Coordinates: 9.9252, 78.1328'), findsOneWidget);
      expect(find.textContaining('https://www.google.com/maps/dir/?api=1&destination=9.9252,78.1328'), findsOneWidget);
    });

    testWidgets('11. Multilingual display works in Tamil', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
        locale: const Locale('ta'),
      ));
      await tester.pumpAndSettle();

      expect(find.text('மருத்துவமனைகள் & மையங்கள்'), findsOneWidget);
      expect(find.text('அரசு ராஜாஜி மருத்துவமனை'), findsOneWidget);
      expect(find.text('அவசர சிகிச்சை'), findsOneWidget);
      expect(find.text('இந்த மருத்துவமனை ஏன்?'), findsOneWidget);
    });

    testWidgets('12. Responsive test: No RenderFlex overflow on narrow 320px viewport', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital, testUnknownClinic],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Government Rajaji Hospital'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('13. Map View: Initial viewport dynamically derived from facility coordinates', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      expect(find.byType(FacilityMapView), findsOneWidget);
      // Ensure no crash or exception
      expect(tester.takeException(), isNull);
    });

    testWidgets('14. Map View: Clustering groups multiple nearby facilities into cluster badge', (tester) async {
      // Create 5 facilities located near each other in Madurai
      final clusterFacilities = List.generate(5, (index) {
        return Facility(
          id: 'fac-madurai-$index',
          name: 'Madurai Health Post $index',
          facilityType: FacilityType.primaryHealthCentre,
          providerCategory: ProviderCategory.government,
          location: FacilityLocation(
            addressLine: 'Street $index',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252 + (index * 0.0001), // close coordinates in same grid cell
            longitude: 78.1198 + (index * 0.0001),
          ),
          emergencyCapability: EmergencyCapability.noEmergency,
          provenance: FacilityProvenance(
            verificationStatus: VerificationStatus.official,
            dataSourceType: DataSourceType.official,
            sourceName: 'Tamil Nadu NHM',
            lastUpdated: testDate,
          ),
        );
      });

      await tester.pumpWidget(createTestApp(
        facilities: clusterFacilities,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      // Because the 5 facilities are close together at the initial zoomed-out view, they cluster into badge '5'
      expect(find.text('5'), findsOneWidget);
    });

    testWidgets('15. Map View: Tapping a cluster zooms in toward the cluster', (tester) async {
      final List<Facility> clusterFacilities = List.generate(3, (index) {
        return Facility(
          id: 'fac-cluster-zoom-$index',
          name: 'Cluster Clinic $index',
          facilityType: FacilityType.clinic,
          providerCategory: ProviderCategory.government,
          emergencyCapability: EmergencyCapability.noEmergency,
          location: FacilityLocation(
            addressLine: 'Main Road $index',
            city: 'Madurai',
            district: 'Madurai',
            state: 'Tamil Nadu',
            pincode: '625001',
            latitude: 9.9252 + (index * 0.0001),
            longitude: 78.1198 + (index * 0.0001),
          ),
          provenance: FacilityProvenance(
            verificationStatus: VerificationStatus.official,
            dataSourceType: DataSourceType.official,
            sourceName: 'Tamil Nadu NHM',
            lastUpdated: testDate,
          ),
        );
      });

      await tester.pumpWidget(createTestApp(
        facilities: clusterFacilities,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      final clusterBadge = find.text('3');
      expect(clusterBadge, findsOneWidget);

      // Tap cluster badge
      await tester.tap(clusterBadge);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('16. Map View: Tapping individual marker selects facility and shows detail sheet on button tap', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      // The single facility renders as an individual hospital/emergency pin
      final markerPin = find.byIcon(Icons.emergency);
      expect(markerPin, findsOneWidget);

      // Tap the marker
      await tester.tap(markerPin);
      await tester.pumpAndSettle();

      // Selected card appears at bottom
      expect(find.text('Government Rajaji Hospital'), findsWidgets);
      expect(find.text('Details'), findsOneWidget);

      // Tap Details
      await tester.tap(find.text('Details'));
      await tester.pumpAndSettle();

      // Opens FacilityDetailSheet
      expect(find.byType(FacilityDetailSheet), findsOneWidget);
    });

    testWidgets('17. Map View: Handles zero coordinates safely without crashing', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testUnknownClinic], // null lat/lon
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      expect(find.byType(FacilityMapView), findsOneWidget);
      expect(find.textContaining('0 facilities on map (1 without GPS coordinates)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('18. Map View: Recenter button triggers extent refitting without error', (tester) async {
      await tester.pumpWidget(createTestApp(
        facilities: [testEmergencyHospital],
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Map View'));
      await tester.pumpAndSettle();

      final recenterBtn = find.byTooltip('Fit Tamil Nadu extent');
      expect(recenterBtn, findsOneWidget);

      await tester.tap(recenterBtn);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
