import '../triage_json_utils.dart';

/// Small, prototype-safe context about the patient that may matter to a
/// future triage step. Every field is optional and self-/VHN-reported —
/// this is not a medical record, and no field here is inferred or
/// computed.
///
/// Deliberately kept small per Task 05A's scope: no speculative clinical
/// fields beyond what's explicitly asked for.
class PatientContext {
  PatientContext({
    int? ageYears,
    this.sex,
    this.pregnancyStatus,
    List<String> knownConditions = const [],
    List<String> currentMedications = const [],
    List<String> allergies = const [],
  })  : ageYears = validateAgeYears(ageYears),
        knownConditions = List.unmodifiable(knownConditions),
        currentMedications = List.unmodifiable(currentMedications),
        allergies = List.unmodifiable(allergies);

  /// Age in years, if reported. `null` if unknown. Validated only for
  /// structural plausibility (0–130) — see [validateAgeYears].
  final int? ageYears;

  /// Free-text sex/gender as reported. Intentionally a free string, not a
  /// closed enum, so this model doesn't impose categories on the patient.
  final String? sex;

  /// Whether the patient has reported being pregnant. `null` means
  /// unknown/not asked — not "no".
  final bool? pregnancyStatus;

  /// Conditions the patient has reported having (as reported, not a
  /// clinician-verified list).
  final List<String> knownConditions;

  /// Medications the patient has reported currently taking.
  final List<String> currentMedications;

  /// Allergies the patient has reported.
  final List<String> allergies;

  factory PatientContext.fromJson(Map<String, dynamic> json) {
    return PatientContext(
      ageYears: json['ageYears'] as int?,
      sex: json['sex'] as String?,
      pregnancyStatus: json['pregnancyStatus'] as bool?,
      knownConditions: readStringList(json['knownConditions']),
      currentMedications: readStringList(json['currentMedications']),
      allergies: readStringList(json['allergies']),
    );
  }

  Map<String, dynamic> toJson() => {
        'ageYears': ageYears,
        'sex': sex,
        'pregnancyStatus': pregnancyStatus,
        'knownConditions': knownConditions,
        'currentMedications': currentMedications,
        'allergies': allergies,
      };

  @override
  String toString() =>
      'PatientContext(ageYears: $ageYears, sex: $sex, '
      'pregnancyStatus: $pregnancyStatus)';
}
