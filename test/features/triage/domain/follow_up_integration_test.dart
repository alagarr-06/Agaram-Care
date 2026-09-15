// Task 07C — Follow-up State + Decision Integration Regression Tests.
//
// This test file addresses the bug where answering "YES" to a follow-up
// severity question (e.g., "Is the chest pain severe or getting worse?")
// produced a dangerously wrong "routine" disposition because the follow-up
// answer was never incorporated into the structured TriageSession before
// re-running the RedFlagEngine.
//
// INVARIANTS VERIFIED:
//  - Follow-up YES answers escalate urgency correctly.
//  - Follow-up NO answers do NOT produce false positives.
//  - Unknown != No — missing answers remain unresolved, never treated as safe.
//  - Severity can only be upgraded by follow-up, never downgraded.
//  - Original session is never mutated.
//  - Enricher is idempotent (calling twice = calling once).
//  - All standard pipeline stages (05B → 05E) produce correct results
//    when wired through the enriched session.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/associated_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/action/action.dart';
import 'package:agaram_care/features/triage/domain/enums/next_action_type.dart';
import 'package:agaram_care/features/triage/domain/extraction/symptom_normalizer.dart';
import 'package:agaram_care/features/triage/domain/follow_up/follow_up.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';
import 'package:agaram_care/features/triage/domain/result/result.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _baseTime = DateTime.utc(2026, 7, 1, 8, 0);

/// Minimal session with chest pain as the primary symptom.
TriageSession _chestPainSession({
  SymptomSeverity? severity,
  List<AssociatedSymptom> associated = const [],
}) {
  return TriageSession(
    id: 'sess-07c',
    patientId: 'pat-07c',
    languageCode: 'en',
    createdAt: _baseTime,
    inputSource: InputSource.text,
    symptoms: [
      PatientSymptom(
        symptomName: 'chest pain',
        inputSource: InputSource.text,
        severity: severity,
        associatedSymptoms: associated,
      ),
    ],
  );
}

