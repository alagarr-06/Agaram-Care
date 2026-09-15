// Task 06 & Task 07A — Agaram Care Triage UI Integration & Input Understanding.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../app/app_state.dart';
import '../../../app/theme/app_theme.dart';
import '../../facilities/domain/matching/patient_care_request.dart';
import '../domain/action/action.dart';
import '../domain/entities/patient_context.dart';
import '../domain/entities/patient_symptom.dart';
import '../domain/entities/triage_session.dart';
import '../domain/enums/input_source.dart';
import '../domain/enums/next_action_type.dart';
import '../domain/enums/symptom_severity.dart';
import '../domain/enums/triage_urgency.dart';
import '../domain/extraction/extraction.dart';
import '../domain/follow_up/follow_up.dart';
import '../domain/red_flags/red_flag_engine.dart';
import '../domain/result/result.dart';

enum _TriageStep {
  input,
  extractionReview,
  followUp,
  result,
}

enum _InputMode { voice, text, quickSelect }

enum VoiceState {
  idle,
  listening,
  processing,
  recognized,
  error,
  unsupportedLanguage,
}

class _QuickSelectOption {
  const _QuickSelectOption({
    required this.symptomKey,
    required this.icon,
    required this.en,
    required this.ta,
    required this.hi,
  });

  final String symptomKey;
  final IconData icon;
  final String en;
  final String ta;
  final String hi;
}

class _QuickSelectCategory {
  const _QuickSelectCategory({
    required this.id,
    required this.icon,
    required this.en,
    required this.ta,
    required this.hi,
    required this.symptoms,
  });

  final String id;
  final IconData icon;
  final String en;
  final String ta;
  final String hi;
  final List<_QuickSelectOption> symptoms;
}

const _commonQuickSelectOptions = [
  _QuickSelectOption(
    symptomKey: 'chest pain',
    icon: Icons.favorite,
    en: 'Chest Pain',
    ta: 'மார்பு வலி',
    hi: 'सीने में दर्द',
  ),
  _QuickSelectOption(
    symptomKey: 'shortness of breath',
    icon: Icons.air,
    en: 'Difficulty Breathing',
    ta: 'மூச்சுத் திணறல்',
    hi: 'सांस लेने में कठिनाई',
  ),
  _QuickSelectOption(
    symptomKey: 'high fever',
    icon: Icons.thermostat,
    en: 'High Fever',
    ta: 'அதிக காய்ச்சல்',
    hi: 'तेज बुखार',
  ),
  _QuickSelectOption(
    symptomKey: 'severe headache',
    icon: Icons.psychology,
    en: 'Severe Headache',
    ta: 'கடுமையான தலைவலி',
    hi: 'गंभीर सिरदर्द',
  ),
  _QuickSelectOption(
    symptomKey: 'cough',
    icon: Icons.sick,
    en: 'Cough',
    ta: 'இருமல்',
    hi: 'खांसी',
  ),
  _QuickSelectOption(
    symptomKey: 'abdominal pain',
    icon: Icons.accessibility_new,
    en: 'Abdominal Pain',
    ta: 'வயிற்று வலி',
    hi: 'पेट दर्द',
  ),
];

