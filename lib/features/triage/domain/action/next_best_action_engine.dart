// Task 05F — Next Best Action Engine.
//
// Translates the current TriageResult disposition into the most appropriate
// high-level next care action.
//
// DECISION PRECEDENCE:
// A. EMERGENCY:
//    triageResult.state == emergency OR urgency == emergency ->
//    actionType: emergencyCare, urgency: emergency,
//    requiresFacilitySelection: false, requiresAppointment: false,
//    requiresHumanReview: true.
// B. NEEDS INFORMATION:
//    triageResult.state == needsInformation OR needsFollowUp == true ->
//    actionType: undetermined, urgency: null,
//    requiresFacilitySelection: false, requiresAppointment: false,
//    requiresHumanReview: preserved from triageResult.
// C. URGENT:
//    triageResult.state == urgent OR urgency == urgent ->
//    actionType: facilityReferral, urgency: urgent,
//    requiresFacilitySelection: true, requiresAppointment: false,
//    requiresHumanReview: true.
// D. ASSESSED / NON-EMERGENCY:
//    Considers structured signals:
//    - selfMonitor (explicit low-risk context)
//    - teleconsultation (explicit remote review suitability)
//    - laboratory (explicit diagnostic testing need)
//    - specialist (explicit specialist pathway)
//    - facilityReferral (explicit in-person / physical assessment need)
//    - primaryCare (general conservative clinical-access default)
//
// SAFETY INVARIANTS:
// - Unknown != No (missing information is never converted to selfMonitor).
// - AI extraction confidence alone NEVER determines the next action.
// - No facility matching, appointment booking, diagnosis, or prescription.
library;

import '../entities/triage_session.dart';
import '../enums/next_action_type.dart';
import '../enums/symptom_severity.dart';
import '../enums/triage_urgency.dart';
import '../extraction/extraction_result.dart';
import '../result/triage_disposition_state.dart';
import '../result/triage_result.dart';
import 'next_best_action.dart';

/// Pure, deterministic engine that computes a [NextBestAction] recommendation.
class NextBestActionEngine {
  const NextBestActionEngine();

