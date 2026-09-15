// Unit tests for Task 05D — AI Symptom Extraction.
//
// These tests verify that the symptom extraction layer adheres to all safety
// principles, provider independence, untrusted JSON parsing, and boundary rules:
// - Extracts explicit facts only, never invents missing facts
// - Never decides urgency, diagnosis, or treatment
// - Preserves languageCode, inputSource, and rawInput exactly
// - Parses untrusted provider JSON safely without crashing
// - Maps cleanly into TriageSession for 05B and 05C consumption
//
// Offline, deterministic tests only — no live AI or network dependencies.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/entities/patient_context.dart';
import 'package:agaram_care/features/triage/domain/entities/patient_symptom.dart';
import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';
import 'package:agaram_care/features/triage/domain/follow_up/follow_up.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';

void main() {
  const service = MockSymptomExtractionService();
  const redFlagEngine = RedFlagEngine();
  const followUpEngine = FollowUpEngine();

  group('Task 05D — AI Symptom Extraction', () {
    // 1. English symptom extraction
    test('1. English symptom extraction', () async {
      final result = await service.extract(
        'I have chest pain since yesterday.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.isSuccessful, isTrue);
      expect(result.symptoms, isNotEmpty);
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      expect(result.symptoms.first.duration, equals('since yesterday'));
      expect(result.languageCode, equals('en'));
    });

    // 2. Tamil symptom extraction
    test('2. Tamil symptom extraction', () async {
      final result = await service.extract(
        'நேத்திலிருந்து மார்பில் வலி இருக்கு.',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(result.isSuccessful, isTrue);
      expect(result.symptoms, isNotEmpty);
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      expect(result.symptoms.first.duration, equals('since yesterday'));
      expect(result.languageCode, equals('ta'));
    });

    // 3. Hindi symptom extraction
    test('3. Hindi symptom extraction', () async {
      final result = await service.extract(
        'mujhe seene mein dard hai kal se.',
        languageCode: 'hi',
        inputSource: InputSource.voice,
      );
      expect(result.isSuccessful, isTrue);
      expect(result.symptoms, isNotEmpty);
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      expect(result.symptoms.first.duration, equals('since yesterday'));
      expect(result.languageCode, equals('hi'));
    });

    // 4. Voice input source preserved
    test('4. voice input source preserved', () async {
      final result = await service.extract(
        'fever for 2 days',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      expect(result.inputSource, equals(InputSource.voice));
      expect(result.symptoms.first.inputSource, equals(InputSource.voice));
    });

    // 5. Text input source preserved
    test('5. text input source preserved', () async {
      final result = await service.extract(
        'stomach pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.inputSource, equals(InputSource.text));
      expect(result.symptoms.first.inputSource, equals(InputSource.text));
    });

    // 6. Quick-select input source preserved
    test('6. quick-select input source preserved', () async {
      final result = await service.extract(
        'headache',
        languageCode: 'en',
        inputSource: InputSource.quickSelect,
      );
      expect(result.inputSource, equals(InputSource.quickSelect));
      expect(result.symptoms.first.inputSource, equals(InputSource.quickSelect));
    });

    // 7. VHN input source preserved
    test('7. VHN input source preserved', () async {
      final result = await service.extract(
        'bleeding from wound',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(result.inputSource, equals(InputSource.vhn));
      expect(result.symptoms.first.inputSource, equals(InputSource.vhn));
    });

    // 8. Raw input preserved exactly
    test('8. raw input preserved exactly', () async {
      const originalInput = '  Nethu night la chest pain romba strong ah irundhuchu.  ';
      final result = await service.extract(
        originalInput,
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(result.rawInput, equals(originalInput));
    });

    // 9. Explicit severity extracted correctly
    test('9. explicit severity extracted correctly', () async {
      final result = await service.extract(
        'I have severe stomach pain.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.symptoms.first.severity, equals(SymptomSeverity.severe));
    });

    // 10. Missing severity remains unknown/null
    test('10. missing severity remains unknown/null', () async {
      final result = await service.extract(
        'I have stomach pain.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.symptoms.first.severity, isNull);
      expect(
        result.warnings.any((w) => w.code == ExtractionWarningCode.missingSeverity),
        isTrue,
      );
    });

    // 11. Explicit duration extracted correctly
    test('11. explicit duration extracted correctly', () async {
      final result = await service.extract(
        'I have fever for 2 days.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.symptoms.first.duration, equals('2 days'));
    });

    // 12. Missing duration remains unknown/null
    test('12. missing duration remains unknown/null', () async {
      final result = await service.extract(
        'I have fever.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.symptoms.first.duration, isNull);
      expect(
        result.warnings.any((w) => w.code == ExtractionWarningCode.missingDuration),
        isTrue,
      );
    });

    // 13. Associated symptoms extracted
    test('13. associated symptoms extracted', () async {
      final result = await service.extract(
        'I have severe chest pain and difficulty breathing.',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      expect(result.symptoms.first.associatedSymptoms, hasLength(1));
      expect(
        result.symptoms.first.associatedSymptoms.first.symptomName,
        equals('difficulty breathing'),
      );
    });

    // 14. Explicit patient age extracted
    test('14. explicit patient age extracted', () async {
      final result = await service.extract(
        'Patient is 45 years old with chest pain.',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(result.patientContext, isNotNull);
      expect(result.patientContext!.ageYears, equals(45));
    });

    // 15. Unspecified patient age remains null
    test('15. unspecified patient age remains null', () async {
      final result = await service.extract(
        'chest pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(result.patientContext?.ageYears, isNull);
    });

    // 16. Pregnancy status only extracted when explicitly stated
    test('16. pregnancy status only extracted when explicitly stated', () async {
      final pregnantResult = await service.extract(
        'Patient is pregnant and has headache.',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(pregnantResult.patientContext?.pregnancyStatus, isTrue);

      final unstatedResult = await service.extract(
        'Patient has headache.',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(unstatedResult.patientContext?.pregnancyStatus, isNull);
    });

    // 17. Allergies only extracted when explicitly stated
    test('17. allergies only extracted when explicitly stated', () async {
      final allergyResult = await service.extract(
        'I have fever and penicillin allergy.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(allergyResult.patientContext?.allergies, contains('penicillin'));

      final noMentionResult = await service.extract(
        'I have fever.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(noMentionResult.patientContext?.allergies ?? [], isEmpty);
    });

    // 18. Medications only extracted when explicitly stated
    test('18. medications only extracted when explicitly stated', () async {
      final medResult = await service.extract(
        'I have dizziness and taking metformin.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(medResult.patientContext?.currentMedications, contains('metformin'));

      final noMedResult = await service.extract(
        'I have dizziness.',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(noMedResult.patientContext?.currentMedications ?? [], isEmpty);
    });

    // 19. Unknown enum values handled safely
    test('19. unknown enum values handled safely', () {
      final untrustedJson = {
        'rawInput': 'mild cough',
        'languageCode': 'en',
        'inputSource': 'unsupported_channel_xyz',
        'symptoms': [
          {
            'symptomName': 'cough',
            'severity': 'extreme_mega_severe',
            'inputSource': 'quantum_telepathy',
          }
        ],
      };

      final result = parseUntrustedExtractionJson(
        untrustedJson,
        fallbackRawInput: 'mild cough',
        fallbackLanguageCode: 'en',
        fallbackInputSource: InputSource.text,
      );

      expect(result.inputSource, equals(InputSource.unknown));
      expect(result.symptoms.first.severity, isNull);
      expect(result.symptoms.first.inputSource, equals(InputSource.unknown));
    });

    // 20. Malformed provider JSON is handled safely
    test('20. malformed provider JSON is handled safely', () {
      final result = parseUntrustedExtractionJson(
        'not a valid json object',
        fallbackRawInput: 'raw text',
        fallbackLanguageCode: 'en',
        fallbackInputSource: InputSource.text,
      );
      expect(result.isSuccessful, isFalse);
      expect(result.failure, isNotNull);
      expect(result.failure!.reason, equals(ExtractionFailureReason.malformedOutput));
    });

    // 21. Invalid age is rejected safely
    test('21. invalid age is rejected safely', () {
      final untrustedJson = {
        'rawInput': 'patient age is 300',
        'symptoms': [{'symptomName': 'headache'}],
        'patientContext': {
          'ageYears': 300,
        },
      };

      final result = parseUntrustedExtractionJson(
        untrustedJson,
        fallbackRawInput: 'patient age is 300',
        fallbackLanguageCode: 'en',
        fallbackInputSource: InputSource.text,
      );

      expect(result.patientContext?.ageYears, isNull);
      expect(
        result.warnings.any((w) => w.field == 'ageYears'),
        isTrue,
      );
    });

    // 22. Unsupported fields are ignored/rejected safely
    test('22. unsupported fields are ignored/rejected safely', () {
      final untrustedJson = {
        'rawInput': 'chest pain',
        'symptoms': [{'symptomName': 'chest pain'}],
        'diagnosis': 'heart attack',
        'urgency': 'emergency',
        'prescription': 'aspirin 300mg',
        'referralHospital': 'Apollo Hospital',
      };

      final result = parseUntrustedExtractionJson(
        untrustedJson,
        fallbackRawInput: 'chest pain',
        fallbackLanguageCode: 'en',
        fallbackInputSource: InputSource.text,
      );

      expect(result.isSuccessful, isTrue);
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      // Verify warnings captured the unsupported fields
      expect(
        result.warnings.where((w) => w.code == ExtractionWarningCode.unsupportedField),
        hasLength(4),
      );
    });

    // 23. Low-confidence extraction produces warning/uncertainty
    test('23. low-confidence extraction produces warning/uncertainty', () async {
      final result = await service.extract(
        'xyz abc gibberish words nothing medical',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      expect(result.confidence.overall, equals(ExtractionConfidenceLevel.low));
      expect(
        result.warnings.any((w) => w.code == ExtractionWarningCode.lowConfidence),
        isTrue,
      );
    });

    // 24. Extraction does NOT decide urgency
    test('24. extraction does NOT decide urgency', () async {
      final result = await service.extract(
        'severe chest pain and unconscious',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      // ExtractionResult does not even have an urgency field
      final json = result.toJson();
      expect(json.containsKey('urgency'), isFalse);
    });

    // 25. Extraction does NOT create a diagnosis
    test('25. extraction does NOT create a diagnosis', () async {
      final result = await service.extract(
        'severe chest pain radiating to left arm',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      final json = result.toJson();
      expect(json.containsKey('diagnosis'), isFalse);
      expect(json.containsKey('treatment'), isFalse);
      expect(json.containsKey('prescription'), isFalse);
    });

    // 26. Extraction result JSON round-trip
    test('26. extraction result JSON round-trip', () {
      final original = ExtractionResult.success(
        rawInput: 'chest pain since yesterday',
        languageCode: 'ta',
        inputSource: InputSource.voice,
        symptoms: [
          PatientSymptom(
            symptomName: 'chest pain',
            inputSource: InputSource.voice,
            severity: SymptomSeverity.moderate,
            duration: 'since yesterday',
          ),
        ],
        patientContext: PatientContext(
          ageYears: 50,
          knownConditions: ['hypertension'],
        ),
        confidence: const ExtractionConfidence.high(),
        warnings: const [
          ExtractionWarning(
            code: ExtractionWarningCode.missingSeverity,
            message: 'Note',
          ),
        ],
      );

      final json = original.toJson();
      final restored = ExtractionResult.fromJson(json);

      expect(restored.rawInput, equals(original.rawInput));
      expect(restored.languageCode, equals(original.languageCode));
      expect(restored.inputSource, equals(original.inputSource));
      expect(restored.symptoms.first.symptomName, equals('chest pain'));
      expect(restored.symptoms.first.severity, equals(SymptomSeverity.moderate));
      expect(restored.patientContext?.ageYears, equals(50));
      expect(restored.confidence.overall, equals(ExtractionConfidenceLevel.high));
      expect(restored.warnings.first.code, equals(ExtractionWarningCode.missingSeverity));
    });

    // 27. Provider abstraction can be replaced with mock/test implementation
    test('27. provider abstraction can be replaced with mock/test implementation', () async {
      // Create an inline custom implementation of SymptomExtractionService
      final customService = _CustomTestExtractor();
      final result = await customService.extract(
        'custom input',
        languageCode: 'hi',
        inputSource: InputSource.text,
      );
      expect(result.symptoms.first.symptomName, equals('custom symptom'));
    });

    // 28. Provider unavailable/failure is represented safely
    test('28. provider unavailable/failure is represented safely', () async {
      const failingService = MockSymptomExtractionService(
        shouldFail: true,
        failureReason: ExtractionFailureReason.providerUnavailable,
        failureMessage: 'AI service unreachable.',
      );

      final result = await failingService.extract(
        'chest pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );

      expect(result.isSuccessful, isFalse);
      expect(result.failure, isNotNull);
      expect(result.failure!.reason, equals(ExtractionFailureReason.providerUnavailable));
      expect(result.symptoms, isEmpty);
      expect(result.patientContext, isNull);
    });

    // 29. Deterministic repeated extraction produces same result
    test('29. deterministic repeated extraction produces same result', () async {
      const input = 'severe chest pain since yesterday';
      final res1 = await service.extract(input, languageCode: 'en', inputSource: InputSource.voice);
      final res2 = await service.extract(input, languageCode: 'en', inputSource: InputSource.voice);

      expect(res1.symptoms.first.symptomName, equals(res2.symptoms.first.symptomName));
      expect(res1.symptoms.first.severity, equals(res2.symptoms.first.severity));
      expect(res1.symptoms.first.duration, equals(res2.symptoms.first.duration));
      expect(res1.confidence.overall, equals(res2.confidence.overall));
      expect(res1.warnings.length, equals(res2.warnings.length));
    });

    // 30. Extracted result can be mapped to existing TriageSession structures
    test('30. extracted result can be mapped to existing TriageSession structures and fed into 05B and 05C', () async {
      final extraction = await service.extract(
        'I have chest pain since yesterday.',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );

      // Map to TriageSession
      final session = extraction.toTriageSession(
        sessionId: 'session-001',
        patientId: 'patient-999',
        createdAt: DateTime.utc(2026, 9, 14, 12, 0),
      );

      expect(session.id, equals('session-001'));
      expect(session.symptoms, isNotEmpty);
      expect(session.symptoms.first.symptomName, equals('chest pain'));

      // Feed directly into 05B RedFlagEngine
      final assessment = redFlagEngine.assess(session);
      expect(assessment.missingSafetyInformation, isNotEmpty); // Chest pain triggers missing info

      // Feed directly into 05C FollowUpEngine
      final followUp = followUpEngine.evaluate(session);
      expect(followUp.question, isNotNull);
      expect(followUp.question!.id, equals('chest_pain.breathing'));
    });

    // 31. Tanglish / mixed language raw input preservation
    test('Tanglish mixed language preserves raw input and extracts structured facts', () async {
      const tanglish = 'Nethu night la chest pain romba strong ah irundhuchu.';
      final result = await service.extract(
        tanglish,
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );

      expect(result.rawInput, equals(tanglish));
      expect(result.symptoms.first.symptomName, equals('chest pain'));
      expect(result.symptoms.first.severity, equals(SymptomSeverity.severe));
      expect(result.symptoms.first.duration, equals('since yesterday'));
    });
  });
}

class _CustomTestExtractor implements SymptomExtractionService {
  @override
  Future<ExtractionResult> extract(
    String rawInput, {
    required String languageCode,
    required InputSource inputSource,
  }) async {
    return ExtractionResult.success(
      rawInput: rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
      symptoms: [
        PatientSymptom(
          symptomName: 'custom symptom',
          inputSource: inputSource,
        ),
      ],
    );
  }
}
