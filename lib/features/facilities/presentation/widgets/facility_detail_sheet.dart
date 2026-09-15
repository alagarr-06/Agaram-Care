// Task 10 - Facility Detail Sheet.
//
// Full details modal bottom sheet for a selected facility.
//
// CRITICAL INVARIANTS:
// - UNKNOWN != NO:
//   Missing capabilities (ICU, Inpatient, Blood Bank, Beds) display as
//   "Information not available" / "Not verified", NEVER as "No ICU" or "0 beds".
// - Emergency status clearly distinguished:
//   fullEmergency / emergencyAvailable -> Confirmed Emergency
//   limitedEmergency -> Limited Daytime Emergency / Stabilization
//   noEmergency -> No Emergency Services
//   unknown -> Emergency Capability Not Verified
// - Real coordinates rendered; "Get Directions" links to external maps safely.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_state.dart';
import '../../domain/facilities.dart';

class FacilityDetailSheet extends ConsumerWidget {
  const FacilityDetailSheet({
    super.key,
    required this.facility,
    this.distanceKm,
    this.onGetDirections,
  });

  final Facility facility;
  final double? distanceKm;
  final VoidCallback? onGetDirections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final locale = ref.watch(selectedLocaleProvider);
    final isTamil = locale.languageCode == 'ta';
    final isHindi = locale.languageCode == 'hi';

    String text({
      required String en,
      required String ta,
      required String hi,
    }) {
      if (isTamil) return ta;
      if (isHindi) return hi;
      return en;
    }

    final displayName = isTamil && facility.nameTa != null && facility.nameTa!.isNotEmpty
        ? facility.nameTa!
        : (isHindi && facility.nameHi != null && facility.nameHi!.isNotEmpty
            ? facility.nameHi!
            : facility.name);

