import 'follow_up_priority.dart';
import 'follow_up_response_type.dart';

/// A single follow-up question the engine may ask to resolve a missing
/// piece of safety-relevant information.
///
/// [questionText] is a map from language code (e.g. `"en"`, `"ta"`, `"hi"`)
/// to the question string in that language. [id] is always
/// language-independent so callers can track which question was asked across
/// language switches.
///
/// No medical logic lives here — this is a plain data carrier.
class FollowUpQuestion {
  const FollowUpQuestion({
    required this.id,
    required this.questionText,
    required this.priority,
    required this.responseType,
    this.options = const [],
    required this.target,
    this.relatedRuleId,
    this.requiredForSafety = false,
  });

  /// Language-independent stable identifier (e.g. `"chest_pain.breathing"`).
  /// Never changes once a question ships.
  final String id;

  /// Question text keyed by language code.
  final Map<String, String> questionText;

  /// How urgent it is to ask this question relative to others.
  final FollowUpPriority priority;

  /// What kind of answer this question expects (yes/no, choice, etc.).
  final FollowUpResponseType responseType;

  /// Options for [FollowUpResponseType.singleChoice] or
  /// [FollowUpResponseType.yesNo] questions. Empty for [text]/[number].
  final List<String> options;

  /// The structured-data field or concept this question is trying to
  /// resolve (e.g. `"breathingStatus"`). Used by the engine to decide
  /// whether the information is already present.
  final String target;

  /// The 05B red-flag rule whose [RedFlagRuleOutcome.insufficientInformation]
  /// result this question is designed to resolve. `null` if not tied to a
  /// specific rule.
  final String? relatedRuleId;

  /// Whether this question MUST be answered before the 05B engine can
  /// reach a confident safety conclusion.
  final bool requiredForSafety;

  // ---------------------------------------------------------------------------
  // Serialization
  // ---------------------------------------------------------------------------

  /// Constructs from JSON, validating structural correctness only.
  ///
  /// Throws [FormatException] / [ArgumentError] for missing/malformed
  /// required fields. Unknown enum values are handled safely in
  /// [FollowUpPriority.fromJson] and [FollowUpResponseType.fromJson].
  factory FollowUpQuestion.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? '';
    if (rawId.trim().isEmpty) {
      throw ArgumentError.value(rawId, 'id', 'must not be empty');
    }

    final rawText = json['questionText'];
    if (rawText is! Map) {
      throw FormatException(
        'FollowUpQuestion.questionText must be a map, got: $rawText',
      );
    }
    final textMap = <String, String>{};
    for (final e in rawText.entries) {
      if (e.key is String && e.value is String && (e.value as String).isNotEmpty) {
        textMap[e.key as String] = e.value as String;
      }
    }
    if (textMap.isEmpty) {
      throw ArgumentError.value(
        rawText,
        'questionText',
        'must contain at least one non-empty question string',
      );
    }

    final rawTarget = json['target'] as String? ?? '';
    if (rawTarget.trim().isEmpty) {
      throw ArgumentError.value(rawTarget, 'target', 'must not be empty');
    }

    final rawOptions = json['options'] as List<dynamic>? ?? [];
    return FollowUpQuestion(
      id: rawId,
      questionText: textMap,
      priority: FollowUpPriority.fromJson(json['priority']),
      responseType: FollowUpResponseType.fromJson(json['responseType']),
      options: [
        for (final o in rawOptions)
          if (o is String && o.isNotEmpty) o,
      ],
      target: rawTarget,
      relatedRuleId: json['relatedRuleId'] as String?,
      requiredForSafety: json['requiredForSafety'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'questionText': questionText,
        'priority': priority.toJson(),
        'responseType': responseType.toJson(),
        'options': options,
        'target': target,
        'relatedRuleId': relatedRuleId,
        'requiredForSafety': requiredForSafety,
      };

  // ---------------------------------------------------------------------------
  // Convenience
  // ---------------------------------------------------------------------------

  /// Returns the question text for [languageCode], falling back to English
  /// (`"en"`) if the requested language is not present, then to the first
  /// available entry.
  String textFor(String languageCode) {
    return questionText[languageCode] ??
        questionText['en'] ??
        (questionText.isEmpty ? '' : questionText.values.first);
  }

  @override
  String toString() =>
      'FollowUpQuestion(id: $id, priority: $priority, '
      'requiredForSafety: $requiredForSafety)';
}
