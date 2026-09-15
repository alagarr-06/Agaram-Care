// Unit tests for Task 05F — Next Best Action Engine.
//
// Verifies deterministic mapping from TriageResult to high-level NextBestAction:
// - Strict decision precedence (Emergency -> Needs Information -> Urgent -> Assessed)
// - Protection of emergency results against downgrade
// - Protection of missing/unknown information against false selfMonitor
// - Non-emergency pathways (selfMonitor, primaryCare, teleconsultation, laboratory, specialist, facilityReferral)
// - Downstream flags (facilitySelection, appointment, humanReview)
// - AI extraction confidence independence
// - JSON serialization, unknown enum safety, determinism
// - Boundary protections (no facility matching, booking, diagnosis, or prescription)

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/action/action.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/next_action_type.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';
import 'package:agaram_care/features/triage/domain/result/result.dart';

final _fixedTime = DateTime.utc(2026, 9, 14, 16, 0, 0);

TriageResult _createTriageResult({
  required String sessionId,
  required TriageDispositionState state,
  TriageUrgency? urgency,
  bool needsFollowUp = false,
  bool requiresHumanReview = false,
  String explanation = 'Test explanation',
  List<String> notes = const [],
}) {
  return TriageResult(
    sourceSessionId: sessionId,
    urgency: urgency,
    state: state,
    title: 'Test Title',
    explanation: explanation,
    needsFollowUp: needsFollowUp,
    requiresHumanReview: requiresHumanReview,
    triggeredRuleIds: urgency == TriageUrgency.emergency ? ['unconsciousness'] : const [],
    completedAt: _fixedTime,
    notes: notes,
  );
}

TriageSession _createSession({
  required String symptomName,
  SymptomSeverity? severity,
}) {
  return TriageSession(
    id: 'test-sess',
    patientId: 'patient-1',
    languageCode: 'en',
    createdAt: _fixedTime,
    inputSource: InputSource.text,
    symptoms: [
      PatientSymptom(
        symptomName: symptomName,
        inputSource: InputSource.text,
        severity: severity,
      ),
    ],
  );
}

