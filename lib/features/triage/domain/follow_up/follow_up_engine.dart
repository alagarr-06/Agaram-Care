import '../entities/triage_session.dart';
import '../red_flags/red_flag_engine.dart';
import '../red_flags/red_flag_assessment.dart';
import '../red_flags/symptom_identifier.dart';
import '../red_flags/symptom_identifier_matcher.dart';
import '../enums/triage_urgency.dart';
import 'follow_up_answer.dart';
import 'follow_up_priority.dart';
import 'follow_up_question.dart';
import 'follow_up_question_bank.dart';

/// The maximum number of [FollowUpPriority.safetyCritical] questions the
/// engine will automatically ask in one triage progression.
///
/// Exposing this as a constant lets callers (e.g. UI and tests) check the
/// limit without duplicating the number.
const int followUpSafetyCriticalLimit = 3;

/// The result returned by [FollowUpEngine.evaluate].
///
/// Carries the selected question (or `null`) alongside the assessment used
/// to derive it and the current safety-critical question count — enough
/// information for the application layer to know where to continue.
class FollowUpResult {
  const FollowUpResult({
    required this.question,
    required this.assessment,
    required this.safetyCriticalAsked,
    required this.limitReached,
    required this.stopReason,
  });

  /// The single highest-priority question to ask next, or `null` when no
  /// further automatic question should be presented.
  final FollowUpQuestion? question;

  /// The [RedFlagAssessment] computed as part of this evaluation. Always
  /// present — callers may inspect it for display/routing decisions even
  /// when [question] is `null`.
  final RedFlagAssessment assessment;

  /// How many safety-critical questions have already been asked (i.e.
  /// recorded in [FollowUpEngine.answers]). At [followUpSafetyCriticalLimit]
  /// or above, no further automatic question is selected.
  final int safetyCriticalAsked;

  /// `true` when [safetyCriticalAsked] >= [followUpSafetyCriticalLimit].
  final bool limitReached;

  /// Human-readable reason why [question] is `null`, or `null` if a
  /// question was selected. Intended for debugging and test assertions, not
  /// for display to patients.
  final String? stopReason;

  @override
  String toString() =>
      'FollowUpResult(question: ${question?.id}, '
      'safetyCriticalAsked: $safetyCriticalAsked, '
      'limitReached: $limitReached, '
      'stopReason: $stopReason)';
}

/// Deterministic follow-up question selection engine (Task 05C).
///
/// ## Responsibilities
/// - Delegates safety assessment to [RedFlagEngine] (05B).
/// - Detects which safety-critical information is still missing.
/// - Selects the single highest-priority unresolved question.
/// - Enforces the three-question automatic limit.
/// - Respects all stop conditions (see [evaluate]).
///
/// ## What this class does NOT do
/// - No diagnosis, treatment, or prescription.
/// - No AI/LLM.
/// - No symptom NLP (delegates to [SymptomIdentifierMatcher]).
/// - No UI rendering.
/// - No backend calls.
///
/// ## Determinism
/// [evaluate] is a pure function: the same [session] and [answers] always
/// produce the same [FollowUpResult]. Call it as many times as needed.
class FollowUpEngine {
  /// Creates an engine with the given question [bank] and optional custom
  /// [redFlagEngine]. Defaults to [followUpQuestionBank] and the default
  /// [RedFlagEngine].
  const FollowUpEngine({
    List<FollowUpQuestion>? bank,
    RedFlagEngine? redFlagEngine,
  })  : _bank = bank ?? followUpQuestionBank,
        _redFlagEngine = redFlagEngine ?? const RedFlagEngine();

