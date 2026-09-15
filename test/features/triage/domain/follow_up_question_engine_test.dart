// Unit tests for Task 05C — Follow-Up Question Engine.
//
// These tests verify the engine's documented behaviour (stop conditions,
// question selection priority, unknown-information handling, limit
// enforcement) using only structured domain objects. They do not assert
// any clinical conclusion beyond the engine's narrow, documented scope
// and they do not start a Flutter widget tree.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/associated_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/follow_up/follow_up.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

final _baseTime = DateTime.utc(2026, 1, 10, 8, 0);

TriageSession _session({
  String symptomName = 'mild headache',
  SymptomSeverity? severity,
  InputSource source = InputSource.text,
  List<AssociatedSymptom> associatedSymptoms = const [],
  List<PatientSymptom> extraSymptoms = const [],
}) {
  return TriageSession(
    id: 'test-session',
    patientId: 'test-patient',
    languageCode: 'en',
    createdAt: _baseTime,
    inputSource: source,
    symptoms: [
      PatientSymptom(
        symptomName: symptomName,
        inputSource: source,
        severity: severity,
        associatedSymptoms: associatedSymptoms,
      ),
      ...extraSymptoms,
    ],
  );
}

FollowUpAnswer _answer(
  String questionId, {
  String value = 'yes',
  InputSource source = InputSource.text,
  DateTime? at,
}) {
  return FollowUpAnswer(
    questionId: questionId,
    value: value,
    inputSource: source,
    answeredAt: at ?? _baseTime,
  );
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main() {
  const engine = FollowUpEngine();
  const redFlagEngine = RedFlagEngine();

  // ── 1. No relevant symptoms → no question ─────────────────────────────────
  group('1. no relevant symptoms → no question', () {
    test('session with unrelated symptom produces null question', () {
      final session = _session(symptomName: 'mild headache');
      final result = engine.evaluate(session);
      expect(result.question, isNull);
    });
  });

  // ── 2. Chest pain + unknown breathing → breathing question ────────────────
  group('2. chest pain + unknown breathing → breathing question', () {
    test('returns chest_pain.breathing when breathing status is unknown', () {
      final session = _session(symptomName: 'chest pain');
      final result = engine.evaluate(session);
      expect(result.question, isNotNull);
      expect(result.question!.id, equals('chest_pain.breathing'));
    });
  });

  // ── 3. Already-known breathing status → no duplicate question ─────────────
  group('3. already-known breathing status → no duplicate', () {
    test('breathing already answered → engine skips that question', () {
      final session = _session(symptomName: 'chest pain');
      final answers = [_answer('chest_pain.breathing', value: 'no')];
      final result = engine.evaluate(session, answers: answers);
      // Should advance to the next unresolved chest-pain question
      expect(result.question?.id, isNot(equals('chest_pain.breathing')));
    });
  });

  // ── 4. Highest-priority unresolved question is selected ───────────────────
  group('4. highest-priority question selection', () {
    test('safety-critical question beats triageRelevant in same session', () {
      // A chest-pain session has safety-critical gaps; the engine must pick
      // the first one (chest_pain.breathing), not skip to a lower priority.
      final session = _session(symptomName: 'chest pain');
      final result = engine.evaluate(session);
      expect(result.question!.priority, equals(FollowUpPriority.safetyCritical));
    });
  });

  // ── 5. Breathing complaint → correct question ─────────────────────────────
  group('5. breathing complaint → correct question', () {
    test('partial breathing complaint triggers breathing.severity question', () {
      // 'trouble breathing' contains 'breath' → secondary relevance check fires.
      // It does NOT match 05B's exact keyword list, so no confirmed emergency.
      // Engine should ask breathing.severity.
      final session = _session(symptomName: 'trouble breathing');
      final result = engine.evaluate(session);
      expect(result.question, isNotNull,
          reason: 'Partial breathing complaint should trigger a follow-up question');
      expect(result.question!.id, equals('breathing.severity'));
    });
  });

  // ── 6. Allergy complaint → correct airway/breathing question ─────────────
  group('6. allergy complaint → correct question', () {
    test('allergic reaction triggers allergy.breathing question', () {
      final session = _session(symptomName: 'allergic reaction');
      final result = engine.evaluate(session);
      expect(result.question, isNotNull);
      expect(result.question!.id, equals('allergy.breathing'));
    });
  });

  // ── 7. Stroke-like complaint → correct follow-up question ────────────────
  group('7. stroke-like complaint → correct question', () {
    test('partial neurological complaint triggers neuro.limb_weakness question', () {
      // 'sudden weakness' matches secondary text keyword for stroke_warning_sign.
      // It does NOT match 05B's exact keywords ('arm weakness', 'leg weakness',
      // 'facial weakness', etc.), so 05B returns notTriggered.
      // Engine should ask neuro.limb_weakness (first neuro question in bank).
      final session = _session(symptomName: 'sudden weakness');
      final result = engine.evaluate(session);
      expect(result.question, isNotNull,
          reason: 'Partial neuro complaint should trigger a follow-up question');
      expect(result.question!.id, equals('neuro.limb_weakness'));
      expect(result.question!.relatedRuleId, equals('stroke_warning_sign'));
    });
  });

  // ── 8. Bleeding complaint → correct follow-up question ───────────────────
  group('8. bleeding complaint → correct question', () {
    test('partial bleeding complaint triggers bleeding.control question', () {
      // 'bleeding from a wound' contains 'bleed' → secondary relevance check.
      // It does NOT match 05B's keywords ('heavy bleeding', 'uncontrolled
      // bleeding', etc.), so 05B returns notTriggered.
      // Engine should ask bleeding.control.
      final session = _session(symptomName: 'bleeding from a wound');
      final result = engine.evaluate(session);
      expect(result.question, isNotNull,
          reason: 'Partial bleeding complaint should trigger a follow-up question');
      expect(result.question!.id, equals('bleeding.control'));
    });
  });

  // ── 9. Existing emergency red flag → no further question ──────────────────
  group('9. existing emergency red flag → no further question', () {
    test('confirmed emergency (unconscious) with no missing info → null question', () {
      // "unconscious" triggers UnconsciousnessRule with no insufficientInfo
      final session = _session(symptomName: 'unconscious');
      final assessment = redFlagEngine.assess(session);
      // Verify 05B sees this as emergency with no missing info first
      expect(assessment.hasRedFlag, isTrue);
      expect(assessment.urgency, equals(TriageUrgency.emergency));
      expect(assessment.missingSafetyInformation, isEmpty);

      final result = engine.evaluate(session);
      expect(result.question, isNull);
      expect(result.stopReason, contains('Emergency'));
    });
  });

  // ── 10. Unknown information is never treated as "no" ──────────────────────
  group('10. unknown != no', () {
    test('missing breathing status for chest pain is unresolved, not "no"', () {
      // No associated symptoms, no breathing answer → engine MUST ask
      final session = _session(symptomName: 'chest pain');
      final result = engine.evaluate(session);
      // If unknown were treated as "no", result.question would be null.
      // It must not be null.
      expect(result.question, isNotNull,
          reason: 'Unknown breathing status must be unresolved, not "no"');
    });

    test('chest pain with unknown severity and no answer → engine asks', () {
      final session = _session(symptomName: 'chest pain', severity: null);
      final result = engine.evaluate(session);
      expect(result.question, isNotNull);
    });
  });

  // ── 11. Voice answer preserves InputSource.voice ─────────────────────────
  group('11. voice answer preserves InputSource.voice', () {
    test('FollowUpAnswer created with voice preserves voice source', () {
      final answer = FollowUpAnswer(
        questionId: 'chest_pain.breathing',
        value: 'yes',
        inputSource: InputSource.voice,
        answeredAt: _baseTime,
      );
      expect(answer.inputSource, equals(InputSource.voice));
    });
  });

  // ── 12. Text answer preserves InputSource.text ───────────────────────────
  group('12. text answer preserves InputSource.text', () {
    test('FollowUpAnswer created with text preserves text source', () {
      final answer = _answer('chest_pain.breathing', source: InputSource.text);
      expect(answer.inputSource, equals(InputSource.text));
    });
  });

  // ── 13. Quick-select answer preserves InputSource.quickSelect ────────────
  group('13. quick-select answer preserves InputSource.quickSelect', () {
    test('FollowUpAnswer created with quickSelect preserves quickSelect source', () {
      final answer = _answer('chest_pain.breathing', source: InputSource.quickSelect);
      expect(answer.inputSource, equals(InputSource.quickSelect));
    });
  });

  // ── 14. VHN answer preserves InputSource.vhn ─────────────────────────────
  group('14. VHN answer preserves InputSource.vhn', () {
    test('FollowUpAnswer created with vhn preserves vhn source', () {
      final answer = _answer('chest_pain.breathing', source: InputSource.vhn);
      expect(answer.inputSource, equals(InputSource.vhn));
    });
  });

  // ── 15. FollowUpQuestion JSON round-trip ─────────────────────────────────
  group('15. FollowUpQuestion JSON round-trip', () {
    test('toJson → fromJson preserves all fields', () {
      const original = FollowUpQuestion(
        id: 'test.q1',
        questionText: {
          'en': 'Test question?',
          'ta': 'சோதனை கேள்வி?',
          'hi': 'परीक्षण प्रश्न?',
        },
        priority: FollowUpPriority.safetyCritical,
        responseType: FollowUpResponseType.yesNo,
        options: ['yes', 'no'],
        target: 'testTarget',
        relatedRuleId: 'some_rule',
        requiredForSafety: true,
      );
      final json = original.toJson();
      final decoded = FollowUpQuestion.fromJson(json);
      expect(decoded.id, equals(original.id));
      expect(decoded.questionText, equals(original.questionText));
      expect(decoded.priority, equals(original.priority));
      expect(decoded.responseType, equals(original.responseType));
      expect(decoded.options, equals(original.options));
      expect(decoded.target, equals(original.target));
      expect(decoded.relatedRuleId, equals(original.relatedRuleId));
      expect(decoded.requiredForSafety, equals(original.requiredForSafety));
    });
  });

  // ── 16. FollowUpAnswer JSON round-trip ───────────────────────────────────
  group('16. FollowUpAnswer JSON round-trip', () {
    test('toJson → fromJson preserves all fields', () {
      final original = FollowUpAnswer(
        questionId: 'chest_pain.breathing',
        value: 'yes',
        inputSource: InputSource.quickSelect,
        answeredAt: _baseTime,
      );
      final json = original.toJson();
      final decoded = FollowUpAnswer.fromJson(json);
      expect(decoded.questionId, equals(original.questionId));
      expect(decoded.value, equals(original.value));
      expect(decoded.inputSource, equals(original.inputSource));
      expect(decoded.answeredAt, equals(original.answeredAt));
    });
  });

  // ── 17. Unknown enum parsing is safe ─────────────────────────────────────
  group('17. unknown enum parsing is safe', () {
    test('FollowUpPriority.fromJson with garbage returns contextual', () {
      expect(
        FollowUpPriority.fromJson('__totally_unknown__'),
        equals(FollowUpPriority.contextual),
      );
    });

    test('FollowUpPriority.fromJson with null returns contextual', () {
      expect(FollowUpPriority.fromJson(null), equals(FollowUpPriority.contextual));
    });

    test('FollowUpResponseType.fromJson with garbage returns text', () {
      expect(
        FollowUpResponseType.fromJson('__totally_unknown__'),
        equals(FollowUpResponseType.text),
      );
    });

    test('FollowUpResponseType.fromJson with null returns text', () {
      expect(FollowUpResponseType.fromJson(null), equals(FollowUpResponseType.text));
    });

    test('InputSource.fromJson with garbage returns unknown', () {
      expect(InputSource.fromJson('__garbage__'), equals(InputSource.unknown));
    });

    test('FollowUpAnswer.fromJson with unknown inputSource uses unknown', () {
      final json = {
        'questionId': 'chest_pain.breathing',
        'value': 'yes',
        'inputSource': '__bogus__',
        'answeredAt': _baseTime.toIso8601String(),
      };
      final answer = FollowUpAnswer.fromJson(json);
      expect(answer.inputSource, equals(InputSource.unknown));
    });
  });

  // ── 18. Three-question automatic limit is enforced ───────────────────────
  group('18. three-question limit', () {
    test('after 3 safety-critical answers the engine returns null question', () {
      final session = _session(symptomName: 'chest pain');
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
        _answer('chest_pain.severity', value: 'no'),
      ];
      final result = engine.evaluate(session, answers: answers);
      // All 3 chest-pain questions answered → limit reached
      expect(result.limitReached, isTrue);
      expect(result.question, isNull);
      expect(result.safetyCriticalAsked, equals(3));
    });

    test('limit constant is 3', () {
      expect(followUpSafetyCriticalLimit, equals(3));
    });

    test('after exactly 2 answers the engine still asks a question', () {
      final session = _session(symptomName: 'chest pain');
      final answers = [
        _answer('chest_pain.breathing', value: 'no'),
        _answer('chest_pain.consciousness', value: 'no'),
      ];
      final result = engine.evaluate(session, answers: answers);
      expect(result.safetyCriticalAsked, equals(2));
      expect(result.limitReached, isFalse);
      expect(result.question, isNotNull);
    });
  });

  // ── 19. Repeated evaluation is deterministic ─────────────────────────────
  group('19. repeated evaluation is deterministic', () {
    test('same session produces same result on multiple calls', () {
      final session = _session(symptomName: 'chest pain');
      final first = engine.evaluate(session);
      final second = engine.evaluate(session);
      final third = engine.evaluate(session);
      expect(first.question?.id, equals(second.question?.id));
      expect(second.question?.id, equals(third.question?.id));
    });
  });

  // ── 20. Existing 05A behaviour remains unaffected ────────────────────────
  group('20. 05A behaviour unaffected', () {
    test('TriageSession serialization still works', () {
      final session = _session(
        symptomName: 'chest pain',
        severity: SymptomSeverity.mild,
        source: InputSource.voice,
      );
      final json = session.toJson();
      final decoded = TriageSession.fromJson(json);
      expect(decoded.id, equals(session.id));
      expect(decoded.symptoms.length, equals(session.symptoms.length));
      expect(decoded.inputSource, equals(InputSource.voice));
    });

    test('PatientSymptom round-trips correctly', () {
      final symptom = PatientSymptom(
        symptomName: 'chest pain',
        inputSource: InputSource.quickSelect,
        severity: SymptomSeverity.severe,
      );
      final decoded = PatientSymptom.fromJson(symptom.toJson());
      expect(decoded.symptomName, equals(symptom.symptomName));
      expect(decoded.severity, equals(symptom.severity));
      expect(decoded.inputSource, equals(symptom.inputSource));
    });
  });

  // ── 21. Existing 05B behaviour remains unaffected ────────────────────────
  group('21. 05B behaviour unaffected', () {
    test('RedFlagEngine still flags breathing difficulty as emergency', () {
      final session = _session(symptomName: 'difficulty breathing');
      final assessment = redFlagEngine.assess(session);
      expect(assessment.hasRedFlag, isTrue);
      expect(assessment.urgency, equals(TriageUrgency.emergency));
    });

    test('RedFlagEngine still flags chest-pain-without-info as insufficientInfo', () {
      final session = _session(symptomName: 'chest pain');
      final assessment = redFlagEngine.assess(session);
      expect(assessment.missingSafetyInformation, isNotEmpty);
    });

    test('RedFlagEngine still returns no red flag for mild headache', () {
      final session = _session(
        symptomName: 'mild headache',
        severity: SymptomSeverity.mild,
      );
      final assessment = redFlagEngine.assess(session);
      expect(assessment.hasRedFlag, isFalse);
    });
  });

  // ── Bonus: question text is available in ta / hi ─────────────────────────
  group('multilingual question text', () {
    test('chest_pain.breathing question has Tamil text', () {
      final session = _session(symptomName: 'chest pain');
      final result = engine.evaluate(session);
      expect(result.question!.textFor('ta'), isNotEmpty);
    });

    test('chest_pain.breathing question has Hindi text', () {
      final session = _session(symptomName: 'chest pain');
      final result = engine.evaluate(session);
      expect(result.question!.textFor('hi'), isNotEmpty);
    });

    test('textFor falls back to English for unknown language', () {
      const q = FollowUpQuestion(
        id: 'test.q',
        questionText: {'en': 'English question?'},
        priority: FollowUpPriority.contextual,
        responseType: FollowUpResponseType.text,
        target: 'x',
      );
      expect(q.textFor('fr'), equals('English question?'));
    });
  });

  // ── Bonus: allergy engine picks breathing before swelling ─────────────────
  group('allergy question ordering', () {
    test('allergy breathing question comes before swelling question', () {
      final session = _session(symptomName: 'allergic reaction');
      final result = engine.evaluate(session);
      expect(result.question!.id, equals('allergy.breathing'));
    });

    test('after allergy breathing answered, swelling question is next', () {
      final session = _session(symptomName: 'allergic reaction');
      final answers = [_answer('allergy.breathing', value: 'no')];
      final result = engine.evaluate(session, answers: answers);
      expect(result.question?.id, equals('allergy.swelling'));
    });
  });

  // ── Bonus: FollowUpResult carries assessment ──────────────────────────────
  group('FollowUpResult carries 05B assessment', () {
    test('assessment is non-null even when question is null', () {
      final session = _session(symptomName: 'mild headache');
      final result = engine.evaluate(session);
      expect(result.assessment, isNotNull);
      expect(result.question, isNull);
    });
  });
}
