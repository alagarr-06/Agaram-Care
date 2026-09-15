import 'associated_symptom.dart';
import '../enums/input_source.dart';
import '../enums/symptom_severity.dart';
import '../triage_json_utils.dart';

/// The main symptom a patient reports in a [TriageSession].
///
/// Voice, typed text, quick-select, and VHN-assisted entry must all be
/// able to produce a [PatientSymptom] with this same shape — nothing that
/// consumes this class should need to know which channel produced it.
class PatientSymptom {
  PatientSymptom({
    required String symptomName,
    required this.inputSource,
    this.severity,
    this.duration,
    List<AssociatedSymptom> associatedSymptoms = const [],
  })  : symptomName = requireNonEmpty(symptomName, 'symptomName'),
        associatedSymptoms = List.unmodifiable(associatedSymptoms);

  /// Symptom name, in whatever language it was reported. Never translated
  /// or normalized.
  final String symptomName;

  /// Self-/VHN-reported severity, if given. `null` means not reported.
  final SymptomSeverity? severity;

  /// How long this symptom has been present, exactly as reported. Free
  /// text — see [AssociatedSymptom.duration] for why this stays a plain
  /// string rather than a parsed structure.
  final String? duration;

  /// Which input channel produced this entry.
  final InputSource inputSource;

  /// Other symptoms reported alongside this one.
  final List<AssociatedSymptom> associatedSymptoms;

  factory PatientSymptom.fromJson(Map<String, dynamic> json) {
    final rawAssociated = json['associatedSymptoms'] as List<dynamic>? ?? [];

    return PatientSymptom(
      symptomName:
          requireNonEmpty(json['symptomName'] as String? ?? '', 'symptomName'),
      inputSource: InputSource.fromJson(json['inputSource']),
      severity: SymptomSeverity.fromJson(json['severity']),
      duration: json['duration'] as String?,
      associatedSymptoms: [
        for (final entry in rawAssociated)
          AssociatedSymptom.fromJson(entry as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'symptomName': symptomName,
        'inputSource': inputSource.toJson(),
        'severity': severity?.toJson(),
        'duration': duration,
        'associatedSymptoms':
            associatedSymptoms.map((s) => s.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PatientSymptom &&
          runtimeType == other.runtimeType &&
          symptomName == other.symptomName &&
          inputSource == other.inputSource &&
          severity == other.severity &&
          duration == other.duration &&
          _listEquals(associatedSymptoms, other.associatedSymptoms);

  @override
  int get hashCode => Object.hash(
        symptomName,
        inputSource,
        severity,
        duration,
        Object.hashAll(associatedSymptoms),
      );

  @override
  String toString() =>
      'PatientSymptom(symptomName: $symptomName, severity: $severity, '
      'inputSource: $inputSource, associatedSymptoms: '
      '${associatedSymptoms.length})';
}

bool _listEquals(List<AssociatedSymptom> a, List<AssociatedSymptom> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
