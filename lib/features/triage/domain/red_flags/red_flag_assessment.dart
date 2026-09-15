import '../enums/triage_urgency.dart';

/// Record of one rule that fired, with everything needed to explain why to
/// a patient/VHN/doctor view.
class TriggeredRedFlagRule {
  const TriggeredRedFlagRule({
    required this.ruleId,
    required this.reason,
    required this.urgency,
  });

  /// Stable rule identifier — see [RedFlagRule.id].
  final String ruleId;

  /// Human-readable explanation of why this rule fired.
  final String reason;

  /// Urgency this specific rule resulted in.
  final TriageUrgency urgency;

  factory TriggeredRedFlagRule.fromJson(Map<String, dynamic> json) {
    final urgency = TriageUrgency.fromJson(json['urgency']);
    if (urgency == null) {
      // urgency is required for a triggered rule — an unparseable value
      // here means corrupted data, not "no urgency". Throwing surfaces
      // that loudly instead of silently inventing a clinical judgment.
      throw FormatException(
        'TriggeredRedFlagRule requires a valid urgency, got: '
        '${json['urgency']}',
      );
    }
    return TriggeredRedFlagRule(
      ruleId: json['ruleId'] as String,
      reason: json['reason'] as String,
      urgency: urgency,
    );
  }

  Map<String, dynamic> toJson() => {
        'ruleId': ruleId,
        'reason': reason,
        'urgency': urgency.toJson(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TriggeredRedFlagRule &&
          runtimeType == other.runtimeType &&
          ruleId == other.ruleId &&
          reason == other.reason &&
          urgency == other.urgency;

  @override
  int get hashCode => Object.hash(ruleId, reason, urgency);

  @override
  String toString() =>
      'TriggeredRedFlagRule(ruleId: $ruleId, urgency: $urgency)';
}

/// The explainable output of running [RedFlagEngine] against a
/// [TriageSession].
///
/// This is a safety-gate result, not a diagnosis: it never says what is
/// wrong with the patient, only whether known high-confidence red flags
/// were matched and whether the available data is sufficient to be
/// confident nothing was missed.
class RedFlagAssessment {
  const RedFlagAssessment({
    required this.hasRedFlag,
    required this.urgency,
    required this.triggeredRules,
    required this.reasons,
    required this.requiresHumanReview,
    required this.missingSafetyInformation,
  });

  /// Whether at least one rule triggered with high confidence.
  final bool hasRedFlag;

  /// Highest urgency among [triggeredRules], or `null` if none triggered.
  /// Never a "guessed" value — see [TriageUrgency.fromJson] for why this
  /// type has no neutral member to fall back to.
  final TriageUrgency? urgency;

  /// Every rule that fired, in the order the engine evaluated them.
  final List<TriggeredRedFlagRule> triggeredRules;

  /// Convenience flattened list of [TriggeredRedFlagRule.reason] strings,
  /// for callers that just want to display "why" without walking
  /// [triggeredRules] themselves. Does not include
  /// [missingSafetyInformation] notes — those are kept separate since they
  /// represent uncertainty, not a confirmed reason for escalation.
  final List<String> reasons;

  /// True whenever this result should be seen by a human (VHN/clinician)
  /// before being acted on — true for any emergency/urgent trigger, and
  /// also true whenever [missingSafetyInformation] is non-empty, since an
  /// uncertain case must not be silently treated as resolved.
  final bool requiresHumanReview;

  /// Notes describing safety-relevant information that is missing/unknown
  /// and therefore prevented a rule from reaching a confident conclusion.
  /// A non-empty list here does NOT mean the session is unsafe — it means
  /// the engine cannot yet say either way, which is why
  /// [requiresHumanReview] is also true in that case.
  final List<String> missingSafetyInformation;

  factory RedFlagAssessment.fromJson(Map<String, dynamic> json) {
    final rawTriggered = json['triggeredRules'] as List<dynamic>? ?? [];
    return RedFlagAssessment(
      hasRedFlag: json['hasRedFlag'] as bool? ?? false,
      urgency: TriageUrgency.fromJson(json['urgency']),
      triggeredRules: [
        for (final entry in rawTriggered)
          TriggeredRedFlagRule.fromJson(entry as Map<String, dynamic>),
      ],
      reasons: [
        for (final r in (json['reasons'] as List<dynamic>? ?? []))
          r as String,
      ],
      requiresHumanReview: json['requiresHumanReview'] as bool? ?? true,
      missingSafetyInformation: [
        for (final m
            in (json['missingSafetyInformation'] as List<dynamic>? ?? []))
          m as String,
      ],
    );
  }

  Map<String, dynamic> toJson() => {
        'hasRedFlag': hasRedFlag,
        'urgency': urgency?.toJson(),
        'triggeredRules': triggeredRules.map((r) => r.toJson()).toList(),
        'reasons': reasons,
        'requiresHumanReview': requiresHumanReview,
        'missingSafetyInformation': missingSafetyInformation,
      };

  @override
  String toString() =>
      'RedFlagAssessment(hasRedFlag: $hasRedFlag, urgency: $urgency, '
      'triggeredRules: ${triggeredRules.length}, '
      'requiresHumanReview: $requiresHumanReview, '
      'missingSafetyInformation: ${missingSafetyInformation.length})';
}