const _quickSelectCategories = [
  _QuickSelectCategory(
    id: 'pain',
    icon: Icons.healing,
    en: 'Pain',
    ta: 'வலி',
    hi: 'दर्द',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'chest pain',
        icon: Icons.favorite,
        en: 'Chest pain',
        ta: 'மார்பு வலி',
        hi: 'सीने में दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'headache',
        icon: Icons.psychology,
        en: 'Headache',
        ta: 'தலைவலி',
        hi: 'सिरदर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'abdominal pain',
        icon: Icons.accessibility_new,
        en: 'Abdominal pain',
        ta: 'வயிற்று வலி',
        hi: 'पेट दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'back pain',
        icon: Icons.airline_seat_recline_normal,
        en: 'Back pain',
        ta: 'முதுகு வலி',
        hi: 'पीठ दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'joint pain',
        icon: Icons.directions_walk,
        en: 'Joint pain',
        ta: 'மூட்டு வலி',
        hi: 'जोड़ों का दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'tooth pain',
        icon: Icons.sentiment_very_dissatisfied,
        en: 'Tooth pain',
        ta: 'பல் வலி',
        hi: 'दांत दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'ear pain',
        icon: Icons.hearing,
        en: 'Ear pain',
        ta: 'காது வலி',
        hi: 'कान दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'other pain',
        icon: Icons.more_horiz,
        en: 'Other pain',
        ta: 'மற்ற வலி',
        hi: 'अन्य दर्द',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'fever',
    icon: Icons.thermostat,
    en: 'Fever / Infection',
    ta: 'காய்ச்சல் / தொற்று',
    hi: 'बुखार / संक्रमण',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'high fever',
        icon: Icons.thermostat,
        en: 'High fever',
        ta: 'அதிக காய்ச்சல்',
        hi: 'तेज बुखार',
      ),
      _QuickSelectOption(
        symptomKey: 'fever',
        icon: Icons.thermostat_outlined,
        en: 'Fever',
        ta: 'காய்ச்சல்',
        hi: 'बुखार',
      ),
      _QuickSelectOption(
        symptomKey: 'cough',
        icon: Icons.sick,
        en: 'Cough',
        ta: 'இருமல்',
        hi: 'खांसी',
      ),
      _QuickSelectOption(
        symptomKey: 'cold',
        icon: Icons.ac_unit,
        en: 'Cold / runny nose',
        ta: 'சளி',
        hi: 'जुकाम',
      ),
      _QuickSelectOption(
        symptomKey: 'sore throat',
        icon: Icons.record_voice_over,
        en: 'Sore throat',
        ta: 'தொண்டை வலி',
        hi: 'गले में खराश',
      ),
      _QuickSelectOption(
        symptomKey: 'body aches',
        icon: Icons.accessibility,
        en: 'Body aches',
        ta: 'உடல் வலி',
        hi: 'बदन दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'weakness',
        icon: Icons.battery_alert,
        en: 'Weakness',
        ta: 'பலவீனம்',
        hi: 'कमजोरी',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'breathing',
    icon: Icons.air,
    en: 'Breathing',
    ta: 'சுவாசம்',
    hi: 'सांस',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'shortness of breath',
        icon: Icons.air,
        en: 'Difficulty breathing',
        ta: 'மூச்சுத் திணறல்',
        hi: 'सांस लेने में कठिनाई',
      ),
      _QuickSelectOption(
        symptomKey: 'wheezing',
        icon: Icons.waves,
        en: 'Wheezing',
        ta: 'மூச்சிரைப்பு',
        hi: 'घरघराहट',
      ),
      _QuickSelectOption(
        symptomKey: 'fast breathing',
        icon: Icons.speed,
        en: 'Fast breathing',
        ta: 'வேகமான சுவாசம்',
        hi: 'तेज सांस',
      ),
      _QuickSelectOption(
        symptomKey: 'breathing concern',
        icon: Icons.help_outline,
        en: 'Other breathing concern',
        ta: 'பிற சுவாச பிரச்சனை',
        hi: 'अन्य सांस की समस्या',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'stomach',
    icon: Icons.accessibility_new,
    en: 'Stomach / Digestion',
    ta: 'வயிறு / செரிமானம்',
    hi: 'पेट / पाचन',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'stomach pain',
        icon: Icons.healing,
        en: 'Stomach pain',
        ta: 'வயிற்று வலி',
        hi: 'पेट दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'nausea',
        icon: Icons.sentiment_dissatisfied,
        en: 'Nausea',
        ta: 'குமட்டல்',
        hi: 'जी मिचलाना',
      ),
      _QuickSelectOption(
        symptomKey: 'vomiting',
        icon: Icons.warning_amber,
        en: 'Vomiting',
        ta: 'வாந்தி',
        hi: 'उल्टी',
      ),
      _QuickSelectOption(
        symptomKey: 'diarrhea',
        icon: Icons.water_damage,
        en: 'Diarrhea',
        ta: 'வயிற்றுப்போக்கு',
        hi: 'दस्त',
      ),
      _QuickSelectOption(
        symptomKey: 'constipation',
        icon: Icons.hourglass_bottom,
        en: 'Constipation',
        ta: 'மலச்சிக்கல்',
        hi: 'कब्ज',
      ),
      _QuickSelectOption(
        symptomKey: 'loss of appetite',
        icon: Icons.no_food,
        en: 'Loss of appetite',
        ta: 'பசியின்மை',
        hi: 'भूख न लगना',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'neurological',
    icon: Icons.psychology,
    en: 'Head / Neurological',
    ta: 'தலை / நரம்பியல்',
    hi: 'सिर / न्यूरोलॉजिकल',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'severe headache',
        icon: Icons.psychology,
        en: 'Severe headache',
        ta: 'கடுமையான தலைவலி',
        hi: 'गंभीर सिरदर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'dizziness',
        icon: Icons.sync,
        en: 'Dizziness',
        ta: 'தலைச்சுற்றல்',
        hi: 'चक्कर',
      ),
      _QuickSelectOption(
        symptomKey: 'fainting',
        icon: Icons.airline_seat_flat,
        en: 'Fainting',
        ta: 'மயக்கம்',
        hi: 'बेहोशी',
      ),
      _QuickSelectOption(
        symptomKey: 'sudden weakness',
        icon: Icons.bolt,
        en: 'Sudden weakness',
        ta: 'திடீர் பலவீனம்',
        hi: 'अचानक कमजोरी',
      ),
      _QuickSelectOption(
        symptomKey: 'speech difficulty',
        icon: Icons.record_voice_over,
        en: 'Speech difficulty',
        ta: 'பேச்சு சிரமம்',
        hi: 'बोलने में कठिनाई',
      ),
      _QuickSelectOption(
        symptomKey: 'seizure',
        icon: Icons.flash_on,
        en: 'Seizure',
        ta: 'வலிப்பு',
        hi: 'दौरे',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'skin',
    icon: Icons.spa,
    en: 'Skin / Allergy',
    ta: 'தோல் / ஒவ்வாமை',
    hi: 'त्वचा / एलर्जी',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'allergic reaction',
        icon: Icons.warning,
        en: 'Allergy symptoms',
        ta: 'ஒவ்வாமை அறிகுறிகள்',
        hi: 'एलर्जी के लक्षण',
      ),
      _QuickSelectOption(
        symptomKey: 'rash',
        icon: Icons.grain,
        en: 'Rash',
        ta: 'தோல் தடிப்பு',
        hi: 'दाने',
      ),
      _QuickSelectOption(
        symptomKey: 'itching',
        icon: Icons.touch_app,
        en: 'Itching',
        ta: 'அரிப்பு',
        hi: 'खुजली',
      ),
      _QuickSelectOption(
        symptomKey: 'swelling',
        icon: Icons.circle,
        en: 'Swelling',
        ta: 'வீக்கம்',
        hi: 'सूजन',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'injury',
    icon: Icons.personal_injury,
    en: 'Injury',
    ta: 'காயம்',
    hi: 'चोट',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'cut / wound',
        icon: Icons.healing,
        en: 'Cut / wound',
        ta: 'காயம் / வெட்டு',
        hi: 'कट / घाव',
      ),
      _QuickSelectOption(
        symptomKey: 'bleeding',
        icon: Icons.bloodtype,
        en: 'Bleeding',
        ta: 'ரத்தப்போக்கு',
        hi: 'रक्तस्राव',
      ),
      _QuickSelectOption(
        symptomKey: 'burn',
        icon: Icons.whatshot,
        en: 'Burn',
        ta: 'தீக்காயம்',
        hi: 'जलन',
      ),
      _QuickSelectOption(
        symptomKey: 'fall',
        icon: Icons.airline_seat_flat_angled,
        en: 'Fall',
        ta: 'கீழே விழுதல்',
        hi: 'गिरना',
      ),
      _QuickSelectOption(
        symptomKey: 'accident / trauma',
        icon: Icons.car_crash,
        en: 'Accident / trauma',
        ta: 'விபத்து',
        hi: 'दुर्घटना',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'urinary',
    icon: Icons.water_drop,
    en: 'Urinary',
    ta: 'சிறுநீர்',
    hi: 'मूत्र',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'painful urination',
        icon: Icons.warning_amber,
        en: 'Painful urination',
        ta: 'வலிமிகுந்த சிறுநீர் கழித்தல்',
        hi: 'दर्दनाक पेशाब',
      ),
      _QuickSelectOption(
        symptomKey: 'frequent urination',
        icon: Icons.repeat,
        en: 'Frequent urination',
        ta: 'அடிக்கடி சிறுநீர் கழித்தல்',
        hi: 'बार-बार पेशाब आना',
      ),
      _QuickSelectOption(
        symptomKey: 'blood in urine',
        icon: Icons.bloodtype,
        en: 'Blood in urine',
        ta: 'சிறுநீரில் ரத்தம்',
        hi: 'पेशाब में खून',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'women',
    icon: Icons.pregnant_woman,
    en: 'Women\'s / Pregnancy-related',
    ta: 'பெண்கள் / கர்ப்பம்',
    hi: 'महिला / गर्भावस्था',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'pregnancy-related concern',
        icon: Icons.pregnant_woman,
        en: 'Pregnancy-related concern',
        ta: 'கர்ப்ப பிரச்சனை',
        hi: 'गर्भावस्था संबंधी चिंता',
      ),
      _QuickSelectOption(
        symptomKey: 'pregnancy pain',
        icon: Icons.healing,
        en: 'Pregnancy pain',
        ta: 'கர்ப்ப வலி',
        hi: 'गर्भावस्था में दर्द',
      ),
      _QuickSelectOption(
        symptomKey: 'pregnancy bleeding',
        icon: Icons.bloodtype,
        en: 'Pregnancy bleeding',
        ta: 'கர்ப்பத்தில் ரத்தப்போக்கு',
        hi: 'गर्भावस्था में रक्तस्राव',
      ),
      _QuickSelectOption(
        symptomKey: 'other women\'s concern',
        icon: Icons.more_horiz,
        en: 'Other women\'s health concern',
        ta: 'பிற பெண்கள் நல பிரச்சனை',
        hi: 'अन्य महिला स्वास्थ्य चिंता',
      ),
    ],
  ),
  _QuickSelectCategory(
    id: 'other',
    icon: Icons.more_horiz,
    en: 'Other',
    ta: 'மற்றவை',
    hi: 'अन्य',
    symptoms: [
      _QuickSelectOption(
        symptomKey: 'extreme fatigue',
        icon: Icons.bedtime,
        en: 'Extreme fatigue',
        ta: 'மிகுந்த சோர்வு',
        hi: 'अत्यधिक थकान',
      ),
      _QuickSelectOption(
        symptomKey: 'unexplained weight loss',
        icon: Icons.trending_down,
        en: 'Unexplained weight loss',
        ta: 'விவரிக்க முடியாத எடை இழப்பு',
        hi: 'அஸ்பஷ்டீக்ருத வஜன் கடனா',
      ),
      _QuickSelectOption(
        symptomKey: 'other symptom',
        icon: Icons.help_outline,
        en: 'Other symptom',
        ta: 'மற்ற அறிகுறி',
        hi: 'अन्य लक्षण',
      ),
    ],
  ),
];

