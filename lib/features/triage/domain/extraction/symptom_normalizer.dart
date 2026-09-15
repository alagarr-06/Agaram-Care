// Task 07A — Agaram Care Symptom Understanding & Normalization Layer.
//
// Normalizes symptoms, severity, duration, and patient context across
// English, Tamil script, Tanglish, Hindi, and Hinglish.
// Strictly adheres to deterministic extraction: does NOT invent facts.
library;

import '../entities/associated_symptom.dart';
import '../entities/patient_context.dart';
import '../entities/patient_symptom.dart';
import '../enums/input_source.dart';
import '../enums/symptom_severity.dart';
import 'extraction_confidence.dart';
import 'extraction_result.dart';
import 'extraction_warning.dart';

class SymptomNormalizer {
  const SymptomNormalizer();

  /// Canonical symptom definitions with multi-language phrase matches.
  static final List<_SymptomDef> _canonicalDefs = [
    _SymptomDef(
      canonicalName: 'chest pain',
      phrases: [
        'chest pain', 'heart pain', 'pain in chest', 'chest heaviness',
        'chest tightness', 'pressure in chest', 'pain in my chest',
        'மார்பு வலி', 'நெஞ்சு வலி', 'மார்பில் வலி', 'நெஞ்சில் வலி', 'இதய வலி',
        'marbu vali', 'nenju vali', 'marbil vali', 'nenjil vali', 'chest vali',
        'seene mein dard', 'seene me dard', 'chhati me dard', 'chhati mein dard',
        'dil me dard', 'सीने में दर्द', 'छाती में दर्द', 'दिल में दर्द',
      ],
      tokenCombos: [
        ['सीने', 'दर्द'],
        ['छाती', 'दर्द'],
        ['dil', 'dard'],
        ['chest', 'pain'],
        ['marbil', 'vali'],
        ['marbu', 'vali'],
        ['nenjil', 'vali'],
        ['nenju', 'vali'],
        ['மார்பில்', 'வலி'],
        ['மார்பு', 'வலி'],
        ['நெஞ்சில்', 'வலி'],
        ['நெஞ்சு', 'வலி'],
      ],
    ),
    _SymptomDef(
      canonicalName: 'difficulty breathing',
      phrases: [
        'difficulty breathing', 'breathing difficulty', 'shortness of breath',
        'breathless', 'trouble breathing', 'can not breathe', 'cannot breathe',
        'gasping for air', 'heavy breathing',
        'மூச்சு திணறல்', 'மூச்சுத்திணறல்', 'மூச்சு விட சிரமம்', 'மூச்சு வாங்குது',
        'சுவாசிப்பதில் சிரமம்',
        'moochu thinaral', 'moochu thinare', 'moochu vida mudiyala',
        'moochu vanguthu', 'moochu kastam', 'moochu vida kashdam',
        'saans lene me dikkat', 'saans lene mein dikkat', 'saans phool rahi hai',
        'saans fulna', 'saans lene me taklif',
        'सांस लेने में तकलीफ', 'सांस फूलना', 'सांस लेने में दिक्कत', 'सांस लेने में परेशानी',
      ],
      tokenCombos: [
        ['shortness', 'breath'],
        ['difficulty', 'breathing'],
        ['saans', 'dikkat'],
        ['saans', 'taklif'],
        ['सांस', 'तकलीफ'],
        ['सांस', 'दिक्कत'],
        ['moochu', 'thinaral'],
        ['மூச்சு', 'திணறல்'],
      ],
    ),
    _SymptomDef(
      canonicalName: 'stomach pain',
      phrases: [
        'stomach pain', 'abdominal pain', 'belly pain', 'tummy ache',
        'pain in stomach', 'cramps in stomach', 'pain in abdomen',
        'வயிறு வலி', 'வயிற்று வலி', 'வயிற்றில் வலி', 'வயிற்று கடுப்பு',
        'vayiru vali', 'vayithu vali', 'vayitril vali', 'stomach vali',
        'pet dard', 'pet me dard', 'pet mein dard',
        'पेट दर्द', 'पेट में दर्द', 'पेट का दर्द',
      ],
      tokenCombos: [
        ['stomach', 'pain'],
        ['abdominal', 'pain'],
        ['pet', 'dard'],
        ['पेट', 'दर्द'],
        ['vayiru', 'vali'],
        ['vayithu', 'vali'],
        ['வயிறு', 'வலி'],
        ['வயிற்று', 'வலி'],
      ],
    ),
    _SymptomDef(
      canonicalName: 'headache',
      phrases: [
        'headache', 'head pain', 'pain in head', 'migraine', 'throbbing head',
        'severe headache',
        'தலைவலி', 'தலை வலி', 'தலையில் வலி',
        'thalavali', 'thalai vali', 'thalayila vali', 'head vali',
        'sir dard', 'sar dard', 'sar me dard', 'sir me dard',
        'सिरदर्द', 'सिर में दर्द', 'सर दर्द',
      ],
      tokenCombos: [
        ['head', 'pain'],
        ['sir', 'dard'],
        ['sar', 'dard'],
        ['सिर', 'दर्द'],
        ['सर', 'दर्द'],
        ['thalai', 'vali'],
        ['தலை', 'வலி'],
      ],
    ),
    _SymptomDef(
      canonicalName: 'fever',
      phrases: [
        'fever', 'high fever', 'temperature', 'chills and fever', 'feeling feverish',
        'காய்ச்சல்', 'ஜுரம்', 'சுரம்', 'கடும் காய்ச்சல்',
        'kaichal', 'juram', 'suram', 'fever adikkuthu', 'fever irukku',
        'bukhar', 'tez bukhar', 'fever hai',
        'बुखार', 'तेज बुखार',
      ],
      tokenCombos: [
        ['high', 'fever'],
        ['तेज', 'बुखार'],
        ['கடும்', 'காய்ச்சல்'],
      ],
    ),
    _SymptomDef(
      canonicalName: 'cough',
      phrases: [
        'cough', 'dry cough', 'coughing', 'wet cough',
        'இருமல்', 'சளி இருமல்', 'வறட்டு இருமல்',
        'irumal', 'varattu irumal', 'cough varuthu',
        'khansi', 'sukhi khansi', 'cough aa raha hai',
        'खांसी', 'सुखी खांसी',
      ],
    ),
    _SymptomDef(
      canonicalName: 'allergic reaction',
      phrases: [
        'allergic reaction', 'allergy', 'hives', 'rash', 'skin rash',
        'itching all over', 'swelling on face',
        'ஒவ்வாமை', 'அலர்ஜி', 'தோல் தடிப்பு', 'அரிப்பு',
        'allergy', 'arippu', 'thadipu', 'thodai arippu',
        'khujli', 'chakatte', 'rash ho gaya',
        'एलर्जी', 'खुजली', 'चकत्ते',
      ],
    ),
    _SymptomDef(
      canonicalName: 'bleeding',
      phrases: [
        'bleeding', 'blood loss', 'blood coming out', 'coughing blood', 'vomiting blood',
        'ரத்தப்போக்கு', 'இரத்தப்போக்கு', 'ரத்தம் வருது', 'இரத்தம்',
        'rathapokku', 'ratham varuthu', 'blood varuthu',
        'khoon nikal raha hai', 'khoon beh raha hai', 'khoon',
        'खून बहना', 'रक्तस्राव', 'खून आ रहा है',
      ],
    ),
    _SymptomDef(
      canonicalName: 'sudden weakness',
      phrases: [
        'sudden weakness', 'facial weakness', 'face drooping', 'arm weakness',
        'leg weakness', 'one-sided weakness', 'slurred speech', 'paralysis',
        'numbness on one side',
        'திடீர் பலவீனம்', 'முக வாதம்', 'கை கால் பலவீனம்', 'பேச்சு குழறல்',
        'thideer balaveenam', 'kai kaal ilukaathu', 'kai kaal varala',
        'oru pakkam balaveenam', 'balheenatha',
        'achanak kamzori', 'chehra jhukna', 'hath pair kamzor',
        'ek taraf kamzori', 'lakwa',
        'अचानक कमजोरी', 'चेहरा लटकना', 'हाथ पैर में कमजोरी', 'लकवा',
      ],
    ),
    _SymptomDef(
      canonicalName: 'vomiting',
      phrases: [
        'vomiting', 'nausea', 'throwing up', 'vomit', 'feel like vomiting',
        'வாந்தி', 'குமட்டல்', 'வாந்தி வருது',
        'vaanthi', 'vanthi', 'kumattal', 'vomit varuthu',
        'ulti', 'ulti aa rahi hai', 'ji michlana', 'vomiting ho rahi',
        'उल्टी', 'जी मिचलाना', 'उल्टी आ रही है',
      ],
    ),
    _SymptomDef(
      canonicalName: 'diarrhea',
      phrases: [
        'diarrhea', 'loose motions', 'watery stools', 'stomach upset',
        'வயிற்றுப்போக்கு', 'பேதி', 'லூஸ் மோஷன்',
        'vayitrupokku', 'loose motion', 'bedhi',
        'dast', 'loose motion', 'patle dast',
        'दस्त', 'लूज मोशन', 'पतले दस्त',
      ],
    ),
    _SymptomDef(
      canonicalName: 'dizziness',
      phrases: [
        'dizziness', 'fainting', 'loss of consciousness', 'blacked out',
        'vertigo', 'feeling faint', 'passed out',
        'மயக்கம்', 'தலைச்சுற்றல்', 'மயங்கி விழுந்தேன்',
        'mayakkam', 'thalaichuttal', 'mayangi vizhunthen',
        'chakkar', 'chakkar aana', 'behoshi', 'chakkar aa raha hai',
        'चक्कर', 'बेहोशी', 'चक्कर आना',
      ],
    ),
    _SymptomDef(
      canonicalName: 'injury',
      phrases: [
        'injury', 'accident', 'fall', 'fracture', 'wound', 'head injury', 'trauma',
        'காயம்', 'விபத்து', 'அடிபட்டது', 'எலும்பு முறிவு',
        'kaayam', 'adipattathu', 'vibathu', 'fracture aachu',
        'chot lag gayi', 'hadde toot gayi', 'fracture', 'chot',
        'चोट', 'दुर्घटना', 'घाव', 'हड्डी टूटना',
      ],
    ),
    _SymptomDef(
      canonicalName: 'urinary issue',
      phrases: [
        'painful urination', 'burning urination', 'blood in urine',
        'urinary issue', 'urine infection', 'burning while urinating',
        'சிறுநீர் எரிச்சல்', 'சிறுநீரில் ரத்தம்', 'சிறுநீர் போக வலி',
        'urine erichal', 'urine vali', 'siruneer erichal',
        'peshab me jalan', 'peshab me dard', 'urine infection',
        'पेशाब में जलन', 'पेशाब में दर्द', 'पेशाब में खून',
      ],
    ),
    _SymptomDef(
      canonicalName: 'pregnancy complication',
      phrases: [
        'pregnancy complications', 'vaginal bleeding in pregnancy',
        'severe pelvic pain', 'labor pains', 'water broke',
        'கர்ப்ப சிக்கல்', 'கர்ப்ப வலி', 'கருப்பை வலி',
        'garbha vali', 'delivery vali', 'pelvic vali',
        'pregnancy me dard', 'delivery dard',
        'गर्भावस्था की समस्याएं', 'प्रसव पीड़ा',
      ],
    ),
  ];

