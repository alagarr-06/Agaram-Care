// Task 05E — Triage disposition state enum.
//
// Represents the high-level semantic status of a triage progression.
// Used by UI layers (Patient, VHN, Doctor) to present appropriate next steps.
library;

/// High-level disposition state of a triage assessment.
enum TriageDispositionState {
  /// Confirmed emergency red flag identified. Immediate emergency care needed.
  emergency,

  /// Confirmed urgent symptom pattern requiring prompt medical assessment.
  urgent,

  /// Incomplete or missing safety information. Further clarification needed.
  needsInformation,

  /// Triage assessment is complete with no red-flag or urgent triggers.
  assessed,

  /// Requires human clinician / VHN review before final disposition.
  humanReview;

  String toJson() => name;

  /// Safe parsing with fallback to [humanReview].
  ///
  /// Unrecognized values conservatively default to [humanReview] so that
  /// unexpected states are never silently treated as routine.
  static TriageDispositionState fromJson(Object? value) {
    for (final state in TriageDispositionState.values) {
      if (state.name == value) return state;
    }
    return TriageDispositionState.humanReview;
  }
}