class TriageScreen extends ConsumerStatefulWidget {
  const TriageScreen({
    super.key,
    this.extractionService = const MockSymptomExtractionService(),
    this.redFlagEngine = const RedFlagEngine(),
    this.followUpEngine = const FollowUpEngine(),
    this.resultEngine = const TriageResultEngine(),
    this.actionEngine = const NextBestActionEngine(),
    this.speechToText,
  });

  final SymptomExtractionService extractionService;
  final RedFlagEngine redFlagEngine;
  final FollowUpEngine followUpEngine;
  final TriageResultEngine resultEngine;
  final NextBestActionEngine actionEngine;
  final SpeechToText? speechToText;

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  _TriageStep _currentStep = _TriageStep.input;
  _InputMode _inputMode = _InputMode.text;

  final TextEditingController _textController = TextEditingController();
  final TextEditingController _durationEditController = TextEditingController();
  String? _errorMessage;

  late final SpeechToText _speech;
  bool _speechAvailable = false;
  VoiceState _voiceState = VoiceState.idle;

  // Quick select state
  String? _selectedCategoryId;

  // Extraction review editable state
  String? _reviewedSymptomName;
  SymptomSeverity? _reviewedSeverity;
  String? _reviewedDuration;

  bool _isLoading = false;
  ExtractionResult? _extractionResult;
  TriageSession? _currentSession;
  FollowUpResult? _followUpResult;
  final List<FollowUpAnswer> _followUpAnswers = [];
  TriageResult? _triageResult;
  NextBestAction? _nextBestAction;

  @override
  void initState() {
    super.initState();
    _speech = widget.speechToText ?? SpeechToText();
    _initSpeech();
  }

  @override
  void dispose() {
    _textController.dispose();
    _durationEditController.dispose();
    super.dispose();
  }

