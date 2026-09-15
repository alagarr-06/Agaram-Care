// Task 05D / Task 07A — Deterministic implementation of SymptomExtractionService.
//
// This offline, deterministic extractor is used by tests and local development.
// It uses SymptomNormalizer to map multi-lingual natural language (English, Tamil,
// Tanglish, Hindi, Hinglish) to structured symptoms and patient context, produces
// structured warnings when information is missing/ambiguous, and ensures
// tests do not depend on internet, API keys, or live AI services.
library;

import '../enums/input_source.dart';
import 'extraction_failure.dart';
import 'extraction_result.dart';
import 'symptom_extraction_service.dart';
import 'symptom_normalizer.dart';

/// Offline, deterministic extractor that extracts structured facts from text.
class MockSymptomExtractionService implements SymptomExtractionService {
  const MockSymptomExtractionService({
    this.shouldFail = false,
    this.failureReason = ExtractionFailureReason.providerUnavailable,
    this.failureMessage = 'Mock service simulated failure.',
    this.normalizer = const SymptomNormalizer(),
  });

  /// Configurable flag to simulate provider unavailability or failure in tests.
  final bool shouldFail;
  final ExtractionFailureReason failureReason;
  final String failureMessage;
  final SymptomNormalizer normalizer;

  @override
  Future<ExtractionResult> extract(
    String rawInput, {
    required String languageCode,
    required InputSource inputSource,
  }) async {
    if (shouldFail) {
      return ExtractionResult.failure(
        rawInput: rawInput,
        languageCode: languageCode,
        inputSource: inputSource,
        failure: ExtractionFailure(
          reason: failureReason,
          message: failureMessage,
        ),
      );
    }

    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return ExtractionResult.failure(
        rawInput: rawInput,
        languageCode: languageCode,
        inputSource: inputSource,
        failure: const ExtractionFailure(
          reason: ExtractionFailureReason.invalidProviderResponse,
          message: 'Raw input cannot be empty.',
        ),
      );
    }

    return normalizer.extract(
      rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
    );
  }
}
