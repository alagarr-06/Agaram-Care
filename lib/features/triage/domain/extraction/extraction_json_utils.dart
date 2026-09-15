// Task 05D — Untrusted extraction JSON parsing and validation helpers.
//
// All AI/provider output is UNTRUSTED input.
// This parser strips unsupported fields, safely parses types and enums,
// validates context fields (like age), and produces structured warnings
// for anomalies rather than throwing or fabricating medical data.
library;

import '../entities/associated_symptom.dart';
import '../entities/patient_context.dart';
import '../entities/patient_symptom.dart';
import '../enums/input_source.dart';
import '../enums/symptom_severity.dart';
import 'extraction_confidence.dart';
import 'extraction_failure.dart';
import 'extraction_result.dart';
import 'extraction_warning.dart';

/// Known / supported top-level schema keys in provider JSON.
const Set<String> _supportedTopLevelKeys = {
  'rawInput',
  'languageCode',
  'inputSource',
  'symptoms',
  'patientContext',
  'confidence',
  'warnings',
  'failure',
};

/// Safely parses an untrusted JSON map from a provider into an [ExtractionResult].
///
/// If [untrustedJson] is malformed or invalid, returns an [ExtractionResult.failure]
/// with [ExtractionFailureReason.malformedOutput].
ExtractionResult parseUntrustedExtractionJson(
  Object? untrustedJson, {
  required String fallbackRawInput,
  required String fallbackLanguageCode,
  required InputSource fallbackInputSource,
}) {
  if (untrustedJson is! Map<String, dynamic>) {
    return ExtractionResult.failure(
      rawInput: fallbackRawInput,
      languageCode: fallbackLanguageCode,
      inputSource: fallbackInputSource,
      failure: ExtractionFailure(
        reason: ExtractionFailureReason.malformedOutput,
        message: 'Provider output must be a valid JSON Map.',
        rawProviderOutput: untrustedJson?.toString(),
      ),
    );
  }

  final warnings = <ExtractionWarning>[];

  // 1. Check for unsupported top-level fields (e.g. diagnosis, urgency)
  for (final key in untrustedJson.keys) {
    if (!_supportedTopLevelKeys.contains(key)) {
      warnings.add(
        ExtractionWarning(
          code: ExtractionWarningCode.unsupportedField,
          message: 'Unsupported field "$key" was ignored.',
          field: key,
        ),
      );
    }
  }

  // 2. Raw input (Must preserve original)
  final rawInput = untrustedJson['rawInput'] is String &&
          (untrustedJson['rawInput'] as String).trim().isNotEmpty
      ? untrustedJson['rawInput'] as String
      : fallbackRawInput;

  // 3. Language code
  final languageCode = untrustedJson['languageCode'] is String &&
          (untrustedJson['languageCode'] as String).trim().isNotEmpty
      ? untrustedJson['languageCode'] as String
      : fallbackLanguageCode;

  // 4. Input source
  final inputSource = untrustedJson.containsKey('inputSource')
      ? InputSource.fromJson(untrustedJson['inputSource'])
      : fallbackInputSource;

  // 5. Failure representation if present in provider payload
  if (untrustedJson['failure'] is Map<String, dynamic>) {
    final failureMap = untrustedJson['failure'] as Map<String, dynamic>;
    return ExtractionResult.failure(
      rawInput: rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
      failure: ExtractionFailure.fromJson(failureMap),
    );
  }

  // 6. Confidence
  ExtractionConfidence confidence = const ExtractionConfidence.medium();
  if (untrustedJson['confidence'] is Map<String, dynamic>) {
    confidence = ExtractionConfidence.fromJson(
      untrustedJson['confidence'] as Map<String, dynamic>,
    );
  } else if (untrustedJson['confidence'] is String) {
    confidence = ExtractionConfidence(
      overall: ExtractionConfidenceLevel.fromJson(untrustedJson['confidence']),
    );
  }

  if (confidence.overall == ExtractionConfidenceLevel.low) {
    warnings.add(
      const ExtractionWarning(
        code: ExtractionWarningCode.lowConfidence,
        message: 'Extraction has overall low confidence. Verification recommended.',
      ),
    );
  }

  // 7. Symptoms
  final symptoms = <PatientSymptom>[];
  final rawSymptoms = untrustedJson['symptoms'];
  if (rawSymptoms is List) {
    for (var i = 0; i < rawSymptoms.length; i++) {
      final item = rawSymptoms[i];
      if (item is! Map<String, dynamic>) {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.ambiguousSymptom,
            message: 'Symptom entry at index $i is not an object and was skipped.',
          ),
        );
        continue;
      }

      final symptomName = item['symptomName'];
      if (symptomName is! String || symptomName.trim().isEmpty) {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.ambiguousSymptom,
            message: 'Symptom at index $i had an empty or missing name and was skipped.',
          ),
        );
        continue;
      }

      // Safe severity parsing
      SymptomSeverity? severity;
      if (item.containsKey('severity') && item['severity'] != null) {
        severity = SymptomSeverity.fromJson(item['severity']);
      } else {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.missingSeverity,
            message: 'Severity was not explicitly stated for "$symptomName".',
            field: 'severity',
          ),
        );
      }

      // Duration
      String? duration;
      if (item['duration'] is String && (item['duration'] as String).trim().isNotEmpty) {
        duration = (item['duration'] as String).trim();
      } else {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.missingDuration,
            message: 'Duration was not explicitly stated for "$symptomName".',
            field: 'duration',
          ),
        );
      }

      // Associated symptoms
      final associatedSymptoms = <AssociatedSymptom>[];
      final rawAssociated = item['associatedSymptoms'];
      if (rawAssociated is List) {
        for (final assoc in rawAssociated) {
          if (assoc is Map<String, dynamic>) {
            final assocName = assoc['symptomName'];
            if (assocName is String && assocName.trim().isNotEmpty) {
              associatedSymptoms.add(
                AssociatedSymptom(
                  symptomName: assocName.trim(),
                  inputSource: assoc.containsKey('inputSource')
                      ? InputSource.fromJson(assoc['inputSource'])
                      : inputSource,
                  severity: assoc.containsKey('severity') && assoc['severity'] != null
                      ? SymptomSeverity.fromJson(assoc['severity'])
                      : null,
                  duration: assoc['duration'] is String ? assoc['duration'] as String : null,
                ),
              );
            }
          }
        }
      }

      symptoms.add(
        PatientSymptom(
          symptomName: symptomName.trim(),
          inputSource: item.containsKey('inputSource')
              ? InputSource.fromJson(item['inputSource'])
              : inputSource,
          severity: severity,
          duration: duration,
          associatedSymptoms: associatedSymptoms,
        ),
      );
    }
  }

  // 8. Patient Context
  PatientContext? patientContext;
  final rawContext = untrustedJson['patientContext'];
  if (rawContext is Map<String, dynamic>) {
    int? ageYears;
    if (rawContext.containsKey('ageYears') && rawContext['ageYears'] != null) {
      final rawAge = rawContext['ageYears'];
      if (rawAge is int) {
        if (rawAge < 0 || rawAge > 130) {
          warnings.add(
            ExtractionWarning(
              code: ExtractionWarningCode.incompleteContext,
              message: 'Invalid age $rawAge ignored (must be 0-130).',
              field: 'ageYears',
            ),
          );
        } else {
          ageYears = rawAge;
        }
      } else {
        warnings.add(
          const ExtractionWarning(
            code: ExtractionWarningCode.incompleteContext,
            message: 'Non-integer age ignored.',
            field: 'ageYears',
          ),
        );
      }
    }

    final sex = rawContext['sex'] is String ? (rawContext['sex'] as String).trim() : null;
    final pregnancyStatus = rawContext['pregnancyStatus'] is bool
        ? rawContext['pregnancyStatus'] as bool
        : null;

    final knownConditions = _parseStringList(rawContext['knownConditions']);
    final currentMedications = _parseStringList(rawContext['currentMedications']);
    final allergies = _parseStringList(rawContext['allergies']);

    patientContext = PatientContext(
      ageYears: ageYears,
      sex: sex,
      pregnancyStatus: pregnancyStatus,
      knownConditions: knownConditions,
      currentMedications: currentMedications,
      allergies: allergies,
    );
  }

  // 9. Merge any warnings provided in the JSON payload
  if (untrustedJson['warnings'] is List) {
    for (final w in untrustedJson['warnings'] as List) {
      if (w is Map<String, dynamic>) {
        warnings.add(ExtractionWarning.fromJson(w));
      }
    }
  }

  return ExtractionResult.success(
    rawInput: rawInput,
    languageCode: languageCode,
    inputSource: inputSource,
    symptoms: symptoms,
    patientContext: patientContext,
    confidence: confidence,
    warnings: warnings,
  );
}

List<String> _parseStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item.trim(),
  ];
}
