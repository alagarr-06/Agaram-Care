import '../enums/input_source.dart';
import '../enums/symptom_severity.dart';
import '../triage_json_utils.dart';

/// A symptom reported alongside the main [PatientSymptom] — e.g. "fever"
/// with an associated symptom of "chills".
///
/// Severity and duration are nullable by design: an associated symptom is
/// often mentioned without either being specified, and this model must
/// never invent a value the patient didn't report.
class AssociatedSymptom {
  AssociatedSymptom({
    required String symptomName,
    required this.inputSource,
    this.severity,
    this.duration,
  }) : symptomName = requireNonEmpty(symptomName, 'symptomName');

  /// Name of the associated symptom, in whatever language it was reported.
  /// Never translated or normalized.
  final String symptomName;

  /// Self-/VHN-reported severity, if given. `null` means not reported —
  /// see [SymptomSeverity.fromJson] for why this is never guessed.
  final SymptomSeverity? severity;

  /// How long this symptom has been present, exactly as reported (e.g.
  /// "2 days", "இரண்டு நாட்கள்"). Free text, not normalized/parsed —
  /// keeping it a plain string avoids inventing structure this task
  /// wasn't asked to define.
  final String? duration;

  /// Which input channel this specific associated symptom was captured
  /// through (may differ from the primary symptom's channel).
  final InputSource inputSource;

  factory AssociatedSymptom.fromJson(Map<String, dynamic> json) {
    return AssociatedSymptom(
      symptomName:
          requireNonEmpty(json['symptomName'] as String? ?? '', 'symptomName'),
      inputSource: InputSource.fromJson(json['inputSource']),
      severity: SymptomSeverity.fromJson(json['severity']),
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'symptomName': symptomName,
        'inputSource': inputSource.toJson(),
        'severity': severity?.toJson(),
        'duration': duration,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssociatedSymptom &&
          runtimeType == other.runtimeType &&
          symptomName == other.symptomName &&
          inputSource == other.inputSource &&
          severity == other.severity &&
          duration == other.duration;

  @override
  int get hashCode =>
      Object.hash(symptomName, inputSource, severity, duration);

  @override
  String toString() =>
      'AssociatedSymptom(symptomName: $symptomName, severity: $severity, '
      'duration: $duration, inputSource: $inputSource)';
}
