// Task 05D — Extraction confidence types.
//
// Confidence is an extraction quality signal ONLY.
// It MUST NOT drive clinical safety decisions.
// Low confidence means "we don't know enough" — never "safe to ignore".
library;

/// Granularity of extraction confidence.
enum ExtractionConfidenceLevel {
  /// Key fields were present and unambiguous.
  high,

  /// Some information was present but one or more fields were ambiguous,
  /// inferred from context, or could not be confirmed by the extractor.
  medium,

  /// Extraction quality is poor: input was unrecognized, key fields are
  /// missing, or the structured output is unreliable.
  ///
  /// The application MUST NOT interpret low confidence as "safe". It should
  /// request clarification via 05C follow-up questions or human review.
  low;

  String toJson() => name;

  /// Parses [value] into an [ExtractionConfidenceLevel].
  ///
  /// Unknown / missing values fall back to [low] — the conservative choice.
  /// An unrecognized confidence must never be silently promoted to high.
  static ExtractionConfidenceLevel fromJson(Object? value) {
    for (final level in ExtractionConfidenceLevel.values) {
      if (level.name == value) return level;
    }
    return ExtractionConfidenceLevel.low;
  }
}

/// Structured confidence information attached to an [ExtractionResult].
class ExtractionConfidence {
  const ExtractionConfidence({required this.overall});
  const ExtractionConfidence.high()
      : overall = ExtractionConfidenceLevel.high;
  const ExtractionConfidence.medium()
      : overall = ExtractionConfidenceLevel.medium;
  const ExtractionConfidence.low()
      : overall = ExtractionConfidenceLevel.low;

  /// Overall extraction confidence level.
  final ExtractionConfidenceLevel overall;

  factory ExtractionConfidence.fromJson(Map<String, dynamic> json) {
    return ExtractionConfidence(
      overall: ExtractionConfidenceLevel.fromJson(json['overall']),
    );
  }

  Map<String, dynamic> toJson() => {'overall': overall.toJson()};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExtractionConfidence &&
          runtimeType == other.runtimeType &&
          overall == other.overall;

  @override
  int get hashCode => overall.hashCode;

  @override
  String toString() => 'ExtractionConfidence(overall: $overall)';
}
