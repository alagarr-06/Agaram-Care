// Small parsing/validation helpers for the facilities domain models.
// Kept dependency-free since this project uses handwritten serialization.
library;

/// Validates a required, non-empty identifier or name string. Throws an
/// [ArgumentError] if [value] is empty or whitespace-only.
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

/// Parses an optional timestamp field. Returns `null` if missing or invalid.
DateTime? parseOptionalTimestamp(Object? value) {
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

/// Reads a list of strings from decoded JSON, dropping any non-string or
/// blank entries.
List<String> readStringList(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is String && item.trim().isNotEmpty) item,
  ];
}
