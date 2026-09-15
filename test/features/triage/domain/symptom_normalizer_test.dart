// Task 07A — Symptom Normalizer Unit Tests.
//
// Verifies normalization across English, Tamil script, Tanglish, Hindi, and Hinglish.
// Confirms that missing severity and duration stay null and do not invent facts.

import 'package:flutter_test/flutter_test.dart';

import 'package:agaram_care/features/triage/domain/enums/input_source.dart';
import 'package:agaram_care/features/triage/domain/enums/symptom_severity.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';

void main() {
  const normalizer = SymptomNormalizer();

  group('Task 07A — Symptom Normalizer Tests', () {
    // English symptoms
    test('normalizes English canonical symptoms', () {
      final res1 = normalizer.extract(
        'Severe chest pain since morning',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(res1.symptoms.first.symptomName, equals('chest pain'));
      expect(res1.symptoms.first.severity, equals(SymptomSeverity.severe));
      expect(res1.symptoms.first.duration, equals('since morning'));

      final res2 = normalizer.extract(
        'Mild difficulty breathing for 3 hours',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      expect(res2.symptoms.first.symptomName, equals('difficulty breathing'));
      expect(res2.symptoms.first.severity, equals(SymptomSeverity.mild));
      expect(res2.symptoms.first.duration, equals('3 hours'));

      final res3 = normalizer.extract(
        'Moderate stomach pain',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(res3.symptoms.first.symptomName, equals('stomach pain'));
      expect(res3.symptoms.first.severity, equals(SymptomSeverity.moderate));
      expect(res3.symptoms.first.duration, isNull);
    });

    // Tamil script symptoms
    test('normalizes Tamil script symptoms', () {
      final res1 = normalizer.extract(
        'கடுமையான மார்பு வலி',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(res1.symptoms.first.symptomName, equals('chest pain'));
      expect(res1.symptoms.first.severity, equals(SymptomSeverity.severe));

      final res2 = normalizer.extract(
        'லேசான தலைவலி இன்று காலை முதல்',
        languageCode: 'ta',
        inputSource: InputSource.text,
      );
      expect(res2.symptoms.first.symptomName, equals('headache'));
      expect(res2.symptoms.first.severity, equals(SymptomSeverity.mild));
      expect(res2.symptoms.first.duration, equals('since morning'));

      final res3 = normalizer.extract(
        'மூச்சு திணறல் மற்றும் காய்ச்சல்',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(res3.symptoms.first.symptomName, equals('difficulty breathing'));
      expect(res3.symptoms.first.associatedSymptoms, hasLength(1));
      expect(res3.symptoms.first.associatedSymptoms.first.symptomName, equals('fever'));
    });

    // Tanglish symptoms
    test('normalizes Tanglish symptoms', () {
      final res1 = normalizer.extract(
        'nenju vali romba athigam nethu la irunthu',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(res1.symptoms.first.symptomName, equals('chest pain'));
      expect(res1.symptoms.first.severity, equals(SymptomSeverity.severe));
      expect(res1.symptoms.first.duration, equals('since yesterday'));

      final res2 = normalizer.extract(
        'moochu vida mudiyala thideer onset',
        languageCode: 'ta',
        inputSource: InputSource.voice,
      );
      expect(res2.symptoms.first.symptomName, equals('difficulty breathing'));
      expect(res2.symptoms.first.duration, equals('sudden onset'));

      final res3 = normalizer.extract(
        'vayiru vali konjam irukku',
        languageCode: 'ta',
        inputSource: InputSource.text,
      );
      expect(res3.symptoms.first.symptomName, equals('stomach pain'));
      expect(res3.symptoms.first.severity, equals(SymptomSeverity.mild));
    });

    // Hindi script symptoms
    test('normalizes Hindi script symptoms', () {
      final res1 = normalizer.extract(
        'सीने में तेज दर्द कल से',
        languageCode: 'hi',
        inputSource: InputSource.voice,
      );
      expect(res1.symptoms.first.symptomName, equals('chest pain'));
      expect(res1.symptoms.first.severity, equals(SymptomSeverity.severe));
      expect(res1.symptoms.first.duration, equals('since yesterday'));

      final res2 = normalizer.extract(
        'हल्का बुखार 2 दिन से',
        languageCode: 'hi',
        inputSource: InputSource.text,
      );
      expect(res2.symptoms.first.symptomName, equals('fever'));
      expect(res2.symptoms.first.severity, equals(SymptomSeverity.mild));
      expect(res2.symptoms.first.duration, equals('2 days'));
    });

    // Hinglish symptoms
    test('normalizes Hinglish symptoms', () {
      final res1 = normalizer.extract(
        'seene me dard bahut tez hai kal se',
        languageCode: 'hi',
        inputSource: InputSource.voice,
      );
      expect(res1.symptoms.first.symptomName, equals('chest pain'));
      expect(res1.symptoms.first.severity, equals(SymptomSeverity.severe));
      expect(res1.symptoms.first.duration, equals('since yesterday'));

      final res2 = normalizer.extract(
        'saans lene me dikkat achanak shuru hui',
        languageCode: 'hi',
        inputSource: InputSource.voice,
      );
      expect(res2.symptoms.first.symptomName, equals('difficulty breathing'));
      expect(res2.symptoms.first.duration, equals('sudden onset'));

      final res3 = normalizer.extract(
        'thoda sar dard hai aaj subah se',
        languageCode: 'hi',
        inputSource: InputSource.text,
      );
      expect(res3.symptoms.first.symptomName, equals('headache'));
      expect(res3.symptoms.first.severity, equals(SymptomSeverity.mild));
      expect(res3.symptoms.first.duration, equals('since morning'));
    });

    // Unstated severity and duration stay null
    test('leaves unstated severity and duration null without inventing facts', () {
      final res = normalizer.extract(
        'I have cough',
        languageCode: 'en',
        inputSource: InputSource.text,
      );
      expect(res.symptoms.first.symptomName, equals('cough'));
      expect(res.symptoms.first.severity, isNull);
      expect(res.symptoms.first.duration, isNull);
      expect(res.warnings.any((w) => w.code == ExtractionWarningCode.missingSeverity), isTrue);
      expect(res.warnings.any((w) => w.code == ExtractionWarningCode.missingDuration), isTrue);
    });

    // Patient Context extraction
    test('extracts patient context across languages', () {
      final res = normalizer.extract(
        'Patient is 52 years old female with diabetic and taking insulin and high bp',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(res.patientContext?.ageYears, equals(52));
      expect(res.patientContext?.sex, equals('female'));
      expect(res.patientContext?.knownConditions, contains('diabetes'));
      expect(res.patientContext?.knownConditions, contains('hypertension'));
      expect(res.patientContext?.currentMedications, contains('insulin'));
    });

    test('extracts pregnancy status only when explicitly stated', () {
      final res = normalizer.extract(
        'Patient is pregnant with severe headache',
        languageCode: 'en',
        inputSource: InputSource.vhn,
      );
      expect(res.patientContext?.pregnancyStatus, isTrue);
    });

    test('returns low confidence and warning for unrecognizable text', () {
      final res = normalizer.extract(
        'blablabla completely unrelated noise',
        languageCode: 'en',
        inputSource: InputSource.voice,
      );
      expect(res.confidence.overall, equals(ExtractionConfidenceLevel.low));
      expect(res.warnings.any((w) => w.code == ExtractionWarningCode.unrecognizedPhrase), isTrue);
      expect(res.symptoms, isEmpty);
    });
  });
}