  Future<void> _initSpeech() async {
    try {
      final available = await _speech.initialize(
        onStatus: (status) {
          debugPrint('[SpeechDebug] onStatus: "$status"');
          if (!mounted) return;
          if (status == 'done' || status == 'notListening') {
            setState(() {
              if (_textController.text.trim().isNotEmpty) {
                _voiceState = VoiceState.recognized;
              } else {
                _voiceState = VoiceState.idle;
              }
            });
          } else if (status == 'listening') {
            setState(() => _voiceState = VoiceState.listening);
          }
        },
        onError: (e) {
          debugPrint('[SpeechDebug] onError: errorMsg="${e.errorMsg}", permanent=${e.permanent}');
          if (!mounted) return;
          final msg = e.errorMsg.toLowerCase();
          if (msg.contains('error_language_not_supported') ||
              msg.contains('error_language_unavailable') ||
              msg.contains('language not supported') ||
              msg.contains('language unavailable')) {
            setState(() => _voiceState = VoiceState.unsupportedLanguage);
          } else if (msg.contains('error_speech_timeout') ||
                     msg.contains('error_no_match')) {
            setState(() {
              if (_textController.text.trim().isNotEmpty) {
                _voiceState = VoiceState.recognized;
              } else {
                _voiceState = VoiceState.idle;
              }
            });
          } else {
            setState(() => _voiceState = VoiceState.error);
          }
        },
      );
      debugPrint('[SpeechDebug] initialize() finished: available=$available');
      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (e) {
      debugPrint('[SpeechDebug] initialize() threw exception: $e');
      if (mounted) {
        setState(() {
          _speechAvailable = false;
          _voiceState = VoiceState.error;
        });
      }
    }
  }

  String _text({
    required String en,
    required String ta,
    required String hi,
  }) {
    final code = ref.watch(selectedLocaleProvider).languageCode;
    return switch (code) {
      'ta' => ta,
      'hi' => hi,
      _ => en,
    };
  }

  Future<void> _toggleListening() async {
    if (_voiceState == VoiceState.listening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          if (_textController.text.trim().isNotEmpty) {
            _voiceState = VoiceState.recognized;
          } else {
            _voiceState = VoiceState.idle;
          }
        });
      }
      return;
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        if (mounted) {
          setState(() => _voiceState = VoiceState.error);
        }
        return;
      }
    }

    final code = ref.read(selectedLocaleProvider).languageCode;
    debugPrint('[SpeechDebug] _toggleListening: appLocale=$code, _speechAvailable=$_speechAvailable');

    List<LocaleName> availableLocales = [];
    try {
      availableLocales = await _speech.locales();
      debugPrint('[SpeechDebug] locales() count=${availableLocales.length}: ${availableLocales.map((l) => l.localeId).take(15).toList()}');
    } catch (e) {
      debugPrint('[SpeechDebug] locales() query exception: $e');
      availableLocales = [];
    }

    String localeId;
    if (code == 'ta') {
      LocaleName? matchedTamil;
      if (availableLocales.isNotEmpty) {
        for (final l in availableLocales) {
          final id = l.localeId.toLowerCase();
          final name = l.name.toLowerCase();
          if (id.startsWith('ta') ||
              id.startsWith('tam') ||
              name.contains('tamil') ||
              name.contains('தமிழ்')) {
            matchedTamil = l;
            break;
          }
        }
      }
      // CRITICAL: On Android 13+ (API 33+), locales() only returns on-device offline models.
      // Online recognition handles Tamil (ta-IN) even if offline models are not installed.
      // Therefore, attempt recognition with the matched device locale ID if available,
      // or default to standard 'ta-IN'. Do NOT prematurely block with unsupportedLanguage.
      localeId = matchedTamil?.localeId ?? 'ta-IN';
      debugPrint('[SpeechDebug] selected Tamil localeId="$localeId" (matchedOnDevice=${matchedTamil?.localeId})');
    } else if (code == 'hi') {
      LocaleName? matchedHindi;
      if (availableLocales.isNotEmpty) {
        for (final l in availableLocales) {
          final id = l.localeId.toLowerCase();
          final name = l.name.toLowerCase();
          if (id.startsWith('hi') ||
              id.startsWith('hin') ||
              name.contains('hindi') ||
              name.contains('हिंदी') ||
              name.contains('हिन्दी')) {
            matchedHindi = l;
            break;
          }
        }
      }
      localeId = matchedHindi?.localeId ?? 'hi-IN';
      debugPrint('[SpeechDebug] selected Hindi localeId="$localeId"');
    } else {
      LocaleName? matchedEnglish;
      if (availableLocales.isNotEmpty) {
        for (final l in availableLocales) {
          final id = l.localeId.toLowerCase();
          if (id.startsWith('en-in') || id.startsWith('en_in')) {
            matchedEnglish = l;
            break;
          }
        }
        matchedEnglish ??= availableLocales.cast<LocaleName?>().firstWhere(
              (l) => l != null && l.localeId.toLowerCase().startsWith('en'),
              orElse: () => null,
            );
      }
      localeId = matchedEnglish?.localeId ?? 'en-IN';
      debugPrint('[SpeechDebug] selected English localeId="$localeId"');
    }

    try {
      setState(() {
        _voiceState = VoiceState.listening;
        _errorMessage = null;
      });

      debugPrint('[SpeechDebug] calling _speech.listen(localeId: "$localeId")...');
      await _speech.listen(
        onResult: (result) {
          debugPrint('[SpeechDebug] onResult: words="${result.recognizedWords}", final=${result.finalResult}');
          if (mounted) {
            setState(() {
              _textController.text = result.recognizedWords;
              if (result.recognizedWords.isNotEmpty) {
                _voiceState = VoiceState.recognized;
              }
            });
          }
        },
        listenOptions: SpeechListenOptions(
          localeId: localeId,
          partialResults: true,
        ),
      );
      debugPrint('[SpeechDebug] _speech.listen started successfully');
    } catch (e) {
      debugPrint('[SpeechDebug] _speech.listen threw exception: $e');
      if (mounted) {
        final msg = e.toString().toLowerCase();
        if (msg.contains('error_language_not_supported') ||
            msg.contains('error_language_unavailable') ||
            msg.contains('not supported') ||
            msg.contains('unsupported')) {
          setState(() => _voiceState = VoiceState.unsupportedLanguage);
        } else {
          setState(() => _voiceState = VoiceState.error);
        }
      }
    }
  }

  Future<void> _submitInput() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() {
        _errorMessage = _text(
          en: 'Please enter or speak your symptoms.',
          ta: 'உங்கள் அறிகுறிகளை உள்ளிடவும் அல்லது பேசவும்.',
          hi: 'कृपया अपने लक्षण दर्ज करें या बोलें।',
        );
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final langCode = ref.read(selectedLocaleProvider).languageCode;
    final source = _inputMode == _InputMode.voice ? InputSource.voice : InputSource.text;

    final extraction = await widget.extractionService.extract(
      text,
      languageCode: langCode,
      inputSource: source,
    );

    if (!mounted) return;

    final primary = extraction.symptoms.isNotEmpty ? extraction.symptoms.first : null;

    setState(() {
      _isLoading = false;
      _extractionResult = extraction;
      _reviewedSymptomName = primary?.symptomName;
      _reviewedSeverity = primary?.severity;
      _reviewedDuration = primary?.duration;
      _durationEditController.text = primary?.duration ?? '';
      _currentStep = _TriageStep.extractionReview;
    });
  }

  Future<void> _showQuickSelectSeverityPicker(String symptomName) async {
    final chosenSeverity = await showModalBottomSheet<SymptomSeverity?>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _text(
                    en: 'How severe is it? (Optional)',
                    ta: 'இதன் தீவிரம் என்ன? (விருப்பமானது)',
                    hi: 'यह कितना गंभीर है? (वैकल्पिक)',
                  ),
                  style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  symptomName,
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: Text(_text(en: 'Mild', ta: 'லேசான', hi: 'हल्का')),
                      onPressed: () => Navigator.of(ctx).pop(SymptomSeverity.mild),
                    ),
                    ActionChip(
                      label: Text(_text(en: 'Moderate', ta: 'மிதமான', hi: 'मध्यम')),
                      onPressed: () => Navigator.of(ctx).pop(SymptomSeverity.moderate),
                    ),
                    ActionChip(
                      label: Text(_text(en: 'Severe', ta: 'கடுமையான', hi: 'गंभीर')),
                      onPressed: () => Navigator.of(ctx).pop(SymptomSeverity.severe),
                    ),
                    ActionChip(
                      label: Text(_text(en: 'Not sure', ta: 'தெரியவில்லை', hi: 'निश्चित नहीं')),
                      onPressed: () => Navigator.of(ctx).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    _onQuickSelectSymptom(symptomName, severity: chosenSeverity);
  }

  void _onQuickSelectSymptom(String symptomName, {SymptomSeverity? severity}) {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final session = TriageSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_default',
      languageCode: ref.read(selectedLocaleProvider).languageCode,
      createdAt: DateTime.now(),
      inputSource: InputSource.quickSelect,
      symptoms: [
        PatientSymptom(
          symptomName: symptomName,
          severity: severity,
          inputSource: InputSource.quickSelect,
        ),
      ],
      patientContext: PatientContext(),
    );

    _runPipelineFromSession(session);
  }

  void _confirmExtractionReview() {
    final extraction = _extractionResult;
    if (extraction == null) return;

    // Apply user edits if modified in review
    final confirmedSymptomName = _reviewedSymptomName ??
        (extraction.symptoms.isNotEmpty ? extraction.symptoms.first.symptomName : 'general unwellness');

    final primarySymptom = PatientSymptom(
      symptomName: confirmedSymptomName,
      inputSource: extraction.inputSource,
      severity: _reviewedSeverity,
      duration: _durationEditController.text.trim().isNotEmpty
          ? _durationEditController.text.trim()
          : _reviewedDuration,
      associatedSymptoms: extraction.symptoms.isNotEmpty
          ? extraction.symptoms.first.associatedSymptoms
          : const [],
    );

    final session = TriageSession(
      id: 'sess_${DateTime.now().millisecondsSinceEpoch}',
      patientId: 'patient_default',
      languageCode: extraction.languageCode,
      createdAt: DateTime.now(),
      inputSource: extraction.inputSource,
      symptoms: [primarySymptom],
      patientContext: extraction.patientContext ?? PatientContext(),
    );

    _runPipelineFromSession(session);
  }

  void _runPipelineFromSession(TriageSession session) {
    _currentSession = session;

    // Task 07C fix: enrich the session with all collected follow-up answers
    // BEFORE running the safety pipeline. This ensures that answers such as
    // "Yes, the chest pain is severe or getting worse" are reflected in the
    // structured session that RedFlagEngine evaluates.
    //
    // The original session is never mutated — applyFollowUpAnswers returns a
    // new session. If there are no answers, the original is returned as-is.
    final enrichedSession = applyFollowUpAnswers(session, _followUpAnswers);

    // 05B RedFlagEngine — evaluate against the ENRICHED session
    final redFlagAssessment = widget.redFlagEngine.assess(enrichedSession);

    // 05C FollowUpEngine — also uses enriched session so relevance checks
    // and missing-info checks are consistent with the latest state
    final followUpResult = widget.followUpEngine.evaluate(
      enrichedSession,
      answers: _followUpAnswers,
    );
    _followUpResult = followUpResult;

    // Check if safety red flag allows follow up or question exists
    if (!redFlagAssessment.hasRedFlag && followUpResult.question != null) {
      setState(() {
        _isLoading = false;
        _currentStep = _TriageStep.followUp;
      });
      return;
    }

    // 05E TriageResultEngine — evaluate against the enriched session
    final triageResult = widget.resultEngine.generate(
      enrichedSession,
      safetyAssessment: redFlagAssessment,
      followUpResult: followUpResult,
      extractionResult: _extractionResult,
    );

    // 05F NextBestActionEngine — evaluate against the enriched session
    final nextBestAction = widget.actionEngine.determine(
      triageResult,
      session: enrichedSession,
      extractionResult: _extractionResult,
    );

    setState(() {
      _isLoading = false;
      _triageResult = triageResult;
      _nextBestAction = nextBestAction;
      _currentStep = _TriageStep.result;
    });
  }

  void _submitFollowUpAnswer(dynamic value) {
    final question = _followUpResult?.question;
    final session = _currentSession;
    if (question == null || session == null) return;

    final String answerVal;
    if (value is bool) {
      answerVal = value ? 'yes' : 'no';
    } else {
      final str = value.toString().trim();
      answerVal = str.isEmpty ? 'unknown' : str;
    }

    final answer = FollowUpAnswer(
      questionId: question.id,
      value: answerVal,
      inputSource: switch (_inputMode) {
        _InputMode.voice => InputSource.voice,
        _InputMode.text => InputSource.text,
        _InputMode.quickSelect => InputSource.quickSelect,
      },
      answeredAt: DateTime.now(),
    );

    setState(() {
      _isLoading = true;
      _followUpAnswers.add(answer);
    });

    _runPipelineFromSession(session);
  }

  void _resetFlow() {
    setState(() {
      _currentStep = _TriageStep.input;
      _inputMode = _InputMode.text;
      _textController.clear();
      _durationEditController.clear();
      _isLoading = false;
      _voiceState = VoiceState.idle;
      _selectedCategoryId = null;
      _reviewedSymptomName = null;
      _reviewedSeverity = null;
      _reviewedDuration = null;
      _errorMessage = null;
      _extractionResult = null;
      _currentSession = null;
      _followUpResult = null;
      _followUpAnswers.clear();
      _triageResult = null;
      _nextBestAction = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _text(
            en: 'Symptom Triage',
            ta: 'அறிகுறி பரிசோதனை',
            hi: 'लक्षण ट्राइएज',
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_currentStep != _TriageStep.input) {
              _resetFlow();
            } else {
              context.pop();
            }
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: switch (_currentStep) {
                _TriageStep.input => _buildInputStep(),
                _TriageStep.extractionReview => _buildExtractionReviewStep(),
                _TriageStep.followUp => _buildFollowUpStep(),
                _TriageStep.result => _buildResultStep(),
              },
            ),
    );
  }

  Widget _buildInputStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _text(
            en: 'How are you feeling today?',
            ta: 'இன்று உங்களுக்கு எவ்வாறு உள்ளது?',
            hi: 'आज आप कैसा महसूस कर रहे हैं?',
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          _text(
            en: 'Describe your symptoms using voice, text, or quick select.',
            ta: 'குரல், தட்டச்சு அல்லது விரைவு தேர்வு மூலம் அறிகுறிகளை விவரிக்கவும்.',
            hi: 'आवाज, टेक्स्ट या त्वरित चयन का उपयोग करके अपने लक्षणों का वर्णन करें।',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        SegmentedButton<_InputMode>(
          segments: [
            ButtonSegment<_InputMode>(
              value: _InputMode.voice,
              icon: const Icon(Icons.mic),
              label: Text(_text(en: 'Voice', ta: 'குரல்', hi: 'आवाज')),
            ),
            ButtonSegment<_InputMode>(
              value: _InputMode.text,
              icon: const Icon(Icons.edit),
              label: Text(_text(en: 'Text', ta: 'உரை', hi: 'टेक्स्ट')),
            ),
            ButtonSegment<_InputMode>(
              value: _InputMode.quickSelect,
              icon: const Icon(Icons.touch_app),
              label: Text(_text(en: 'Quick Select', ta: 'விரைவு தேர்வு', hi: 'त्वरित चयन')),
            ),
          ],
          selected: {_inputMode},
          onSelectionChanged: (set) {
            setState(() {
              _inputMode = set.first;
              _errorMessage = null;
            });
          },
        ),
        const SizedBox(height: 20),
        if (_inputMode == _InputMode.voice) ...[
          _buildVoiceSection(),
        ] else if (_inputMode == _InputMode.text) ...[
          TextField(
            controller: _textController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: _text(
                en: 'e.g., I have severe chest pain and shortness of breath since 2 hours',
                ta: 'எ.கா., எனக்கு 2 மணி நேரமாக கடுமையான மார்பு வலி மற்றும் மூச்சுத் திணறல் உள்ளது',
                hi: 'उदा., मुझे 2 घंटे से सीने में तेज दर्द और सांस लेने में तकलीफ है',
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _submitInput,
            icon: const Icon(Icons.arrow_forward),
            label: Text(_text(en: 'Analyze Symptoms', ta: 'அறிகுறிகளை ஆய்வு செய்', hi: 'लक्षणों का विश्लेषण करें')),
          ),
        ] else ...[
          _buildQuickSelectSection(),
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceSection() {
    if (_voiceState == VoiceState.unsupportedLanguage) {
      return Card(
        color: Colors.amber.shade50,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 44),
              const SizedBox(height: 12),
              Text(
                _text(
                  en: 'Tamil voice recognition is not supported by the speech service on this device. Please use text input or Quick Select.',
                  ta: 'இந்த சாதனத்தின் பேச்சு சேவையில் தமிழ் குரல் உள்ளீடு கிடைக்கவில்லை. தட்டச்சு அல்லது விரைவு தேர்வைப் பயன்படுத்தவும்.',
                  hi: 'इस डिवाइस की ध्वनि सेवा में तमिल आवाज पहचान समर्थित नहीं है। कृपया टेक्स्ट इनपुट या त्वरित चयन का उपयोग करें।',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _inputMode = _InputMode.text;
                        _voiceState = VoiceState.idle;
                      });
                    },
                    icon: const Icon(Icons.edit),
                    label: Text(_text(en: 'Type Symptoms', ta: 'தட்டச்சு செய்', hi: 'टेक्स्ट इनपुट')),
                  ),
                  FilledButton.icon(
                    onPressed: () {
                      setState(() {
                        _inputMode = _InputMode.quickSelect;
                        _voiceState = VoiceState.idle;
                      });
                    },
                    icon: const Icon(Icons.touch_app),
                    label: Text(_text(en: 'Quick Select', ta: 'விரைவு தேர்வு', hi: 'त्वरित चयन')),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final isListening = _voiceState == VoiceState.listening;
    final isRecognized = _voiceState == VoiceState.recognized;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            IconButton.filled(
              iconSize: 48,
              style: IconButton.styleFrom(
                backgroundColor: isListening ? Colors.red : AppTheme.primary,
              ),
              icon: Icon(isListening ? Icons.mic : Icons.mic_none),
              onPressed: _toggleListening,
            ),
            const SizedBox(height: 12),
            Text(
              isListening
                  ? _text(en: 'Listening... Speak clearly.', ta: 'கேட்கிறது... தெளிவாகப் பேசவும்.', hi: 'सुन रहा है... स्पष्ट रूप से बोलें।')
                  : _text(en: 'Tap microphone to speak', ta: 'பேச மைக்ரோஃபோனைத் தட்டவும்', hi: 'बोलने के लिए माइक्रोफ़ोन टैप करें'),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isListening ? FontWeight.bold : FontWeight.normal,
                    color: isListening ? Colors.red : Colors.black87,
                  ),
            ),
            const SizedBox(height: 16),
            if (isRecognized && _textController.text.trim().isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _text(en: 'I heard:', ta: 'நான் கேட்டது:', hi: 'मैंने सुना:'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _textController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _textController.clear();
                        _toggleListening();
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(_text(en: 'Try again', ta: 'மீண்டும் செய்', hi: 'पुनः प्रयास करें')),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _inputMode = _InputMode.text);
                      },
                      icon: const Icon(Icons.edit, size: 18),
                      label: Text(_text(en: 'Edit', ta: 'திருத்து', hi: 'संपादित करें')),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _submitInput,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_text(en: 'Use this / Analyze', ta: 'இதைப் பயன்படுத்து', hi: 'उपयोग करें / विश्लेषण करें')),
              ),
            ] else ...[
              TextField(
                controller: _textController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: _text(
                    en: 'Spoken words appear here...',
                    ta: 'பேசும் வார்த்தைகள் இங்கே தோன்றும்...',
                    hi: 'बोले गए शब्द यहाँ दिखाई देंगे...',
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _submitInput,
                icon: const Icon(Icons.arrow_forward),
                label: Text(_text(en: 'Analyze Symptoms', ta: 'அறிகுறிகளை ஆய்வு செய்', hi: 'लक्षणों का विश्लेषण करें')),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSelectSection() {
    if (_selectedCategoryId == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Common Symptoms
          Text(
            _text(
              en: 'Common Symptoms:',
              ta: 'பொதுவான அறிகுறிகள்:',
              hi: 'सामान्य लक्षण:',
            ),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _commonQuickSelectOptions.map((opt) {
              final label = _text(en: opt.en, ta: opt.ta, hi: opt.hi);
              return ActionChip(
                avatar: Icon(opt.icon, size: 18),
                label: Text(label),
                onPressed: () => _showQuickSelectSeverityPicker(opt.symptomKey),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // Browse by Category
          Text(
            _text(
              en: 'Browse by Category:',
              ta: 'பிரிவு வாரியாக பார்க்கவும்:',
              hi: 'श्रेणी के अनुसार ब्राउज़ करें:',
            ),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _quickSelectCategories.length,
            itemBuilder: (context, idx) {
              final cat = _quickSelectCategories[idx];
              final catTitle = _text(en: cat.en, ta: cat.ta, hi: cat.hi);
              return Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    setState(() => _selectedCategoryId = cat.id);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                          child: Icon(cat.icon, size: 18, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            catTitle,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      );
    }

    // Category selected: show subcategories
    final category = _quickSelectCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _quickSelectCategories.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                setState(() => _selectedCategoryId = null);
              },
            ),
            Expanded(
              child: Text(
                _text(en: category.en, ta: category.ta, hi: category.hi),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedCategoryId = null);
              },
              child: Text(_text(en: 'All Categories', ta: 'அனைத்து பிரிவுகள்', hi: 'सभी श्रेणियां')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: category.symptoms.map((opt) {
            final label = _text(en: opt.en, ta: opt.ta, hi: opt.hi);
            return ActionChip(
              avatar: Icon(opt.icon, size: 18),
              label: Text(label),
              onPressed: () => _showQuickSelectSeverityPicker(opt.symptomKey),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildExtractionReviewStep() {
    final result = _extractionResult;
    if (result == null) return const SizedBox.shrink();

    final primarySymptom = result.symptoms.isNotEmpty ? result.symptoms.first : null;
    final currentSymptomName = _reviewedSymptomName ?? primarySymptom?.symptomName ?? 'Symptom';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _text(
            en: 'Agaram Care Understood',
            ta: 'அகரம் கேர் புரிந்து கொண்டது',
            hi: 'अग्रम केयर ने समझा',
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          _text(
            en: 'Is this correct? You can adjust before safety evaluation.',
            ta: 'இது சரியானதா? மதிப்பீட்டிற்கு முன் நீங்கள் மாற்றலாம்.',
            hi: 'क्या यह सही है? मूल्यांकन से पहले आप बदल सकते हैं।',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.15),
                    child: const Icon(Icons.medical_services, color: AppTheme.primary),
                  ),
                  title: Text(
                    currentSymptomName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Text(
                    '${_text(en: 'Severity', ta: 'தீவிரம்', hi: 'गंभीरता')}: ${_reviewedSeverity?.name ?? _text(en: 'Unknown', ta: 'தெரியவில்லை', hi: 'अज्ञात')}',
                  ),
                ),
                const Divider(),
                const SizedBox(height: 4),

                // Severity override chips
                Text(
                  _text(en: 'Adjust Severity:', ta: 'தீவிரத்தை மாற்று:', hi: 'गंभीरता बदलें:'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    ChoiceChip(
                      label: Text(_text(en: 'Mild', ta: 'லேசான', hi: 'हल्का')),
                      selected: _reviewedSeverity == SymptomSeverity.mild,
                      onSelected: (sel) {
                        setState(() => _reviewedSeverity = sel ? SymptomSeverity.mild : null);
                      },
                    ),
                    ChoiceChip(
                      label: Text(_text(en: 'Moderate', ta: 'மிதமான', hi: 'मध्यम')),
                      selected: _reviewedSeverity == SymptomSeverity.moderate,
                      onSelected: (sel) {
                        setState(() => _reviewedSeverity = sel ? SymptomSeverity.moderate : null);
                      },
                    ),
                    ChoiceChip(
                      label: Text(_text(en: 'Severe', ta: 'கடுமையான', hi: 'गंभीर')),
                      selected: _reviewedSeverity == SymptomSeverity.severe,
                      onSelected: (sel) {
                        setState(() => _reviewedSeverity = sel ? SymptomSeverity.severe : null);
                      },
                    ),
                    ChoiceChip(
                      label: Text(_text(en: 'Not sure', ta: 'தெரியவில்லை', hi: 'निश्चित नहीं')),
                      selected: _reviewedSeverity == null,
                      onSelected: (sel) {
                        setState(() => _reviewedSeverity = null);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Duration edit field
                Text(
                  _text(en: 'Duration:', ta: 'கால அளவு:', hi: 'अवधि:'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _durationEditController,
                  decoration: InputDecoration(
                    hintText: _text(
                      en: 'e.g., since morning, 2 days',
                      ta: 'எ.கா., இன்று காலை முதல், 2 நாட்கள்',
                      hi: 'उदा., आज सुबह से, 2 दिन',
                    ),
                    isDense: true,
                    border: const OutlineInputBorder(),
                  ),
                ),

                if (result.symptoms.isNotEmpty && result.symptoms.first.associatedSymptoms.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _text(
                      en: 'Associated symptoms recognized:',
                      ta: 'தொடர்புடைய பிற அறிகுறிகள்:',
                      hi: 'संबंधित अन्य लक्षण:',
                    ),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: result.symptoms.first.associatedSymptoms.map((s) {
                      return Chip(
                        label: Text(s.symptomName),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                ],

                if (result.patientContext != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _text(en: 'Patient Context:', ta: 'நோயாளி சூழல்:', hi: 'मरीज का संदर्भ:'),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  if (result.patientContext!.ageYears != null)
                    Text('• Age: ${result.patientContext!.ageYears} years', style: const TextStyle(fontSize: 12)),
                  if (result.patientContext!.pregnancyStatus == true)
                    Text('• Pregnancy: Yes', style: const TextStyle(fontSize: 12)),
                  if (result.patientContext!.knownConditions.isNotEmpty)
                    Text('• Conditions: ${result.patientContext!.knownConditions.join(", ")}', style: const TextStyle(fontSize: 12)),
                  if (result.patientContext!.currentMedications.isNotEmpty)
                    Text('• Medications: ${result.patientContext!.currentMedications.join(", ")}', style: const TextStyle(fontSize: 12)),
                ],

                if (result.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            result.warnings.first.message,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _currentStep = _TriageStep.input;
                    _inputMode = _InputMode.text;
                  });
                },
                child: Text(_text(en: 'Edit Input', ta: 'திருத்து', hi: 'संपादित करें')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: _confirmExtractionReview,
                child: Text(_text(en: 'Confirm & Triage', ta: 'உறுதி செய்', hi: 'पुष्टि करें')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFollowUpStep() {
    final result = _followUpResult;
    final question = result?.question;
    if (question == null) return const SizedBox.shrink();

    final currentLang = ref.watch(selectedLocaleProvider).languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.help_outline, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _text(
                      en: 'Follow-Up Question',
                      ta: 'பின்தொடர் கேள்வி',
                      hi: 'फॉलो-अप प्रश्न',
                    ),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(
                    _text(
                      en: 'Please answer to help us assess safety accurately.',
                      ta: 'பாதுகாப்பை துல்லியமாக மதிப்பீடு செய்ய பதிலளிக்கவும்.',
                      hi: 'सुरक्षा का सटीक आकलन करने के लिए कृपया उत्तर दें।',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  question.textFor(currentLang),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 20),
                if (question.responseType == FollowUpResponseType.yesNo) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _submitFollowUpAnswer(false),
                          child: Text(_text(en: 'No', ta: 'இல்லை', hi: 'नहीं')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => _submitFollowUpAnswer(true),
                          child: Text(_text(en: 'Yes', ta: 'ஆம்', hi: 'हाँ')),
                        ),
                      ),
                    ],
                  ),
                ] else if (question.options.isNotEmpty) ...[
                  ...question.options.map((opt) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: () => _submitFollowUpAnswer(opt),
                        child: Text(opt),
                      ),
                    );
                  }),
                ] else ...[
                  OutlinedButton(
                    onPressed: () => _submitFollowUpAnswer('Done'),
                    child: Text(_text(en: 'Continue', ta: 'தொடரவும்', hi: 'जारी रखें')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultStep() {
    final result = _triageResult;
    final action = _nextBestAction;
    if (result == null || action == null) return const SizedBox.shrink();

    final isEmergency = result.urgency == TriageUrgency.emergency ||
        action.actionType == NextActionType.emergencyCare;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Triage Result Card
        Card(
          color: isEmergency ? Colors.red.shade50 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isEmergency ? Colors.red.shade300 : Colors.grey.shade200,
              width: isEmergency ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isEmergency ? Icons.warning_amber_rounded : Icons.health_and_safety,
                      color: isEmergency ? Colors.red : AppTheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isEmergency ? Colors.red.shade900 : Colors.black87,
                                ),
                          ),
                          if (result.urgency != null) ...[
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _urgencyColor(result.urgency!).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                result.urgency!.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _urgencyColor(result.urgency!),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  result.explanation,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (result.triggeredRuleIds.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: result.triggeredRuleIds.map((rfId) {
                        return Row(
                          children: [
                            const Icon(Icons.emergency, color: Colors.red, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                rfId,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.verified_user_outlined, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        result.requiresHumanReview
                            ? _text(
                                en: 'Requires clinician/VHN review.',
                                ta: 'மருத்துவர்/VHN மதிப்பாய்வு தேவை.',
                                hi: 'चिकित्सक/VHN समीक्षा आवश्यक है।',
                              )
                            : _text(
                                en: 'Self-limiting / Standard care.',
                                ta: 'சுய கட்டுப்பாடு / வழக்கமான பராமரிப்பு.',
                                hi: 'आत्म-सीमित / मानक देखभाल।',
                              ),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Next Best Action Card
        Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: isEmergency
                          ? Colors.red.shade100
                          : AppTheme.primary.withValues(alpha: 0.15),
                      child: Icon(
                        _actionIcon(action.actionType),
                        color: isEmergency ? Colors.red : AppTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _text(
                              en: 'Recommended Next Action',
                              ta: 'பரிந்துரைக்கப்பட்ட அடுத்த நடவடிக்கை',
                              hi: 'अनुशंसित अगली कार्रवाई',
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            _actionLabel(action.actionType),
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  action.reason,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Find Healthcare / Matched Facilities button
        if (action.requiresFacilitySelection || isEmergency) ...[
          FilledButton.icon(
            style: isEmergency
                ? FilledButton.styleFrom(backgroundColor: Colors.red.shade700)
                : null,
            onPressed: () {
              final careRequest = PatientCareRequest.fromTriage(
                triageResult: result,
                nextBestAction: action,
              );
              context.push('/facilities', extra: careRequest);
            },
            icon: const Icon(Icons.local_hospital_outlined),
            label: Text(
              _text(
                en: 'View Matched Facilities',
                ta: 'பொருத்தமான மருத்துவமனைகளைப் பார்க்க',
                hi: 'मेल खाने वाली सुविधाएं देखें',
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Home action button
        FilledButton.icon(
          onPressed: () {
            context.go('/patient');
          },
          icon: const Icon(Icons.home),
          label: Text(
            _text(
              en: 'Return to Home',
              ta: 'முகப்பிற்குத் திரும்பு',
              hi: 'होम पर वापस जाएं',
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: _resetFlow,
          child: Text(
            _text(
              en: 'Start New Assessment',
              ta: 'புதிய பரிசோதனையைத் தொடங்கு',
              hi: 'नया मूल्यांकन शुरू करें',
            ),
          ),
        ),
      ],
    );
  }

  Color _urgencyColor(TriageUrgency urgency) {
    return switch (urgency) {
      TriageUrgency.emergency => Colors.red,
      TriageUrgency.urgent => Colors.orange,
      TriageUrgency.soon => Colors.amber.shade700,
      TriageUrgency.routine => Colors.green,
    };
  }

  IconData _actionIcon(NextActionType type) {
    return switch (type) {
      NextActionType.emergencyCare || NextActionType.emergencyReferral => Icons.local_hospital,
      NextActionType.facilityReferral => Icons.business,
      NextActionType.teleconsultation => Icons.video_call,
      NextActionType.vhnFollowUp => Icons.home_work,
      NextActionType.selfCare || NextActionType.selfMonitor => Icons.spa,
      NextActionType.primaryCare => Icons.medical_services,
      NextActionType.laboratory => Icons.biotech,
      NextActionType.specialist => Icons.person,
      NextActionType.undetermined => Icons.help_outline,
    };
  }

  String _actionLabel(NextActionType type) {
    return switch (type) {
      NextActionType.emergencyCare || NextActionType.emergencyReferral => _text(
          en: 'Emergency Care',
          ta: 'அவசர சிகிச்சை',
          hi: 'आपातकालीन देखभाल',
        ),
      NextActionType.facilityReferral => _text(
          en: 'Visit Healthcare Facility',
          ta: 'சுகாதார நிலையத்திற்குச் செல்லவும்',
          hi: 'स्वास्थ्य केंद्र पर जाएं',
        ),
      NextActionType.teleconsultation => _text(
          en: 'Doctor Teleconsultation',
          ta: 'மருத்துவர் தொலைத்தொடர்பு',
          hi: 'डॉक्टर टेलीकंसल्टेशन',
        ),
      NextActionType.vhnFollowUp => _text(
          en: 'VHN Home Visit',
          ta: 'VHN இல்ல வருகை',
          hi: 'VHN गृह दौरा',
        ),
      NextActionType.selfCare || NextActionType.selfMonitor => _text(
          en: 'Self-Care & Monitoring',
          ta: 'சுய பராமரிப்பு மற்றும் கண்காணிப்பு',
          hi: 'स्व-देखभाल और निगरानी',
        ),
      NextActionType.primaryCare => _text(
          en: 'Primary Care Consultation',
          ta: 'ஆரம்ப சுகாதார ஆலோசனை',
          hi: 'प्राथमिक देखभाल परामर्श',
        ),
      NextActionType.laboratory => _text(
          en: 'Diagnostic Laboratory',
          ta: 'பரிசோதனை ஆய்வகம்',
          hi: 'नैदानिक प्रयोगशाला',
        ),
      NextActionType.specialist => _text(
          en: 'Specialist Consultation',
          ta: 'சிறப்பு மருத்துவர் ஆலோசனை',
          hi: 'विशेषज्ञ परामर्श',
        ),
      NextActionType.undetermined => _text(
          en: 'Further Assessment Needed',
          ta: 'கூடுதல் மதிப்பீடு தேவை',
          hi: 'आगे के मूल्यांकन की आवश्यकता है',
        ),
    };
  }
}