  final List<FollowUpQuestion> _bank;
  final RedFlagEngine _redFlagEngine;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Evaluates [session] against 05B safety rules, then selects the single
  /// highest-priority unresolved follow-up question from [answers] context.
  ///
  /// [answers] contains the structured answers collected so far for this
  /// session. The engine uses them to:
  ///   a) Count how many safety-critical questions have already been asked.
  ///   b) Determine which question [target]s are already known.
  ///
  /// ## Stop conditions (returns `question: null`)
  /// 1. A confirmed emergency/high-risk red flag is already established —
  ///    further automatic questioning cannot override an emergency result.
  /// 2. No safety-critical information is missing from the session.
  /// 3. Three safety-critical questions have already been asked.
  /// 4. The patient/VHN explicitly declined to answer (pass an answer with
  ///    value `"declined"` to signal this; the engine counts it against the
  ///    limit and stops when the limit is reached).
  ///
  /// ## Unknown ≠ No
  /// A missing [target] is always treated as "unresolved", never as "no".
  /// The engine never invents a default negative answer.
  FollowUpResult evaluate(
    TriageSession session, {
    List<FollowUpAnswer> answers = const [],
  }) {
    // Step 1: run 05B safety assessment.
    final assessment = _redFlagEngine.assess(session);

    // Step 2: count safety-critical questions already asked.
    final askedTargets = <String>{
      for (final a in answers) a.questionId,
    };
    final safetyCriticalAsked = answers
        .where((a) => _isBankQuestion(a.questionId, FollowUpPriority.safetyCritical))
        .length;

    // Stop condition 1: confirmed emergency with no missing information —
    // an established emergency red flag must not be overridden by more
    // questions. (If there IS missing info, we may still want to resolve it
    // to distinguish emergency from "uncertain".)
    if (assessment.hasRedFlag &&
        _isHighRisk(assessment) &&
        assessment.missingSafetyInformation.isEmpty) {
      return FollowUpResult(
        question: null,
        assessment: assessment,
        safetyCriticalAsked: safetyCriticalAsked,
        limitReached: safetyCriticalAsked >= followUpSafetyCriticalLimit,
        stopReason: 'Emergency/high-risk red flag already established; '
            'no further automatic question.',
      );
    }

    // Stop condition 3: three-question limit reached.
    if (safetyCriticalAsked >= followUpSafetyCriticalLimit) {
      return FollowUpResult(
        question: null,
        assessment: assessment,
        safetyCriticalAsked: safetyCriticalAsked,
        limitReached: true,
        stopReason: 'Safety-critical question limit '
            '($followUpSafetyCriticalLimit) reached.',
      );
    }

    // Step 3: determine which symptom categories are present.
    final presentIdentifiers = SymptomIdentifierMatcher.matchSession(session)
        .map((m) => m.identifier)
        .toSet();

    // Step 4: find known targets (from answers).
    final knownTargets = <String>{
      for (final a in answers) _targetForQuestionId(a.questionId),
    }..remove(''); // drop empty strings from unmatched IDs

    // Step 5: iterate the bank in order and pick the first applicable,
    // unasked, unresolved question.
    for (final q in _bank) {
      // Only surface questions whose symptom category is relevant.
      if (!_isRelevant(q, presentIdentifiers, session)) continue;

      // Skip if we already have an answer for this question.
      if (askedTargets.contains(q.id)) continue;

      // Skip if the target information is already known.
      if (knownTargets.contains(q.target)) continue;

      // Skip non-safety-critical questions when a safety-critical gap
      // remains — we always resolve the highest-priority level first.
      // (The bank is already ordered so this naturally happens, but this
      // guard makes the rule explicit.)
      if (q.priority != FollowUpPriority.safetyCritical &&
          _hasSafetyCriticalGap(presentIdentifiers, knownTargets, askedTargets, session)) {
        continue;
      }

      return FollowUpResult(
        question: q,
        assessment: assessment,
        safetyCriticalAsked: safetyCriticalAsked,
        limitReached: false,
        stopReason: null,
      );
    }

    // No question found — all gaps resolved or no relevant gaps exist.
    return FollowUpResult(
      question: null,
      assessment: assessment,
      safetyCriticalAsked: safetyCriticalAsked,
      limitReached: safetyCriticalAsked >= followUpSafetyCriticalLimit,
      stopReason: 'No unresolved safety-critical information found.',
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns `true` when the assessment urgency indicates an emergency or
  /// high-risk (urgent) condition.
  static bool _isHighRisk(RedFlagAssessment assessment) {
    return assessment.urgency == TriageUrgency.emergency ||
        assessment.urgency == TriageUrgency.urgent;
  }

  /// Returns `true` if [questionId] corresponds to a bank question with the
  /// given [priority].
  bool _isBankQuestion(String questionId, FollowUpPriority priority) {
    for (final q in _bank) {
      if (q.id == questionId && q.priority == priority) return true;
    }
    return false;
  }

  /// Looks up the [FollowUpQuestion.target] for a given [questionId].
  /// Returns `''` if the question is not in the bank (safe default — an
  /// unknown ID never falsely marks a target as known).
  String _targetForQuestionId(String questionId) {
    for (final q in _bank) {
      if (q.id == questionId) return q.target;
    }
    return '';
  }

  /// Returns `true` when at least one safety-critical question in the bank
  /// is both relevant and unresolved (i.e. its target is neither known nor
  /// already asked).
  bool _hasSafetyCriticalGap(
    Set<SymptomIdentifier> presentIdentifiers,
    Set<String> knownTargets,
    Set<String> askedIds,
    TriageSession session,
  ) {
    for (final q in _bank) {
      if (q.priority != FollowUpPriority.safetyCritical) continue;
      if (!_isRelevant(q, presentIdentifiers, session)) continue;
      if (askedIds.contains(q.id)) continue;
      if (knownTargets.contains(q.target)) continue;
      return true;
    }
    return false;
  }

  /// Returns `true` when [q] is applicable to this session.
  ///
  /// Two checks are performed in order:
  ///   1. **Primary** — the session contains a [SymptomIdentifier] that
  ///      directly matches the question's [relatedRuleId] category.
  ///   2. **Secondary** — the session contains symptom text that is
  ///      semantically in the same category but didn't match 05B's narrower
  ///      keyword list (e.g. "trouble breathing", "sudden weakness",
  ///      "bleeding from a wound"). This ensures partial or ambiguous
  ///      presentations still surface the right follow-up question.
  ///
  /// A question is relevant if EITHER check passes.
  static bool _isRelevant(
    FollowUpQuestion q,
    Set<SymptomIdentifier> present,
    TriageSession session,
  ) {
    switch (q.relatedRuleId) {
      case 'chest_pain_or_pressure':
        return present.contains(SymptomIdentifier.chestPainOrPressure) ||
            _sessionTextContainsAny(
                session, ['chest', 'cardiac', 'heart pain']);
      case 'severe_breathing_difficulty':
        return present.contains(SymptomIdentifier.breathingDifficulty) ||
            _sessionTextContainsAny(
                session, ['breath', 'respir', 'airway']);
      case 'severe_allergic_reaction':
        return present.contains(SymptomIdentifier.severeAllergicReaction) ||
            _sessionTextContainsAny(
                session, ['allerg', 'anaphyl', 'hives', 'rash and swelling']);
      case 'stroke_warning_sign':
        return present.contains(SymptomIdentifier.suddenFacialWeakness) ||
            present.contains(SymptomIdentifier.suddenLimbWeakness) ||
            present.contains(SymptomIdentifier.suddenSpeechDifficulty) ||
            _sessionTextContainsAny(session, [
              'sudden weakness',
              'neurological',
              'numb',
              'tingling',
              'drooping',
            ]);
      case 'uncontrolled_heavy_bleeding':
        return present.contains(SymptomIdentifier.heavyUncontrolledBleeding) ||
            _sessionTextContainsAny(
                session, ['bleed', 'blood', 'hemorrh', 'haemorrhage']);
      default:
        // Unknown or missing rule ID: conservatively treat as relevant.
        return true;
    }
  }

  /// Returns `true` if any symptom text in [session] (primary or associated)
  /// contains at least one of [keywords] as a substring (case-insensitive).
  ///
  /// Intentionally a simple substring check — no stemming, no NLP. Exists
  /// only to give the relevance gate a slightly broader reach than the exact
  /// 05B keyword list for partial or ambiguous presentations.
  static bool _sessionTextContainsAny(
    TriageSession session,
    List<String> keywords,
  ) {
    for (final symptom in session.symptoms) {
      final lower = symptom.symptomName.toLowerCase();
      for (final kw in keywords) {
        if (lower.contains(kw)) return true;
      }
      for (final assoc in symptom.associatedSymptoms) {
        final assocLower = assoc.symptomName.toLowerCase();
        for (final kw in keywords) {
          if (assocLower.contains(kw)) return true;
        }
      }
    }
    return false;
  }
}
