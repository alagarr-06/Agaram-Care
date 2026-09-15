// Unit tests for the Task 05A triage domain model foundation.
//
// These tests use only neutral example data (generic symptom names like
// "cough" / "fever") and never assert or exercise any clinical conclusion,
// severity ranking, or urgency computation — the model itself performs no
// such logic, and these tests must not imply otherwise.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/associated_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/next_action.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_context.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/entities/triage_session.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/next_action_type.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/enums/triage_urgency.dart';

void main() {
  group('InputSource', () {
    test('parses every valid value correctly', () {
      expect(InputSource.fromJson('voice'), InputSource.voice);
      expect(InputSource.fromJson('text'), InputSource.text);
      expect(InputSource.fromJson('quickSelect'), InputSource.quickSelect);
      expect(InputSource.fromJson('vhn'), InputSource.vhn);
      expect(InputSource.fromJson('unknown'), InputSource.unknown);
    });

    test('round-trips all values through toJson/fromJson', () {
      for (final source in InputSource.values) {
        expect(InputSource.fromJson(source.toJson()), source);
      }
    });

    test('maps unknown/malformed values to InputSource.unknown, '
        'NOT InputSource.text', () {
      expect(InputSource.fromJson('carrier_pigeon'), InputSource.unknown);
      expect(InputSource.fromJson(null), InputSource.unknown);
      expect(InputSource.fromJson(42), InputSource.unknown);
      expect(InputSource.fromJson(''), InputSource.unknown);

      // Explicitly confirm it is NOT the old (incorrect) fallback.
      expect(InputSource.fromJson('carrier_pigeon'), isNot(InputSource.text));
    });
  });

  group('SymptomSeverity', () {
    test('parses every valid value correctly', () {
      expect(SymptomSeverity.fromJson('mild'), SymptomSeverity.mild);
      expect(SymptomSeverity.fromJson('moderate'), SymptomSeverity.moderate);
      expect(SymptomSeverity.fromJson('severe'), SymptomSeverity.severe);
    });

    test('round-trips all values through toJson/fromJson', () {
      for (final severity in SymptomSeverity.values) {
        expect(SymptomSeverity.fromJson(severity.toJson()), severity);
      }
    });

    test('maps unknown/malformed values to null', () {
      expect(SymptomSeverity.fromJson('extreme'), isNull);
      expect(SymptomSeverity.fromJson(null), isNull);
      expect(SymptomSeverity.fromJson(7), isNull);
    });
  });

  group('TriageUrgency', () {
    test('parses every valid value correctly', () {
      expect(TriageUrgency.fromJson('routine'), TriageUrgency.routine);
      expect(TriageUrgency.fromJson('soon'), TriageUrgency.soon);
      expect(TriageUrgency.fromJson('urgent'), TriageUrgency.urgent);
      expect(TriageUrgency.fromJson('emergency'), TriageUrgency.emergency);
    });

    test('round-trips all values through toJson/fromJson', () {
      for (final urgency in TriageUrgency.values) {
        expect(TriageUrgency.fromJson(urgency.toJson()), urgency);
      }
    });

    test('maps unknown/malformed values to null', () {
      expect(TriageUrgency.fromJson('made_up_level'), isNull);
      expect(TriageUrgency.fromJson(null), isNull);
    });
  });

  group('NextActionType', () {
    test('parses every valid value correctly', () {
      for (final type in NextActionType.values) {
        expect(NextActionType.fromJson(type.name), type);
      }
    });

    test('round-trips all values through toJson/fromJson', () {
      for (final type in NextActionType.values) {
        expect(NextActionType.fromJson(type.toJson()), type);
      }
    });

    test('maps unknown/malformed values to NextActionType.undetermined', () {
      expect(
        NextActionType.fromJson('surgery'),
        NextActionType.undetermined,
      );
      expect(NextActionType.fromJson(null), NextActionType.undetermined);
    });
  });

  group('AssociatedSymptom', () {
    test('throws ArgumentError for an empty symptomName', () {
      expect(
        () => AssociatedSymptom(symptomName: '', inputSource: InputSource.text),
        throwsArgumentError,
      );
      expect(
        () =>
            AssociatedSymptom(symptomName: '   ', inputSource: InputSource.text),
        throwsArgumentError,
      );
    });

    test('serializes to JSON with the expected shape', () {
      final symptom = AssociatedSymptom(
        symptomName: 'chills',
        inputSource: InputSource.quickSelect,
        severity: SymptomSeverity.mild,
        duration: '2 days',
      );

      expect(symptom.toJson(), {
        'symptomName': 'chills',
        'inputSource': 'quickSelect',
        'severity': 'mild',
        'duration': '2 days',
      });
    });

    test('round-trips through JSON', () {
      final symptom = AssociatedSymptom(
        symptomName: 'sore throat',
        inputSource: InputSource.vhn,
        severity: SymptomSeverity.moderate,
        duration: '1 week',
      );
      final roundTripped = AssociatedSymptom.fromJson(symptom.toJson());
      expect(roundTripped, symptom);
    });

    test('nullable fields (severity, duration) survive as null', () {
      final symptom = AssociatedSymptom(
        symptomName: 'fatigue',
        inputSource: InputSource.text,
      );
      final roundTripped = AssociatedSymptom.fromJson(symptom.toJson());
      expect(roundTripped.severity, isNull);
      expect(roundTripped.duration, isNull);
    });
  });

  group('PatientSymptom', () {
    PatientSymptom buildSymptom({InputSource source = InputSource.text}) {
      return PatientSymptom(
        symptomName: 'cough',
        inputSource: source,
        severity: SymptomSeverity.moderate,
        duration: '3 days',
        associatedSymptoms: [
          AssociatedSymptom(
            symptomName: 'sore throat',
            inputSource: InputSource.text,
          ),
        ],
      );
    }

    test('throws ArgumentError for an empty symptomName', () {
      expect(
        () => PatientSymptom(symptomName: '', inputSource: InputSource.text),
        throwsArgumentError,
      );
    });

    test('serializes to JSON with the expected shape', () {
      final symptom = PatientSymptom(
        symptomName: 'fever',
        inputSource: InputSource.voice,
        severity: SymptomSeverity.severe,
        duration: '1 day',
      );

      expect(symptom.toJson(), {
        'symptomName': 'fever',
        'inputSource': 'voice',
        'severity': 'severe',
        'duration': '1 day',
        'associatedSymptoms': [],
      });
    });

    test('round-trips through JSON, including nested associatedSymptoms',
        () {
      final symptom = buildSymptom();
      final roundTripped = PatientSymptom.fromJson(symptom.toJson());

      expect(roundTripped, symptom);
      expect(roundTripped.associatedSymptoms, hasLength(1));
      expect(roundTripped.associatedSymptoms.single.symptomName,
          'sore throat');
    });

    test('nullable fields (severity, duration) survive serialization as '
        'null when not provided', () {
      final symptom = PatientSymptom(
        symptomName: 'headache',
        inputSource: InputSource.quickSelect,
      );
      final roundTripped = PatientSymptom.fromJson(symptom.toJson());

      expect(roundTripped.severity, isNull);
      expect(roundTripped.duration, isNull);
      expect(roundTripped.associatedSymptoms, isEmpty);
    });

    test('is compatible with InputSource.voice from the current voice '
        'screen (recognized text + language code only)', () {
      // Mirrors what future application code will do with
      // voice_screen.dart's current output: a recognized-text String plus
      // a selected language code, and nothing else structured yet.
      const recognizedText = 'I have had a fever since yesterday';
      const languageCode = 'ta';

      final symptom = PatientSymptom(
        symptomName: recognizedText,
        inputSource: InputSource.voice,
      );
      final session = TriageSession(
        id: 'session-voice-1',
        patientId: 'patient-1',
        languageCode: languageCode,
        createdAt: DateTime.utc(2026, 1, 10),
        inputSource: InputSource.voice,
        symptoms: [symptom],
      );

      expect(session.inputSource, InputSource.voice);
      expect(session.symptoms.single.inputSource, InputSource.voice);
      expect(session.symptoms.single.symptomName, recognizedText);
      expect(session.languageCode, languageCode);

      final roundTripped = TriageSession.fromJson(session.toJson());
      expect(roundTripped.inputSource, InputSource.voice);
      expect(roundTripped.symptoms.single.inputSource, InputSource.voice);
      expect(roundTripped.symptoms.single.symptomName, recognizedText);
      expect(roundTripped.languageCode, languageCode);
    });
  });

  group('PatientContext', () {
    test('throws ArgumentError for an invalid (out-of-range) age', () {
      expect(
        () => PatientContext(ageYears: -1),
        throwsArgumentError,
      );
      expect(
        () => PatientContext(ageYears: 131),
        throwsArgumentError,
      );
    });

    test('accepts a valid boundary age without throwing', () {
      expect(() => PatientContext(ageYears: 0), returnsNormally);
      expect(() => PatientContext(ageYears: 130), returnsNormally);
    });

    test('round-trips through JSON', () {
      final context = PatientContext(
        ageYears: 34,
        sex: 'female',
        pregnancyStatus: false,
        knownConditions: ['asthma'],
        currentMedications: ['inhaler'],
        allergies: ['penicillin'],
      );
      final json = context.toJson();
      final roundTripped = PatientContext.fromJson(json);

      expect(roundTripped.ageYears, context.ageYears);
      expect(roundTripped.sex, context.sex);
      expect(roundTripped.pregnancyStatus, context.pregnancyStatus);
      expect(roundTripped.knownConditions, context.knownConditions);
      expect(roundTripped.currentMedications, context.currentMedications);
      expect(roundTripped.allergies, context.allergies);
    });

    test('nullable fields survive serialization as null when not provided',
        () {
      final context = PatientContext();
      final roundTripped = PatientContext.fromJson(context.toJson());

      expect(roundTripped.ageYears, isNull);
      expect(roundTripped.sex, isNull);
      expect(roundTripped.pregnancyStatus, isNull);
      expect(roundTripped.knownConditions, isEmpty);
    });
  });

  group('NextAction', () {
    test('undetermined() is the safe default', () {
      const action = NextAction.undetermined();
      expect(action.type, NextActionType.undetermined);
      expect(action.urgency, isNull);
      expect(action.reason, isNull);
    });

    test('round-trips through JSON', () {
      const action = NextAction(
        type: NextActionType.undetermined,
        urgency: null,
        reason: null,
      );
      final roundTripped = NextAction.fromJson(action.toJson());
      expect(roundTripped, action);
    });
  });

  group('TriageSession', () {
    TriageSession buildSession({String languageCode = 'en'}) {
      return TriageSession(
        id: 'session-1',
        patientId: 'patient-1',
        languageCode: languageCode,
        createdAt: DateTime.utc(2026, 1, 10, 9, 30),
        inputSource: InputSource.text,
        symptoms: [
          PatientSymptom(
            symptomName: 'fever',
            inputSource: InputSource.text,
            severity: SymptomSeverity.moderate,
          ),
        ],
        patientContext: PatientContext(ageYears: 40),
      );
    }

    test('throws ArgumentError for an empty id', () {
      expect(
        () => TriageSession(
          id: '',
          patientId: 'patient-1',
          languageCode: 'en',
          createdAt: DateTime.utc(2026, 1, 10),
          inputSource: InputSource.text,
        ),
        throwsArgumentError,
      );
    });

    test('throws ArgumentError for an empty patientId', () {
      expect(
        () => TriageSession(
          id: 'session-1',
          patientId: '   ',
          languageCode: 'en',
          createdAt: DateTime.utc(2026, 1, 10),
          inputSource: InputSource.text,
        ),
        throwsArgumentError,
      );
    });

    test('fromJson throws for missing/empty required id or patientId', () {
      final base = buildSession().toJson();

      final missingId = Map<String, dynamic>.from(base)..remove('id');
      expect(() => TriageSession.fromJson(missingId), throwsArgumentError);

      final missingPatientId = Map<String, dynamic>.from(base)
        ..remove('patientId');
      expect(
        () => TriageSession.fromJson(missingPatientId),
        throwsArgumentError,
      );
    });

    test('fromJson throws for a missing/invalid createdAt', () {
      final base = buildSession().toJson();

      final missingCreatedAt = Map<String, dynamic>.from(base)
        ..remove('createdAt');
      expect(
        () => TriageSession.fromJson(missingCreatedAt),
        throwsFormatException,
      );

      final badCreatedAt = Map<String, dynamic>.from(base)
        ..['createdAt'] = 'not-a-date';
      expect(
        () => TriageSession.fromJson(badCreatedAt),
        throwsFormatException,
      );
    });

    test('urgency and nextAction default to the safe "not yet assessed" '
        'state', () {
      final session = buildSession();
      expect(session.urgency, isNull);
      expect(session.nextAction.type, NextActionType.undetermined);
      expect(session.nextAction.urgency, isNull);
    });

    test('preserves the reported language code for en, ta, and hi', () {
      for (final code in ['en', 'ta', 'hi']) {
        final session = buildSession(languageCode: code);
        final roundTripped = TriageSession.fromJson(session.toJson());
        expect(roundTripped.languageCode, code);
      }
    });

    test('round-trips through JSON, including nested symptoms/context', () {
      final session = buildSession();
      final json = session.toJson();
      final roundTripped = TriageSession.fromJson(json);

      expect(roundTripped.id, session.id);
      expect(roundTripped.patientId, session.patientId);
      expect(roundTripped.languageCode, session.languageCode);
      expect(roundTripped.createdAt, session.createdAt);
      expect(roundTripped.inputSource, session.inputSource);
      expect(roundTripped.symptoms, hasLength(1));
      expect(roundTripped.symptoms.single.symptomName, 'fever');
      expect(roundTripped.patientContext?.ageYears, 40);
      expect(roundTripped.urgency, isNull);
      expect(roundTripped.nextAction.type, NextActionType.undetermined);
    });

    test('nullable fields (patientContext, urgency) survive serialization '
        'as null when not provided', () {
      final session = TriageSession(
        id: 'session-2',
        patientId: 'patient-2',
        languageCode: 'en',
        createdAt: DateTime.utc(2026, 1, 10),
        inputSource: InputSource.quickSelect,
      );
      final roundTripped = TriageSession.fromJson(session.toJson());

      expect(roundTripped.patientContext, isNull);
      expect(roundTripped.urgency, isNull);
      expect(roundTripped.symptoms, isEmpty);
    });

    test('an unknown serialized inputSource becomes InputSource.unknown, '
        'not InputSource.text', () {
      final json = buildSession().toJson();
      json['inputSource'] = 'some_future_channel';

      final session = TriageSession.fromJson(json);

      expect(session.inputSource, InputSource.unknown);
      expect(session.inputSource, isNot(InputSource.text));
    });

    test('symptoms list is unmodifiable', () {
      final session = buildSession();
      expect(() => session.symptoms.clear(), throwsUnsupportedError);
    });
  });
}
