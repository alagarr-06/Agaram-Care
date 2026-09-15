import 'next_action.dart';
import 'patient_context.dart';
import 'patient_symptom.dart';
import '../enums/input_source.dart';
import '../enums/triage_urgency.dart';
import '../triage_json_utils.dart';

/// Root aggregate for a triage session: the structured-data foundation
/// that voice, typed text, quick-select, and VHN-assisted input all
/// converge into.
///
/// This class holds data only. It performs no AI symptom extraction, no
/// safety-rule evaluation, no urgency scoring, and recommends no next
/// action — [urgency] and [nextAction] exist only so a future engine has
/// somewhere to write its result.
class TriageSession {
  TriageSession({
    required String id,
    required String patientId,
    required this.languageCode,
    required this.createdAt,
    required this.inputSource,
    List<PatientSymptom> symptoms = const [],
    this.patientContext,
    this.urgency,
    this.nextAction = const NextAction.undetermined(),
  })  : id = requireNonEmpty(id, 'id'),
        patientId = requireNonEmpty(patientId, 'patientId'),
        symptoms = List.unmodifiable(symptoms);

  /// Unique identifier for this triage session.
  final String id;

  /// Reference to the patient this session belongs to. An ID/reference
  /// only — no patient identity data lives on this model.
  final String patientId;

  /// Language code the patient used for this session (`en`, `ta`, or
  /// `hi`). Preserved exactly as reported — never rewritten, translated,
  /// or normalized.
  final String languageCode;

  /// When this session was created.
  final DateTime createdAt;

  /// The input channel that initiated this session. Individual
  /// [PatientSymptom]/[AssociatedSymptom] entries carry their own
  /// [InputSource] too, since a session could in principle mix channels
  /// (e.g. started by voice, a later symptom added via quick-select).
  final InputSource inputSource;

  /// Structured symptom entries reported so far.
  final List<PatientSymptom> symptoms;

  /// Non-diagnostic patient context relevant to a future triage step.
  final PatientContext? patientContext;

  /// Session-level urgency. `null` until a future safety-rule engine sets
  /// it — nothing in this task computes it. See [TriageUrgency.fromJson]
  /// for why this is nullable rather than defaulted.
  final TriageUrgency? urgency;

  /// Reserved slot for a future next-best-action recommendation. Always
  /// [NextAction.undetermined] until a future decision engine sets it.
  final NextAction nextAction;

  /// Parses a [TriageSession] from JSON.
  ///
  /// Throws for missing/invalid required fields ([id], [patientId],
  /// [createdAt]).
  factory TriageSession.fromJson(Map<String, dynamic> json) {
    final rawSymptoms = json['symptoms'] as List<dynamic>? ?? [];

    return TriageSession(
      id: requireNonEmpty(json['id'] as String? ?? '', 'id'),
      patientId: requireNonEmpty(json['patientId'] as String? ?? '', 'patientId'),
      languageCode: json['languageCode'] as String? ?? 'en',
      createdAt: parseRequiredTimestamp(json['createdAt'], 'createdAt'),
      inputSource: InputSource.fromJson(json['inputSource']),
      symptoms: [
        for (final entry in rawSymptoms)
          PatientSymptom.fromJson(entry as Map<String, dynamic>),
      ],
      patientContext: json['patientContext'] == null
          ? null
          : PatientContext.fromJson(
              json['patientContext'] as Map<String, dynamic>,
            ),
      urgency: TriageUrgency.fromJson(json['urgency']),
      nextAction: json['nextAction'] == null
          ? const NextAction.undetermined()
          : NextAction.fromJson(json['nextAction'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        'languageCode': languageCode,
        'createdAt': createdAt.toIso8601String(),
        'inputSource': inputSource.toJson(),
        'symptoms': symptoms.map((s) => s.toJson()).toList(),
        'patientContext': patientContext?.toJson(),
        'urgency': urgency?.toJson(),
        'nextAction': nextAction.toJson(),
      };

  @override
  String toString() =>
      'TriageSession(id: $id, patientId: $patientId, '
      'symptoms: ${symptoms.length}, urgency: $urgency)';
}
