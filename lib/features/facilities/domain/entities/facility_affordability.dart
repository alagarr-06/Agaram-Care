// Task 08 - Agaram Care Facility Affordability & Insurance Entity.
library;

import '../facilities_json_utils.dart';

/// Healthcare schemes, subsidies, and affordability information.
///
/// Captures public insurance and welfare coverage without making speculative claims.
class FacilityAffordability {
  const FacilityAffordability({
    this.acceptsGovernmentSchemes = false,
    this.supportedSchemes = const [],
    this.isFreeCareAvailable,
    this.consultationFeeEstimate,
    this.pricingTier,
    this.insuranceNotes,
  });

  /// Whether the facility accepts public government welfare schemes (e.g. CMCHIS, PM-JAY).
  final bool acceptsGovernmentSchemes;

  /// List of scheme codes/names accepted (e.g. ['CMCHIS', 'AB-PMJAY', 'ESI']).
  final List<String> supportedSchemes;

  /// Whether completely free consultations/treatment are provided (e.g. Government PHC/GH).
  /// `null` means unknown/unverified.
  final bool? isFreeCareAvailable;

  /// Estimated baseline out-of-pocket consultation fee string if published (e.g. "Free", "Rs. 200-300").
  final String? consultationFeeEstimate;

  /// Descriptive pricing bracket (e.g. "government_free", "subsidized", "standard", "tertiary_private").
  final String? pricingTier;

  /// Remarks regarding payment, co-pay, or eligibility documentation.
  final String? insuranceNotes;

  factory FacilityAffordability.fromJson(Map<String, dynamic> json) {
    return FacilityAffordability(
      acceptsGovernmentSchemes: json['acceptsGovernmentSchemes'] as bool? ?? false,
      supportedSchemes: readStringList(json['supportedSchemes']),
      isFreeCareAvailable: json['isFreeCareAvailable'] as bool?,
      consultationFeeEstimate: json['consultationFeeEstimate'] as String?,
      pricingTier: json['pricingTier'] as String?,
      insuranceNotes: json['insuranceNotes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'acceptsGovernmentSchemes': acceptsGovernmentSchemes,
    'supportedSchemes': supportedSchemes,
    if (isFreeCareAvailable != null) 'isFreeCareAvailable': isFreeCareAvailable,
    if (consultationFeeEstimate != null) 'consultationFeeEstimate': consultationFeeEstimate,
    if (pricingTier != null) 'pricingTier': pricingTier,
    if (insuranceNotes != null) 'insuranceNotes': insuranceNotes,
  };
}
