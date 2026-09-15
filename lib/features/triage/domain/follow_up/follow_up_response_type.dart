/// The kind of answer a [FollowUpQuestion] expects.
///
/// Used by the application layer to decide which input widget to render.
/// The domain engine itself never renders UI — it only sets this field so
/// callers know what format of answer to collect.
enum FollowUpResponseType {
  /// Yes/No binary choice.
  yesNo,

  /// One option from a short, closed list supplied in
  /// [FollowUpQuestion.options].
  singleChoice,

  /// Free-text entry.
  text,

  /// A whole number (e.g. duration in days).
  number;

  String toJson() => name;

  /// Parses [value] into a [FollowUpResponseType].
  ///
  /// Safe fallback: unrecognized/missing values map to [text] — a neutral
  /// response type that never loses the answer.
  static FollowUpResponseType fromJson(Object? value) {
    for (final r in FollowUpResponseType.values) {
      if (r.name == value) return r;
    }
    return FollowUpResponseType.text;
  }
}
