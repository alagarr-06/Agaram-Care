// Task 07B — Agaram Care Triage Safety & Decision Coverage Enhancement Tests.
//
// Covers all 28 verification scenarios from the Task 07B specification:
// 1. Unknown severity does not become routine/mild
// 2. Unknown duration does not become fabricated data
// 3. No red flag + insufficient information -> needsInformation
// 4. Explicit negative breathing answer does not trigger breathing red flag
// 5. Explicit negative chest-pain answer does not trigger chest-pain red flag
// 6. Negated Tamil symptom does not trigger red flag
// 7. Negated Tanglish symptom does not trigger red flag
// 8. Negated Hindi/Hinglish symptom does not trigger red flag
// 9. Historical symptom does not become current patient symptom
// 10. Hypothetical symptom does not become current symptom
// 11. Multiple symptoms evaluated (primary + associated)
// 12. Emergency overrides everything else
// 13. Urgent cannot be downgraded to routine
// 14. Missing safety information cannot become selfMonitor
// 15. Low AI extraction confidence cannot determine urgency
// 16. High AI extraction confidence cannot force routine
// 17. Routine requires sufficient assessment
// 18. Soon is not used as a synonym for unknown
// 19. Contradictory information handled conservatively
// 20. Explicit pregnancy vs unstated vs explicit non-pregnancy
// 21-28. Safety invariants, precedence, and regression coverage

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/action/action.dart';
import 'package:agaram_care/features/triage/domain/entities/associated_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_context.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/next_action_type.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';
import 'package:agaram_care/features/triage/domain/follow_up/follow_up.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';
import 'package:agaram_care/features/triage/domain/red_flags/symptom_identifier.dart';
import 'package:agaram_care/features/triage/domain/red_flags/symptom_identifier_matcher.dart';
import 'package:agaram_care/features/triage/domain/result/result.dart';

