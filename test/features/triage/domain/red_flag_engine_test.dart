// Unit tests for the Task 05B red-flag safety/gate engine.
//
// These tests use only neutral, illustrative example data and check the
// engine's documented behavior (which rule fired, what urgency it
// produced, whether human review is flagged). They do not assert or imply
// any clinical conclusion beyond the rules' own documented, narrow scope.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/associated_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_assessment.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_rule.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_rules.dart';
import 'package:agaram_care/features/triage/domain/enums/next_action_type.dart';
void main() {
  const engine = RedFlagEngine();

  TriageSession sessionWith({
    required String symptomName,
    SymptomSeverity? severity,
    List<AssociatedSymptom> associatedSymptoms = const [],
    InputSource source = InputSource.text,
  }) {
    return TriageSession(
      id: 'session-1',
      patientId: 'patient-1',
      languageCode: 'en',
      createdAt: DateTime.utc(2026, 1, 10),
      inputSource: source,
      symptoms: [
        PatientSymptom(
          symptomName: symptomName,
          inputSource: source,
          severity: severity,
          associatedSymptoms: associatedSymptoms,
        ),
      ],
    );
  }

  // 1. No red flags → no red flag assessment.
  group('no red flags', () {
    test('a session with an unrelated mild symptom produces no red flag',
        () {
      final session = sessionWith(
        symptomName: 'mild headache',
        severity: SymptomSeverity.mild,
      );

      final assessment = engine.assess(session);

      expect(assessment.hasRedFlag, isFalse);
      expect(assessment.urgency, isNull);
      expect(assessment.triggeredRules, isEmpty);
      expect(assessment.reasons, isEmpty);
      expect(assessment.missingSafetyInformation, isEmpty);
      expect(assessment.requiresHumanReview, isFalse);
    });
  });

  // 2. Severe breathing difficulty → emergency.
  group('severe breathing difficulty', () {
    test('triggers emergency', () {
      final session = sessionWith(symptomName: 'severe breathing difficulty');
      final assessment = engine.assess(session);

      expect(assessment.hasRedFlag, isTrue);
      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('severe_breathing_difficulty'),
      );
    });

    test('unknown severity still escalates to emergency (unknown != safe)',
        () {
      final session = sessionWith(symptomName: 'shortness of breath');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
    });

    test('explicitly mild breathing difficulty is downgraded to urgent',
        () {
      final session = sessionWith(
        symptomName: 'breathing difficulty',
        severity: SymptomSeverity.mild,
      );
      final assessment = engine.assess(session);

      final rule = assessment.triggeredRules
          .firstWhere((r) => r.ruleId == 'severe_breathing_difficulty');
      expect(rule.urgency, TriageUrgency.urgent);
    });
  });

  // 3. Unconsciousness → emergency.
  group('unconsciousness', () {
    test('triggers emergency', () {
      final session = sessionWith(symptomName: 'patient is unconscious');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('unconsciousness'),
      );
    });
  });

  // 4. Seizure → emergency.
  group('seizure', () {
    test('triggers emergency', () {
      final session = sessionWith(symptomName: 'had a seizure');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('seizure'),
      );
    });
  });

  // 5. Stroke-like warning sign → emergency.
  group('stroke-like warning signs', () {
    test('sudden facial weakness triggers emergency', () {
      final session = sessionWith(symptomName: 'sudden face drooping');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('stroke_warning_sign'),
      );
    });

    test('sudden speech difficulty triggers emergency', () {
      final session = sessionWith(symptomName: 'slurred speech');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
    });

    test('sudden one-sided limb weakness triggers emergency', () {
      final session = sessionWith(symptomName: 'sudden arm weakness');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
    });
  });

  // 6. Severe/concerning chest pain → emergency or documented urgent
  // behavior, per the rule's own documented logic.
  group('chest pain', () {
    test('severe chest pain triggers emergency', () {
      final session = sessionWith(
        symptomName: 'chest pain',
        severity: SymptomSeverity.severe,
      );
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('chest_pain_or_pressure'),
      );
    });

    test('chest pain with breathing difficulty co-sign triggers emergency '
        'even without severe severity', () {
      final session = sessionWith(
        symptomName: 'chest pressure',
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'breathing difficulty',
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
    });

    test('moderate chest pain (known severity, no co-sign) is urgent, '
        'not emergency', () {
      final session = sessionWith(
        symptomName: 'chest pain',
        severity: SymptomSeverity.moderate,
      );
      final assessment = engine.assess(session);

      final rule = assessment.triggeredRules
          .firstWhere((r) => r.ruleId == 'chest_pain_or_pressure');
      expect(rule.urgency, TriageUrgency.urgent);
    });

    test('mild chest pain (explicitly known, no co-sign) does not trigger',
        () {
      final session = sessionWith(
        symptomName: 'chest pain',
        severity: SymptomSeverity.mild,
      );
      final assessment = engine.assess(session);

      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        isNot(contains('chest_pain_or_pressure')),
      );
    });
  });

  // 7. Uncontrolled heavy bleeding → emergency.
  group('heavy bleeding', () {
    test('triggers emergency', () {
      final session = sessionWith(symptomName: 'heavy bleeding from wound');
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('uncontrolled_heavy_bleeding'),
      );
    });
  });

  // 8. Severe allergic reaction with airway involvement → emergency.
  group('severe allergic reaction', () {
    test('with breathing difficulty triggers emergency', () {
      final session = sessionWith(
        symptomName: 'allergic reaction',
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'breathing difficulty',
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('severe_allergic_reaction'),
      );
    });

    test('with throat swelling triggers emergency', () {
      final session = sessionWith(
        symptomName: 'allergic reaction',
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'throat swelling',
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = engine.assess(session);

      expect(assessment.urgency, TriageUrgency.emergency);
    });
  });

  // 9. High-risk/uncertain information is not incorrectly treated as safe.
  group('unknown/insufficient information is never treated as safe', () {
    test('chest pain with no severity and no co-sign is insufficient '
        'information, not "safe" and not silently ignored', () {
      final session = sessionWith(symptomName: 'chest pain');
      final assessment = engine.assess(session);

      // Not a confirmed red flag...
      expect(assessment.hasRedFlag, isFalse);
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        isNot(contains('chest_pain_or_pressure')),
      );
      // ...but explicitly NOT silently safe either.
      expect(assessment.missingSafetyInformation, isNotEmpty);
      expect(assessment.requiresHumanReview, isTrue);
    });

    test('allergic reaction with no airway information is insufficient '
        'information, not "safe"', () {
      final session = sessionWith(symptomName: 'allergic reaction');
      final assessment = engine.assess(session);

      expect(assessment.hasRedFlag, isFalse);
      expect(assessment.missingSafetyInformation, isNotEmpty);
      expect(assessment.requiresHumanReview, isTrue);
    });
  });

  // 10. Every triggered rule has rule ID + reason.
  group('explainability', () {
    test('every triggered rule carries a non-empty ruleId and reason', () {
      final session = sessionWith(symptomName: 'severe breathing difficulty');
      final assessment = engine.assess(session);

      expect(assessment.triggeredRules, isNotEmpty);
      for (final rule in assessment.triggeredRules) {
        expect(rule.ruleId, isNotEmpty);
        expect(rule.reason, isNotEmpty);
      }
      // reasons is a convenience flattening of the same data.
      expect(
        assessment.reasons,
        assessment.triggeredRules.map((r) => r.reason).toList(),
      );
    });
  });

  // 11. requiresHumanReview is true for emergency/high-risk results.
  group('requiresHumanReview', () {
    test('is true for an emergency-triggering session', () {
      final session = sessionWith(symptomName: 'seizure');
      final assessment = engine.assess(session);
      expect(assessment.requiresHumanReview, isTrue);
    });

    test('is true for an urgent-only trigger (major trauma alone)', () {
      final session = sessionWith(symptomName: 'major trauma from a fall');
      final assessment = engine.assess(session);

      expect(assessment.requiresHumanReview, isTrue);
      final rule = assessment.triggeredRules
          .firstWhere((r) => r.ruleId == 'major_trauma_injury');
      expect(rule.urgency, TriageUrgency.urgent);
    });

    test('is false when nothing triggered and nothing is missing', () {
      final session = sessionWith(symptomName: 'runny nose');
      final assessment = engine.assess(session);
      expect(assessment.requiresHumanReview, isFalse);
    });
  });

  // 12. Multiple simultaneous red flags are handled deterministically.
  group('multiple simultaneous red flags', () {
    test('a session with two independent red flags reports both, with '
        'the highest urgency surfaced at the top level', () {
      final session = TriageSession(
        id: 'session-multi',
        patientId: 'patient-1',
        languageCode: 'en',
        createdAt: DateTime.utc(2026, 1, 10),
        inputSource: InputSource.text,
        symptoms: [
          PatientSymptom(
            symptomName: 'seizure',
            inputSource: InputSource.text,
          ),
          PatientSymptom(
            symptomName: 'major trauma from a road accident',
            inputSource: InputSource.text,
          ),
        ],
      );

      final assessment = engine.assess(session);

      final ruleIds = assessment.triggeredRules.map((r) => r.ruleId).toSet();
      expect(ruleIds, containsAll(['seizure', 'major_trauma_injury']));
      // Overall urgency is the highest of the two (emergency beats urgent).
      expect(assessment.urgency, TriageUrgency.emergency);
    });
  });

  // 13. Rule evaluation is deterministic/repeatable.
  group('determinism', () {
    test('evaluating the same session twice produces an identical result',
        () {
      final session = sessionWith(
        symptomName: 'chest pain',
        severity: SymptomSeverity.severe,
      );

      final first = engine.assess(session);
      final second = engine.assess(session);

      expect(first.hasRedFlag, second.hasRedFlag);
      expect(first.urgency, second.urgency);
      expect(first.triggeredRules, second.triggeredRules);
      expect(first.reasons, second.reasons);
      expect(first.requiresHumanReview, second.requiresHumanReview);
      expect(
        first.missingSafetyInformation,
        second.missingSafetyInformation,
      );
    });

    test('rule order in defaultRedFlagRules is fixed', () {
      expect(defaultRedFlagRules.map((r) => r.id).toList(), [
        'severe_breathing_difficulty',
        'unconsciousness',
        'seizure',
        'stroke_warning_sign',
        'chest_pain_or_pressure',
        'uncontrolled_heavy_bleeding',
        'major_trauma_injury',
        'severe_allergic_reaction',
        'severe_collapse_or_shock',
      ]);
    });
  });

  // 14. Existing TriageSession serialization remains unaffected.
  group('TriageSession serialization is unaffected by Task 05B', () {
    test('TriageSession.toJson/fromJson round-trip still works exactly as '
        'in Task 05A, independent of the red-flag engine', () {
      final session = sessionWith(
        symptomName: 'fever',
        severity: SymptomSeverity.moderate,
      );

      final roundTripped = TriageSession.fromJson(session.toJson());

      expect(roundTripped.id, session.id);
      expect(roundTripped.patientId, session.patientId);
      expect(roundTripped.languageCode, session.languageCode);
      expect(roundTripped.createdAt, session.createdAt);
      expect(roundTripped.inputSource, session.inputSource);
      expect(roundTripped.symptoms.single.symptomName, 'fever');
      expect(roundTripped.urgency, isNull);
      expect(
  roundTripped.nextAction.type,
  NextActionType.undetermined,
);
    });
  });

  group('RedFlagAssessment JSON round-trip', () {
    test('serializes and deserializes correctly, including a triggered '
        'rule and missing-information notes', () {
      const assessment = RedFlagAssessment(
        hasRedFlag: true,
        urgency: TriageUrgency.emergency,
        triggeredRules: [
          TriggeredRedFlagRule(
            ruleId: 'seizure',
            reason: 'A seizure was reported.',
            urgency: TriageUrgency.emergency,
          ),
        ],
        reasons: ['A seizure was reported.'],
        requiresHumanReview: true,
        missingSafetyInformation: ['example missing-info note'],
      );

      final roundTripped = RedFlagAssessment.fromJson(assessment.toJson());

      expect(roundTripped.hasRedFlag, assessment.hasRedFlag);
      expect(roundTripped.urgency, assessment.urgency);
      expect(roundTripped.triggeredRules, assessment.triggeredRules);
      expect(roundTripped.reasons, assessment.reasons);
      expect(roundTripped.requiresHumanReview, assessment.requiresHumanReview);
      expect(
        roundTripped.missingSafetyInformation,
        assessment.missingSafetyInformation,
      );
    });
  });
}
