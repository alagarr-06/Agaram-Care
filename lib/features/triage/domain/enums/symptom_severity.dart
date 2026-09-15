/// Patient- or VHN-reported severity of a symptom.
///
/// This is a self-/observer-reported classification only, never a computed
/// clinical judgment — nothing in this task assigns a value here.
enum SymptomSeverity {
  mild,
  moderate,
  severe;

  String toJson() => name;

  /// Parses [value] into a [SymptomSeverity], or `null` if it can't be
  /// determined.
  ///
  /// Safe fallback: unrecognized, missing, or malformed values return
  /// `null` rather than throwing *or* defaulting to one of [mild],
  /// [moderate], [severe]. Severity is deliberately nullable everywhere it
  /// is used (see [PatientSymptom.severity], [AssociatedSymptom.severity])
  /// specifically so an unreported/unparseable severity can be represented
  /// as "not known" rather than silently inventing a medically meaningful
  /// value the patient never reported.
  static SymptomSeverity? fromJson(Object? value) {
    for (final severity in SymptomSeverity.values) {
      if (severity.name == value) return severity;
    }
    return null;
  }
}
