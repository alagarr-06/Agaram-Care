/// Task 07C — Follow-up Session Enricher.
///
/// Applies collected [FollowUpAnswer]s back to the structured [TriageSession]
/// so that the deterministic safety pipeline (05B RedFlagEngine) operates on
/// the LATEST available information, not only on the initial extraction.
///
/// ## Why this is needed
///
/// Follow-up answers are safety-relevant structured facts. When a patient
/// confirms "yes, the chest pain is severe or getting worse", that fact must
/// be represented in the [TriageSession] for [ChestPainRule] to escalate
/// correctly. Storing the answer only in [FollowUpAnswer] records (visible
/// only to [FollowUpEngine]) and re-running [RedFlagEngine] against the
/// unchanged original session causes the "YES" answer to be silently
/// ignored, producing a dangerously wrong "routine" disposition.
///
/// ## Design principles
///
/// - **Pure function**: the original session and answer list are never
///   mutated. A new session is returned.
/// - **Provenance preserved**: the original [PatientSymptom.symptomName] and
///   [PatientSymptom.duration] are never altered. Enrichment only adds or
///   upgrades values; it never removes or silently rewrites existing ones.
/// - **Severity escalation only**: a follow-up answer of "yes" to a severity
///   question can upgrade severity (e.g. mild → severe) but never downgrades
///   an already-higher severity.
/// - **Unknown ≠ No**: answers with value `"no"` are recorded as explicit
///   negatives via associated-symptom entries with the prefix
///   `"no "` (matching the existing negation guard in [SymptomNormalizer] and
///   [SymptomIdentifierMatcher]). An absent answer remains unknown.
/// - **No diagnosis**: this class contains no clinical logic. It maps
///   follow-up question [target] fields to structured session fields
///   according to a fixed, auditable table.
///
/// ## Supported target → session mapping
///
/// | target                    | yes answer effect                           | no answer effect                             |
/// |---------------------------|---------------------------------------------|----------------------------------------------|
/// | chestPainSeverityConfirmed| primary severity → severe (if ≤ moderate)  | (no structural change; non-severe confirmed) |
/// | breathingStatus           | adds AssociatedSymptom("difficulty breathing") | adds AssociatedSymptom("no difficulty breathing") |
/// | consciousnessStatus       | adds AssociatedSymptom("unconscious")       | adds AssociatedSymptom("no fainting")        |
/// | breathingSeverityConfirmed| primary severity → severe (if ≤ moderate)  | (no structural change)                       |
/// | cyanosisStatus            | adds AssociatedSymptom("lips turning blue") | (no structural change)                       |
/// | faceThroatSwellingStatus  | adds AssociatedSymptom("face throat swelling") | (no structural change)                    |
/// | suddenLimbWeaknessStatus  | adds AssociatedSymptom("sudden one-sided weakness") | (no structural change)              |
/// | facialWeaknessStatus      | adds AssociatedSymptom("face drooping")     | (no structural change)                       |
/// | speechDifficultyStatus    | adds AssociatedSymptom("difficulty speaking") | (no structural change)                     |
/// | bleedingControlStatus     | adds AssociatedSymptom("uncontrolled bleeding") | (no structural change)                  |
/// | bleedingFaintnessStatus   | adds AssociatedSymptom("fainting from bleeding") | (no structural change)                |
///
/// All other targets are currently pass-through (no structural change).
library;

import '../entities/associated_symptom.dart';
import '../entities/patient_symptom.dart';
import '../entities/triage_session.dart';
import '../enums/input_source.dart';
import '../enums/symptom_severity.dart';
import 'follow_up_answer.dart';
import 'follow_up_question_bank.dart';

