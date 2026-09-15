// Task 05D — Structured extraction warnings.
//
// Warnings describe extraction uncertainty or incompleteness. They are
// informational only and MUST NOT drive clinical safety decisions. A warning
// should prompt the application to request clarification — it never implies
// a clinical default value.
library;

/// A structured warning produced during extraction.
class ExtractionWarning {
  const ExtractionWarning({
    required this.code,
    required this.message,
    this.field,
  });

  /// Machine-readable code. See [ExtractionWarningCode] for built-in codes.
  /// Stable across releases so application code can react to specific
  /// warning types without brittle string parsing.
  final String code;

  /// Human-readable explanation. Never contains a clinical conclusion or
  /// recommendation.
  final String message;

  /// The name of the field this warning relates to, or `null` for
  /// session-level warnings (e.g. "overall low confidence").
  final String? field;

  factory ExtractionWarning.fromJson(Map<String, dynamic> json) {
    return ExtractionWarning(
      code: json['code'] as String? ?? 'unknown',
      message: json['message'] as String? ?? '',
      field: json['field'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'message': message,
        'field': field,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractionWarning &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          message == other.message &&
          field == other.field;

  @override
  int get hashCode => Object.hash(code, message, field);

  @override
  String toString() => 'ExtractionWarning(code: $code, field: $field)';
}

/// Built-in warning codes.
///
/// Use these constants rather than raw strings to avoid typos and enable
/// stable downstream matching.
class ExtractionWarningCode {
  const ExtractionWarningCode._();

  /// The symptom wording was ambiguous or unrecognized by the extractor.
  static const String ambiguousSymptom = 'ambiguous_symptom';

  /// Symptom severity was not explicitly stated in the input.
  static const String missingSeverity = 'missing_severity';

  /// Symptom duration was not explicitly stated in the input.
  static const String missingDuration = 'missing_duration';

  /// A phrase in the input was not recognized by the extractor.
  static const String unrecognizedPhrase = 'unrecognized_phrase';

  /// Overall extraction confidence is low.
  static const String lowConfidence = 'low_confidence';

  /// Patient context information was incomplete or failed validation.
  static const String incompleteContext = 'incomplete_context';

  /// The provider returned a field that is not in the supported schema.
  static const String unsupportedField = 'unsupported_field';
}
