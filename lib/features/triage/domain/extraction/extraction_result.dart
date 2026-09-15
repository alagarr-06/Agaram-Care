// Task 05D — Extraction result and TriageSession bridge.
//
// ExtractionResult is the OUTPUT of the AI extraction layer.
// It carries structured facts extracted from raw patient input.
//
// SAFETY BOUNDARY:
// - ExtractionResult contains ONLY patient-reported facts.
// - ExtractionResult does NOT contain urgency, diagnosis, treatment,
//   or prescription.
// - Safety decisions are made by the 05B RedFlagEngine after this result
//   is mapped to a TriageSession.
library;

import '../entities/patient_context.dart';
import '../entities/patient_symptom.dart';
import '../entities/triage_session.dart';
import '../enums/input_source.dart';
import 'extraction_confidence.dart';
import 'extraction_failure.dart';
import 'extraction_warning.dart';

/// The output of [SymptomExtractionService.extract].
///
/// ## Invariants
/// - [rawInput] is always the EXACT original input string, never mutated.
/// - [isSuccessful] is `true` when [failure] is `null`.
/// - [symptoms] and [warnings] are always non-null, unmodifiable lists.
/// - When [isSuccessful] is `false`, [symptoms] is empty and
///   [patientContext] is `null` — no partial facts from a failed extraction
///   should be used as if they were valid.
///
/// ## What this does NOT contain
/// - No urgency, no diagnosis, no treatment, no recommendation.
/// - No clinical conclusion of any kind.
class ExtractionResult {
  ExtractionResult({
    required this.rawInput,
    required this.languageCode,
    required this.inputSource,
    required List<PatientSymptom> symptoms,
    this.patientContext,
    required this.confidence,
    required List<ExtractionWarning> warnings,
    this.failure,
  })  : symptoms = List.unmodifiable(symptoms),
        warnings = List.unmodifiable(warnings);

  /// The original, unmodified patient/VHN input.
  ///
  /// Preserved exactly for human review, auditing, and future re-processing.
  /// Never replaced with normalized or translated text.
  final String rawInput;

  /// BCP-47 language code supplied by the caller (e.g. "en", "ta", "hi").
  final String languageCode;

  /// Which input channel produced [rawInput].
  final InputSource inputSource;

  /// Structured symptoms extracted from [rawInput].
  ///
  /// Contains only information EXPLICITLY stated or reasonably represented
  /// by the patient's words. The extractor must never invent missing fields.
  final List<PatientSymptom> symptoms;

  /// Patient context extracted from [rawInput], or `null` if none was
  /// stated.
  final PatientContext? patientContext;

  /// Confidence in the quality of this extraction.
  ///
  /// Low confidence MUST NOT be treated as safe. It means "more information
  /// is needed", not "the patient is fine".
  final ExtractionConfidence confidence;

  /// Informational warnings about this extraction.
  ///
  /// Warnings MUST NOT drive clinical safety decisions. They indicate
  /// uncertainty or ambiguity that should be resolved via 05C follow-up
  /// questions or human review.
  final List<ExtractionWarning> warnings;

  /// Failure detail, or `null` if extraction succeeded.
  final ExtractionFailure? failure;

  /// `true` when extraction completed and [symptoms] may be used.
  bool get isSuccessful => failure == null;

  // ---------------------------------------------------------------------------
  // Named factories
  // ---------------------------------------------------------------------------

  /// Creates a successful extraction result.
  factory ExtractionResult.success({
    required String rawInput,
    required String languageCode,
    required InputSource inputSource,
    List<PatientSymptom> symptoms = const [],
    PatientContext? patientContext,
    ExtractionConfidence confidence = const ExtractionConfidence.medium(),
    List<ExtractionWarning> warnings = const [],
  }) {
    return ExtractionResult(
      rawInput: rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
      symptoms: symptoms,
      patientContext: patientContext,
      confidence: confidence,
      warnings: warnings,
      failure: null,
    );
  }

  /// Creates a failed extraction result. [symptoms] will be empty and
  /// [patientContext] will be null — no partial data from a failed
  /// extraction should propagate as valid facts.
  factory ExtractionResult.failure({
    required String rawInput,
    required String languageCode,
    required InputSource inputSource,
    required ExtractionFailure failure,
  }) {
    return ExtractionResult(
      rawInput: rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
      symptoms: const [],
      patientContext: null,
      confidence: const ExtractionConfidence.low(),
      warnings: const [],
      failure: failure,
    );
  }

  // ---------------------------------------------------------------------------
  // JSON serialization (handwritten — no code generation)
  // ---------------------------------------------------------------------------

  factory ExtractionResult.fromJson(Map<String, dynamic> json) {
    final rawInput = json['rawInput'];
    if (rawInput is! String) {
      throw FormatException(
        'ExtractionResult: rawInput must be a non-null String, got: $rawInput',
      );
    }
    final rawSymptoms = json['symptoms'] as List<dynamic>? ?? [];
    final rawWarnings = json['warnings'] as List<dynamic>? ?? [];

    return ExtractionResult(
      rawInput: rawInput,
      languageCode: json['languageCode'] as String? ?? 'en',
      inputSource: InputSource.fromJson(json['inputSource']),
      symptoms: [
        for (final s in rawSymptoms)
          PatientSymptom.fromJson(s as Map<String, dynamic>),
      ],
      patientContext: json['patientContext'] == null
          ? null
          : PatientContext.fromJson(
              json['patientContext'] as Map<String, dynamic>),
      confidence: json['confidence'] == null
          ? const ExtractionConfidence.medium()
          : ExtractionConfidence.fromJson(
              json['confidence'] as Map<String, dynamic>),
      warnings: [
        for (final w in rawWarnings)
          ExtractionWarning.fromJson(w as Map<String, dynamic>),
      ],
      failure: json['failure'] == null
          ? null
          : ExtractionFailure.fromJson(
              json['failure'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'rawInput': rawInput,
        'languageCode': languageCode,
        'inputSource': inputSource.toJson(),
        'symptoms': symptoms.map((s) => s.toJson()).toList(),
        'patientContext': patientContext?.toJson(),
        'confidence': confidence.toJson(),
        'warnings': warnings.map((w) => w.toJson()).toList(),
        'failure': failure?.toJson(),
      };

  // ---------------------------------------------------------------------------
  // Bridge to TriageSession (05A)
  // ---------------------------------------------------------------------------

  /// Maps this result to a [TriageSession] so the 05B safety engine and
  /// 05C follow-up engine can process it.
  ///
  /// Callers must provide [sessionId], [patientId], and [createdAt] because
  /// these are application-layer concerns, not facts the extractor can know.
  ///
  /// Only call this when [isSuccessful] is `true`; the application should
  /// handle failed extractions separately (fallback UI, manual entry, etc.).
  TriageSession toTriageSession({
    required String sessionId,
    required String patientId,
    required DateTime createdAt,
  }) {
    return TriageSession(
      id: sessionId,
      patientId: patientId,
      languageCode: languageCode,
      createdAt: createdAt,
      inputSource: inputSource,
      symptoms: symptoms,
      patientContext: patientContext,
    );
  }

  @override
  String toString() =>
      'ExtractionResult(isSuccessful: $isSuccessful, '
      'symptoms: ${symptoms.length}, '
      'confidence: ${confidence.overall}, '
      'languageCode: $languageCode)';
}
