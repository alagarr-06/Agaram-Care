import '../entities/triage_session.dart';
import '../enums/triage_urgency.dart';
import 'red_flag_assessment.dart';
import 'red_flag_rule.dart';
import 'red_flag_rules.dart';

/// Evaluates a [TriageSession] against a fixed, ordered set of
/// [RedFlagRule]s and aggregates the results into one explainable
/// [RedFlagAssessment].
///
/// This is a deterministic safety gate: the same session always produces
/// the same assessment, and every escalation is traceable back to a named
/// rule with a human-readable reason. It performs no diagnosis, no
/// treatment recommendation, and no next-best-action selection.
class RedFlagEngine {
  const RedFlagEngine([List<RedFlagRule>? rules])
      : rules = rules ?? defaultRedFlagRules;

  /// Rules this engine evaluates, in the order they run. Defaults to
  /// [defaultRedFlagRules]; a different/smaller list can be injected for
  /// testing or staged rollout.
  final List<RedFlagRule> rules;

  RedFlagAssessment assess(TriageSession session) {
    final triggered = <TriggeredRedFlagRule>[];
    final missingInfo = <String>[];

    for (final rule in rules) {
      final result = rule.evaluate(session);
      switch (result.outcome) {
        case RedFlagRuleOutcome.triggered:
          triggered.add(
            TriggeredRedFlagRule(
              ruleId: rule.id,
              reason: result.reason!,
              urgency: result.urgency!,
            ),
          );
          break;
        case RedFlagRuleOutcome.insufficientInformation:
          missingInfo.add(result.reason!);
          break;
        case RedFlagRuleOutcome.notTriggered:
          break;
      }
    }

    final hasRedFlag = triggered.isNotEmpty;
    final urgency = hasRedFlag ? _highestUrgency(triggered) : null;

    // Any confirmed emergency/urgent trigger needs a human to see it — and
    // so does an uncertain case where information was missing, since an
    // unresolved unknown must never be treated as equivalent to "safe".
    final requiresHumanReview = triggered.any(
          (t) =>
              t.urgency == TriageUrgency.emergency ||
              t.urgency == TriageUrgency.urgent,
        ) ||
        missingInfo.isNotEmpty;

    return RedFlagAssessment(
      hasRedFlag: hasRedFlag,
      urgency: urgency,
      triggeredRules: triggered,
      reasons: [for (final t in triggered) t.reason],
      requiresHumanReview: requiresHumanReview,
      missingSafetyInformation: missingInfo,
    );
  }

  TriageUrgency _highestUrgency(List<TriggeredRedFlagRule> triggered) {
    return triggered
        .map((t) => t.urgency)
        .reduce((a, b) => _rank(a) >= _rank(b) ? a : b);
  }

  static int _rank(TriageUrgency urgency) => switch (urgency) {
        TriageUrgency.routine => 0,
        TriageUrgency.soon => 1,
        TriageUrgency.urgent => 2,
        TriageUrgency.emergency => 3,
      };
}
