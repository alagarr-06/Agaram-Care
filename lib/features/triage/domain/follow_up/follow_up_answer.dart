import '../enums/input_source.dart';
import '../triage_json_utils.dart';

/// A structured answer to a [FollowUpQuestion], carrying the raw value and
/// the exact input channel through which it was collected.
///
/// The application layer creates [FollowUpAnswer] objects after collecting
/// the patient's (or VHN's) response and passes them back so the engine can
/// re-evaluate the session. The engine never creates answers itself.
///
/// [inputSource] is preserved exactly — voice answers must remain
/// [InputSource.voice], quick-select answers must remain
/// [InputSource.quickSelect], and so on. This class never upgrades,
/// downgrades, or normalizes the source.
class FollowUpAnswer {
  FollowUpAnswer({
    required String questionId,
    required String value,
    required this.inputSource,
    required this.answeredAt,
  })  : questionId = requireNonEmpty(questionId, 'questionId'),
        value = _validateValue(value);

  /// Matches [FollowUpQuestion.id] — which question this answers.
  final String questionId;

  /// The raw answer value: `"yes"` / `"no"` for yes/no questions, the
  /// selected option text for single-choice, free text for text-type, or
  /// a numeric string for number-type. Always the patient/VHN's exact
  /// reported answer — never a default, never interpreted.
  final String value;

  /// The channel through which this answer was collected. One of
  /// [InputSource.voice], [InputSource.text], [InputSource.quickSelect],
  /// [InputSource.vhn]. Preserved exactly.
  final InputSource inputSource;

  /// When the answer was recorded. Required — an answer without a
  /// timestamp cannot be placed in the session timeline.
  final DateTime answeredAt;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  factory FollowUpAnswer.fromJson(Map<String, dynamic> json) {
    return FollowUpAnswer(
      questionId:
          requireNonEmpty(json['questionId'] as String? ?? '', 'questionId'),
      value: _validateValue(json['value'] as String? ?? ''),
      inputSource: InputSource.fromJson(json['inputSource']),
      answeredAt: parseRequiredTimestamp(json['answeredAt'], 'answeredAt'),
    );
  }

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'value': value,
        'inputSource': inputSource.toJson(),
        'answeredAt': answeredAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FollowUpAnswer &&
          runtimeType == other.runtimeType &&
          questionId == other.questionId &&
          value == other.value &&
          inputSource == other.inputSource &&
          answeredAt == other.answeredAt;

  @override
  int get hashCode => Object.hash(questionId, value, inputSource, answeredAt);

  @override
  String toString() =>
      'FollowUpAnswer(questionId: $questionId, value: $value, '
      'inputSource: $inputSource)';
}

String _validateValue(String value) {
  // An empty value is structurally invalid: an answer with no content is
  // not distinguishable from no answer at all, which could be confused
  // with "unknown". Throw early so this is caught at parse/construction
  // time, not silently treated as a valid "no" answer.
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, 'value', 'must not be empty');
  }
  return value;
}
