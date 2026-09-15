// Task 08 - Demonstration Healthcare Facilities Dataset.
//
// STATIC DEMONSTRATION DATASET FOR DEVELOPMENT & TESTING ONLY.
//
// ALL records in this file are synthetic demonstrations and are explicitly
// marked with:
//   dataSourceType = DataSourceType.demonstration
//   verificationStatus = VerificationStatus.demonstration
//
// SAFETY & INTEGRITY PRINCIPLE:
// - These records are NOT real healthcare facilities.
// - No live bed occupancy, queue times, or dynamic inventory are fabricated.
// - Unknown operational values are preserved as null.
library;

import '../entities/facility.dart';
import '../entities/facility_affordability.dart';
import '../entities/facility_capability.dart';
import '../entities/facility_location.dart';
import '../entities/facility_provenance.dart';
import '../entities/facility_specialty.dart';
import '../enums/facility_enums.dart';

final _demoDate = DateTime.utc(2026, 9, 14, 12, 0, 0);

/// Curated demonstration facilities spanning different capability tiers
/// across Tamil Nadu districts for development and test scenarios.
final List<Facility> demonstrationFacilities = List.unmodifiable([
  // 1. Government Primary Health Centre (PHC)
  Facility(
    id: 'demo-phc-01',
    name: 'Government Primary Health Centre, Alanganallur',
    nameTa: 'அரசு ஆரம்ப சுகாதார நிலையம், அலங்காநல்லூர்',
    nameHi: 'सरकारी प्राथमिक स्वास्थ्य केंद्र, अलंगानल्लूर',
    facilityType: FacilityType.primaryHealthCentre,
    providerCategory: ProviderCategory.government,
    location: const FacilityLocation(
      addressLine: 'Main Road, Near Bus Stand',
      area: 'Alanganallur',
      city: 'Vadipatti',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625501',
      latitude: 10.0462,
      longitude: 78.0934,
    ),
    emergencyCapability: EmergencyCapability.limitedEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: false,
      icuAvailable: false,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: false,
      ambulanceAvailable: true,
      approxTotalBeds: 6,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['National Health Mission', 'Tamil Nadu State Health'],
      isFreeCareAvailable: true,
      consultationFeeEstimate: 'Free',
      pricingTier: 'government_free',
      insuranceNotes: 'All primary OPD services and essential medicines are provided free of cost.',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-PHC-001',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for rural primary healthcare testing.',
    ),
    specialties: const [
      FacilitySpecialty(
        id: 'general_medicine',
        name: 'General Medicine',
        nameTa: 'பொது மருத்துவம்',
        nameHi: 'सामान्य चिकित्सा',
      ),
      FacilitySpecialty(
        id: 'maternal_and_child_health',
        name: 'Maternal and Child Health',
        nameTa: 'தாய் மற்றும் சேய் நலம்',
        nameHi: 'मातृ एवं शिशु स्वास्थ्य',
      ),
    ],
    services: const [
      FacilityService(
        id: 'outpatient_clinic',
        name: 'Outpatient Clinic',
        nameTa: 'வெளிநோயாளி பிரிவு',
        is24x7: false,
      ),
      FacilityService(
        id: 'immunization',
        name: 'Immunization & Vaccination',
        nameTa: 'தடுப்பூசி சேவை',
        is24x7: false,
      ),
      FacilityService(
        id: 'basic_lab',
        name: 'Basic Blood & Urine Testing',
        nameTa: 'அடிப்படை பரிசோதனைக்கூடம்',
        is24x7: false,
      ),
    ],
    operatingHours: '9:00 AM - 4:00 PM (Emergency nurse on call 24/7)',
    contactPhone: '+91 452 245001',
    emergencyPhone: '108',
  ),

  // 2. Government Community Health Centre (CHC)
  Facility(
    id: 'demo-chc-01',
    name: 'Government Community Health Centre, Melur',
    nameTa: 'அரசு சமுதாய சுகாதார மையம், மேலூர்',
    nameHi: 'सरकारी सामुदायिक स्वास्थ्य केंद्र, मेलूर',
    facilityType: FacilityType.communityHealthCentre,
    providerCategory: ProviderCategory.government,
    location: const FacilityLocation(
      addressLine: 'Trichy Main Road',
      area: 'Melur Town',
      city: 'Melur',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625106',
      latitude: 10.0315,
      longitude: 78.3375,
    ),
    emergencyCapability: EmergencyCapability.emergencyAvailable,
    capability: const FacilityCapability(
      inpatientAvailable: true,
      icuAvailable: false,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: false,
      ambulanceAvailable: true,
      neonatalIcuAvailable: false,
      ventilatorAvailable: false,
      approxTotalBeds: 30,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['CMCHIS', 'AB-PMJAY', 'NHM'],
      isFreeCareAvailable: true,
      consultationFeeEstimate: 'Free',
      pricingTier: 'government_free',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-CHC-002',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for secondary community health facility.',
    ),
    specialties: const [
      FacilitySpecialty(
        id: 'general_medicine',
        name: 'General Medicine',
        nameTa: 'பொது மருத்துவம்',
      ),
      FacilitySpecialty(
        id: 'pediatrics',
        name: 'Pediatrics',
        nameTa: 'குழந்தைகள் நலம்',
      ),
      FacilitySpecialty(
        id: 'obstetrics_and_gynecology',
        name: 'Obstetrics & Gynecology',
        nameTa: 'மகப்பேறு மற்றும் மகளிர் நலம்',
      ),
      FacilitySpecialty(
        id: 'general_surgery',
        name: 'General Surgery',
        nameTa: 'பொது அறுவை சிகிச்சை',
      ),
    ],
    services: const [
      FacilityService(
        id: 'emergency_casualty',
        name: 'Emergency Casualty',
        nameTa: 'அவசர சிகிச்சை பிரிவு',
        is24x7: true,
      ),
      FacilityService(
        id: 'labor_room',
        name: '24/7 Delivery & Labor Room',
        nameTa: 'பிரசவ அறை',
        is24x7: true,
      ),
      FacilityService(
        id: 'x_ray',
        name: 'X-Ray Diagnostics',
        nameTa: 'எக்ஸ்ரே பரிசோதனை',
        is24x7: false,
      ),
    ],
    operatingHours: '24/7 Emergency, 8:00 AM - 1:00 PM OPD',
    contactPhone: '+91 452 278002',
    emergencyPhone: '108',
  ),

  // 3. Government Tertiary / Medical College Hospital (Full Emergency, Government Tertiary)
  Facility(
    id: 'demo-govt-tertiary-01',
    name: 'Government Rajaji Hospital & Medical College',
    nameTa: 'அரசு ராஜாஜி மருத்துவமனை மற்றும் மருத்துவக் கல்லூரி',
    nameHi: 'सरकारी राजाजी अस्पताल एवं मेडिकल कॉलेज',
    facilityType: FacilityType.hospital,
    providerCategory: ProviderCategory.government,
    location: const FacilityLocation(
      addressLine: 'Panagal Road, Shenoy Nagar',
      area: 'Goripalayam',
      city: 'Madurai',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625020',
      latitude: 9.9298,
      longitude: 78.1328,
    ),
    emergencyCapability: EmergencyCapability.fullEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: true,
      icuAvailable: true,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: true,
      ambulanceAvailable: true,
      burnUnitAvailable: true,
      neonatalIcuAvailable: true,
      ventilatorAvailable: true,
      approxTotalBeds: 2500,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['CMCHIS', 'AB-PMJAY', 'Tamil Nadu Free Healthcare Scheme'],
      isFreeCareAvailable: true,
      consultationFeeEstimate: 'Free',
      pricingTier: 'government_free',
      insuranceNotes: 'Comprehensive tertiary and emergency care fully covered by state.',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-TERT-003',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for government tertiary apex hospital.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'emergency_medicine', name: 'Emergency Medicine', nameTa: 'அவசர சிகிச்சை மருத்துவம்'),
      FacilitySpecialty(id: 'cardiology', name: 'Cardiology', nameTa: 'இதயவியல்'),
      FacilitySpecialty(id: 'neurology', name: 'Neurology', nameTa: 'நரம்பியல்'),
      FacilitySpecialty(id: 'orthopedics', name: 'Orthopedics', nameTa: 'எலும்பியல்'),
      FacilitySpecialty(id: 'pediatrics', name: 'Pediatrics', nameTa: 'குழந்தைகள் நலம்'),
      FacilitySpecialty(id: 'nephrology', name: 'Nephrology', nameTa: 'சிறுநீரகவியல்'),
      FacilitySpecialty(id: 'pulmonology', name: 'Pulmonology', nameTa: 'நுரையீரல் மருத்துவம்'),
      FacilitySpecialty(id: 'general_surgery', name: 'General Surgery', nameTa: 'பொது அறுவை சிகிச்சை'),
    ],
    services: const [
      FacilityService(id: 'trauma_care_center', name: 'Level 1 Trauma Care', is24x7: true),
      FacilityService(id: 'cardiac_icu', name: 'Cardiac Intensive Care Unit (ICCU)', is24x7: true),
      FacilityService(id: 'ct_scan', name: 'CT Scan 128-Slice', is24x7: true),
      FacilityService(id: 'mri_scan', name: 'MRI Diagnostics', is24x7: true),
      FacilityService(id: 'blood_bank', name: 'Regional Blood Transfusion Center', is24x7: true),
      FacilityService(id: 'dialysis_unit', name: '24/7 Dialysis Unit', is24x7: true),
    ],
    operatingHours: '24/7 (Emergency & Inpatient)',
    contactPhone: '+91 452 2532535',
    emergencyPhone: '+91 452 2532536',
    website: 'https://grhmdu.tn.gov.in',
  ),

  // 4. Private Multi-Specialty Tertiary Hospital (Full Emergency, Private, CMCHIS Empaneled)
  Facility(
    id: 'demo-pvt-tertiary-01',
    name: 'Meenakshi Mission Hospital & Research Centre',
    nameTa: 'மீனாட்சி மிஷன் மருத்துவமனை மற்றும் ஆராய்ச்சி மையம்',
    nameHi: 'मीनाक्षी मिशन अस्पताल एवं अनुसंधान केंद्र',
    facilityType: FacilityType.hospital,
    providerCategory: ProviderCategory.private,
    location: const FacilityLocation(
      addressLine: 'Lake Area, Melur Road',
      area: 'Mattuthavani',
      city: 'Madurai',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625107',
      latitude: 9.9482,
      longitude: 78.1633,
    ),
    emergencyCapability: EmergencyCapability.fullEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: true,
      icuAvailable: true,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: true,
      ambulanceAvailable: true,
      burnUnitAvailable: true,
      neonatalIcuAvailable: true,
      ventilatorAvailable: true,
      approxTotalBeds: 1000,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['CMCHIS', 'AB-PMJAY', 'Private TPA / Insurance'],
      isFreeCareAvailable: false,
      consultationFeeEstimate: 'Rs. 400 - 800',
      pricingTier: 'tertiary_private',
      insuranceNotes: 'Empaneled for Chief Minister Comprehensive Health Insurance Scheme (CMCHIS).',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-PVT-004',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for private multi-specialty tertiary care.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'emergency_medicine', name: 'Emergency Medicine', nameTa: 'அவசர சிகிச்சை மருத்துவம்'),
      FacilitySpecialty(id: 'cardiology', name: 'Cardiology', nameTa: 'இதயவியல்'),
      FacilitySpecialty(id: 'cardiac_surgery', name: 'Cardiothoracic Surgery', nameTa: 'இதய அறுவை சிகிச்சை'),
      FacilitySpecialty(id: 'neurology', name: 'Neurology', nameTa: 'நரம்பியல்'),
      FacilitySpecialty(id: 'orthopedics', name: 'Orthopedics', nameTa: 'எலும்பியல்'),
      FacilitySpecialty(id: 'oncology', name: 'Oncology', nameTa: 'புற்றுநோயியல்'),
    ],
    services: const [
      FacilityService(id: 'emergency_trauma', name: 'Emergency Trauma & Cardiac Care', is24x7: true),
      FacilityService(id: 'cath_lab', name: 'Digital Cardiac Cath Lab', is24x7: true),
      FacilityService(id: 'mri_3t', name: '3-Tesla MRI', is24x7: true),
      FacilityService(id: 'blood_bank', name: 'Component Blood Bank', is24x7: true),
    ],
    operatingHours: '24/7',
    contactPhone: '+91 452 4263000',
    emergencyPhone: '+91 452 4263100',
    website: 'https://www.meenakshimission.org',
  ),

  // 5. Private Urban Clinic (No Emergency, Outpatient Consultation Only)
  Facility(
    id: 'demo-clinic-01',
    name: 'Apollo Clinic, Anna Nagar',
    nameTa: 'அப்பல்லோ கிளினிக், அண்ணா நகர்',
    nameHi: 'अपोलो क्लिनिक, अन्ना नगर',
    facilityType: FacilityType.clinic,
    providerCategory: ProviderCategory.private,
    location: const FacilityLocation(
      addressLine: '80 Feet Road, Near Kuruvikaran Salai',
      area: 'Anna Nagar',
      city: 'Madurai',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625020',
      latitude: 9.9192,
      longitude: 78.1438,
    ),
    emergencyCapability: EmergencyCapability.noEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: false,
      icuAvailable: false,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: false,
      ambulanceAvailable: false,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: false,
      supportedSchemes: [],
      isFreeCareAvailable: false,
      consultationFeeEstimate: 'Rs. 350 - 500',
      pricingTier: 'standard_private',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-CLN-005',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for private day clinic without emergency capability.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'general_medicine', name: 'General Medicine', nameTa: 'பொது மருத்துவம்'),
      FacilitySpecialty(id: 'pediatrics', name: 'Pediatrics', nameTa: 'குழந்தைகள் நலம்'),
      FacilitySpecialty(id: 'dermatology', name: 'Dermatology', nameTa: 'தோல் மருத்துவம்'),
      FacilitySpecialty(id: 'diabetology', name: 'Diabetology', nameTa: 'சர்க்கரை நோய் மருத்துவம்'),
    ],
    services: const [
      FacilityService(id: 'routine_consultation', name: 'Doctor Consultation', is24x7: false),
      FacilityService(id: 'sample_collection', name: 'Lab Sample Collection', is24x7: false),
      FacilityService(id: 'ecg', name: '12-Lead ECG', is24x7: false),
    ],
    operatingHours: '8:00 AM - 8:00 PM (Mon-Sat), 8:00 AM - 1:00 PM (Sun)',
    contactPhone: '+91 452 4390000',
  ),

  // 6. Specialized Standalone Diagnostic & Imaging Centre (No Inpatient, Diagnostic Only)
  Facility(
    id: 'demo-diag-01',
    name: 'Aarthi Scans and Diagnostic Centre, KK Nagar',
    nameTa: 'ஆர்த்தி ஸ்கேன்ஸ் மற்றும் கண்டறியும் மையம், கே.கே.நகர்',
    nameHi: 'आरती स्कैन्स एवं डायग्नोस्टिक सेंटर, के.के.नगर',
    facilityType: FacilityType.diagnosticCentre,
    providerCategory: ProviderCategory.private,
    location: const FacilityLocation(
      addressLine: '80 Feet Road, Opp. District Court',
      area: 'KK Nagar',
      city: 'Madurai',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625020',
      latitude: 9.9272,
      longitude: 78.1488,
    ),
    emergencyCapability: EmergencyCapability.noEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: false,
      icuAvailable: false,
      teleconsultAvailable: false,
      pharmacyAvailable: false,
      bloodBankAvailable: false,
      ambulanceAvailable: false,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['CMCHIS Diagnostic Empanelment'],
      isFreeCareAvailable: false,
      consultationFeeEstimate: 'Subsidized / Standard Scan Rates',
      pricingTier: 'subsidized_diagnostic',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-DIAG-006',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for standalone advanced diagnostic imaging.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'radiology', name: 'Radiology & Imaging', nameTa: 'கதிரியக்கவியல் மற்றும் ஸ்கேன்'),
      FacilitySpecialty(id: 'pathology', name: 'Clinical Pathology', nameTa: 'நோயியல் பரிசோதனை'),
    ],
    services: const [
      FacilityService(id: 'mri_scan', name: '1.5T MRI', is24x7: true),
      FacilityService(id: 'ct_scan', name: 'Multislice CT', is24x7: true),
      FacilityService(id: 'ultrasound', name: 'Ultrasound Doppler', is24x7: false),
      FacilityService(id: 'blood_biochemistry', name: 'Fully Automated Biochemistry', is24x7: true),
    ],
    operatingHours: '24/7 (Emergency Scans), 7:00 AM - 9:00 PM (Routine)',
    contactPhone: '+91 452 2580000',
  ),

  // 7. Community Charitable Non-Profit Hospital (Emergency Available, Nonprofit)
  Facility(
    id: 'demo-charity-01',
    name: 'Christian Mission Community Hospital, Pasumalai',
    nameTa: 'கிறிஸ்தவ மிஷன் சமூக மருத்துவமனை, பசுமலை',
    nameHi: 'ईसाई मिशन सामुदायिक अस्पताल, पसुमलाई',
    facilityType: FacilityType.hospital,
    providerCategory: ProviderCategory.nonprofit,
    location: const FacilityLocation(
      addressLine: 'Pasumalai Main Road',
      area: 'Pasumalai',
      city: 'Madurai',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625004',
      latitude: 9.8975,
      longitude: 78.0822,
    ),
    emergencyCapability: EmergencyCapability.emergencyAvailable,
    capability: const FacilityCapability(
      inpatientAvailable: true,
      icuAvailable: true,
      teleconsultAvailable: true,
      pharmacyAvailable: true,
      bloodBankAvailable: false,
      ambulanceAvailable: true,
      ventilatorAvailable: true,
      approxTotalBeds: 120,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['CMCHIS', 'Mission Concession Support'],
      isFreeCareAvailable: false,
      consultationFeeEstimate: 'Rs. 100 - 200',
      pricingTier: 'subsidized_nonprofit',
      insuranceNotes: 'Subsidized charitable tariffs with concession for underprivileged patients.',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-CHARITY-007',
      lastUpdated: _demoDate,
      verifiedAt: _demoDate,
      verificationNotes: 'Synthetic benchmark record for nonprofit charitable hospital.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'general_medicine', name: 'General Medicine', nameTa: 'பொது மருத்துவம்'),
      FacilitySpecialty(id: 'general_surgery', name: 'General Surgery', nameTa: 'பொது அறுவை சிகிச்சை'),
      FacilitySpecialty(id: 'ophthalmology', name: 'Ophthalmology', nameTa: 'கண் மருத்துவம்'),
      FacilitySpecialty(id: 'orthopedics', name: 'Orthopedics', nameTa: 'எலும்பியல்'),
    ],
    services: const [
      FacilityService(id: 'casualty', name: '24/7 Casualty & Emergency', is24x7: true),
      FacilityService(id: 'inpatient_wards', name: 'General & Private Wards', is24x7: true),
      FacilityService(id: 'eye_care', name: 'Community Eye Clinic', is24x7: false),
    ],
    operatingHours: '24/7 Emergency & Inpatient',
    contactPhone: '+91 452 2370001',
    emergencyPhone: '+91 452 2370108',
  ),

  // 8. Remote Sub-Centre with Unverified Geocoordinates (Nullable Lat/Lng & Unknown operational features)
  Facility(
    id: 'demo-rural-sc-01',
    name: 'Health Sub-Centre, Chettikulam',
    nameTa: 'சுகாதார துணை நிலையம், செட்டிக்குளம்',
    nameHi: 'स्वास्थ्य उप-केंद्र, चेट्टिकुलम',
    facilityType: FacilityType.clinic,
    providerCategory: ProviderCategory.government,
    location: const FacilityLocation(
      addressLine: 'Near Village Panchayat Office',
      area: 'Chettikulam Village',
      city: 'Usilampatti Taluk',
      district: 'Madurai',
      state: 'Tamil Nadu',
      pincode: '625532',
      latitude: null, // Deliberately null to test un-geocoded facility records
      longitude: null,
    ),
    emergencyCapability: EmergencyCapability.noEmergency,
    capability: const FacilityCapability(
      inpatientAvailable: false,
      icuAvailable: false,
      teleconsultAvailable: null, // UNKNOWN != NO
      pharmacyAvailable: true,
      bloodBankAvailable: false,
      ambulanceAvailable: null,   // UNKNOWN != NO
      burnUnitAvailable: null,    // UNKNOWN != NO
      approxTotalBeds: null,
    ),
    affordability: const FacilityAffordability(
      acceptsGovernmentSchemes: true,
      supportedSchemes: ['NHM'],
      isFreeCareAvailable: true,
      consultationFeeEstimate: 'Free',
      pricingTier: 'government_free',
    ),
    provenance: FacilityProvenance(
      verificationStatus: VerificationStatus.demonstration,
      dataSourceType: DataSourceType.demonstration,
      sourceName: 'Agaram Care Synthetic Test Registry',
      sourceRegistryId: 'DEMO-REG-RURAL-008',
      lastUpdated: _demoDate,
      verifiedAt: null, // Unaudited
      verificationNotes: 'Synthetic benchmark record for rural sub-centre testing un-geocoded coordinates and unknown operational flags.',
    ),
    specialties: const [
      FacilitySpecialty(id: 'primary_care', name: 'First Aid & Primary Care', nameTa: 'முதலுதவி மற்றும் ஆரம்ப சிகிச்சை'),
    ],
    services: const [
      FacilityService(id: 'vhn_consultation', name: 'VHN Community Visit & First Aid', is24x7: false),
    ],
    operatingHours: '10:00 AM - 2:00 PM (VHN Field Duty)',
  ),
]);
