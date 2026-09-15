import '../entities/patient_symptom.dart';
import '../entities/triage_session.dart';
import '../enums/symptom_severity.dart';
import 'symptom_identifier.dart';

/// A single deterministic match of a [SymptomIdentifier] found in a
/// session, along with the severity (if any) reported alongside it and the
/// original text that matched — kept so rules and reasons can reference
/// what was actually said.
class MatchedSymptomIdentifier {
  const MatchedSymptomIdentifier({
    required this.identifier,
    required this.severity,
    required this.matchedText,
  });

  final SymptomIdentifier identifier;

  /// Severity reported on the specific [PatientSymptom]/`AssociatedSymptom`
  /// entry that matched — not a session-wide severity. `null` if that
  /// entry didn't report one.
  final SymptomSeverity? severity;

  /// The original `symptomName` text that produced this match.
  final String matchedText;
}

/// Deterministic, keyword-based matching from free-text symptom names to
/// [SymptomIdentifier]s.
///
/// This is deliberately small and NOT natural-language processing: no
/// stemming, no synonym expansion beyond the fixed list below, no fuzzy or
/// language-model matching, and no attempt to cover every phrasing a
/// patient might use (including Tamil/Hindi phrasing — this interim
/// matcher only recognizes the English keywords below). It exists purely
/// so Task 05B's rules have something deterministic to evaluate against
/// today; Task 05D's structured symptom capture is expected to make this
/// keyword step unnecessary for input that already arrives structured
/// (e.g. quick-select), since the matcher works just as well against an
/// exact canonical phrase as it does against transcribed free text.
class SymptomIdentifierMatcher {
  const SymptomIdentifierMatcher._();

  /// Matches every symptom in [session] (the main symptom and its
  /// associated symptoms) against the keyword table, returning every hit
  /// found anywhere in the session.
  static List<MatchedSymptomIdentifier> matchSession(TriageSession session) {
    final matches = <MatchedSymptomIdentifier>[];
    for (final symptom in session.symptoms) {
      matches.addAll(_matchText(symptom.symptomName, symptom.severity));
      for (final associated in symptom.associatedSymptoms) {
        matches.addAll(_matchText(associated.symptomName, associated.severity));
      }
    }
    return matches;
  }

  static List<MatchedSymptomIdentifier> _matchText(
    String text,
    SymptomSeverity? severity,
  ) {
    final lower = text.toLowerCase();
    final matches = <MatchedSymptomIdentifier>[];
    for (final entry in _keywordsByIdentifier.entries) {
      for (final keyword in entry.value) {
        int searchFrom = 0;
        while (true) {
          final index = lower.indexOf(keyword, searchFrom);
          if (index == -1) break;
          if (!_isNegatedOrNonCurrent(lower, index, keyword.length)) {
            matches.add(
              MatchedSymptomIdentifier(
                identifier: entry.key,
                severity: severity,
                matchedText: text,
              ),
            );
            break; // one match per identifier per text entry is enough
          }
          searchFrom = index + keyword.length;
        }
        if (matches.any((m) => m.identifier == entry.key)) {
          break;
        }
      }
    }
    return matches;
  }

