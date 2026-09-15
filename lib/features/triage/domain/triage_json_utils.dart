/// Small parsing/validation helpers shared by the triage domain models.
/// Kept dependency-free (no `json_serializable`/`freezed`) since this
/// project uses handwritten serialization throughout.
library;

/// Validates a required, non-empty identifier or name string. Throws an
/// [ArgumentError] if [value] is empty or whitespace-only — this is
/// structural validation only (a required piece of data is missing), not
/// a medical judgment.
String requireNonEmpty(String value, String fieldName) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, fieldName, 'must not be empty');
  }
  return value;
}

/// Parses a required timestamp field. Throws a [FormatException] if
/// [value] is missing or not a valid ISO-8601 string.
DateTime parseRequiredTimestamp(Object? value, String fieldName) {
  if (value is String) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
  }
  throw FormatException(
    'Invalid or missing required timestamp for "$fieldName": $value',
  );
}

/// Validates an age in years against a generous, structurally-sane range.
///
/// This is deliberately not a medical judgment — it only rejects values
/// that cannot be a real human age (negative, or implausibly large due to
/// e.g. a unit mix-up). It does not reject unusual-but-real ages. Returns
/// `null` unchanged; throws [ArgumentError] for an out-of-range non-null
/// value.
int? validateAgeYears(int? ageYears) {
  if (ageYears == null) return null;
  if (ageYears < 0 || ageYears > 130) {
    throw ArgumentError.value(
      ageYears,
      'ageYears',
      'must be between 0 and 130',
    );
  }
  return ageYears;
}

/// Reads a list of strings from decoded JSON, dropping any non-string or
/// blank entries rather than throwing — used for freeform list fields
/// (e.g. known conditions) where one bad entry shouldn't fail the parse.
List<String> readStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item,
  ];
}
