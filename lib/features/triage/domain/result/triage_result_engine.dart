// Task 05E — Deterministic Triage Result / Disposition Engine.
//
// Evaluates the current state of a triage progression by combining:
// - 05A TriageSession (structured data)
// - 05B RedFlagAssessment (safety gate)
// - 05C FollowUpResult (missing information resolution)
// - 05D ExtractionResult (AI extraction metadata & confidence)
//
// SAFETY PRECEDENCE:
// 1. Confirmed Emergency:
//    05B emergency red flag -> urgency: emergency, state: emergency,
//    needsFollowUp: false, requiresHumanReview: true.
// 2. Confirmed Urgent:
//    05B urgent concern -> urgency: urgent, state: urgent,
//    requiresHumanReview: true, needsFollowUp: false (unless safety info missing).
// 3. Missing Safety Information:
//    05B insufficient info OR 05C pending safety question ->
//    needsFollowUp: true, state: needsInformation, requiresHumanReview: true,
//    urgency: null (conservative, never routine).
// 4. Assessed:
//    Complete triage with no red flags ->
//    urgency: routine (or session.urgency), state: assessed.
//
// INVARIANTS:
// - Extraction confidence alone NEVER decides urgency.
// - Unknown != No (unanswered fields remain unresolved).
// - No diagnosis, prescription, facility selection, or treatment claims.
library;

import '../entities/triage_session.dart';
import '../enums/triage_urgency.dart';
import '../extraction/extraction_confidence.dart';
import '../extraction/extraction_result.dart';
import '../follow_up/follow_up_engine.dart';
import '../red_flags/red_flag_assessment.dart';
import '../red_flags/red_flag_engine.dart';
import 'triage_disposition_state.dart';
import 'triage_result.dart';

/// Deterministic engine that computes a summarized [TriageResult] disposition.
class TriageResultEngine {
  const TriageResultEngine({
    RedFlagEngine? redFlagEngine,
    FollowUpEngine? followUpEngine,
  })  : _redFlagEngine = redFlagEngine ?? const RedFlagEngine(),
        _followUpEngine = followUpEngine ?? const FollowUpEngine();

  final RedFlagEngine _redFlagEngine;
  final FollowUpEngine _followUpEngine;

  /// Generates a summarized [TriageResult] for [session].
  ///
  /// Callers may optionally provide precomputed [safetyAssessment],
  /// [followUpResult], and [extractionResult]. If not provided, the engine
  /// will run the deterministic 05B and 05C engines as needed.
  ///
  /// If [timestamp] is omitted, [DateTime.now()] is used.
  TriageResult generate(
    TriageSession session, {
    RedFlagAssessment? safetyAssessment,
    FollowUpResult? followUpResult,
    ExtractionResult? extractionResult,
    DateTime? timestamp,
  }) {
    final completedAt = timestamp ?? DateTime.now();

    // 1. Obtain 05B Safety Assessment
    final assessment = safetyAssessment ?? _redFlagEngine.assess(session);

    // 2. Obtain 05C Follow-up Result if needed
    final followUp = followUpResult ?? _followUpEngine.evaluate(session);

    final triggeredRuleIds = [
      for (final r in assessment.triggeredRules) r.ruleId,
    ];
    final reasons = List<String>.from(assessment.reasons);
    final notes = List<String>.from(assessment.missingSafetyInformation);

    // If extraction result had low confidence or warnings, note them
    if (extractionResult != null) {
      if (extractionResult.confidence.overall == ExtractionConfidenceLevel.low) {
        notes.add('Extraction confidence was low; clinical verification advised.');
      }
      for (final w in extractionResult.warnings) {
        notes.add('Extraction warning: ${w.message}');
      }
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE 1: CONFIRMED EMERGENCY
    // -------------------------------------------------------------------------
    if (assessment.hasRedFlag && assessment.urgency == TriageUrgency.emergency) {
      return TriageResult(
        sourceSessionId: session.id,
        urgency: TriageUrgency.emergency,
        state: TriageDispositionState.emergency,
        title: 'Emergency care needed',
        explanation: reasons.isNotEmpty
            ? reasons.first
            : 'An emergency safety concern was identified.',
        needsFollowUp: false, // Emergency overrides pending questions
        requiresHumanReview: true,
        triggeredRuleIds: triggeredRuleIds,
        completedAt: completedAt,
        pendingQuestionId: null,
        reasons: reasons,
        notes: notes,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE 2: OTHER CONFIRMED URGENT SAFETY RESULT
    // -------------------------------------------------------------------------
    if (assessment.hasRedFlag && assessment.urgency == TriageUrgency.urgent) {
      // If there is also missing safety information, follow-up may still be required
      final hasMissingInfo = assessment.missingSafetyInformation.isNotEmpty ||
          followUp.question != null;

      return TriageResult(
        sourceSessionId: session.id,
        urgency: TriageUrgency.urgent,
        state: TriageDispositionState.urgent,
        title: 'Prompt medical assessment needed',
        explanation: reasons.isNotEmpty
            ? reasons.first
            : 'A concerning symptom pattern requires prompt medical assessment.',
        needsFollowUp: hasMissingInfo,
        requiresHumanReview: true,
        triggeredRuleIds: triggeredRuleIds,
        completedAt: completedAt,
        pendingQuestionId: hasMissingInfo ? followUp.question?.id : null,
        reasons: reasons,
        notes: notes,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE 3: MISSING SAFETY INFORMATION
    // -------------------------------------------------------------------------
    // If 05B reported insufficient info OR 05C selected a follow-up question
    final hasPendingFollowUp = followUp.question != null;
    final hasMissingSafetyInfo = assessment.missingSafetyInformation.isNotEmpty;

    if (hasPendingFollowUp || hasMissingSafetyInfo) {
      return TriageResult(
        sourceSessionId: session.id,
        urgency: null, // Conservative: Never invent routine or arbitrary urgency
        state: TriageDispositionState.needsInformation,
        title: 'More information needed',
        explanation: 'More information is needed to safely assess your symptoms.',
        needsFollowUp: true,
        requiresHumanReview: assessment.requiresHumanReview,
        triggeredRuleIds: triggeredRuleIds,
        completedAt: completedAt,
        pendingQuestionId: followUp.question?.id,
        reasons: reasons,
        notes: notes,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE 4: OTHERWISE (ASSESSED / ROUTINE)
    // -------------------------------------------------------------------------
    // If low extraction confidence exists, require human review but don't invent emergency
    final requiresReview = assessment.requiresHumanReview ||
        (extractionResult != null &&
            extractionResult.confidence.overall == ExtractionConfidenceLevel.low);

    return TriageResult(
      sourceSessionId: session.id,
      urgency: session.urgency ?? TriageUrgency.routine,
      state: requiresReview
          ? TriageDispositionState.humanReview
          : TriageDispositionState.assessed,
      title: 'Assessment can continue',
      explanation: 'No immediate red-flag safety concerns were identified from reported symptoms.',
      needsFollowUp: false,
      requiresHumanReview: requiresReview,
      triggeredRuleIds: triggeredRuleIds,
      completedAt: completedAt,
      pendingQuestionId: null,
      reasons: reasons,
      notes: notes,
    );
  }
}
