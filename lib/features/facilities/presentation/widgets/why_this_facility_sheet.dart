// Task 10 - Why This Facility Sheet.
//
// Modal bottom sheet displaying structured, deterministic matching reasons
// directly from Task 09 FacilityMatchResult.
//
// CRITICAL INVARIANT:
// - Shows ONLY actual match reasons derived from confirmed data evidence.
// - Never displays fabricated clinical diagnoses or opaque ranking numbers alone.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/app_state.dart';
import '../../domain/facilities.dart';

class WhyThisFacilitySheet extends ConsumerWidget {
  const WhyThisFacilitySheet({
    super.key,
    required this.matchResult,
  });

  final FacilityMatchResult matchResult;

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

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.help_outline, color: Colors.blue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      text(
                        en: 'Why this facility?',
                        ta: 'இந்த மருத்துவமனை ஏன்?',
                        hi: 'यह सुविधा क्यों?',
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      f.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
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

          // Match Reasons List
          if (matchResult.matchReasons.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                text(
                  en: 'No specific matching evidence recorded.',
                  ta: 'குறிப்பிட்ட சான்றுகள் பதிவு செய்யப்படவில்லை.',
                  hi: 'कोई विशिष्ट मिलान साक्ष्य दर्ज नहीं है।',
                ),
                style: const TextStyle(color: Colors.grey),
              ),
            )
          else ...[
            Text(
              text(
                en: 'Clinical & Suitability Evidence:',
                ta: 'மருத்துவ & பொருத்தம் சான்றுகள்:',
                hi: 'चिकित्सीय एवं उपयुक्तता साक्ष्य:',
              ),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 10),
            ...matchResult.matchReasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Colors.teal,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        reason,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 12),
          // Provenance note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    f.provenance.isDemonstration
                        ? text(
                            en: 'Demonstration data for development and testing.',
                            ta: 'சோதனை மற்றும் பயிற்சிக்கான மாதிரி தரவு.',
                            hi: 'विकास और परीक्षण के लिए प्रदर्शन डेटा।',
                          )
                        : text(
                            en: 'Verified from National Health Mission (NHM) registry.',
                            ta: 'தேசிய சுகாதார இயக்கம் (NHM) பதிவேட்டில் சரிபார்க்கப்பட்டது.',
                            hi: 'राष्ट्रीय स्वास्थ्य मिशन (NHM) रजिस्ट्री से सत्यापित।',
                          ),
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(text(en: 'Close', ta: 'மூடு', hi: 'बंद करें')),
          ),
        ],
      ),
    );
  }
}
