// Unit tests for Task 05E — Triage Result / Disposition.
//
// These tests verify that the triage result engine accurately summarizes
// the triage progression following the required decision precedence:
// 1. Confirmed Emergency
// 2. Confirmed Urgent
// 3. Missing Safety Information
// 4. Assessed / Non-Emergency
//
// Verifies explainability, immutability, handwritten JSON serialization,
// unknown enum safety, and integration boundaries with 05A, 05B, 05C, and 05D.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';
import 'package:agaram_care/features/triage/domain/result/result.dart';

final _fixedTime = DateTime.utc(2026, 9, 14, 15, 0, 0);

TriageSession _createSession({
  required String id,
  required String symptomName,
  SymptomSeverity? severity,
  InputSource source = InputSource.voice,
}) {
  return TriageSession(
    id: id,
    patientId: 'patient-123',
    languageCode: 'en',
    createdAt: _fixedTime,
    inputSource: source,
    symptoms: [
      PatientSymptom(
        symptomName: symptomName,
        inputSource: source,
        severity: severity,
      ),
    ],
  );
}

void main() {
  const engine = TriageResultEngine();

  group('Task 05E — Triage Result / Disposition Engine', () {
    // 1. Confirmed emergency -> emergency result
    test('1. confirmed emergency -> emergency result', () {
      final session = _createSession(
        id: 'session-emergency-01',
        symptomName: 'unconscious',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.urgency, equals(TriageUrgency.emergency));
      expect(result.state, equals(TriageDispositionState.emergency));
      expect(result.needsFollowUp, isFalse);
      expect(result.requiresHumanReview, isTrue);
      expect(result.title, equals('Emergency care needed'));
      expect(result.explanation, isNotEmpty);
      expect(result.triggeredRuleIds, contains('unconsciousness'));
    });

    // 2. Urgent confirmed concern -> urgent result
    test('2. urgent confirmed concern -> urgent result', () {
      final session = _createSession(
        id: 'session-urgent-01',
        symptomName: 'major trauma from a fall',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.urgency, equals(TriageUrgency.urgent));
      expect(result.state, equals(TriageDispositionState.urgent));
      expect(result.requiresHumanReview, isTrue);
      expect(result.title, equals('Prompt medical assessment needed'));
      expect(result.triggeredRuleIds, contains('major_trauma_injury'));
    });

    // 3. Missing safety information -> needsFollowUp true
    test('3. missing safety information -> needsFollowUp true', () {
      final session = _createSession(
        id: 'session-chest-pain-01',
        symptomName: 'chest pain',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.needsFollowUp, isTrue);
      expect(result.state, equals(TriageDispositionState.needsInformation));
      expect(result.pendingQuestionId, isNotNull);
      expect(result.title, equals('More information needed'));
    });

    // 4. Missing information is not labeled routine/safe
    test('4. missing information is not labeled routine/safe', () {
      final session = _createSession(
        id: 'session-chest-pain-02',
        symptomName: 'chest pain',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      // Must be null urgency to be conservative, never routine
      expect(result.urgency, isNull);
      expect(result.urgency, isNot(equals(TriageUrgency.routine)));
      expect(result.state, equals(TriageDispositionState.needsInformation));
    });

    // 5. Emergency overrides pending follow-up
    test('5. emergency overrides pending follow-up', () {
      final session = _createSession(
        id: 'session-multi-01',
        symptomName: 'unconscious',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.urgency, equals(TriageUrgency.emergency));
      expect(result.needsFollowUp, isFalse);
      expect(result.pendingQuestionId, isNull);
    });

    // 6. TriggeredRuleIds are preserved
    test('6. triggeredRuleIds are preserved', () {
      final session = _createSession(
        id: 'session-seizure-01',
        symptomName: 'active seizure right now',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.triggeredRuleIds, contains('seizure'));
      expect(result.sourceSessionId, equals('session-seizure-01'));
    });

    // 7. RequiresHumanReview behavior
    test('7. requiresHumanReview behavior', () {
      // Emergency requires human review
      final emergencySession = _createSession(
        id: 's-em',
        symptomName: 'unconscious',
      );
      expect(engine.generate(emergencySession).requiresHumanReview, isTrue);

      // Routine / harmless with no warnings does not require immediate human review
      final mildSession = _createSession(
        id: 's-mild',
        symptomName: 'mild runny nose',
        severity: SymptomSeverity.mild,
      );
      final routineResult = engine.generate(mildSession);
      expect(routineResult.requiresHumanReview, isFalse);
      expect(routineResult.state, equals(TriageDispositionState.assessed));
      expect(routineResult.urgency, equals(TriageUrgency.routine));
    });

    // 8. Title and explanation are deterministic
    test('8. title/explanation are deterministic', () {
      final session = _createSession(
        id: 'session-determ-01',
        symptomName: 'chest pain',
      );

      final res1 = engine.generate(session, timestamp: _fixedTime);
      final res2 = engine.generate(session, timestamp: _fixedTime);

      expect(res1.title, equals(res2.title));
      expect(res1.explanation, equals(res2.explanation));
      expect(res1.state, equals(res2.state));
    });

    // 9. AI extraction confidence does not decide urgency
    test('9. AI extraction confidence does not decide urgency', () {
      final session = _createSession(
        id: 'session-conf-01',
        symptomName: 'mild cough',
        severity: SymptomSeverity.mild,
      );

      // Low confidence extraction
      final lowConfExtraction = ExtractionResult.success(
        rawInput: 'mild cough',
        languageCode: 'en',
        inputSource: InputSource.text,
        confidence: const ExtractionConfidence.low(),
      );

      final result = engine.generate(
        session,
        extractionResult: lowConfExtraction,
        timestamp: _fixedTime,
      );

      // Low confidence should flag humanReview or add notes, but NEVER invent emergency
      expect(result.urgency, isNot(equals(TriageUrgency.emergency)));
      expect(result.urgency, equals(TriageUrgency.routine));
      expect(result.requiresHumanReview, isTrue);
      expect(result.notes.any((n) => n.contains('Extraction confidence was low')), isTrue);
    });

    // 10. Unknown information remains unknown
    test('10. unknown information remains unknown (unknown != no)', () {
      // Session with chest pain where breathing is unknown
      final session = _createSession(
        id: 'session-unknown-01',
        symptomName: 'chest pain',
      );

      final result = engine.generate(session, timestamp: _fixedTime);

      expect(result.needsFollowUp, isTrue);
      expect(result.urgency, isNull); // Kept unresolved
      expect(result.notes, isNotEmpty);
    });

    // 11. TriageResult JSON round-trip
    test('11. TriageResult JSON round-trip', () {
      final original = TriageResult(
        sourceSessionId: 'session-xyz',
        urgency: TriageUrgency.urgent,
        state: TriageDispositionState.urgent,
        title: 'Prompt medical assessment needed',
        explanation: 'Concerning trauma injury.',
        needsFollowUp: false,
        requiresHumanReview: true,
        triggeredRuleIds: ['major_trauma_injury'],
        completedAt: _fixedTime,
        pendingQuestionId: null,
        reasons: ['Major trauma reported.'],
        notes: ['Observed note.'],
      );

      final json = original.toJson();
      final restored = TriageResult.fromJson(json);

      expect(restored, equals(original));
      expect(restored.sourceSessionId, equals(original.sourceSessionId));
      expect(restored.urgency, equals(original.urgency));
      expect(restored.state, equals(original.state));
      expect(restored.completedAt, equals(original.completedAt));
    });

    // 12. Safe unknown enum parsing
    test('12. safe unknown enum parsing', () {
      final jsonWithUnknowns = {
        'sourceSessionId': 'session-unknown-enum',
        'urgency': 'super_extreme_danger',
        'state': 'flying_ambulance',
        'title': 'Test',
        'explanation': 'Test',
        'needsFollowUp': false,
        'requiresHumanReview': true,
        'triggeredRuleIds': <String>[],
        'completedAt': _fixedTime.toIso8601String(),
      };

      final result = TriageResult.fromJson(jsonWithUnknowns);

      // Unknown urgency safely falls back to null
      expect(result.urgency, isNull);
      // Unknown state safely falls back to humanReview
      expect(result.state, equals(TriageDispositionState.humanReview));
    });

    // 13. DateTime round-trip
    test('13. DateTime round-trip', () {
      final now = DateTime.utc(2026, 9, 14, 16, 20, 15, 123);
      final original = TriageResult(
        sourceSessionId: 'sess-dt',
        urgency: TriageUrgency.routine,
        state: TriageDispositionState.assessed,
        title: 'Title',
        explanation: 'Exp',
        needsFollowUp: false,
        requiresHumanReview: false,
        triggeredRuleIds: const [],
        completedAt: now,
      );

      final json = original.toJson();
      final restored = TriageResult.fromJson(json);

      expect(restored.completedAt, equals(now));
    });

    // 14. Repeated evaluation is deterministic
    test('14. repeated evaluation is deterministic', () {
      final session = _createSession(
        id: 'sess-rep',
        symptomName: 'difficulty breathing',
      );

      final r1 = engine.generate(session, timestamp: _fixedTime);
      final r2 = engine.generate(session, timestamp: _fixedTime);
      final r3 = engine.generate(session, timestamp: _fixedTime);

      expect(r1, equals(r2));
      expect(r2, equals(r3));
    });

    // 15. 05A serialization still works
    test('15. 05A serialization still works', () {
      final session = _createSession(
        id: 's-05a',
        symptomName: 'chest pain',
        severity: SymptomSeverity.moderate,
      );

      final json = session.toJson();
      final restored = TriageSession.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.symptoms.first.symptomName, equals('chest pain'));
    });
  });
}
