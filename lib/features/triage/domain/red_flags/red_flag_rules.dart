import '../entities/triage_session.dart';
import '../enums/symptom_severity.dart';
import '../enums/triage_urgency.dart';
import 'red_flag_rule.dart';
import 'symptom_identifier.dart';
import 'symptom_identifier_matcher.dart';

/// 1. Severe breathing difficulty.
///
/// Breathing difficulty is treated as emergency-level by default, since an
/// unspecified/unknown severity must never be read as "must be mild". Only
/// an *explicitly* reported mild severity downgrades this to urgent —
/// silence about severity does not.
class BreathingDifficultyRule extends RedFlagRule {
  const BreathingDifficultyRule();

  @override
  String get id => 'severe_breathing_difficulty';

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matches = SymptomIdentifierMatcher.matchSession(session)
        .where((m) => m.identifier == SymptomIdentifier.breathingDifficulty)
        .toList();
    if (matches.isEmpty) return const RedFlagRuleEvaluation.notTriggered();

    final allExplicitlyMild =
        matches.every((m) => m.severity == SymptomSeverity.mild);
    if (allExplicitlyMild) {
      return const RedFlagRuleEvaluation.triggered(
        reason: 'Breathing difficulty was reported and explicitly rated '
            'mild; still flagged for review.',
        urgency: TriageUrgency.urgent,
      );
    }
    return const RedFlagRuleEvaluation.triggered(
      reason: 'Breathing difficulty was reported.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// 2. Unconsciousness / not responding normally.
class UnconsciousnessRule extends RedFlagRule {
  const UnconsciousnessRule();

  @override
  String get id => 'unconsciousness';

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matched = SymptomIdentifierMatcher.matchSession(session)
        .any((m) => m.identifier == SymptomIdentifier.unconsciousness);
    if (!matched) return const RedFlagRuleEvaluation.notTriggered();
    return const RedFlagRuleEvaluation.triggered(
      reason: 'Unconsciousness or not responding normally was reported.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// 3. Seizure.
class SeizureRule extends RedFlagRule {
  const SeizureRule();

  @override
  String get id => 'seizure';

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matched = SymptomIdentifierMatcher.matchSession(session)
        .any((m) => m.identifier == SymptomIdentifier.seizure);
    if (!matched) return const RedFlagRuleEvaluation.notTriggered();
    return const RedFlagRuleEvaluation.triggered(
      reason: 'A seizure was reported.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// 4. Stroke-like warning signs (sudden facial weakness, sudden one-sided
/// arm/leg weakness, sudden speech difficulty).
///
/// Any one of the three signs alone is treated as emergency-level — this
/// mirrors standard FAST-style public guidance (Face, Arms, Speech, Time)
/// where a single sign is enough to treat as a possible stroke.
class StrokeWarningSignRule extends RedFlagRule {
  const StrokeWarningSignRule();

  @override
  String get id => 'stroke_warning_sign';

  static const _signs = {
    SymptomIdentifier.suddenFacialWeakness: 'sudden facial weakness',
    SymptomIdentifier.suddenLimbWeakness: 'sudden one-sided arm/leg weakness',
    SymptomIdentifier.suddenSpeechDifficulty: 'sudden speech difficulty',
  };

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matchedIdentifiers = SymptomIdentifierMatcher.matchSession(session)
        .map((m) => m.identifier)
        .toSet();

    final matchedSigns = [
      for (final entry in _signs.entries)
        if (matchedIdentifiers.contains(entry.key)) entry.value,
    ];

    if (matchedSigns.isEmpty) return const RedFlagRuleEvaluation.notTriggered();

    return RedFlagRuleEvaluation.triggered(
      reason: 'Stroke-like warning sign(s) reported: '
          '${matchedSigns.join(', ')}.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// 5. Severe/concerning chest pain or pressure.
///
/// This is the rule the task explicitly calls out for unknown-information
/// handling: chest pain with no severity and no supporting associated
/// symptom is neither "safe" nor confidently emergency — it's
/// insufficient information, and must be surfaced as such rather than
/// silently passing the session through.
class ChestPainRule extends RedFlagRule {
  const ChestPainRule();

  @override
  String get id => 'chest_pain_or_pressure';

  /// Identifiers that, alongside chest pain, are concerning enough to
  /// treat the combination as emergency-level even without severe severity
  /// on the chest pain entry itself.
  static const _emergencyCoSigns = {
    SymptomIdentifier.breathingDifficulty,
    SymptomIdentifier.unconsciousness,
    SymptomIdentifier.severeCollapseOrShock,
  };

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final allMatches = SymptomIdentifierMatcher.matchSession(session);
    final chestPainMatches = allMatches
        .where((m) => m.identifier == SymptomIdentifier.chestPainOrPressure)
        .toList();

    if (chestPainMatches.isEmpty) {
      return const RedFlagRuleEvaluation.notTriggered();
    }

    final matchedIdentifiers = allMatches.map((m) => m.identifier).toSet();
    final hasEmergencyCoSign =
        matchedIdentifiers.intersection(_emergencyCoSigns).isNotEmpty;
    final hasSevere =
        chestPainMatches.any((m) => m.severity == SymptomSeverity.severe);

    if (hasSevere || hasEmergencyCoSign) {
      return const RedFlagRuleEvaluation.triggered(
        reason: 'Chest pain/pressure reported with severe severity or a '
            'concerning associated symptom (e.g. breathing difficulty).',
        urgency: TriageUrgency.emergency,
      );
    }

    final hasKnownNonMildSeverity = chestPainMatches.any(
      (m) =>
          m.severity == SymptomSeverity.moderate ||
          m.severity == SymptomSeverity.mild,
    );

    if (hasKnownNonMildSeverity) {
      final hasModerate = chestPainMatches
          .any((m) => m.severity == SymptomSeverity.moderate);
      if (hasModerate) {
        return const RedFlagRuleEvaluation.triggered(
          reason: 'Chest pain/pressure reported with moderate severity.',
          urgency: TriageUrgency.urgent,
        );
      }
      // Explicitly reported mild, with no concerning co-sign: known,
      // not just unspecified — does not trigger.
      return const RedFlagRuleEvaluation.notTriggered();
    }

    // Severity unknown and no concerning associated symptom recorded:
    // cannot rule out a cardiac emergency from the available structured
    // data. This must not be reported as "safe".
    return const RedFlagRuleEvaluation.insufficientInformation(
      reason: 'Chest pain/pressure was reported, but severity and '
          'associated symptoms (e.g. breathing difficulty) are unknown — '
          'this cannot be confirmed safe from the available structured '
          'data and needs follow-up.',
    );
  }
}

/// 6. Uncontrolled heavy bleeding.
class HeavyBleedingRule extends RedFlagRule {
  const HeavyBleedingRule();

  @override
  String get id => 'uncontrolled_heavy_bleeding';

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matched = SymptomIdentifierMatcher.matchSession(session).any(
      (m) => m.identifier == SymptomIdentifier.heavyUncontrolledBleeding,
    );
    if (!matched) return const RedFlagRuleEvaluation.notTriggered();
    return const RedFlagRuleEvaluation.triggered(
      reason: 'Uncontrolled heavy bleeding was reported.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// 7. Major trauma/injury with concerning symptoms.
///
/// Major trauma reported alone is treated as urgent (it always warrants
/// human review); it is escalated to emergency only when the entry is
/// explicitly rated severe or co-occurs with another emergency-tier sign
/// (e.g. unconsciousness, heavy bleeding, breathing difficulty).
class MajorTraumaRule extends RedFlagRule {
  const MajorTraumaRule();

  @override
  String get id => 'major_trauma_injury';

  static const _emergencyCoSigns = {
    SymptomIdentifier.unconsciousness,
    SymptomIdentifier.heavyUncontrolledBleeding,
    SymptomIdentifier.breathingDifficulty,
    SymptomIdentifier.severeCollapseOrShock,
  };

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final allMatches = SymptomIdentifierMatcher.matchSession(session);
    final traumaMatches = allMatches
        .where((m) => m.identifier == SymptomIdentifier.majorTraumaInjury)
        .toList();

    if (traumaMatches.isEmpty) return const RedFlagRuleEvaluation.notTriggered();

    final matchedIdentifiers = allMatches.map((m) => m.identifier).toSet();
    final hasEmergencyCoSign =
        matchedIdentifiers.intersection(_emergencyCoSigns).isNotEmpty;
    final hasSevere =
        traumaMatches.any((m) => m.severity == SymptomSeverity.severe);

    if (hasSevere || hasEmergencyCoSign) {
      return const RedFlagRuleEvaluation.triggered(
        reason: 'Major trauma/injury reported with severe severity or a '
            'concerning associated symptom.',
        urgency: TriageUrgency.emergency,
      );
    }

    return const RedFlagRuleEvaluation.triggered(
      reason: 'Major trauma/injury was reported.',
      urgency: TriageUrgency.urgent,
    );
  }
}

/// 8. Severe allergic reaction with breathing difficulty or significant
/// face/tongue/throat swelling.
///
/// An allergic reaction reported without either qualifying sign is
/// insufficient information, not "safe" — airway involvement is exactly
/// the thing that turns an allergic reaction into an emergency, and this
/// rule must not guess whether it's present.
class SevereAllergicReactionRule extends RedFlagRule {
  const SevereAllergicReactionRule();

  @override
  String get id => 'severe_allergic_reaction';

  static const _airwaySigns = {
    SymptomIdentifier.breathingDifficulty,
    SymptomIdentifier.faceThroatSwelling,
  };

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final allMatches = SymptomIdentifierMatcher.matchSession(session);
    final hasAllergicReaction = allMatches
        .any((m) => m.identifier == SymptomIdentifier.severeAllergicReaction);

    if (!hasAllergicReaction) return const RedFlagRuleEvaluation.notTriggered();

    final matchedIdentifiers = allMatches.map((m) => m.identifier).toSet();
    final hasAirwaySign =
        matchedIdentifiers.intersection(_airwaySigns).isNotEmpty;

    if (hasAirwaySign) {
      return const RedFlagRuleEvaluation.triggered(
        reason: 'Severe allergic reaction reported with breathing '
            'difficulty or face/tongue/throat swelling.',
        urgency: TriageUrgency.emergency,
      );
    }

    return const RedFlagRuleEvaluation.insufficientInformation(
      reason: 'An allergic reaction was reported, but it is unknown '
          'whether breathing difficulty or face/tongue/throat swelling '
          'is present — airway involvement cannot be ruled out from the '
          'available structured data.',
    );
  }
}

/// 9. Severe collapse / shock-like warning signs, where the available
/// structured data clearly supports it.
class SevereCollapseOrShockRule extends RedFlagRule {
  const SevereCollapseOrShockRule();

  @override
  String get id => 'severe_collapse_or_shock';

  @override
  RedFlagRuleEvaluation evaluate(TriageSession session) {
    final matched = SymptomIdentifierMatcher.matchSession(session).any(
      (m) => m.identifier == SymptomIdentifier.severeCollapseOrShock,
    );
    if (!matched) return const RedFlagRuleEvaluation.notTriggered();
    return const RedFlagRuleEvaluation.triggered(
      reason: 'Severe collapse or shock-like warning signs were reported.',
      urgency: TriageUrgency.emergency,
    );
  }
}

/// The full initial prototype rule set, in a fixed, deterministic order.
const List<RedFlagRule> defaultRedFlagRules = [
  BreathingDifficultyRule(),
  UnconsciousnessRule(),
  SeizureRule(),
  StrokeWarningSignRule(),
  ChestPainRule(),
  HeavyBleedingRule(),
  MajorTraumaRule(),
  SevereAllergicReactionRule(),
  SevereCollapseOrShockRule(),
];