/// Pure function: applies [answers] to a copy of [session], returning a
/// new [TriageSession] with the latest follow-up information reflected in
/// structured symptom fields.
///
/// The original [session] is never mutated.
TriageSession applyFollowUpAnswers(
  TriageSession session,
  List<FollowUpAnswer> answers,
) {
  if (answers.isEmpty || session.symptoms.isEmpty) return session;

  // Build a lookup: questionId → answer value (lower-cased).
  final answerByQuestionId = <String, String>{
    for (final a in answers) a.questionId: a.value.toLowerCase().trim(),
  };

  // Build target → answer value lookup via the question bank.
  final answerByTarget = <String, String>{};
  for (final q in followUpQuestionBank) {
    final val = answerByQuestionId[q.id];
    if (val != null) {
      answerByTarget[q.target] = val;
    }
  }

  if (answerByTarget.isEmpty) return session;

  // Enrich only the primary symptom (index 0) — follow-up questions are
  // always about the primary presenting complaint.
  final primary = session.symptoms.first;
  final enriched = _enrichPrimarySymptom(primary, answerByTarget, answers);

  if (enriched == primary) return session; // no change — return original

  return TriageSession(
    id: session.id,
    patientId: session.patientId,
    languageCode: session.languageCode,
    createdAt: session.createdAt,
    inputSource: session.inputSource,
    symptoms: [
      enriched,
      for (int i = 1; i < session.symptoms.length; i++) session.symptoms[i],
    ],
    patientContext: session.patientContext,
    urgency: session.urgency,
    nextAction: session.nextAction,
  );
}

PatientSymptom _enrichPrimarySymptom(
  PatientSymptom original,
  Map<String, String> answerByTarget,
  List<FollowUpAnswer> answers,
) {
  var severity = original.severity;
  final extraAssociated = <AssociatedSymptom>[];

  // Determine the InputSource for injected associated symptoms
  // (use the first follow-up answer's source, or text as default).
  final followUpSource = answers.isNotEmpty ? answers.first.inputSource : InputSource.text;

  for (final entry in answerByTarget.entries) {
    final target = entry.key;
    final value = entry.value;
    final isYes = value == 'yes' || value == 'true';
    final isNo = value == 'no' || value == 'false';

    switch (target) {
      case 'chestPainSeverityConfirmed':
        // A "yes" answer to "Is the chest pain severe or getting worse?"
        // is the strongest available structured evidence that the severity
        // should be treated as severe. Only upgrade — never downgrade.
        if (isYes) {
          if (severity == null ||
              severity == SymptomSeverity.mild ||
              severity == SymptomSeverity.moderate) {
            severity = SymptomSeverity.severe;
          }
        }
        // A "no" answer means the severity is confirmed NOT severe/worsening.
        // We do not change an already-severe rating; if currently mild/null we
        // leave it as-is (the "no" means not-severe, not necessarily mild).
        break;

      case 'breathingStatus':
        if (isYes) {
          // Confirmed breathing difficulty — inject as associated symptom
          // so ChestPainRule's _emergencyCoSigns check fires correctly.
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'difficulty breathing',
            inputSource: followUpSource,
          ));
        } else if (isNo) {
          // Confirmed NO breathing difficulty — explicit negative,
          // preserving Unknown ≠ No principle.
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'no difficulty breathing',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'consciousnessStatus':
        if (isYes) {
          // Confirmed loss of consciousness.
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'unconscious',
            inputSource: followUpSource,
          ));
        } else if (isNo) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'no fainting or loss of consciousness',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'breathingSeverityConfirmed':
        if (isYes) {
          if (severity == null ||
              severity == SymptomSeverity.mild ||
              severity == SymptomSeverity.moderate) {
            severity = SymptomSeverity.severe;
          }
        }
        break;

      case 'cyanosisStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'lips turning blue',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'faceThroatSwellingStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'face swelling',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'suddenLimbWeaknessStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'one-sided weakness',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'facialWeaknessStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'face drooping',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'speechDifficultyStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'difficulty speaking',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'bleedingControlStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'uncontrolled bleeding',
            inputSource: followUpSource,
          ));
        }
        break;

      case 'bleedingFaintnessStatus':
        if (isYes) {
          extraAssociated.add(AssociatedSymptom(
            symptomName: 'fainting from bleeding',
            inputSource: followUpSource,
          ));
        }
        break;

      default:
        // Unknown target: no structural change — safe pass-through.
        break;
    }
  }

  // Determine if anything actually changed.
  final severityChanged = severity != original.severity;
  if (!severityChanged && extraAssociated.isEmpty) return original;

  return PatientSymptom(
    symptomName: original.symptomName,
    inputSource: original.inputSource,
    severity: severity,
    duration: original.duration,
    associatedSymptoms: [
      ...original.associatedSymptoms,
      ...extraAssociated,
    ],
  );
}