FollowUpAnswer _answer(String questionId, {String value = 'yes'}) {
  return FollowUpAnswer(
    questionId: questionId,
    value: value,
    inputSource: InputSource.text,
    answeredAt: _baseTime,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  const engine = RedFlagEngine();
  const resultEngine = TriageResultEngine();
  const followUpEngine = FollowUpEngine();

  // ── GROUP 1: applyFollowUpAnswers — direct unit tests ───────────────────
  group('1. applyFollowUpAnswers — core behavior', () {
    test('1a. No answers: returns original session unchanged', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final enriched = applyFollowUpAnswers(session, []);
      expect(identical(enriched, session), isTrue,
          reason: 'With no answers, the exact original session should be returned');
    });

    test('1b. YES to chest_pain.severity upgrades mild → severe', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.severity', value: 'yes')],
      );
      expect(enriched.symptoms.first.severity, equals(SymptomSeverity.severe),
          reason: 'YES to "is it severe or getting worse" must upgrade mild to severe');
    });

    test('1c. YES to chest_pain.severity upgrades null severity → severe', () {
      final session = _chestPainSession();
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.severity', value: 'yes')],
      );
      expect(enriched.symptoms.first.severity, equals(SymptomSeverity.severe));
    });

    test('1d. NO to chest_pain.severity does NOT change severity', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.severity', value: 'no')],
      );
      expect(enriched.symptoms.first.severity, equals(SymptomSeverity.mild),
          reason: 'NO answer must not alter severity');
    });

    test('1e. YES to chest_pain.breathing adds "difficulty breathing" as associated symptom', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.breathing', value: 'yes')],
      );
      final names = enriched.symptoms.first.associatedSymptoms.map((a) => a.symptomName).toList();
      expect(names, contains('difficulty breathing'));
    });

    test('1f. NO to chest_pain.breathing adds explicit "no difficulty breathing"', () {
      final session = _chestPainSession();
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.breathing', value: 'no')],
      );
      final names = enriched.symptoms.first.associatedSymptoms.map((a) => a.symptomName).toList();
      expect(names, contains('no difficulty breathing'),
          reason: 'Explicit NO must be preserved; Unknown != No');
    });

    test('1g. YES to chest_pain.consciousness adds "unconscious" as associated symptom', () {
      final session = _chestPainSession();
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.consciousness', value: 'yes')],
      );
      final names = enriched.symptoms.first.associatedSymptoms.map((a) => a.symptomName).toList();
      expect(names, contains('unconscious'));
    });

    test('1h. Existing associated symptoms are preserved when enriching', () {
      final original = AssociatedSymptom(
        symptomName: 'nausea',
        inputSource: InputSource.text,
      );
      final session = _chestPainSession(associated: [original]);
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.breathing', value: 'yes')],
      );
      final names = enriched.symptoms.first.associatedSymptoms.map((a) => a.symptomName).toList();
      expect(names, contains('nausea'), reason: 'Original associated symptoms must be preserved');
      expect(names, contains('difficulty breathing'));
    });

    test('1i. Original session is NOT mutated (immutability)', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final _ = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.severity', value: 'yes')],
      );
      expect(session.symptoms.first.severity, equals(SymptomSeverity.mild),
          reason: 'Original session must never be mutated');
    });

    test('1j. Enricher is idempotent — applying same answers twice = applying once', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [_answer('chest_pain.severity', value: 'yes')];
      final enrichedOnce = applyFollowUpAnswers(session, answers);
      final enrichedTwice = applyFollowUpAnswers(enrichedOnce, answers);
      expect(enrichedTwice.symptoms.first.severity, equals(SymptomSeverity.severe));
    });

    test('1k. YES to severity does NOT downgrade an already-severe severity', () {
      final session = _chestPainSession(severity: SymptomSeverity.severe);
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.severity', value: 'yes')],
      );
      expect(enriched.symptoms.first.severity, equals(SymptomSeverity.severe));
    });
  });

  // ── GROUP 2: Bug reproduction — "mild chest pain + YES to severity" ──────
  group('2. Bug reproduction: mild chest pain → YES follow-up → emergency', () {
    // This exactly reproduces the reported bug:
    // Input: "I have mild chest pain"
    // Q1: "Are you having difficulty breathing?" → NO
    // Q2: "Have you fainted or lost consciousness?" → NO
    // Q3: "Is the chest pain severe or getting worse?" → YES
    // EXPECTED: emergency (not routine)

    test('2a. Enriched session: chest pain with YES severity → severity is severe', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      expect(enriched.symptoms.first.severity, equals(SymptomSeverity.severe));
    });

    test('2b. RedFlagEngine on enriched session → hasRedFlag = true', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      expect(assessment.hasRedFlag, isTrue);
    });

    test('2c. RedFlagEngine on enriched session → urgency = emergency', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      expect(assessment.urgency, equals(TriageUrgency.emergency),
          reason: 'Severe chest pain confirmed by follow-up must produce emergency urgency');
    });

    test('2d. TriageResultEngine on enriched session → state = emergency', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      final followUpResult = followUpEngine.evaluate(enriched, answers: answers);
      final result = resultEngine.generate(
        enriched,
        safetyAssessment: assessment,
        followUpResult: followUpResult,
      );
      expect(result.state, equals(TriageDispositionState.emergency),
          reason: 'The final triage disposition must be emergency, not routine');
    });

    test('2e. Same scenario WITHOUT enrichment (demonstrates original bug) → NOT emergency', () {
      // This test DEMONSTRATES the bug: evaluating against the original
      // unenriched session produces the wrong (routine) result.
      // This is intentional — it confirms that enrichment is what fixes it.
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final assessment = engine.assess(session); // unenriched
      expect(assessment.hasRedFlag, isFalse,
          reason: 'Without enrichment, mild chest pain alone is not a red flag — '
              'this demonstrates why enrichment is required');
    });
  });

  // ── GROUP 3: Unknown != No — absent answers remain unresolved ────────────
  group('3. Unknown != No: absent answers never treated as safe', () {
    test('3a. Chest pain with null severity and no answers → insufficientInformation', () {
      final session = _chestPainSession();
      final assessment = engine.assess(session);
      expect(assessment.missingSafetyInformation, isNotEmpty,
          reason: 'Unknown severity + no answers must remain as insufficientInformation, never "safe"');
    });

    test('3b. Chest pain with only "no breathing" answer still lacks severity info', () {
      final session = _chestPainSession();
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.breathing', value: 'no')],
      );
      final assessment = engine.assess(enriched);
      expect(assessment.missingSafetyInformation, isNotEmpty,
          reason: 'A single NO answer does not resolve all missing info');
    });

    test('3c. YES to breathing + chest pain → emergency co-sign detected', () {
      final session = _chestPainSession();
      final enriched = applyFollowUpAnswers(
        session,
        [_answer('chest_pain.breathing', value: 'yes')],
      );
      final assessment = engine.assess(enriched);
      expect(assessment.hasRedFlag, isTrue);
      expect(assessment.urgency, equals(TriageUrgency.emergency),
          reason: 'Breathing difficulty + chest pain is an emergency');
    });
  });

  // ── GROUP 4: NO answers never create false positives ──────────────────────
  group('4. NO answers do not create false positives', () {
    test('4a. All NO answers on chest pain with mild severity → no red flag', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'no'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      expect(assessment.hasRedFlag, isFalse,
          reason: 'All-NO answers + mild severity should not trigger red flag');
    });

    test('4b. TriageResultEngine with all-NO answers on mild chest pain → not emergency/urgent', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'no'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      final followUpResult = followUpEngine.evaluate(enriched, answers: answers);
      final result = resultEngine.generate(
        enriched,
        safetyAssessment: assessment,
        followUpResult: followUpResult,
      );
      expect(result.state == TriageDispositionState.emergency, isFalse,
          reason: 'All-NO + mild chest pain must not produce emergency disposition');
      expect(result.state == TriageDispositionState.urgent, isFalse,
          reason: 'All-NO + mild chest pain must not produce urgent disposition');
    });
  });

  // ── GROUP 5: FollowUpEngine stop condition after answers ─────────────────
  group('5. FollowUpEngine correctly stops when answers complete the picture', () {
    test('5a. After all 3 chest pain questions answered, FollowUpEngine returns null question', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final followUpResult = followUpEngine.evaluate(enriched, answers: answers);
      expect(followUpResult.question, isNull,
          reason: 'After 3 safety-critical answers, no more questions should be asked');
    });

    test('5b. After YES to severity, FollowUpEngine does not re-ask severity question', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [_answer('chest_pain.severity', value: 'yes')];
      final enriched = applyFollowUpAnswers(session, answers);
      final followUpResult = followUpEngine.evaluate(enriched, answers: answers);
      if (followUpResult.question != null) {
        expect(followUpResult.question!.id, isNot(equals('chest_pain.severity')));
      }
    });
  });

  // ── GROUP 6: 05F Action Engine propagation & Traceability ────────────────
  group('6. 05F NextBestActionEngine propagation and Provenance', () {
    const actionEngine = NextBestActionEngine();

    test('6a. Emergency TriageResult propagates to NextActionType.emergencyCare', () {
      final session = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'yes'),
      ];
      final enriched = applyFollowUpAnswers(session, answers);
      final assessment = engine.assess(enriched);
      final followUpResult = followUpEngine.evaluate(enriched, answers: answers);
      final triageResult = resultEngine.generate(
        enriched,
        safetyAssessment: assessment,
        followUpResult: followUpResult,
      );

      final nextAction = actionEngine.determine(triageResult, session: enriched);
      expect(nextAction.actionType, equals(NextActionType.emergencyCare),
          reason: 'Emergency result MUST produce emergencyCare action, never selfMonitor');
      expect(nextAction.urgency, equals(TriageUrgency.emergency));
    });

    test('6b. Provenance: original extracted severity remains traceable in base session', () {
      final baseSession = _chestPainSession(severity: SymptomSeverity.mild);
      final answers = [_answer('chest_pain.severity', value: 'yes')];
      final enrichedSession = applyFollowUpAnswers(baseSession, answers);

      // Base session retains original extracted mild severity
      expect(baseSession.symptoms.first.severity, equals(SymptomSeverity.mild),
          reason: 'Original extracted severity must be preserved for auditability');

      // Enriched session reflects the upgraded safety severity
      expect(enrichedSession.symptoms.first.severity, equals(SymptomSeverity.severe),
          reason: 'Enriched session reflects explicit follow-up answer');
    });
  });

  // ── GROUP 7: Vague input and Negation safety ─────────────────────────────
  group('7. Vague input & Negation safety invariants', () {
    const normalizer = SymptomNormalizer();

    test('7a. Negated Tamil chest pain ("நெஞ்சுவலி இல்ல") does not trigger red flag', () {
      final extracted = normalizer.extract(
        'எனக்கு நெஞ்சுவலி இல்ல',
        languageCode: 'ta',
        inputSource: InputSource.text,
      );
      // Symptom should either be empty or marked negated
      final session = TriageSession(
        id: 'neg-ta',
        patientId: 'pat-ta',
        languageCode: 'ta',
        createdAt: _baseTime,
        inputSource: InputSource.text,
        symptoms: extracted.symptoms,
      );
      final assessment = engine.assess(session);
      expect(assessment.hasRedFlag, isFalse,
          reason: 'Negated Tamil chest pain must never trigger a red flag');
    });

    test('7b. Symptom-less severity text ("நேத்து ரொம்ப ஸ்ட்ராங்கா இருந்தது") does not produce routine', () {
      final extracted = normalizer.extract(
        'நேத்து ரொம்ப ஸ்ட்ராங்கா இருந்தது',
        languageCode: 'ta',
        inputSource: InputSource.text,
      );
      // No valid symptoms extracted
      expect(extracted.symptoms.isEmpty, isTrue);

      final session = TriageSession(
        id: 'symptomless-ta',
        patientId: 'pat-ta',
        languageCode: 'ta',
        createdAt: _baseTime,
        inputSource: InputSource.text,
        symptoms: extracted.symptoms,
      );
      final assessment = engine.assess(session);
      final followUpResult = followUpEngine.evaluate(session);
      final triageResult = resultEngine.generate(
        session,
        safetyAssessment: assessment,
        followUpResult: followUpResult,
        extractionResult: extracted,
      );

      // With low confidence or empty symptoms, requires review — must not be treated as routine clean bill of health
      expect(triageResult.state != TriageDispositionState.emergency, isTrue);
      expect(triageResult.requiresHumanReview, isTrue,
          reason: 'Symptom-less text cannot be silently cleared as safe');
    });
  });
}