  /// Normalizes the given raw input into an [ExtractionResult].
  ExtractionResult extract(
    String rawInput, {
    required String languageCode,
    required InputSource inputSource,
  }) {
    final trimmed = rawInput.trim();
    if (trimmed.isEmpty) {
      return ExtractionResult(
        rawInput: rawInput,
        languageCode: languageCode,
        inputSource: inputSource,
        symptoms: const [],
        confidence: const ExtractionConfidence.low(),
        warnings: const [
          ExtractionWarning(
            code: ExtractionWarningCode.unrecognizedPhrase,
            message: 'Raw input is empty.',
          ),
        ],
      );
    }

    final lower = trimmed.toLowerCase();
    final warnings = <ExtractionWarning>[];

    // 1. Detect explicit severity
    final severity = _extractSeverity(lower);

    // 2. Detect explicit duration
    final duration = _extractDuration(lower);

    // 3. Detect symptoms
    final detectedSymptoms = <_DetectedSymptom>[];
    for (final def in _canonicalDefs) {
      int matchIndex = -1;
      int matchLen = 0;

      bool hadPhraseOccurrence = false;
      for (final phrase in def.phrases) {
        int searchFrom = 0;
        while (true) {
          final index = lower.indexOf(phrase, searchFrom);
          if (index == -1) break;
          hadPhraseOccurrence = true;
          // Check if negated or non-current at this occurrence
          if (!_isNegatedOrNonCurrent(lower, index, phrase.length)) {
            matchIndex = index;
            matchLen = phrase.length;
            break;
          }
          searchFrom = index + phrase.length;
        }
        if (matchIndex != -1) break;
      }

      // Check token combinations if direct phrase not matched (e.g. "सीने में तेज दर्द")
      // Only do tokenCombos if no direct phrase was found or if no phrase occurrence was negated
      if (matchIndex == -1 && !hadPhraseOccurrence && def.tokenCombos != null) {
        for (final combo in def.tokenCombos!) {
          bool allFound = true;
          int firstIdx = 999999;
          int lastEndIdx = -1;
          for (final token in combo) {
            final tIdx = lower.indexOf(token);
            if (tIdx == -1) {
              allFound = false;
              break;
            }
            if (tIdx < firstIdx) firstIdx = tIdx;
            final endIdx = tIdx + token.length;
            if (endIdx > lastEndIdx) lastEndIdx = endIdx;
          }
          // Tokens must be in close proximity (within 30 chars of each other)
          if (allFound && (lastEndIdx - firstIdx <= 30)) {
            final spanLen = (lastEndIdx > firstIdx) ? (lastEndIdx - firstIdx) : 10;
            if (!_isNegatedOrNonCurrent(lower, firstIdx, spanLen)) {
              matchIndex = firstIdx;
              matchLen = spanLen;
              break;
            }
          }
        }
      }

      if (matchIndex != -1) {
        detectedSymptoms.add(_DetectedSymptom(
          canonicalName: def.canonicalName,
          index: matchIndex,
          phraseLength: matchLen,
        ));
      }
    }

    // Sort by earliest appearance in input text
    detectedSymptoms.sort((a, b) => a.index.compareTo(b.index));

    final symptoms = <PatientSymptom>[];
    ExtractionConfidence confidence;

    if (detectedSymptoms.isNotEmpty) {
      final primaryName = detectedSymptoms.first.canonicalName;
      final associatedSymptoms = <AssociatedSymptom>[];

      for (int i = 1; i < detectedSymptoms.length; i++) {
        associatedSymptoms.add(
          AssociatedSymptom(
            symptomName: detectedSymptoms[i].canonicalName,
            inputSource: inputSource,
          ),
        );
      }

      if (severity == null) {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.missingSeverity,
            message: 'Severity was not explicitly stated for "$primaryName".',
            field: 'severity',
          ),
        );
      }
      if (duration == null) {
        warnings.add(
          ExtractionWarning(
            code: ExtractionWarningCode.missingDuration,
            message: 'Duration was not explicitly stated for "$primaryName".',
            field: 'duration',
          ),
        );
      }