  static bool _isNegatedOrNonCurrent(String text, int startIdx, int length) {
    final prefixStart = (startIdx - 50) > 0 ? (startIdx - 50) : 0;
    final prefix = text.substring(prefixStart, startIdx);

    final endIdx = startIdx + length;
    final suffixEnd = (endIdx + 50) < text.length ? (endIdx + 50) : text.length;
    final suffix = text.substring(endIdx, suffixEnd);

    final historicalPrefixes = [
      'mother had', 'father had', 'brother had', 'sister had', 'friend had',
      'mom had', 'dad had', 'family history', 'past history', 'history of',
      'used to have', 'years ago', 'my mother', 'my father', 'my sister',
      'my brother', 'my friend',
      'அம்மாவுக்கு', 'அப்பாவுக்கு', 'தம்பிக்கு', 'அண்ணனுக்கு', 'தங்கைக்கு',
      'நண்பருக்கு', 'முன்னாடி இருந்தது',
      'ammavukku', 'appavukku', 'munnadi irunthathu',
      'mataji ko', 'pitaji ko', 'bhai ko', 'behen ko', 'dost ko',
      'pehle tha', 'purana itihaas',
      'माताजी को', 'पिताजी को', 'भाई को', 'बहन को', 'पहले था',
    ];
    for (final hp in historicalPrefixes) {
      if (prefix.contains(hp)) return true;
    }

    final hypotheticalPrefixes = [
      'if i get', 'if i have', 'if i ever', 'what if', 'in case of', 'suppose i have',
      'ஒருவேளை வந்தால்', 'வந்தால் என்ன செய்வது', 'oruvelai vanthaal',
      'agar mujhe', 'agar kabhi', 'yadi mujhe',
      'अगर मुझे', 'अगर कभी', 'यदि मुझे',
    ];
    for (final hp in hypotheticalPrefixes) {
      if (prefix.contains(hp)) return true;
    }

    final prefixNegations = [
      r'\bno\s*$',
      r'\bnot\s+having\s*$',
      r'\bdo\s*not\s+have\s*$',
      r"\bdon'?t\s+have\s*$",
      r'\bwithout\s*$',
      r'\bnever\s+had\s*$',
      r'\bnegative\s+for\s*$',
      r'\bfree\s+of\s*$',
      r'\bdenies\s*$',
      r'\bdenying\s*$',
      r'இல்லை\s*$',
      r'இல்ல\s*$',
      r'கிடையாது\s*$',
      r'\billa\s*$',
      r'\billai\s*$',
      r'\bkedayadhu\s*$',
      r'नहीं\s*$',
      r'\bnahi\s*$',
      r'\bnahin\s*$',
    ];
    for (final pat in prefixNegations) {
      if (RegExp(pat).hasMatch(prefix.trimRight())) return true;
    }

    final nearPrefix = prefix.length > 25 ? prefix.substring(prefix.length - 25) : prefix;
    final prefixWords = [
      'no ', 'no\t', 'without ', "don't have ", 'dont have ', 'do not have ',
      'not having ', 'denies ', 'never had ', 'negative for ',
    ];
    for (final pw in prefixWords) {
      if (nearPrefix.contains(pw)) return true;
    }

    final suffixNegations = [
      r'^\s*இல்லை',
      r'^\s*இல்ல',
      r'^\s*கிடையாது',
      r'^\s*illa\b',
      r'^\s*illai\b',
      r'^\s*kedayadhu\b',
      r'^\s*இல்லைனு',
      r'^\s*இல்லைன்னு',
      r'^\s*नहीं',
      r'^\s*nahi\b',
      r'^\s*nahin\b',
      r'^\s*nahi hai\b',
      r'^\s*नहीं है',
      r'^\s*is absent\b',
      r'^\s*is ruled out\b',
      r'^\s*is negative\b',
    ];
    for (final pat in suffixNegations) {
      if (RegExp(pat).hasMatch(suffix.trimLeft())) return true;
    }

    final nearSuffix = suffix.length > 25 ? suffix.substring(0, 25) : suffix;
    final suffixWords = [
      ' இல்லை', ' இல்ல', ' கிடையாது',
      ' illa', ' illai', ' kedayadhu',
      ' nahi', ' nahin', ' nahi hai', ' नहीं', ' नहीं है',
      ' is not present', ' is absent', ' not there',
    ];
    for (final sw in suffixWords) {
      if (nearSuffix.contains(sw)) return true;
    }

    return false;
  }

  /// The fixed keyword table. Deliberately small and English-only for now
  /// — see the class doc comment for why.
  static const Map<SymptomIdentifier, List<String>> _keywordsByIdentifier = {
    SymptomIdentifier.breathingDifficulty: [
      'breathing difficulty',
      'difficulty breathing',
      'shortness of breath',
      "can't breathe",
      'cannot breathe',
      'struggling to breathe',
      'breathless',
      'gasping',
    ],
    SymptomIdentifier.unconsciousness: [
      'unconscious',
      'not responding',
      'unresponsive',
      'passed out',
      'not waking up',
    ],
    SymptomIdentifier.seizure: [
      'seizure',
      'convulsion',
      'convulsing',
      'fit',
    ],
    SymptomIdentifier.suddenFacialWeakness: [
      'facial weakness',
      'face drooping',
      'face is drooping',
      'one side of face',
      'face dropped',
    ],
    SymptomIdentifier.suddenLimbWeakness: [
      'arm weakness',
      'leg weakness',
      'limb weakness',
      'one-sided weakness',
      'one sided weakness',
      'arm is weak',
      'leg is weak',
      'cannot move arm',
      'cannot move leg',
    ],
    SymptomIdentifier.suddenSpeechDifficulty: [
      'speech difficulty',
      'slurred speech',
      'difficulty speaking',
      'cannot speak clearly',
      "can't speak clearly",
    ],
    SymptomIdentifier.chestPainOrPressure: [
      'chest pain',
      'chest pressure',
      'chest tightness',
      'pressure in chest',
      'pressure in the chest',
    ],
    SymptomIdentifier.heavyUncontrolledBleeding: [
      'heavy bleeding',
      'uncontrolled bleeding',
      'severe bleeding',
      "won't stop bleeding",
      'wont stop bleeding',
      'bleeding heavily',
      'bleeding a lot',
    ],
    SymptomIdentifier.majorTraumaInjury: [
      'major trauma',
      'severe injury',
      'major injury',
      'fell from height',
      'road accident',
      'traffic accident',
      'serious accident',
    ],
    SymptomIdentifier.severeAllergicReaction: [
      'allergic reaction',
      'anaphylaxis',
      'severe allergy',
    ],
    SymptomIdentifier.faceThroatSwelling: [
      'throat swelling',
      'tongue swelling',
      'face swelling',
      'swelling of the throat',
      'swelling of the face',
      'swelling of the tongue',
    ],
    SymptomIdentifier.severeCollapseOrShock: [
      'collapse',
      'collapsed',
      'shock',
      'fainted',
      'fainting',
      'cold and clammy',
    ],
  };
}
