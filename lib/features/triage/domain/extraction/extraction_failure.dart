// Task 05D — Structured extraction failure types.
//
// Failures are infrastructure events (network down, bad provider response).
// They carry NO clinical information.
library;

/// Why an extraction operation failed.
///
/// All reasons describe infrastructure or provider problems, not patient
/// conditions. A failed extraction never implies anything about a patient's
/// safety or health state.
enum ExtractionFailureReason {
  /// The extraction provider was unreachable (network error, service down).
  providerUnavailable,

  /// The provider responded but the response was not a valid extraction.
  invalidProviderResponse,

  /// The provider response could not be parsed as the expected schema.
  malformedOutput,

  /// The language code is not supported by the current provider.
  unsupportedLanguage,

  /// The operation did not complete within the expected time.
  timeout,

  /// An unclassified failure.
  unknown;

  String toJson() => name;

  /// Safe fallback: unrecognized values map to [unknown].
  static ExtractionFailureReason fromJson(Object? value) {
    for (final r in ExtractionFailureReason.values) {
      if (r.name == value) return r;
    }
    return ExtractionFailureReason.unknown;
  }
}

/// Structured description of an extraction failure.
///
/// Present in [ExtractionResult] when extraction did not succeed. Never
/// carries clinical information — it is an infrastructure record only.
class ExtractionFailure {
  const ExtractionFailure({
    required this.reason,
    required this.message,
    this.rawProviderOutput,
  });

  /// Categorized reason for the failure.
  final ExtractionFailureReason reason;

  /// Human-readable description for developer/support logs.
  /// Must not be displayed directly to patients or VHNs.
  final String message;

  /// The raw provider output that triggered the failure, for debugging.
  /// Never displayed to patients or VHNs.
  final String? rawProviderOutput;

  factory ExtractionFailure.fromJson(Map<String, dynamic> json) {
    return ExtractionFailure(
      reason: ExtractionFailureReason.fromJson(json['reason']),
      message: json['message'] as String? ?? 'Unknown failure.',
      rawProviderOutput: json['rawProviderOutput'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'reason': reason.toJson(),
        'message': message,
        'rawProviderOutput': rawProviderOutput,
      };

  @override
  String toString() =>
      'ExtractionFailure(reason: $reason, message: $message)';
}
