import 'follow_up_priority.dart';
import 'follow_up_question.dart';
import 'follow_up_response_type.dart';

/// The fixed, deterministic catalogue of safety follow-up questions used
/// by [FollowUpEngine].
///
/// Each question has a stable [FollowUpQuestion.id] and
/// [FollowUpQuestion.target]. The engine uses [target] to check whether
/// the information is already present in the session before asking.
///
/// Groups are ordered by symptom category; within each group, questions
/// are ordered from most to least urgent. The engine evaluates the bank
/// in this list order and returns the first unasked, unresolved question.
///
/// To add a new question: append to the relevant group (or create a new
/// group). No engine code needs to change.
const List<FollowUpQuestion> followUpQuestionBank = [
  // ─── 1. CHEST PAIN ────────────────────────────────────────────────────────
  FollowUpQuestion(
    id: 'chest_pain.breathing',
    questionText: {
      'en': 'Are you having difficulty breathing?',
      'ta': 'நீங்கள் சுவாசிக்க சிரமப்படுகிறீர்களா?',
      'hi': 'क्या आपको सांस लेने में कठिनाई हो रही है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'breathingStatus',
    relatedRuleId: 'chest_pain_or_pressure',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'chest_pain.consciousness',
    questionText: {
      'en': 'Have you fainted or lost consciousness?',
      'ta': 'நீங்கள் மூர்ச்சையாகியிருக்கிறீர்களா அல்லது உணர்வை இழந்தீர்களா?',
      'hi': 'क्या आप बेहोश हो गए थे या होश खो बैठे थे?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'consciousnessStatus',
    relatedRuleId: 'chest_pain_or_pressure',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'chest_pain.severity',
    questionText: {
      'en': 'Is the chest pain severe or getting worse?',
      'ta': 'மார்பு வலி கடுமையாக உள்ளதா அல்லது அதிகமாகிறதா?',
      'hi': 'क्या सीने का दर्द गंभीर है या बढ़ रहा है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'chestPainSeverityConfirmed',
    relatedRuleId: 'chest_pain_or_pressure',
    requiredForSafety: true,
  ),

  // ─── 2. BREATHING COMPLAINT ───────────────────────────────────────────────
  FollowUpQuestion(
    id: 'breathing.severity',
    questionText: {
      'en': 'Are you having severe difficulty breathing or unable to breathe normally?',
      'ta': 'சுவாசிக்க மிகவும் கஷ்டமாக உள்ளதா அல்லது சாதாரணமாக சுவாசிக்க முடியவில்லையா?',
      'hi': 'क्या आपको सांस लेने में गंभीर कठिनाई हो रही है या सामान्य रूप से सांस नहीं ले पा रहे?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'breathingSeverityConfirmed',
    relatedRuleId: 'severe_breathing_difficulty',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'breathing.lip_color',
    questionText: {
      'en': 'Are your lips or face turning blue or grey?',
      'ta': 'உங்கள் உதடுகள் அல்லது முகம் நீல அல்லது சாம்பல் நிறமாக மாறுகிறதா?',
      'hi': 'क्या आपके होंठ या चेहरा नीले या भूरे रंग का हो रहा है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'cyanosisStatus',
    relatedRuleId: 'severe_breathing_difficulty',
    requiredForSafety: true,
  ),

  // ─── 3. ALLERGIC REACTION ─────────────────────────────────────────────────
  FollowUpQuestion(
    id: 'allergy.breathing',
    questionText: {
      'en': 'Are you having difficulty breathing?',
      'ta': 'நீங்கள் சுவாசிக்க சிரமப்படுகிறீர்களா?',
      'hi': 'क्या आपको सांस लेने में कठिनाई हो रही है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'breathingStatus',
    relatedRuleId: 'severe_allergic_reaction',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'allergy.swelling',
    questionText: {
      'en': 'Is there swelling of your face, tongue, or throat?',
      'ta': 'உங்கள் முகம், நாக்கு அல்லது தொண்டை வீக்கம் உள்ளதா?',
      'hi': 'क்या आपके चेहरे, जीभ या गले में सूजन है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'faceThroatSwellingStatus',
    relatedRuleId: 'severe_allergic_reaction',
    requiredForSafety: true,
  ),

  // ─── 4. NEUROLOGICAL / STROKE-LIKE ────────────────────────────────────────
  FollowUpQuestion(
    id: 'neuro.limb_weakness',
    questionText: {
      'en': 'Do you have sudden weakness on one side of your body (arm or leg)?',
      'ta': 'உங்கள் உடலின் ஒரு பக்கம் (கை அல்லது கால்) திடீரென பலவீனமாக உள்ளதா?',
      'hi': 'क्या आपके शरीर के एक तरफ (हाथ या पैर) अचानक कमज़ोरी आई है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'suddenLimbWeaknessStatus',
    relatedRuleId: 'stroke_warning_sign',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'neuro.facial_weakness',
    questionText: {
      'en': 'Is one side of your face drooping or weak?',
      'ta': 'உங்கள் முகத்தின் ஒரு பக்கம் தொங்குகிறதா அல்லது பலவீனமாக உள்ளதா?',
      'hi': 'क्या आपके चेहरे का एक हिस्सा लटक रहा है या कमज़ोर है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'facialWeaknessStatus',
    relatedRuleId: 'stroke_warning_sign',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'neuro.speech',
    questionText: {
      'en': 'Are you having difficulty speaking or is your speech slurred?',
      'ta': 'பேசுவதில் சிரமம் உள்ளதா அல்லது பேச்சு தெளிவற்றதாக உள்ளதா?',
      'hi': 'क्या आपको बोलने में कठिनाई हो रही है या आपकी बोली अस्पष्ट है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'speechDifficultyStatus',
    relatedRuleId: 'stroke_warning_sign',
    requiredForSafety: true,
  ),

  // ─── 5. BLEEDING ──────────────────────────────────────────────────────────
  FollowUpQuestion(
    id: 'bleeding.control',
    questionText: {
      'en': 'Is the bleeding uncontrolled or very heavy?',
      'ta': 'இரத்தப்போக்கு கட்டுக்கடங்காமல் அல்லது மிகவும் அதிகமாக உள்ளதா?',
      'hi': 'क्या रक्तस्राव बेकाबू या बहुत अधिक है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'bleedingControlStatus',
    relatedRuleId: 'uncontrolled_heavy_bleeding',
    requiredForSafety: true,
  ),
  FollowUpQuestion(
    id: 'bleeding.faintness',
    questionText: {
      'en': 'Are you feeling faint or unusually weak from the bleeding?',
      'ta': 'இரத்தப்போக்கால் மயக்கம் அல்லது அசாதாரண பலவீனம் உணர்கிறீர்களா?',
      'hi': 'क्या खून बहने से आपको चक्कर आ रहा है या असामान्य कमज़ोरी महसूस हो रही है?',
    },
    priority: FollowUpPriority.safetyCritical,
    responseType: FollowUpResponseType.yesNo,
    options: ['yes', 'no'],
    target: 'bleedingFaintnessStatus',
    relatedRuleId: 'uncontrolled_heavy_bleeding',
    requiredForSafety: true,
  ),
];
