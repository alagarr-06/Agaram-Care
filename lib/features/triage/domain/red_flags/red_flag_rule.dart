import '../entities/triage_session.dart';
import '../enums/triage_urgency.dart';

/// Result of evaluating one [RedFlagRule] against one session.
enum RedFlagRuleOutcome {
  /// The rule found nothing relevant — this says nothing about safety on
  /// its own, only that this particular rule has no concern to raise.
  notTriggered,

  /// The rule found a clear, high-confidence match for its red flag.
  triggered,

  /// The rule found a partial signal (e.g. a concerning symptom was
  /// reported) but cannot reach a confident conclusion because supporting
  /// information is missing/unknown. This is deliberately distinct from
  /// [notTriggered]: unknown information must never be read as "safe".
  insufficientInformation,
}

/// The outcome of evaluating a single [RedFlagRule].
///
/// Exactly one of the three named constructors should be used to build
/// this — they enforce which fields are required for each outcome
/// ([reason] and [urgency] for [triggered]; [reason] only for
/// [insufficientInformation]; neither for [notTriggered]).
class RedFlagRuleEvaluation {
  const RedFlagRuleEvaluation.notTriggered()
      : outcome = RedFlagRuleOutcome.notTriggered,
        reason = null,
        urgency = null;

  const RedFlagRuleEvaluation.triggered({
    required this.reason,
    required this.urgency,
  }) : outcome = RedFlagRuleOutcome.triggered;

  const RedFlagRuleEvaluation.insufficientInformation({
    required this.reason,
  })  : outcome = RedFlagRuleOutcome.insufficientInformation,
        urgency = null;

  final RedFlagRuleOutcome outcome;

  /// Human-readable explanation. Non-null whenever [outcome] is
  /// [RedFlagRuleOutcome.triggered] or
  /// [RedFlagRuleOutcome.insufficientInformation].
  final String? reason;

  /// Resulting urgency. Non-null only when [outcome] is
  /// [RedFlagRuleOutcome.triggered] — an insufficient-information result
  /// deliberately has no urgency, since inventing one would mean guessing.
  final TriageUrgency? urgency;
}

/// A single, independently testable safety/red-flag rule.
///
/// Each rule looks only at the structured [TriageSession] data from
/// Task 05A (via [SymptomIdentifierMatcher] where free-text matching is
/// needed) and returns a deterministic [RedFlagRuleEvaluation] — the same
/// session must always produce the same result. Rules must not perform
/// diagnosis, recommend treatment, or reason beyond their single, narrow
/// red flag.
abstract class RedFlagRule {
  const RedFlagRule();

  /// Stable, machine-readable identifier for this rule (e.g.
  /// `severe_breathing_difficulty`). Must never change once a rule ships,
  /// since downstream code/UI may reference it.
  String get id;

  RedFlagRuleEvaluation evaluate(TriageSession session);
}