void main() {
  const normalizer = SymptomNormalizer();
  const redFlagEngine = RedFlagEngine();
  const followUpEngine = FollowUpEngine();
  const resultEngine = TriageResultEngine();
  const actionEngine = NextBestActionEngine();

  final baseTime = DateTime.utc(2026, 1, 10, 8, 0);

  TriageSession buildSession({
    required String primarySymptom,
    SymptomSeverity? severity,
    String? duration,
    List<AssociatedSymptom> associatedSymptoms = const [],
    PatientContext? patientContext,
    InputSource inputSource = InputSource.text,
  }) {
    return TriageSession(
      id: 'session-safety-test',
      patientId: 'patient-test',
      languageCode: 'en',
      createdAt: baseTime,
      inputSource: inputSource,
      symptoms: [
        PatientSymptom(
          symptomName: primarySymptom,
          severity: severity,
          duration: duration,
          associatedSymptoms: associatedSymptoms,
          inputSource: inputSource,
        ),
      ],
      patientContext: patientContext,
    );
  }

  group('Task 07B — Triage Safety & Decision Coverage Enhancement Tests', () {
    // 1. No red flag + insufficient information -> needsInformation
    test('1. No red flag + insufficient information results in needsInformation disposition', () {
      final session = buildSession(
        primarySymptom: 'chest pain',
        severity: null, // Unknown severity
      );
      final redFlagAssessment = redFlagEngine.assess(session);
      expect(redFlagAssessment.hasRedFlag, isFalse);
      expect(redFlagAssessment.missingSafetyInformation, isNotEmpty);

      final triageResult = resultEngine.generate(
        session,
        safetyAssessment: redFlagAssessment,
      );
      expect(triageResult.state, equals(TriageDispositionState.needsInformation));
      expect(triageResult.urgency, isNull);
      expect(triageResult.needsFollowUp, isTrue);

      final nextAction = actionEngine.determine(triageResult, session: session);
      expect(nextAction.actionType, equals(NextActionType.undetermined));
      expect(nextAction.urgency, isNull);
    });

    // 2. Unknown severity does not become routine or mild
    test('2. Unknown severity does not default to mild or routine', () {
      final extraction = normalizer.extract(
        'I have chest pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.severity, isNull);
      expect(
        extraction.warnings.any((w) => w.code == ExtractionWarningCode.missingSeverity),
        isTrue,
      );

      final session = buildSession(
        primarySymptom: extraction.symptoms.first.symptomName,
        severity: extraction.symptoms.first.severity,
      );
      final assessment = redFlagEngine.assess(session);
      // Not confirmed mild, so cannot be ruled safe
      expect(assessment.missingSafetyInformation, isNotEmpty);

      final result = resultEngine.generate(session, safetyAssessment: assessment);
      expect(result.urgency, isNull); // Conservative, not routine!
    });

    // 3. Unknown duration does not become fabricated data
    test('3. Unknown duration stays null without invented values', () {
      final extraction = normalizer.extract(
        'I have cough',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.duration, isNull);
      expect(
        extraction.warnings.any((w) => w.code == ExtractionWarningCode.missingDuration),
        isTrue,
      );
    });

    // 4. Explicit negative breathing answer does not trigger breathing red flag
    test('4. Explicit negative breathing phrasing does not trigger breathing red flag', () {
      final extraction = normalizer.extract(
        'I have fever, no difficulty breathing',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.symptomName, equals('fever'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName.contains('breathing')),
        isFalse,
      );

      // Even if raw symptom string has "no difficulty breathing"
      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'no difficulty breathing'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.breathingDifficulty), isFalse);
    });

    // 5. Explicit negative chest-pain answer does not trigger chest-pain red flag
    test('5. Explicit negative chest pain phrasing does not trigger chest-pain red flag', () {
      final extraction = normalizer.extract(
        'Patient has fever but no chest pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.symptomName, equals('fever'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName.contains('chest')),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'no chest pain'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 6. Negated Tamil symptom does not trigger positive red flag
    test('6. Negated Tamil symptom ("நெஞ்சு வலி இல்லை") does not trigger red flag', () {
      final extraction = normalizer.extract(
        'காய்ச்சல் இருக்கு ஆனால் நெஞ்சு வலி இல்லை',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(extraction.symptoms.first.symptomName, equals('fever'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName.contains('chest')),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'நெஞ்சு வலி இல்லை'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 7. Negated Tanglish symptom does not trigger positive red flag
    test('7. Negated Tanglish symptom ("nenju vali illa") does not trigger red flag', () {
      final extraction = normalizer.extract(
        'kaichal irukku aana nenju vali illa',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(extraction.symptoms.first.symptomName, equals('fever'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName.contains('chest')),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'nenju vali illa'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 8. Negated Hindi/Hinglish symptom does not trigger positive red flag
    test('8. Negated Hindi/Hinglish symptom ("seene mein dard nahi") does not trigger red flag', () {
      final extraction = normalizer.extract(
        'bukhar hai lekin seene mein dard nahi hai',
        languageCode: 'hi',
        inputSource: InputSource.voice,
      );
      expect(extraction.symptoms.first.symptomName, equals('fever'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName.contains('chest')),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'seene mein dard nahi hai'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 9. Historical symptom does not become current patient symptom
    test('9. Historical symptom ("my mother had chest pain") is not extracted as current symptom', () {
      final extraction = normalizer.extract(
        'I have cough. My mother had chest pain 5 years ago.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.symptomName, equals('cough'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName == 'chest pain'),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'my mother had chest pain'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 10. Hypothetical symptom does not become current symptom
    test('10. Hypothetical symptom ("if I ever get chest pain") is not extracted as current symptom', () {
      final extraction = normalizer.extract(
        'I have stomach pain. What if I get chest pain later?',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(extraction.symptoms.first.symptomName, equals('stomach pain'));
      expect(
        extraction.symptoms.first.associatedSymptoms.any((a) => a.symptomName == 'chest pain'),
        isFalse,
      );

      final matches = SymptomIdentifierMatcher.matchSession(
        buildSession(primarySymptom: 'if I get chest pain'),
      );
      expect(matches.any((m) => m.identifier == SymptomIdentifier.chestPainOrPressure), isFalse);
    });

    // 11. Multiple symptoms evaluated (primary + associated)
    test('11. Evaluates all symptoms in primary and associated lists for red flags', () {
      final session = buildSession(
        primarySymptom: 'fever',
        severity: SymptomSeverity.moderate,
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'breathing difficulty',
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = redFlagEngine.assess(session);
      expect(assessment.hasRedFlag, isTrue);
      expect(assessment.urgency, equals(TriageUrgency.emergency));
      expect(
        assessment.triggeredRules.map((r) => r.ruleId),
        contains('severe_breathing_difficulty'),
      );
    });

    // 12. Emergency overrides everything else
    test('12. Confirmed emergency overrides pending questions and other complaints', () {
      final session = buildSession(
        primarySymptom: 'unconscious',
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'chest pain', // chest pain alone would need follow up
            inputSource: InputSource.text,
          ),
        ],
      );
      final redFlag = redFlagEngine.assess(session);
      final triageResult = resultEngine.generate(session, safetyAssessment: redFlag);

      expect(triageResult.urgency, equals(TriageUrgency.emergency));
      expect(triageResult.state, equals(TriageDispositionState.emergency));
      expect(triageResult.needsFollowUp, isFalse);
      expect(triageResult.requiresHumanReview, isTrue);

      final nextAction = actionEngine.determine(triageResult, session: session);
      expect(nextAction.actionType, equals(NextActionType.emergencyCare));
      expect(nextAction.urgency, equals(TriageUrgency.emergency));
    });

    // 13. Urgent cannot be downgraded to routine
    test('13. Confirmed urgent concern cannot be downgraded to routine', () {
      final session = buildSession(
        primarySymptom: 'chest pain',
        severity: SymptomSeverity.moderate,
      );
      final assessment = redFlagEngine.assess(session);
      expect(assessment.urgency, equals(TriageUrgency.urgent));

      final triageResult = resultEngine.generate(session, safetyAssessment: assessment);
      expect(triageResult.urgency, equals(TriageUrgency.urgent));
      expect(triageResult.state, equals(TriageDispositionState.urgent));

      final action = actionEngine.determine(triageResult, session: session);
      expect(action.actionType, equals(NextActionType.facilityReferral));
      expect(action.urgency, equals(TriageUrgency.urgent));
    });

    // 14. Missing safety information cannot become selfMonitor
    test('14. Missing safety information cannot be routed to selfMonitor', () {
      final triageResult = TriageResult(
        sourceSessionId: 'sess-1',
        urgency: null,
        state: TriageDispositionState.needsInformation,
        title: 'Information needed',
        explanation: 'Missing safety details',
        needsFollowUp: true,
        requiresHumanReview: true,
        triggeredRuleIds: const [],
        completedAt: baseTime,
      );
      final action = actionEngine.determine(triageResult);
      expect(action.actionType, equals(NextActionType.undetermined));
      expect(action.actionType, isNot(equals(NextActionType.selfMonitor)));
    });

    // 15. Unknown severity cannot become mild
    test('15. Unknown severity is preserved as null in PatientSymptom', () {
      final extraction = normalizer.extract(
        'Difficulty breathing with unknown severity',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      final primary = extraction.symptoms.first;
      expect(primary.symptomName, equals('difficulty breathing'));
      expect(primary.severity, isNull);
    });

    // 16. Low AI confidence cannot determine urgency
    test('16. Low AI extraction confidence requires review but does not change urgency', () {
      final session = buildSession(
        primarySymptom: 'mild headache',
        severity: SymptomSeverity.mild,
      );
      final lowExtraction = ExtractionResult(
        rawInput: 'some ambiguous speech',
        languageCode: 'en',
        inputSource: InputSource.voice,
        symptoms: session.symptoms,
        confidence: const ExtractionConfidence.low(),
        warnings: const [
          ExtractionWarning(
            code: ExtractionWarningCode.lowConfidence,
            message: 'Low confidence audio',
          ),
        ],
      );

      final result = resultEngine.generate(
        session,
        extractionResult: lowExtraction,
      );
      // Urgency remains routine, but state requires human review
      expect(result.urgency, equals(TriageUrgency.routine));
      expect(result.state, equals(TriageDispositionState.humanReview));
      expect(result.requiresHumanReview, isTrue);
    });

    // 17. High AI confidence cannot force routine for an emergency
    test('17. High AI confidence cannot override an emergency red flag', () {
      final session = buildSession(
        primarySymptom: 'chest pain',
        severity: SymptomSeverity.severe,
      );
      final highExtraction = ExtractionResult(
        rawInput: 'severe chest pain',
        languageCode: 'en',
        inputSource: InputSource.text,
        symptoms: session.symptoms,
        confidence: const ExtractionConfidence.high(),
        warnings: const [],
      );

      final assessment = redFlagEngine.assess(session);
      final result = resultEngine.generate(
        session,
        safetyAssessment: assessment,
        extractionResult: highExtraction,
      );
      expect(result.urgency, equals(TriageUrgency.emergency));
      expect(result.state, equals(TriageDispositionState.emergency));
    });

    // 18. Routine requires sufficient assessment
    test('18. Routine disposition requires completed assessment with no red flags or gaps', () {
      final session = buildSession(
        primarySymptom: 'headache',
        severity: SymptomSeverity.mild,
        duration: '1 day',
      );
      final assessment = redFlagEngine.assess(session);
      final result = resultEngine.generate(session, safetyAssessment: assessment);

      expect(result.urgency, equals(TriageUrgency.routine));
      expect(result.state, equals(TriageDispositionState.assessed));
      expect(result.needsFollowUp, isFalse);

      final action = actionEngine.determine(result, session: session);
      expect(action.actionType, equals(NextActionType.selfMonitor));
    });

    // 19. Soon is not used as a synonym for unknown
    test('19. TriageUrgency.soon is not used as a placeholder for unknown safety state', () {
      final session = buildSession(primarySymptom: 'allergic reaction');
      final assessment = redFlagEngine.assess(session);
      expect(assessment.hasRedFlag, isFalse);
      expect(assessment.missingSafetyInformation, isNotEmpty);

      final result = resultEngine.generate(session, safetyAssessment: assessment);
      expect(result.urgency, isNull);
      expect(result.urgency, isNot(equals(TriageUrgency.soon)));
    });

    // 20. Contradictory information handled conservatively
    test('20. Contradictory answers/severities are escalated conservatively', () {
      // Session with mild breathing difficulty AND severe breathing difficulty entry
      final session = TriageSession(
        id: 'contradictory-sess',
        patientId: 'pat-1',
        languageCode: 'en',
        createdAt: baseTime,
        inputSource: InputSource.text,
        symptoms: [
          PatientSymptom(
            symptomName: 'breathing difficulty',
            severity: SymptomSeverity.mild,
            inputSource: InputSource.text,
          ),
          PatientSymptom(
            symptomName: 'shortness of breath',
            severity: SymptomSeverity.severe,
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = redFlagEngine.assess(session);
      // Severe breathing difficulty triggers emergency, mild cannot downgrade if another is severe
      expect(assessment.urgency, equals(TriageUrgency.emergency));
    });

    // 21. Pregnancy status: explicit true, explicit false, and null
    test('21. Pregnancy status extracts true when pregnant, false when not pregnant, null when unstated', () {
      final resUnstated = normalizer.extract(
        'Patient has fever and body ache',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(resUnstated.patientContext?.pregnancyStatus, isNull);

      final resPregnant = normalizer.extract(
        'Patient is pregnant with nausea',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(resPregnant.patientContext?.pregnancyStatus, isTrue);

      final resNotPregnantEn = normalizer.extract(
        'Patient is not pregnant, having stomach ache',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(resNotPregnantEn.patientContext?.pregnancyStatus, isFalse);

      final resNotPregnantTa = normalizer.extract(
        'கர்ப்பமாக இல்லை, காய்ச்சல் உள்ளது',
        languageCode: 'ta',
        inputSource: InputSource.text,
      );
      expect(resNotPregnantTa.patientContext?.pregnancyStatus, isFalse);

      final resNotPregnantHi = normalizer.extract(
        'गर्भवती नहीं है, सिरदर्द है',
        languageCode: 'hi',
        inputSource: InputSource.text,
      );
      expect(resNotPregnantHi.patientContext?.pregnancyStatus, isFalse);
    });

    // 22. Multiple red flags return highest urgency
    test('22. RedFlagEngine returns highest urgency when multiple rules trigger', () {
      final session = buildSession(
        primarySymptom: 'chest pain',
        severity: SymptomSeverity.moderate, // would be urgent alone
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'seizure', // emergency
            inputSource: InputSource.text,
          ),
        ],
      );
      final assessment = redFlagEngine.assess(session);
      expect(assessment.urgency, equals(TriageUrgency.emergency));
      expect(assessment.triggeredRules.length, greaterThanOrEqualTo(2));
    });

    // 23. FollowUpEngine does not exceed limit
    test('23. FollowUpEngine respects followUpSafetyCriticalLimit and marks limitReached', () {
      final session = buildSession(primarySymptom: 'chest pain');
      final answers = [
        FollowUpAnswer(
          questionId: 'chest_pain.breathing',
          value: 'no',
          inputSource: InputSource.text,
          answeredAt: baseTime,
        ),
        FollowUpAnswer(
          questionId: 'chest_pain.consciousness',
          value: 'no',
          inputSource: InputSource.text,
          answeredAt: baseTime,
        ),
        FollowUpAnswer(
          questionId: 'chest_pain.severity',
          value: 'no',
          inputSource: InputSource.text,
          answeredAt: baseTime,
        ),
      ];

      final followUp = followUpEngine.evaluate(session, answers: answers);
      expect(followUp.limitReached, isTrue);
      expect(followUp.question, isNull);
    });

    // 24. All 9 red flag rules preserve original IDs
    test('24. All 9 default red-flag rule IDs remain strictly preserved', () {
      const expectedIds = [
        'severe_breathing_difficulty',
        'unconsciousness',
        'seizure',
        'stroke_warning_sign',
        'chest_pain_or_pressure',
        'uncontrolled_heavy_bleeding',
        'major_trauma_injury',
        'severe_allergic_reaction',
        'severe_collapse_or_shock',
      ];
      final actualIds = redFlagEngine.rules.map((r) => r.id).toList();
      expect(actualIds, equals(expectedIds));
    });

    // 25. TriageSession JSON serialization integrity
    test('25. TriageSession serialization maintains patientContext and symptoms fidelity', () {
      final session = buildSession(
        primarySymptom: 'fever',
        severity: SymptomSeverity.moderate,
        duration: '2 days',
        patientContext: PatientContext(
          ageYears: 28,
          sex: 'female',
          pregnancyStatus: false,
        ),
      );
      final json = session.toJson();
      final roundTripped = TriageSession.fromJson(json);

      expect(roundTripped.patientContext?.pregnancyStatus, isFalse);
      expect(roundTripped.symptoms.first.symptomName, equals('fever'));
      expect(roundTripped.symptoms.first.severity, equals(SymptomSeverity.moderate));
    });

    // 26. TriageResult JSON serialization integrity
    test('26. TriageResult serialization maintains disposition state and rule IDs', () {
      final result = TriageResult(
        sourceSessionId: 'sess-abc',
        urgency: TriageUrgency.urgent,
        state: TriageDispositionState.urgent,
        title: 'Prompt assessment needed',
        explanation: 'Moderate chest pain reported',
        needsFollowUp: false,
        requiresHumanReview: true,
        triggeredRuleIds: const ['chest_pain_or_pressure'],
        completedAt: baseTime,
      );
      final json = result.toJson();
      final roundTripped = TriageResult.fromJson(json);

      expect(roundTripped.urgency, equals(TriageUrgency.urgent));
      expect(roundTripped.state, equals(TriageDispositionState.urgent));
      expect(roundTripped.triggeredRuleIds, contains('chest_pain_or_pressure'));
    });

    // 27. NextBestAction determinism
    test('27. NextBestAction calculation is deterministic and idempotent', () {
      final result = TriageResult(
        sourceSessionId: 'sess-1',
        urgency: TriageUrgency.emergency,
        state: TriageDispositionState.emergency,
        title: 'Emergency',
        explanation: 'Unconscious patient',
        needsFollowUp: false,
        requiresHumanReview: true,
        triggeredRuleIds: const ['unconsciousness'],
        completedAt: baseTime,
      );
      final action1 = actionEngine.determine(result);
      final action2 = actionEngine.determine(result);

      expect(action1.actionType, equals(action2.actionType));
      expect(action1.urgency, equals(action2.urgency));
      expect(action1.requiresHumanReview, equals(action2.requiresHumanReview));
    });

    // 28. No diagnostic claims in NextBestAction reasons
    test('28. NextBestAction contains no diagnosis, prescription, or clinical overreach', () {
      final result = TriageResult(
        sourceSessionId: 'sess-1',
        urgency: TriageUrgency.routine,
        state: TriageDispositionState.assessed,
        title: 'Assessed',
        explanation: 'Mild symptoms',
        needsFollowUp: false,
        requiresHumanReview: false,
        triggeredRuleIds: const [],
        completedAt: baseTime,
      );
      final action = actionEngine.determine(result);
      expect(action.reason.contains('prescribe'), isFalse);
      expect(action.reason.contains('diagnosis'), isFalse);
      expect(action.reason.contains('diagnosed'), isFalse);
      expect(action.reason.contains('medication'), isFalse);
    });
  });
}
