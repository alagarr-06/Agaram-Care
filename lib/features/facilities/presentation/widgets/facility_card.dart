// Task 10 - Facility Card Component.
//
// Represents an individual facility match result.
//
// CRITICAL INVARIANTS:
// - NO "best hospital" language.
// - Unknown metrics rendered as "Not verified", NEVER "No" or "0".
// - Structured "Why this facility?" button wired to explainable match reasons.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_state.dart';
import '../../domain/facilities.dart';
import 'facility_detail_sheet.dart';
import 'why_this_facility_sheet.dart';

class FacilityCard extends ConsumerWidget {
  const FacilityCard({
    super.key,
    required this.matchResult,
    this.onSelect,
    this.onGetDirections,
  });

  final FacilityMatchResult matchResult;
  final VoidCallback? onSelect;
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

    final f = matchResult.facility;
    final displayName = isTamil && f.nameTa != null && f.nameTa!.isNotEmpty
        ? f.nameTa!
        : (isHindi && f.nameHi != null && f.nameHi!.isNotEmpty ? f.nameHi! : f.name);

    final isEmergency = f.emergencyCapability == EmergencyCapability.fullEmergency ||
        f.emergencyCapability == EmergencyCapability.emergencyAvailable;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEmergency ? Colors.red.shade200 : Colors.grey.shade200,
          width: isEmergency ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onSelect ??
            () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (modalCtx) => FacilityDetailSheet(
                  facility: f,
                  distanceKm: matchResult.distanceKm,
                  onGetDirections: onGetDirections,
                ),
              );
            },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Type badge, Provenance, Distance
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _typeColor(f.facilityType).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _typeLabel(f.facilityType),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _typeColor(f.facilityType),
                            ),
                          ),
                        ),
                        if (f.provenance.isDemonstration)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Text(
                              text(en: 'Demo', ta: 'மாதிரி', hi: 'डेमो'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple.shade700,
                              ),
                            ),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified, size: 12, color: Colors.teal.shade700),
                                const SizedBox(width: 3),
                                Text(
                                  text(en: 'NHM Verified', ta: 'சரிபார்க்கப்பட்டது', hi: 'सत्यापित'),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (matchResult.distanceKm != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 11, color: Colors.grey),
                          const SizedBox(width: 3),
                          Text(
                            matchResult.formattedDistance ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),

              // Facility Name
              Text(
                displayName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),

              // Location snippet
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${f.location.district}${f.location.pincode.isNotEmpty ? " • ${f.location.pincode}" : ""}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Capabilities pills row
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (isEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.emergency, size: 12, color: Colors.red),
                          const SizedBox(width: 4),
                          Text(
                            text(en: 'Emergency', ta: 'அவசர சிகிச்சை', hi: 'आपातकाल'),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (f.emergencyCapability == EmergencyCapability.limitedEmergency)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        text(en: 'Daytime Care', ta: 'பகல்நேர சிகிச்சை', hi: 'दिन की देखभाल'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ),

                  if (f.providerCategory == ProviderCategory.government)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        text(en: 'Govt / Free Care', ta: 'அரசு / இலவசம்', hi: 'सरकारी / निःशुल्क'),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                      ),
                    ),

                  if (f.affordability.acceptsGovernmentSchemes)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'CMCHIS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal.shade800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),

              // Bottom Action Bar
              Row(
                children: [
                  // "Why this facility?" button
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (sheetCtx) => WhyThisFacilitySheet(matchResult: matchResult),
                          );
                        },
                        icon: const Icon(Icons.help_outline, size: 15),
                        label: Text(
                          text(
                            en: 'Why this facility?',
                            ta: 'இந்த மருத்துவமனை ஏன்?',
                            hi: 'यह सुविधा क्यों?',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),

                  // Detail arrow or direction icon
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (f.location.hasCoordinates)
                        IconButton(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          tooltip: text(en: 'Get Directions', ta: 'வழிகாட்டுதல்', hi: 'दिशा-निर्देश'),
                          onPressed: onGetDirections,
                          icon: const Icon(Icons.directions, color: Colors.teal, size: 20),
                        ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios, size: 13, color: Colors.grey),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(FacilityType type) {
    return switch (type) {
      FacilityType.hospital => Colors.red.shade700,
      FacilityType.communityHealthCentre => Colors.deepOrange,
      FacilityType.primaryHealthCentre => Colors.blue.shade700,
      FacilityType.clinic => Colors.teal.shade700,
      _ => Colors.indigo.shade600,
    };
  }

  String _typeLabel(FacilityType type) {
    return switch (type) {
      FacilityType.hospital => 'Hospital',
      FacilityType.communityHealthCentre => 'CHC',
      FacilityType.primaryHealthCentre => 'PHC',
      FacilityType.clinic => 'Clinic / HSC',
      _ => 'Healthcare',
    };
  }
}