    final f = facility;
    // cap & aff accessed via f

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // Header
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.teal.shade50,
                      child: Icon(
                        _facilityTypeIcon(f.facilityType),
                        color: Colors.teal.shade700,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_providerCategoryLabel(f.providerCategory)} • ${_facilityTypeLabel(f.facilityType)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Emergency Badge Banner
                _buildEmergencyBanner(context, text),
                const SizedBox(height: 16),

                // Location & Address Card
                _buildLocationCard(context, text),
                const SizedBox(height: 16),

                // Clinical & Service Capabilities Card (UNKNOWN != NO strictly enforced)
                _buildCapabilitiesCard(context, text),
                const SizedBox(height: 16),

                // Affordability & Government Schemes Card
                _buildAffordabilityCard(context, text),
                const SizedBox(height: 16),

                // Provenance & Registry Metadata
                _buildProvenanceCard(context, text),
                const SizedBox(height: 24),

                // Navigation / Action Buttons
                Row(
                  children: [
                    if (f.location.hasCoordinates) ...[
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop();
                            onGetDirections?.call();
                          },
                          icon: const Icon(Icons.directions, size: 18),
                          label: Text(text(
                            en: 'Get Directions',
                            ta: 'வழிகாட்டுதல்',
                            hi: 'दिशा-निर्देश',
                          )),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(text(en: 'Close', ta: 'மூடு', hi: 'बंद करें')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyBanner(
    BuildContext context,
    String Function({required String en, required String ta, required String hi}) text,
  ) {
    final status = facility.emergencyCapability;
    Color bgColor;
    Color fgColor;
    IconData icon;
    String title;
    String subtitle;

    switch (status) {
      case EmergencyCapability.fullEmergency:
      case EmergencyCapability.emergencyAvailable:
        bgColor = Colors.red.shade50;
        fgColor = Colors.red.shade800;
        icon = Icons.emergency;
        title = text(
          en: '24/7 Confirmed Emergency Services',
          ta: '24/7 உறுதிப்படுத்தப்பட்ட அவசர சிகிச்சை',
          hi: '24/7 पुष्टि की गई आपातकालीन सेवाएं',
        );
        subtitle = text(
          en: 'Equipped to handle acute clinical trauma and resuscitation.',
          ta: 'தீவிர அவசர சிகிச்சை மற்றும் அதிர்ச்சி மேலாண்மைக்கு தயார்.',
          hi: 'गंभीर आघात और पुनर्जीवन को संभालने के लिए सुसज्जित।',
        );
        break;
      case EmergencyCapability.limitedEmergency:
        bgColor = Colors.amber.shade50;
        fgColor = Colors.amber.shade900;
        icon = Icons.warning_amber_rounded;
        title = text(
          en: 'Limited / Daytime Emergency Stabilization',
          ta: 'வரையறுக்கப்பட்ட / பகல்நேர அவசர உறுதிப்படுத்தல்',
          hi: 'सीमित / दिन के समय आपातकालीन स्थिरीकरण',
        );
        subtitle = text(
          en: 'Initial stabilization and referral. Comprehensive casualty not confirmed.',
          ta: 'ஆரம்ப நிலைப்படுத்தல் மட்டுமே. முழுமையான அவசர பிரிவு இல்லை.',
          hi: 'प्रारंभिक स्थिरीकरण और रेफरल। पूर्ण आपातकालीन इकाई नहीं है।',
        );
        break;
      case EmergencyCapability.noEmergency:
        bgColor = Colors.grey.shade100;
        fgColor = Colors.grey.shade800;
        icon = Icons.block;
        title = text(
          en: 'No Emergency Services',
          ta: 'அவசர சிகிச்சை பிரிவு இல்லை',
          hi: 'कोई आपातकालीन सेवा नहीं',
        );
        subtitle = text(
          en: 'Outpatient consultation and routine appointments only.',
          ta: 'புறநோயாளிகள் ஆலோசனை மற்றும் வழக்கமான பரிசோதனை மட்டுமே.',
          hi: 'केवल बाह्य रोगी परामर्श और नियमित जांच।',
        );
        break;
      case EmergencyCapability.unknown:
        bgColor = Colors.blueGrey.shade50;
        fgColor = Colors.blueGrey.shade700;
        icon = Icons.help_outline;
        title = text(
          en: 'Emergency Capability Not Verified',
          ta: 'அவசர சிகிச்சை திறன் சரிபார்க்கப்படவில்லை',
          hi: 'आपातकालीन क्षमता सत्यापित नहीं है',
        );
        subtitle = text(
          en: 'Contact facility or emergency helpline 108 directly to confirm.',
          ta: 'உறுதிப்படுத்த மருத்துவமனையை அல்லது 108 அவசர எண்ணை தொடர்பு கொள்ளவும்.',
          hi: 'पुष्टि करने के लिए सीधे अस्पताल या 108 हेल्पलाइन से संपर्क करें।',
        );
        break;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: fgColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fgColor, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: fgColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard(
    BuildContext context,
    String Function({required String en, required String ta, required String hi}) text,
  ) {
    final loc = facility.location;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  text(en: 'Location & Address', ta: 'இருப்பிடம் & முகவரி', hi: 'स्थान एवं पता'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                if (distanceKm != null) ...[
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${distanceKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            if (loc.addressLine.isNotEmpty)
              Text(
                loc.addressLine,
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
            Text(
              '${loc.city.isNotEmpty ? "${loc.city}, " : ""}${loc.district}, Tamil Nadu - ${loc.pincode}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  loc.hasCoordinates ? Icons.gps_fixed : Icons.gps_off,
                  size: 14,
                  color: loc.hasCoordinates ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.hasCoordinates
                      ? 'GPS: ${loc.latitude!.toStringAsFixed(4)}, ${loc.longitude!.toStringAsFixed(4)}'
                      : text(
                          en: 'GPS Coordinates not verified (Search by District/PIN)',
                          ta: 'GPS இருப்பிடம் சரிபார்க்கப்படவில்லை',
                          hi: 'जीपीएस स्थान सत्यापित नहीं है',
                        ),
                  style: TextStyle(
                    fontSize: 11,
                    color: loc.hasCoordinates ? Colors.grey.shade800 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilitiesCard(
    BuildContext context,
    String Function({required String en, required String ta, required String hi}) text,
  ) {
    final cap = facility.capability;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medical_services_outlined, size: 18, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  text(
                    en: 'Clinical & Operational Capabilities',
                    ta: 'மருத்துவ & செயல்பாட்டு திறன்கள்',
                    hi: 'चिकित्सा एवं परिचालन क्षमताएं',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _capabilityRow(
              icon: Icons.hotel_outlined,
              label: text(en: 'Inpatient Beds', ta: 'உள்நோயாளிகள் படுக்கை', hi: 'भर्ती बिस्तर'),
              status: cap.inpatientAvailable,
              extraInfo: cap.approxTotalBeds != null ? ' (~${cap.approxTotalBeds} registered)' : null,
              text: text,
            ),
            _capabilityRow(
              icon: Icons.monitor_heart_outlined,
              label: text(en: 'Intensive Care Unit (ICU)', ta: 'தீவிர சிகிச்சை பிரிவு (ICU)', hi: 'आईसीयू'),
              status: cap.icuAvailable,
              text: text,
            ),
            _capabilityRow(
              icon: Icons.bloodtype_outlined,
              label: text(en: 'Blood Bank / Storage', ta: 'இரத்த வங்கி', hi: 'ब्लड बैंक'),
              status: cap.bloodBankAvailable,
              text: text,
            ),
            _capabilityRow(
              icon: Icons.medication_outlined,
              label: text(en: 'Pharmacy on-site', ta: 'மருந்தகம்', hi: 'फार्मेसी'),
              status: cap.pharmacyAvailable,
              text: text,
            ),
            _capabilityRow(
              icon: Icons.airport_shuttle_outlined,
              label: text(en: 'Ambulance Service', ta: 'ஆம்புலன்ஸ் சேவை', hi: 'एम्बुलेंस'),
              status: cap.ambulanceAvailable,
              text: text,
            ),
            _capabilityRow(
              icon: Icons.video_call_outlined,
              label: text(en: 'Teleconsultation', ta: 'தொலைமருத்துவம்', hi: 'टेलीकंसल्टेशन'),
              status: cap.teleconsultAvailable,
              text: text,
            ),
          ],
        ),
      ),
    );
  }

  Widget _capabilityRow({
    required IconData icon,
    required String label,
    required bool? status,
    String? extraInfo,
    required String Function({required String en, required String ta, required String hi}) text,
  }) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (status == true) {
      statusText = text(en: 'Available', ta: 'உள்ளது', hi: 'उपलब्ध');
      statusColor = Colors.green.shade700;
      statusIcon = Icons.check_circle;
    } else if (status == false) {
      statusText = text(en: 'Not Available', ta: 'இல்லை', hi: 'उपलब्ध नहीं');
      statusColor = Colors.red.shade700;
      statusIcon = Icons.cancel;
    } else {
      // CRITICAL INVARIANT: UNKNOWN != NO
      statusText = text(en: 'Not verified', ta: 'சரிபார்க்கப்படவில்லை', hi: 'सत्यापित नहीं');
      statusColor = Colors.grey.shade600;
      statusIcon = Icons.help_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label${extraInfo ?? ""}',
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: 14, color: statusColor),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAffordabilityCard(
    BuildContext context,
    String Function({required String en, required String ta, required String hi}) text,
  ) {
    final aff = facility.affordability;

    return Card(
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_balance_outlined, size: 18, color: Colors.teal),
                const SizedBox(width: 8),
                Text(
                  text(
                    en: 'Affordability & Welfare Schemes',
                    ta: 'கட்டணம் & அரசு நலத்திட்டங்கள்',
                    hi: 'लागत एवं कल्याणकारी योजनाएं',
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  aff.acceptsGovernmentSchemes ? Icons.verified : Icons.help_outline,
                  size: 16,
                  color: aff.acceptsGovernmentSchemes ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    aff.acceptsGovernmentSchemes
                        ? text(
                            en: 'Accepts Government Schemes (CMCHIS / AB-PMJAY)',
                            ta: 'முதலமைச்சரின் விரிவான மருத்துவக் காப்பீடு ஏற்கப்படும்',
                            hi: 'सरकारी योजनाएं (CMCHIS / AB-PMJAY) स्वीकृत',
                          )
                        : text(
                            en: 'Scheme coverage not verified',
                            ta: 'காப்பீட்டுத் திட்டம் சரிபார்க்கப்படவில்லை',
                            hi: 'योजना कवरेज सत्यापित नहीं',
                          ),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: aff.acceptsGovernmentSchemes ? Colors.green.shade800 : Colors.grey.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if (aff.supportedSchemes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: aff.supportedSchemes
                    .map((s) => Chip(
                          label: Text(s, style: const TextStyle(fontSize: 10)),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: Colors.teal.shade50,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProvenanceCard(
    BuildContext context,
    String Function({required String en, required String ta, required String hi}) text,
  ) {
    final prov = facility.provenance;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              Text(
                text(en: 'Data Provenance & Trust', ta: 'தரவு நம்பகத்தன்மை', hi: 'डेटा प्रामाणिकता'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            prov.isDemonstration
                ? text(
                    en: 'Demonstration Record: Synthetic data created for local validation.',
                    ta: 'மாதிரி பதிவு: உள்ளூர் சரிபார்ப்புக்கான செயற்கை தரவு.',
                    hi: 'प्रदर्शन रिकॉर्ड: स्थानीय सत्यापन के लिए सिंथेटिक डेटा।',
                  )
                : text(
                    en: 'Official Registry: Sourced from Tamil Nadu National Health Mission (NHM).',
                    ta: 'அதிகாரப்பூர்வ பதிவு: தமிழ்நாடு தேசிய சுகாதார இயக்கம் (NHM).',
                    hi: 'आधिकारिक रजिस्ट्री: तमिलनाडु राष्ट्रीय स्वास्थ्य मिशन (NHM)।',
                  ),
            style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade800),
          ),
          if (prov.sourceRegistryId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Registry ID: ${prov.sourceRegistryId}',
              style: TextStyle(fontSize: 10, color: Colors.blueGrey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  IconData _facilityTypeIcon(FacilityType type) {
    return switch (type) {
      FacilityType.hospital => Icons.local_hospital,
      FacilityType.clinic => Icons.medical_services,
      FacilityType.primaryHealthCentre => Icons.home_work,
      FacilityType.communityHealthCentre => Icons.business,
      FacilityType.diagnosticCentre => Icons.biotech,
      FacilityType.pharmacy => Icons.local_pharmacy,
      FacilityType.telemedicineCentre => Icons.video_call,
      FacilityType.other => Icons.health_and_safety,
    };
  }

  String _providerCategoryLabel(ProviderCategory category) {
    return switch (category) {
      ProviderCategory.government => 'Government',
      ProviderCategory.private => 'Private',
      ProviderCategory.nonprofit => 'Nonprofit / Trust',
      ProviderCategory.mixed => 'Public-Private',
      ProviderCategory.unknown => 'Provider Category Unverified',
    };
  }

  String _facilityTypeLabel(FacilityType type) {
    return switch (type) {
      FacilityType.hospital => 'Hospital',
      FacilityType.clinic => 'Clinic / HSC',
      FacilityType.primaryHealthCentre => 'Primary Health Centre (PHC)',
      FacilityType.communityHealthCentre => 'Community Health Centre (CHC)',
      FacilityType.diagnosticCentre => 'Diagnostic Centre',
      FacilityType.pharmacy => 'Pharmacy',
      FacilityType.telemedicineCentre => 'Telemedicine Centre',
      FacilityType.other => 'Healthcare Facility',
    };
  }
}
