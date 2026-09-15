// Task 05E — Triage Result / Disposition domain model.
//
// Represents the summarized disposition of a triage assessment.
//
// SAFETY BOUNDARIES:
// - TriageResult summarizes the current triage state ONLY.
// - It does NOT diagnose, prescribe, recommend medications, or select hospitals.
// - It does NOT create referrals, book appointments, or call emergency services.
// - Safety decisions originate in 05B; follow-up requirements in 05C.
library;

import '../enums/triage_urgency.dart';
import '../triage_json_utils.dart';
import 'triage_disposition_state.dart';

/// Summarized disposition result of a triage progression.
class TriageResult {
  const TriageResult({
    required this.sourceSessionId,
    required this.urgency,
    required this.state,
    required this.title,
    required this.explanation,
    required this.needsFollowUp,
    required this.requiresHumanReview,
    required this.triggeredRuleIds,
    required this.completedAt,
    this.pendingQuestionId,
    this.reasons = const [],
    this.notes = const [],
  });

  /// The identifier of the [TriageSession] this result was computed for.
  final String sourceSessionId;

  /// Clinical urgency classification.
  ///
  /// `null` means "not yet assessed" or "cannot be determined safely due to
  /// missing information". It is never a guessed value.
  final TriageUrgency? urgency;

  /// High-level disposition state for presentation and flow control.
  final TriageDispositionState state;

  /// Concise user-facing headline suitable for Patient, VHN, and Doctor UIs.
  final String title;

  /// Plain-language explanation of why this disposition was reached.
  final String explanation;

  /// Whether dynamic follow-up questions (05C) or clarifications are still required.
  final bool needsFollowUp;

  /// Whether a human healthcare worker (VHN or clinician) must review this assessment.
  final bool requiresHumanReview;

  /// IDs of any 05B safety rules that fired (e.g. 'chest_pain_or_pressure').
  final List<String> triggeredRuleIds;

  /// When this disposition was generated.
  final DateTime completedAt;

  /// The ID of the specific follow-up question currently recommended by 05C, if any.
  final String? pendingQuestionId;

  /// Explanations or clinical rationales carried from 05B triggered rules.
  final List<String> reasons;

  /// Informational notes or missing safety information notes.
  final List<String> notes;

  // ---------------------------------------------------------------------------
  // JSON Serialization (Handwritten)
  // ---------------------------------------------------------------------------

  factory TriageResult.fromJson(Map<String, dynamic> json) {
    final sourceSessionId = json['sourceSessionId'];
    if (sourceSessionId is! String || sourceSessionId.trim().isEmpty) {
      throw FormatException(
        'TriageResult requires a valid sourceSessionId string, got: $sourceSessionId',
      );
    }

    final title = json['title'] as String? ?? '';
    final explanation = json['explanation'] as String? ?? '';
    final completedAt = parseRequiredTimestamp(json['completedAt'], 'completedAt');

    final rawRules = json['triggeredRuleIds'] as List<dynamic>? ?? [];
    final rawReasons = json['reasons'] as List<dynamic>? ?? [];
    final rawNotes = json['notes'] as List<dynamic>? ?? [];

    return TriageResult(
      sourceSessionId: sourceSessionId,
      urgency: TriageUrgency.fromJson(json['urgency']),
      state: json.containsKey('state')
          ? TriageDispositionState.fromJson(json['state'])
          : TriageDispositionState.humanReview,
      title: title,
      explanation: explanation,
      needsFollowUp: json['needsFollowUp'] as bool? ?? false,
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? true,
      triggeredRuleIds: [for (final r in rawRules) if (r is String) r],
      completedAt: completedAt,
      pendingQuestionId: json['pendingQuestionId'] as String?,
      reasons: [for (final r in rawReasons) if (r is String) r],
      notes: [for (final n in rawNotes) if (n is String) n],
    );
  }

  Map<String, dynamic> toJson() => {
        'sourceSessionId': sourceSessionId,
        'urgency': urgency?.toJson(),
        'state': state.toJson(),
        'title': title,
        'explanation': explanation,
        'needsFollowUp': needsFollowUp,
        'requiresHumanReview': requiresHumanReview,
        'triggeredRuleIds': triggeredRuleIds,
        'completedAt': completedAt.toIso8601String(),
        'pendingQuestionId': pendingQuestionId,
        'reasons': reasons,
        'notes': notes,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriageResult &&
          runtimeType == other.runtimeType &&
          sourceSessionId == other.sourceSessionId &&
          urgency == other.urgency &&
          state == other.state &&
          title == other.title &&
          explanation == other.explanation &&
          needsFollowUp == other.needsFollowUp &&
          requiresHumanReview == other.requiresHumanReview &&
          _listEquals(triggeredRuleIds, other.triggeredRuleIds) &&
          completedAt == other.completedAt &&
          pendingQuestionId == other.pendingQuestionId &&
          _listEquals(reasons, other.reasons) &&
          _listEquals(notes, other.notes);

  @override
  int get hashCode => Object.hash(
        sourceSessionId,
        urgency,
        state,
        title,
        explanation,
        needsFollowUp,
        requiresHumanReview,
        Object.hashAll(triggeredRuleIds),
        completedAt,
        pendingQuestionId,
        Object.hashAll(reasons),
        Object.hashAll(notes),
      );

  @override
  String toString() =>
      'TriageResult(sourceSessionId: $sourceSessionId, urgency: $urgency, '
      'state: $state, needsFollowUp: $needsFollowUp, '
      'requiresHumanReview: $requiresHumanReview)';
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
