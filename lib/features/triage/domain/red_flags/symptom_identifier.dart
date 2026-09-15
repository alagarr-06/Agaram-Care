/// A small, closed set of safety-relevant symptom categories that the
/// Task 05B red-flag engine knows how to reason about.
///
/// This is NOT a general symptom vocabulary and NOT an NLP/synonym system.
/// It exists only because the red-flag rules need *something* deterministic
/// to check against, and Task 05A's [PatientSymptom.symptomName] is
/// intentionally plain free text. Task 05D is expected to introduce proper
/// structured symptom capture (e.g. quick-select chips that set
/// `symptomName` to an exact canonical phrase); until then,
/// [SymptomIdentifierMatcher] does a small, fixed, keyword-based match.
enum SymptomIdentifier {
  breathingDifficulty,
  unconsciousness,
  seizure,
  suddenFacialWeakness,
  suddenLimbWeakness,
  suddenSpeechDifficulty,
  chestPainOrPressure,
  heavyUncontrolledBleeding,
  majorTraumaInjury,
  severeAllergicReaction,
  faceThroatSwelling,
  severeCollapseOrShock,
}
