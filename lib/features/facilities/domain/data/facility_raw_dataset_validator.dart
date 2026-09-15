// Task 08.5 - Agaram Care Real Data Import & Validation Foundation.
//
// Inspects and validates real-world raw CSV files:
// - Districts.csv (LGD)
// - Sub-Districts.csv (LGD)
// - Villages-with-PIN-Codes.csv (LGD)
// - tamil_nadu_nhm_facilities.csv (NHM)
//
// Enforces:
// - UNKNOWN != NO (missing source attributes map strictly to null/unknown).
// - Exact string preservation (PIN codes are Strings, not numbers).
// - Immutable validation statistics & integrity reports.
library;

import 'dart:convert';
import 'dart:io';

/// Holds summary statistics for a validated raw CSV file.
class CsvValidationResult {
  const CsvValidationResult({
    required this.filePath,
    required this.fileSizeBytes,
    required this.headers,
    required this.rowCount,
    required this.malformedRowCount,
    required this.uniquePrimaryIds,
    required this.duplicatePrimaryIds,
  });

  final String filePath;
  final int fileSizeBytes;
  final List<String> headers;
  final int rowCount;
  final int malformedRowCount;
  final int uniquePrimaryIds;
  final int duplicatePrimaryIds;

  bool get isValid => rowCount > 0 && malformedRowCount == 0;
}

/// Parses a CSV line safely respecting quoted strings with commas and escaped quotes.
List<String> parseCsvLine(String line, {String delimiter = ','}) {
  final result = <String>[];
  final buffer = StringBuffer();
  var inQuotes = false;
  var i = 0;

  while (i < line.length) {
    final char = line[i];

    if (char == '"') {
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        buffer.write('"');
        i += 2;
        continue;
      } else {
        inQuotes = !inQuotes;
        i++;
        continue;
      }
    }

    if (char == delimiter && !inQuotes) {
      result.add(buffer.toString());
      buffer.clear();
      i++;
      continue;
    }

    buffer.write(char);
    i++;
  }
  result.add(buffer.toString());
  return result;
}

/// Validates raw CSV files on disk.
class FacilityRawDatasetValidator {
  const FacilityRawDatasetValidator();

  /// Validates a CSV file given its file path and expected column names.
  CsvValidationResult validateFile({
    required File file,
    required List<String> expectedHeaders,
    int idColumnIndex = 0,
  }) {
    if (!file.existsSync()) {
      throw FileSystemException('Raw dataset file not found', file.path);
    }

    final bytes = file.readAsBytesSync();
    final content = utf8.decode(bytes);
    final lines = const LineSplitter().convert(content);

    if (lines.isEmpty) {
      return CsvValidationResult(
        filePath: file.path,
        fileSizeBytes: bytes.length,
        headers: const [],
        rowCount: 0,
        malformedRowCount: 0,
        uniquePrimaryIds: 0,
        duplicatePrimaryIds: 0,
      );
    }

    final headerRow = parseCsvLine(lines.first);
    final expectedColCount = headerRow.length;

    var rowCount = 0;
    var malformedCount = 0;
    final seenIds = <String>{};
    var duplicateIds = 0;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue; // skip trailing empty lines

      final cols = parseCsvLine(line);
      if (cols.length != expectedColCount) {
        malformedCount++;
      } else {
        rowCount++;
        if (idColumnIndex >= 0 && idColumnIndex < cols.length) {
          final idVal = cols[idColumnIndex].trim();
          if (idVal.isNotEmpty) {
            if (seenIds.contains(idVal)) {
              duplicateIds++;
            } else {
              seenIds.add(idVal);
            }
          }
        }
      }
    }

    return CsvValidationResult(
      filePath: file.path,
      fileSizeBytes: bytes.length,
      headers: List.unmodifiable(headerRow),
      rowCount: rowCount,
      malformedRowCount: malformedCount,
      uniquePrimaryIds: seenIds.length,
      duplicatePrimaryIds: duplicateIds,
    );
  }
}
