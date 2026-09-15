import '../enums/next_action_type.dart';
import '../enums/triage_urgency.dart';

/// Placeholder representation of a future recommended next step.
///
/// This is a PLACEHOLDER DOMAIN MODEL only — Task 05A implements no
/// recommendation logic. Every [NextAction] created by this task has
/// [type] = [NextActionType.undetermined], [urgency] = `null`, and
/// [reason] = `null`. A future decision engine is responsible for
/// populating these.
class NextAction {
  const NextAction({
    this.type = NextActionType.undetermined,
    this.urgency,
    this.reason,
  });

  /// No next action has been determined yet.
  const NextAction.undetermined()
      : type = NextActionType.undetermined,
        urgency = null,
        reason = null;

  /// Category of the recommended next step. Always
  /// [NextActionType.undetermined] until a future decision engine sets it.
  final NextActionType type;

  /// Urgency associated with this next action, if determined.
  final TriageUrgency? urgency;

  /// Free-text reason for this next action, if determined. Not populated
  /// by anything in this task.
  final String? reason;

  factory NextAction.fromJson(Map<String, dynamic> json) {
    return NextAction(
      type: NextActionType.fromJson(json['type']),
      urgency: TriageUrgency.fromJson(json['urgency']),
      reason: json['reason'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.toJson(),
        'urgency': urgency?.toJson(),
        'reason': reason,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NextAction &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          urgency == other.urgency &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(type, urgency, reason);

  @override
  String toString() =>
      'NextAction(type: $type, urgency: $urgency, reason: $reason)';
}
