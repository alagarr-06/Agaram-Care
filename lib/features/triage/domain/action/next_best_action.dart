// Task 05F — Next Best Action domain model.
//
// Represents the recommended high-level next care action derived from a
// completed TriageResult disposition.
//
// SAFETY BOUNDARIES:
// - 05F recommends the next high-level care action ONLY.
// - It does NOT select a hospital or match facilities.
// - It does NOT book an appointment or conduct teleconsultation.
// - It does NOT create referrals or call emergency services.
// - It does NOT diagnose or prescribe treatment.
library;

import '../enums/next_action_type.dart';
import '../enums/triage_urgency.dart';
import '../triage_json_utils.dart';

/// Summarized high-level next care action for a patient triage progression.
class NextBestAction {
  const NextBestAction({
    required this.actionType,
    required this.urgency,
    required this.reason,
    required this.requiresFacilitySelection,
    required this.requiresAppointment,
    required this.requiresHumanReview,
    required this.generatedAt,
  });

  /// The high-level action pathway recommended.
  final NextActionType actionType;

  /// Urgency associated with this next action, if determined.
  final TriageUrgency? urgency;

  /// Deterministic, explainable rationale for this recommendation.
  /// Must be non-empty and must not contain clinical treatment instructions.
  final String reason;

  /// Flag indicating whether a downstream facility module must perform
  /// facility matching / selection.
  final bool requiresFacilitySelection;

  /// Flag indicating whether an appointment scheduling module must follow up.
  final bool requiresAppointment;

  /// Flag indicating whether a human healthcare worker (VHN or doctor) must review.
  final bool requiresHumanReview;

  /// Timestamp when this recommendation was computed.
  final DateTime generatedAt;

  // ---------------------------------------------------------------------------
  // JSON Serialization (Handwritten)
  // ---------------------------------------------------------------------------

  factory NextBestAction.fromJson(Map<String, dynamic> json) {
    final reason = json['reason'];
    if (reason is! String || reason.trim().isEmpty) {
      throw FormatException(
        'NextBestAction requires a non-empty reason string, got: $reason',
      );
    }

    final generatedAt = parseRequiredTimestamp(json['generatedAt'], 'generatedAt');

    return NextBestAction(
      actionType: NextActionType.fromJson(json['actionType']),
      urgency: TriageUrgency.fromJson(json['urgency']),
      reason: reason.trim(),
      requiresFacilitySelection: json['requiresFacilitySelection'] as bool? ?? false,
      requiresAppointment: json['requiresAppointment'] as bool? ?? false,
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? true,
      generatedAt: generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'actionType': actionType.toJson(),
        'urgency': urgency?.toJson(),
        'reason': reason,
        'requiresFacilitySelection': requiresFacilitySelection,
        'requiresAppointment': requiresAppointment,
        'requiresHumanReview': requiresHumanReview,
        'generatedAt': generatedAt.toIso8601String(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextBestAction &&
          runtimeType == other.runtimeType &&
          actionType == other.actionType &&
          urgency == other.urgency &&
          reason == other.reason &&
          requiresFacilitySelection == other.requiresFacilitySelection &&
          requiresAppointment == other.requiresAppointment &&
          requiresHumanReview == other.requiresHumanReview &&
          generatedAt == other.generatedAt;

  @override
  int get hashCode => Object.hash(
        actionType,
        urgency,
        reason,
        requiresFacilitySelection,
        requiresAppointment,
        requiresHumanReview,
        generatedAt,
      );

  @override
  String toString() =>
      'NextBestAction(actionType: $actionType, urgency: $urgency, '
      'requiresFacilitySelection: $requiresFacilitySelection, '
      'requiresAppointment: $requiresAppointment, '
      'requiresHumanReview: $requiresHumanReview)';
}
