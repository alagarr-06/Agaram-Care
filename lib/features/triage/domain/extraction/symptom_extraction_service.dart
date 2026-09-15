// Task 05D — Symptom Extraction Service interface.
//
// Provider-independent contract for extracting structured triage facts
// from unstructured natural-language input.
//
// SAFETY PRINCIPLES:
// - The service is an EXTRACTION COMPONENT ONLY.
// - It does NOT diagnose, treat, prescribe, or assign triage urgency.
// - It does NOT recommend facilities or create referrals.
// - Implementations must never fabricate unmentioned facts.
library;

import '../enums/input_source.dart';
import 'extraction_result.dart';

/// Provider-independent abstraction for AI-assisted symptom extraction.
abstract interface class SymptomExtractionService {
  /// Extracts structured symptoms and patient context from [rawInput].
  ///
  /// [rawInput] is the unmodified text from the user (transcribed speech or typed).
  /// [languageCode] is the BCP-47 language tag (e.g. "en", "ta", "hi").
  /// [inputSource] is the provenance channel ([InputSource.voice], [InputSource.text], etc.).
  ///
  /// Implementations must return an [ExtractionResult], even on extraction failure
  /// (via [ExtractionResult.failure]), rather than throwing unhandled exceptions.
  Future<ExtractionResult> extract(
    String rawInput, {
    required String languageCode,
    required InputSource inputSource,
  });
}
