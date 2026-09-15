/// Urgency classification for a triage session.
///
/// IMPORTANT: this task assigns no value to this enum anywhere. It exists
/// only so [TriageSession.urgency] and [NextAction.urgency] have somewhere
/// to hold the result once a future safety-rule/triage engine computes
/// one. No triage scoring, red-flag rules, or urgency logic are
/// implemented here.
enum TriageUrgency {
  routine,
  soon,
  urgent,
  emergency;

  String toJson() => name;

  /// Parses [value] into a [TriageUrgency], or `null` if it can't be
  /// determined.
  ///
  /// Safe fallback: unrecognized, missing, or malformed values return
  /// `null`. There is no neutral member in this enum (all four values —
  /// [routine], [soon], [urgent], [emergency] — carry real clinical
  /// meaning), so `null` is the only way to represent "not yet assessed"
  /// without inventing a fake urgency level. This is why
  /// [TriageSession.urgency] and [NextAction.urgency] are both nullable.
  static TriageUrgency? fromJson(Object? value) {
    for (final urgency in TriageUrgency.values) {
      if (urgency.name == value) return urgency;
    }
    return null;
  }
}