  /// Determines the [NextBestAction] for [triageResult].
  ///
  /// Optional [session] and [extractionResult] provide auxiliary structured
  /// signals for non-emergency routing when explicitly available.
  NextBestAction determine(
    TriageResult triageResult, {
    TriageSession? session,
    ExtractionResult? extractionResult,
    DateTime? timestamp,
  }) {
    final generatedAt = timestamp ?? DateTime.now();

    // -------------------------------------------------------------------------
    // PRECEDENCE A: EMERGENCY
    // -------------------------------------------------------------------------
    if (triageResult.state == TriageDispositionState.emergency ||
        triageResult.urgency == TriageUrgency.emergency) {
      return NextBestAction(
        actionType: NextActionType.emergencyCare,
        urgency: TriageUrgency.emergency,
        reason: triageResult.explanation.isNotEmpty
            ? triageResult.explanation
            : 'An emergency safety concern was identified.',
        requiresFacilitySelection: false,
        requiresAppointment: false,
        requiresHumanReview: true,
        generatedAt: generatedAt,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE B: NEEDS INFORMATION
    // -------------------------------------------------------------------------
    if (triageResult.state == TriageDispositionState.needsInformation ||
        triageResult.needsFollowUp) {
      return NextBestAction(
        actionType: NextActionType.undetermined,
        urgency: null,
        reason: 'More information is needed before selecting the next care step.',
        requiresFacilitySelection: false,
        requiresAppointment: false,
        requiresHumanReview: triageResult.requiresHumanReview,
        generatedAt: generatedAt,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE C: URGENT
    // -------------------------------------------------------------------------
    if (triageResult.state == TriageDispositionState.urgent ||
        triageResult.urgency == TriageUrgency.urgent) {
      return NextBestAction(
        actionType: NextActionType.facilityReferral,
        urgency: TriageUrgency.urgent,
        reason: triageResult.explanation.isNotEmpty
            ? triageResult.explanation
            : 'Prompt in-person clinical assessment is indicated.',
        requiresFacilitySelection: true,
        requiresAppointment: false,
        requiresHumanReview: true,
        generatedAt: generatedAt,
      );
    }

    // -------------------------------------------------------------------------
    // PRECEDENCE D: ASSESSED / NON-EMERGENCY
    // -------------------------------------------------------------------------
    // Evaluate structured signals from session / notes:
    final notesText = triageResult.notes.join(' ').toLowerCase();
    final symptomTexts = session != null
        ? session.symptoms.map((s) => s.symptomName.toLowerCase()).toList()
        : <String>[];
    final allText = '$notesText ${symptomTexts.join(' ')}';

    // 1. Diagnostic Testing / Laboratory signal
    if (_containsAny(allText, ['laboratory', 'lab test', 'blood test', 'diagnostic test', 'testing needed'])) {
      return NextBestAction(
        actionType: NextActionType.laboratory,
        urgency: triageResult.urgency ?? TriageUrgency.routine,
        reason: 'Diagnostic testing pathway is explicitly indicated for assessment.',
        requiresFacilitySelection: true,
        requiresAppointment: true,
        requiresHumanReview: triageResult.requiresHumanReview,
        generatedAt: generatedAt,
      );
    }

    // 2. Specialist care signal
    if (_containsAny(allText, ['specialist', 'specialist referral', 'specialty care', 'consultant review'])) {
      return NextBestAction(
        actionType: NextActionType.specialist,
        urgency: triageResult.urgency ?? TriageUrgency.routine,
        reason: 'Specialist clinical assessment is indicated by structured care signals.',
        requiresFacilitySelection: true,
        requiresAppointment: true,
        requiresHumanReview: triageResult.requiresHumanReview,
        generatedAt: generatedAt,
      );
    }

    // 3. Physical In-Person Facility Referral signal
    if (_containsAny(allText, ['physical assessment', 'in-person examination', 'hands-on care', 'wound dressing'])) {
      return NextBestAction(
        actionType: NextActionType.facilityReferral,
        urgency: triageResult.urgency ?? TriageUrgency.routine,
        reason: 'In-person clinical assessment is indicated for physical examination.',
        requiresFacilitySelection: true,
        requiresAppointment: false,
        requiresHumanReview: triageResult.requiresHumanReview,
        generatedAt: generatedAt,
      );
    }

    // 4. Remote Review / Teleconsultation signal
    if (_containsAny(allText, ['teleconsultation', 'remote review', 'teleconsult', 'virtual visit', 'remote consultation'])) {
      return NextBestAction(
        actionType: NextActionType.teleconsultation,
        urgency: triageResult.urgency ?? TriageUrgency.routine,
        reason: 'Remote clinician review is appropriate based on the current assessment.',
        requiresFacilitySelection: false,
        requiresAppointment: true,
        requiresHumanReview: triageResult.requiresHumanReview,
        generatedAt: generatedAt,
      );
    }

    // 5. Self-Monitoring signal
    // Only applied when the assessment is explicitly low-risk with mild symptoms and no human review required
    final isExplicitLowRisk = triageResult.state == TriageDispositionState.assessed &&
        triageResult.urgency == TriageUrgency.routine &&
        !triageResult.requiresHumanReview &&
        (session != null &&
            session.symptoms.isNotEmpty &&
            session.symptoms.every((s) => s.severity == SymptomSeverity.mild));

    if (isExplicitLowRisk) {
      return NextBestAction(
        actionType: NextActionType.selfMonitor,
        urgency: TriageUrgency.routine,
        reason: 'No immediate escalation is indicated from the current assessment; self-monitoring is appropriate.',
        requiresFacilitySelection: false,
        requiresAppointment: false,
        requiresHumanReview: false,
        generatedAt: generatedAt,
      );
    }

    // 6. Default conservative clinical-access pathway: Primary Care
    return NextBestAction(
      actionType: NextActionType.primaryCare,
      urgency: triageResult.urgency ?? TriageUrgency.routine,
      reason: 'A clinician assessment is appropriate based on the current triage result.',
      requiresFacilitySelection: true,
      requiresAppointment: false,
      requiresHumanReview: triageResult.requiresHumanReview,
      generatedAt: generatedAt,
    );
  }

  static bool _containsAny(String text, List<String> terms) {
    for (final t in terms) {
      if (text.contains(t)) return true;
    }
    return false;
  }
}
