/// Priority level assigned to a [FollowUpQuestion].
///
/// The engine selects only the single highest-priority unresolved question
/// per evaluation — priority ordering here determines which question wins
/// when multiple gaps exist simultaneously.
enum FollowUpPriority {
  /// Safety-critical: the answer could change whether an emergency is
  /// present. Counts toward the three-question automatic limit.
  safetyCritical,

  /// Relevant to the current triage estimate but not life-or-death in
  /// isolation. Does NOT count toward the safety-critical question limit.
  triageRelevant,

  /// Background context — helpful but not required to assess safety.
  contextual;

  String toJson() => name;

  /// Parses [value] into a [FollowUpPriority].
  ///
  /// Safe fallback: unrecognized/missing values map to [contextual] rather
  /// than throwing — an unknown priority must never block the engine.
  static FollowUpPriority fromJson(Object? value) {
    for (final p in FollowUpPriority.values) {
      if (p.name == value) return p;
    }
    return FollowUpPriority.contextual;
  }
}