void main() {
  const engine = NextBestActionEngine();

  group('Task 05F — Next Best Action Engine', () {
    // 1. Emergency result -> emergencyCare
    test('1. emergency result -> emergencyCare', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-em-01',
        state: TriageDispositionState.emergency,
        urgency: TriageUrgency.emergency,
        requiresHumanReview: true,
        explanation: 'Unconscious patient detected.',
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.emergencyCare));
      expect(action.urgency, equals(TriageUrgency.emergency));
      expect(action.requiresFacilitySelection, isFalse);
      expect(action.requiresAppointment, isFalse);
      expect(action.requiresHumanReview, isTrue);
      expect(action.reason, equals('Unconscious patient detected.'));
    });

    // 2. Emergency always overrides all other possible actions
    test('2. emergency always overrides all other possible actions', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-em-override',
        state: TriageDispositionState.emergency,
        urgency: TriageUrgency.emergency,
        needsFollowUp: true, // Follow-up is ignored during emergency
        notes: ['teleconsultation suggested', 'lab test needed'],
      );

      final session = _createSession(symptomName: 'teleconsultation request');
      final action = engine.determine(triageResult, session: session, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.emergencyCare));
      expect(action.urgency, equals(TriageUrgency.emergency));
    });

    // 3. NeedsInformation -> undetermined / no premature action
    test('3. needsInformation -> undetermined/no premature action', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-info-01',
        state: TriageDispositionState.needsInformation,
        needsFollowUp: true,
        requiresHumanReview: true,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.undetermined));
      expect(action.urgency, isNull);
      expect(action.requiresFacilitySelection, isFalse);
      expect(action.requiresAppointment, isFalse);
      expect(action.reason, contains('More information is needed'));
    });

    // 4. Urgent result -> facilityReferral
    test('4. urgent result -> facilityReferral', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-urg-01',
        state: TriageDispositionState.urgent,
        urgency: TriageUrgency.urgent,
        requiresHumanReview: true,
        explanation: 'Major trauma injury reported.',
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.facilityReferral));
      expect(action.urgency, equals(TriageUrgency.urgent));
      expect(action.requiresFacilitySelection, isTrue);
      expect(action.requiresAppointment, isFalse);
      expect(action.requiresHumanReview, isTrue);
      expect(action.reason, equals('Major trauma injury reported.'));
    });

    // 5. Assessed non-emergency -> conservative valid action (primaryCare default)
    test('5. assessed non-emergency -> conservative valid action (primaryCare default)', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-routine-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        requiresHumanReview: false,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.primaryCare));
      expect(action.urgency, equals(TriageUrgency.routine));
      expect(action.requiresFacilitySelection, isTrue);
      expect(action.requiresAppointment, isFalse);
    });

    // 6. Explicit low-risk assessed state -> selfMonitor
    test('6. explicit low-risk assessed state -> selfMonitor', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-mild-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        requiresHumanReview: false,
      );

      final session = _createSession(
        symptomName: 'mild cough',
        severity: SymptomSeverity.mild,
      );

      final action = engine.determine(
        triageResult,
        session: session,
        timestamp: _fixedTime,
      );

      expect(action.actionType, equals(NextActionType.selfMonitor));
      expect(action.urgency, equals(TriageUrgency.routine));
      expect(action.requiresFacilitySelection, isFalse);
      expect(action.requiresAppointment, isFalse);
      expect(action.requiresHumanReview, isFalse);
      expect(action.reason, contains('self-monitoring is appropriate'));
    });

    // 7. Explicit clinician-review state -> primaryCare
    test('7. explicit clinician-review state -> primaryCare', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-clinician-01',
        state: TriageDispositionState.humanReview,
        urgency: TriageUrgency.routine,
        requiresHumanReview: true,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.primaryCare));
      expect(action.requiresHumanReview, isTrue);
      expect(action.requiresFacilitySelection, isTrue);
    });

    // 8. Explicit remote-review suitability -> teleconsultation
    test('8. explicit remote-review suitability -> teleconsultation', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-tele-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        notes: ['teleconsultation recommended for follow-up review'],
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.teleconsultation));
      expect(action.requiresAppointment, isTrue);
      expect(action.requiresFacilitySelection, isFalse);
    });

    // 9. Explicit diagnostic-testing pathway -> laboratory
    test('9. explicit diagnostic-testing pathway -> laboratory', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-lab-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        notes: ['diagnostic test indicated for blood sugar check'],
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.laboratory));
      expect(action.requiresFacilitySelection, isTrue);
      expect(action.requiresAppointment, isTrue);
    });

    // 10. Explicit specialist pathway -> specialist
    test('10. explicit specialist pathway -> specialist', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-spec-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        notes: ['specialist consultant review needed'],
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.specialist));
      expect(action.requiresFacilitySelection, isTrue);
      expect(action.requiresAppointment, isTrue);
    });

    // 11. Explicit physical-care pathway -> facilityReferral
    test('11. explicit physical-care pathway -> facilityReferral', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-phys-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
        notes: ['in-person examination required for physical assessment'],
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, equals(NextActionType.facilityReferral));
      expect(action.requiresFacilitySelection, isTrue);
      expect(action.requiresAppointment, isFalse);
    });

    // 12. Human review flag preserved
    test('12. human review flag preserved', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-hr-01',
        state: TriageDispositionState.humanReview,
        requiresHumanReview: true,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.requiresHumanReview, isTrue);
    });

    // 13. Urgency preserved
    test('13. urgency preserved', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-urg-pres',
        state: TriageDispositionState.urgent,
        urgency: TriageUrgency.urgent,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.urgency, equals(TriageUrgency.urgent));
    });

    // 14. Reason is always present and deterministic
    test('14. reason is always present and deterministic', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-reason-01',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
      );

      final a1 = engine.determine(triageResult, timestamp: _fixedTime);
      final a2 = engine.determine(triageResult, timestamp: _fixedTime);

      expect(a1.reason, isNotEmpty);
      expect(a1.reason, equals(a2.reason));
    });

    // 15. Facility is never selected by 05F
    test('15. facility is never selected by 05F', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-nofac-01',
        state: TriageDispositionState.urgent,
        urgency: TriageUrgency.urgent,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      // Model only has requiresFacilitySelection flag; no facilityId or hospital name
      final json = action.toJson();
      expect(json.containsKey('facilityId'), isFalse);
      expect(json.containsKey('selectedHospital'), isFalse);
    });

    // 16. Appointment is never actually booked by 05F
    test('16. appointment is never actually booked by 05F', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-noapt-01',
        state: TriageDispositionState.assessed,
        notes: ['teleconsultation'],
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      final json = action.toJson();
      expect(json.containsKey('appointmentId'), isFalse);
      expect(json.containsKey('scheduledSlot'), isFalse);
    });

    // 17. AI confidence does not independently change action
    test('17. AI confidence does not independently change action', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-conf-test',
        state: TriageDispositionState.assessed,
        urgency: TriageUrgency.routine,
      );

      final highConfExtraction = ExtractionResult.success(
        rawInput: 'some input',
        languageCode: 'en',
        inputSource: InputSource.text,
        confidence: const ExtractionConfidence.high(),
      );

      final lowConfExtraction = ExtractionResult.success(
        rawInput: 'some input',
        languageCode: 'en',
        inputSource: InputSource.text,
        confidence: const ExtractionConfidence.low(),
      );

      final a1 = engine.determine(
        triageResult,
        extractionResult: highConfExtraction,
        timestamp: _fixedTime,
      );
      final a2 = engine.determine(
        triageResult,
        extractionResult: lowConfExtraction,
        timestamp: _fixedTime,
      );

      // AI confidence must not invent emergency or bypass clinical pathway
      expect(a1.actionType, equals(a2.actionType));
      expect(a1.actionType, equals(NextActionType.primaryCare));
    });

    // 18. Unknown / missing information never becomes selfMonitor
    test('18. unknown/missing information never becomes selfMonitor', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-missing-01',
        state: TriageDispositionState.needsInformation,
        needsFollowUp: true,
      );

      final action = engine.determine(triageResult, timestamp: _fixedTime);

      expect(action.actionType, isNot(equals(NextActionType.selfMonitor)));
      expect(action.actionType, equals(NextActionType.undetermined));
    });

    // 19. Unknown enum values are handled safely
    test('19. unknown enum values are handled safely', () {
      final json = {
        'actionType': 'space_flight_referral',
        'urgency': 'warp_speed',
        'reason': 'Valid test reason',
        'requiresFacilitySelection': true,
        'requiresAppointment': false,
        'requiresHumanReview': true,
        'generatedAt': _fixedTime.toIso8601String(),
      };

      final restored = NextBestAction.fromJson(json);

      expect(restored.actionType, equals(NextActionType.undetermined));
      expect(restored.urgency, isNull);
      expect(restored.reason, equals('Valid test reason'));
    });

    // 20. NextBestAction JSON round-trip
    test('20. NextBestAction JSON round-trip', () {
      final original = NextBestAction(
        actionType: NextActionType.facilityReferral,
        urgency: TriageUrgency.urgent,
        reason: 'Prompt hospital assessment indicated.',
        requiresFacilitySelection: true,
        requiresAppointment: false,
        requiresHumanReview: true,
        generatedAt: _fixedTime,
      );

      final json = original.toJson();
      final restored = NextBestAction.fromJson(json);

      expect(restored, equals(original));
      expect(restored.actionType, equals(NextActionType.facilityReferral));
      expect(restored.urgency, equals(TriageUrgency.urgent));
      expect(restored.generatedAt, equals(_fixedTime));
    });

    // 21. Deterministic repeated evaluation
    test('21. deterministic repeated evaluation', () {
      final triageResult = _createTriageResult(
        sessionId: 'sess-rep-01',
        state: TriageDispositionState.urgent,
        urgency: TriageUrgency.urgent,
      );

      final r1 = engine.determine(triageResult, timestamp: _fixedTime);
      final r2 = engine.determine(triageResult, timestamp: _fixedTime);
      final r3 = engine.determine(triageResult, timestamp: _fixedTime);

      expect(r1, equals(r2));
      expect(r2, equals(r3));
    });
  });
}
