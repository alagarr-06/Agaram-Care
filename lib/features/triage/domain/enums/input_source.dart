/// Where a piece of patient information entered the triage pipeline from.
///
/// Voice, typed text, quick-select taps, and VHN-assisted entry must all be
/// able to produce the same downstream domain objects — this enum only
/// records which channel a given entry came through.
enum InputSource {
  voice,
  text,
  quickSelect,
  vhn,

  /// The input channel could not be determined (e.g. an unrecognized or
  /// malformed serialized value). Distinct from any real channel — using
  /// this instead of guessing avoids inventing the patient's input
  /// provenance.
  unknown;

  String toJson() => name;

  /// Parses [value] into an [InputSource].
  ///
  /// Safe fallback: unrecognized, missing, or malformed values map to
  /// [InputSource.unknown] rather than being guessed as any real channel.
  /// Earlier revisions of this model fell back to [InputSource.text],
  /// which was wrong: silently turning unrecognized data into "typed by
  /// the patient" invents provenance that was never actually reported.
  /// [unknown] makes "we don't know how this was captured" an honest,
  /// explicit state instead.
  static InputSource fromJson(Object? value) {
    for (final source in InputSource.values) {
      if (source.name == value) return source;
    }
    return InputSource.unknown;
  }
}