      symptoms.add(
        PatientSymptom(
          symptomName: primaryName,
          inputSource: inputSource,
          severity: severity,
          duration: duration,
          associatedSymptoms: associatedSymptoms,
        ),
      );
      confidence = const ExtractionConfidence.high();
    } else {
      warnings.add(
        ExtractionWarning(
          code: ExtractionWarningCode.unrecognizedPhrase,
          message: 'Could not clearly extract standardized symptoms from input: "$rawInput"',
        ),
      );
      warnings.add(
        const ExtractionWarning(
          code: ExtractionWarningCode.lowConfidence,
          message: 'Low confidence extraction. Further clarification recommended.',
        ),
      );
      confidence = const ExtractionConfidence.low();
    }

    // 4. Extract explicit PatientContext
    final patientContext = _extractPatientContext(lower);

    return ExtractionResult(
      rawInput: rawInput,
      languageCode: languageCode,
      inputSource: inputSource,
      symptoms: symptoms,
      patientContext: patientContext,
      confidence: confidence,
      warnings: warnings,
    );
  }

  SymptomSeverity? _extractSeverity(String lower) {
    // Severe
    if (_containsAny(lower, [
      'severe', 'unbearable', 'extreme', 'intense', 'very bad', 'worst',
      'romba strong', 'romba athigam', 'thanga mudiyala', 'kadumaiyana',
      'theeviram', 'severe ah', 'bahut jyada', 'bahut tez', 'bohot jyada',
      'bahut jada', 'bura haal', 'தீவிர', 'கடும்', 'கடுமையான', 'தாங்க முடியாத',
      'गंभीर', 'असहनीय', 'अत्यधिक', 'तेज', 'तेज़',
    ])) {
      return SymptomSeverity.severe;
    }

    // Moderate
    if (_containsAny(lower, [
      'moderate', 'medium', 'manageable', 'medium ah', 'moderate ah',
      'konjam athigam', 'sumaara', 'madhyam', 'theek thaak', 'மிதமான',
      'சுமாரான', 'நடுத்தர', 'मध्यम',
    ])) {
      return SymptomSeverity.moderate;
    }

    // Mild
    if (_containsAny(lower, [
      'mild', 'slight', 'minor', 'a little', 'a bit', 'konjam', 'konjama',
      'chinna', 'slight ah', 'mild ah', 'konjam tha', 'halka', 'halki',
      'thoda', 'thoda sa', 'லேசான', 'சற்று', 'हल्का', 'हल्की', 'थोड़ा',
    ])) {
      return SymptomSeverity.mild;
    }

    return null;
  }

  String? _extractDuration(String lower) {
    if (_containsAny(lower, ['since yesterday', 'நேத்திலிருந்து', 'நேற்று முதல்', 'nethu', 'kal se', 'कल से', 'कल'])) {
      return 'since yesterday';
    }
    if (_containsAny(lower, ['since morning', 'இன்று காலை முதல்', 'காலையிலிருந்து', 'kaalaila', 'aaj subah se', 'आज सुबह से', 'सुबह से'])) {
      return 'since morning';
    }
    if (_containsAny(lower, ['today', 'inniku', 'aaj', 'இன்று', 'आज'])) {
      return 'today';
    }
    if (_containsAny(lower, ['sudden', 'suddenly', 'thideer', 'achanak', 'திடீரென', 'திடீர்', 'अचानक'])) {
      return 'sudden onset';
    }

    // Regex for hours
    final hourMatch = RegExp(r'\b(\d+)\s*(?:hours|hour|hrs|hr|mani|ghante|மணி|घंटे|घंटा)\b').firstMatch(lower);
    if (hourMatch != null) {
      return '${hourMatch.group(1)} hours';
    }

    // Regex for days
    final dayMatch = RegExp(r'(\d+)\s*(?:days|day|naala|naal|dina|din|நாட்கள்|நாள்|दिन|दिनों)').firstMatch(lower);
    if (dayMatch != null) {
      return '${dayMatch.group(1)} days';
    }

    // Regex for weeks
    final weekMatch = RegExp(r'(\d+)\s*(?:weeks|week|vaaram|hafte|வாரம்|हफ्ते|सप्ताह)').firstMatch(lower);
    if (weekMatch != null) {
      return '${weekMatch.group(1)} weeks';
    }

    return null;
  }

  PatientContext? _extractPatientContext(String lower) {
    int? ageYears;
    final ageMatch = RegExp(r'\b(\d{1,3})\s*(?:years old|years|yrs|varusham|saal|vayasu|வயது|साल)\b').firstMatch(lower) ??
        RegExp(r'\b(?:age|vayasu|வயது|उम्र)\s*[:=]?\s*(\d{1,3})\b').firstMatch(lower);
    if (ageMatch != null) {
      final parsed = int.tryParse(ageMatch.group(1)!);
      if (parsed != null && parsed >= 0 && parsed <= 130) {
        ageYears = parsed;
      }
    }

    String? sex;
    if (_containsAny(lower, ['female', 'woman', 'girl', 'pen', 'mahila', 'stree', 'பெண்', 'महिला', 'स्त्री'])) {
      sex = 'female';
    } else if (_containsAny(lower, ['male', 'man', 'boy', 'aan', 'purush', 'ஆண்', 'पुरुष'])) {
      sex = 'male';
    }

    bool? pregnancyStatus;
    if (_containsAny(lower, [
      'not pregnant', 'not expecting', 'negative pregnancy',
      'கர்ப்பமாக இல்லை', 'கர்ப்பிணி இல்லை', 'கர்ப்பம் இல்லை',
      'karppam illa', 'karppam illai', 'pregnant illa', 'pregnant illai',
      'garbhvati nahi', 'garbhavastha nahi', 'pregnant nahi',
      'गर्भवती नहीं', 'गर्भावस्था नहीं',
    ])) {
      pregnancyStatus = false;
    } else if (_containsAny(lower, [
      'pregnant', 'garbhini', 'கர்ப்பமாக', 'karppam', 'கர்ப்பிணி', 'garbhvati', 'गर्भावस्था', 'गर्भवती'
    ])) {
      pregnancyStatus = true;
    }

    final allergies = <String>[];
    if (lower.contains('penicillin')) {
      allergies.add('penicillin');
    }
    if (lower.contains('peanut')) {
      allergies.add('peanuts');
    }
    if (lower.contains('sulfa')) {
      allergies.add('sulfa');
    }

    final medications = <String>[];
    if (lower.contains('metformin')) {
      medications.add('metformin');
    }
    if (lower.contains('insulin')) {
      medications.add('insulin');
    }
    if (lower.contains('amlodipine')) {
      medications.add('amlodipine');
    }
    if (lower.contains('paracetamol')) {
      medications.add('paracetamol');
    }

    final conditions = <String>[];
    if (_containsAny(lower, ['diabetic', 'diabetes', 'sugar', 'சர்க்கரை நோய்', 'நீரிழிவு', 'मधुमेह'])) {
      conditions.add('diabetes');
    }
    if (_containsAny(lower, ['hypertension', 'bp', 'blood pressure', 'உயர் ரத்த அழுத்தம்', 'ரத்தக் கொதிப்பு', 'हाई बीपी'])) {
      conditions.add('hypertension');
    }
    if (_containsAny(lower, ['asthma', 'ஆஸ்துமா', 'दमा'])) {
      conditions.add('asthma');
    }

    if (ageYears != null ||
        sex != null ||
        pregnancyStatus != null ||
        allergies.isNotEmpty ||
        medications.isNotEmpty ||
        conditions.isNotEmpty) {
      return PatientContext(
        ageYears: ageYears,
        sex: sex,
        pregnancyStatus: pregnancyStatus,
        knownConditions: conditions,
        currentMedications: medications,
        allergies: allergies,
      );
    }

    return null;
  }

  static bool _containsAny(String text, List<String> phrases) {
    for (final p in phrases) {
      if (text.contains(p)) return true;
    }
    return false;
  }

  /// Checks whether a symptom candidate at [startIdx] with length [length] in [text]
  /// is negated, historical, or hypothetical.
  static bool _isNegatedOrNonCurrent(String text, int startIdx, int length) {
    // 1. Look back: context up to 50 characters before startIdx
    final prefixStart = (startIdx - 50) > 0 ? (startIdx - 50) : 0;
    final prefix = text.substring(prefixStart, startIdx);

    // 2. Look forward: context up to 50 characters after end of symptom phrase
    final endIdx = startIdx + length;
    final suffixEnd = (endIdx + 50) < text.length ? (endIdx + 50) : text.length;
    final suffix = text.substring(endIdx, suffixEnd);

    // Historical context prefixes
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

    // Hypothetical context prefixes
    final hypotheticalPrefixes = [
      'if i get', 'if i have', 'if i ever', 'what if', 'in case of', 'suppose i have',
      'ஒருவேளை வந்தால்', 'வந்தால் என்ன செய்வது', 'oruvelai vanthaal',
      'agar mujhe', 'agar kabhi', 'yadi mujhe',
      'अगर मुझे', 'अगर कभी', 'यदि मुझे',
    ];
    for (final hp in hypotheticalPrefixes) {
      if (prefix.contains(hp)) return true;
    }

    // Prefix negations (e.g. "no chest pain", "don't have breathing difficulty", "nahi hai")
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

    // Also check if prefix ends with negation within last 20 characters
    final nearPrefix = prefix.length > 25 ? prefix.substring(prefix.length - 25) : prefix;
    if (_containsAny(nearPrefix, [
      'no ', 'no\t', 'without ', "don't have ", 'dont have ', 'do not have ',
      'not having ', 'denies ', 'never had ', 'negative for ',
    ])) {
      return true;
    }

    // Suffix negations (e.g. "நெஞ்சு வலி இல்லை", "nenju vali illa", "seene me dard nahi")
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

    // Near suffix check
    final nearSuffix = suffix.length > 25 ? suffix.substring(0, 25) : suffix;
    if (_containsAny(nearSuffix, [
      ' இல்லை', ' இல்ல', ' கிடையாது',
      ' illa', ' illai', ' kedayadhu',
      ' nahi', ' nahin', ' nahi hai', ' नहीं', ' नहीं है',
      ' is not present', ' is absent', ' not there',
    ])) {
      return true;
    }

    return false;
  }
}

class _SymptomDef {
  const _SymptomDef({
    required this.canonicalName,
    required this.phrases,
    this.tokenCombos,
  });

  final String canonicalName;
  final List<String> phrases;
  final List<List<String>>? tokenCombos;
}

class _DetectedSymptom {
  const _DetectedSymptom({
    required this.canonicalName,
    required this.index,
    required this.phraseLength,
  });

  final String canonicalName;
  final int index;
  final int phraseLength;
}
