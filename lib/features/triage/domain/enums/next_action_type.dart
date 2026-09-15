/// Category of a future recommended next step.
///
/// This enum is a PLACEHOLDER shape only. Nothing in this task assigns a
/// value other than [undetermined] — deciding which action fits a given
/// session is a future safety-rule/decision engine's job, explicitly out
/// of scope here. Values are workflow/routing categories (who the patient
/// should be connected to next), not diagnoses or treatment decisions.
enum NextActionType {
  /// No next action has been determined yet. The correct value for an unassessed
  /// or incomplete session.
  undetermined,

  /// Low-risk, assessed situation where self-monitoring is appropriate.
  selfMonitor,

  /// General clinical-access pathway for an assessed non-emergency case.
  primaryCare,

  /// Remote clinician review via teleconsultation.
  teleconsultation,

  /// Diagnostic testing pathway explicitly indicated.
  laboratory,

  /// Specialist clinical assessment explicitly indicated.
  specialist,

  /// Physical facility-based referral or in-person urgent access.
  facilityReferral,

  /// Emergency clinical escalation.
  emergencyCare,

  // Legacy Task 05A placeholder values preserved for backward compatibility:
  selfCare,
  vhnFollowUp,
  emergencyReferral;

  String toJson() => name;

  /// Parses [value] into a [NextActionType].
  ///
  /// Safe fallback: unrecognized, missing, or malformed values fall back
  /// to [undetermined] — the same safe "nothing decided yet" state this
  /// task uses everywhere else, so a bad/old persisted value can never be
  /// misread as an actual routing decision.
  static NextActionType fromJson(Object? value) {
    for (final type in NextActionType.values) {
      if (type.name == value) return type;
    }
    return NextActionType.undetermined;
  }
}
