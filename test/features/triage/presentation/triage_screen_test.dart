import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import 'package:agaram_care/app/app_state.dart';
import 'package:agaram_care/features/triage/domain/action/action.dart';
import 'package:agaram_care/features/triage/domain/extraction/extraction.dart';
import 'package:agaram_care/features/triage/domain/follow_up/follow_up.dart';
import 'package:agaram_care/features/triage/domain/red_flags/red_flag_engine.dart';
import 'package:agaram_care/features/triage/domain/result/result.dart';
import 'package:agaram_care/features/triage/presentation/triage_screen.dart';

class MockSpeechToText extends Fake implements SpeechToText {
  MockSpeechToText({
    this.hasTamilLocale = false,
    this.simulateLanguageNotSupported = false,
    this.localesThrow = false,
    this.customLocales,
    this.recognizedTextToEmit,
    this.initSuccess = true,
  });

  final bool hasTamilLocale;
  final bool simulateLanguageNotSupported;
  final bool localesThrow;
  final List<LocaleName>? customLocales;
  final String? recognizedTextToEmit;
  final bool initSuccess;

  String? lastListenLocaleId;
  SpeechStatusListener? _statusListener;
  SpeechErrorListener? _errorListener;

  @override
  bool get isAvailable => initSuccess;

  @override
  bool get isListening => false;

  @override
  Future<bool> initialize({
    SpeechErrorListener? onError,
    SpeechStatusListener? onStatus,
    dynamic debugLogging = false,
    Duration finalTimeout = SpeechToText.defaultFinalTimeout,
    List<SpeechConfigOption>? options,
  }) async {
    _statusListener = onStatus;
    _errorListener = onError;
    return initSuccess;
  }

  @override
  Future<List<LocaleName>> locales() async {
    if (localesThrow) {
      throw Exception('Locales query unsupported on device');
    }
    if (customLocales != null) {
      return customLocales!;
    }
    if (hasTamilLocale) {
      return [
        LocaleName('ta_IN', 'Tamil (India)'),
        LocaleName('en_IN', 'English (India)'),
      ];
    }
    return [
      LocaleName('en_IN', 'English (India)'),
      LocaleName('hi_IN', 'Hindi (India)'),
    ];
  }

  @override
  Future<dynamic> listen({
    SpeechResultListener? onResult,
    Duration? listenFor,
    Duration? pauseFor,
    String? localeId,
    SpeechSoundLevelChange? onSoundLevelChange,
    dynamic cancelOnError = false,
    dynamic partialResults = true,
    dynamic onDevice = false,
    ListenMode listenMode = ListenMode.confirmation,
    dynamic sampleRate = 0,
    SpeechListenOptions? listenOptions,
  }) async {
    final effectiveLocale = localeId ?? listenOptions?.localeId;
    lastListenLocaleId = effectiveLocale;
    _statusListener?.call('listening');
    if (simulateLanguageNotSupported) {
      _errorListener?.call(SpeechRecognitionError('error_language_not_supported', true));
      return;
    }
    if (recognizedTextToEmit != null && onResult != null) {
      onResult(
        SpeechRecognitionResult(
          [SpeechRecognitionWords(recognizedTextToEmit!, [recognizedTextToEmit!], 1.0)],
          2,
        ),
      );
    }
  }

  @override
  Future<void> stop() async {}
}

Widget createTestWidget({
  Locale locale = const Locale('en'),
  SymptomExtractionService? extractionService,
  RedFlagEngine? redFlagEngine,
  FollowUpEngine? followUpEngine,
  TriageResultEngine? resultEngine,
  NextBestActionEngine? actionEngine,
  SpeechToText? speechToText,
}) {
  return ProviderScope(
    overrides: [
      selectedLocaleProvider.overrideWith((ref) => locale),
    ],
    child: MaterialApp(
      home: TriageScreen(
        extractionService: extractionService ?? const MockSymptomExtractionService(),
        redFlagEngine: redFlagEngine ?? const RedFlagEngine(),
        followUpEngine: followUpEngine ?? const FollowUpEngine(),
        resultEngine: resultEngine ?? const TriageResultEngine(),
        actionEngine: actionEngine ?? const NextBestActionEngine(),
        speechToText: speechToText,
      ),
    ),
  );
}

void main() {
  group('Task 06 & Task 07A — Agaram Care Triage UI & Input Understanding Tests', () {
    testWidgets('1. Triage screen renders with app bar and input title', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Symptom Triage'), findsOneWidget);
      expect(find.text('How are you feeling today?'), findsOneWidget);
    });

    testWidgets('2. Voice, Text, and Quick Select modes are visible in segmented control', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('Voice'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
      expect(find.text('Quick Select'), findsOneWidget);
    });

    testWidgets('3. Empty text submission shows validation error', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final analyzeButton = find.widgetWithText(FilledButton, 'Analyze Symptoms');
      expect(analyzeButton, findsOneWidget);

      await tester.tap(analyzeButton);
      await tester.pumpAndSettle();

      expect(find.text('Please enter or speak your symptoms.'), findsOneWidget);
    });

    testWidgets('4. Quick Select symptom triggers severity sheet and displays result', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Quick Select tab
      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      // Tap on 'Cough' chip
      final coughChip = find.widgetWithText(ActionChip, 'Cough');
      expect(coughChip, findsOneWidget);

      await tester.tap(coughChip);
      await tester.pumpAndSettle();

      // Optional severity sheet appears
      expect(find.text('How severe is it? (Optional)'), findsOneWidget);
      expect(find.text('Not sure'), findsOneWidget);

      // Select 'Not sure'
      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      // Should show result step with return home button
      expect(find.text('Return to Home'), findsOneWidget);
      expect(find.text('Start New Assessment'), findsOneWidget);
    });

    testWidgets('5. Text entry progresses to extraction review step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter text in text field
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);

      await tester.enterText(textField, 'I have a mild cough for 3 days');
      await tester.pumpAndSettle();

      final analyzeButton = find.widgetWithText(FilledButton, 'Analyze Symptoms');
      await tester.tap(analyzeButton);
      await tester.pumpAndSettle();

      // Verify Extraction Review step
      expect(find.text('Agaram Care Understood'), findsOneWidget);
      expect(find.text('Confirm & Triage'), findsOneWidget);
      expect(find.text('Edit Input'), findsOneWidget);
    });

    testWidgets('6. Extraction review confirmation proceeds to triage disposition', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'mild headache');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Analyze Symptoms'));
      await tester.pumpAndSettle();

      expect(find.text('Agaram Care Understood'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirm & Triage'));
      await tester.pumpAndSettle();

      // Check results
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('7. Emergency symptom shows emergency styling and NextBestAction', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Quick Select
      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      // Tap Difficulty Breathing (triggers shortness of breath red flag)
      await tester.tap(find.widgetWithText(ActionChip, 'Difficulty Breathing'));
      await tester.pumpAndSettle();

      // Select 'Severe' in severity picker
      await tester.tap(find.text('Severe'));
      await tester.pumpAndSettle();

      // Check for Emergency indication
      expect(find.text('EMERGENCY'), findsWidgets);
      expect(find.text('Emergency Care'), findsWidgets);
    });

    testWidgets('8. Follow-up step appears when question is needed and answering proceeds', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Chest pain in quick select has missing information requiring follow-up
      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'Chest Pain'));
      await tester.pumpAndSettle();

      // Tap 'Not sure' in severity picker so chest pain has insufficient information and triggers follow-up
      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      // Verify Follow-up question is shown
      expect(find.text('Follow-Up Question'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
      expect(find.text('No'), findsOneWidget);

      // Answer 'No' to progress
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Triage completes
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('9. Start New Assessment resets to input step', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ActionChip, 'Cough'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Not sure'));
      await tester.pumpAndSettle();

      expect(find.text('Start New Assessment'), findsOneWidget);

      await tester.tap(find.text('Start New Assessment'));
      await tester.pumpAndSettle();

      expect(find.text('How are you feeling today?'), findsOneWidget);
      expect(find.text('Text'), findsOneWidget);
    });

    testWidgets('10. Multilingual Tamil rendering', (tester) async {
      await tester.pumpWidget(createTestWidget(locale: const Locale('ta')));
      await tester.pumpAndSettle();

      expect(find.text('அறிகுறி பரிசோதனை'), findsOneWidget);
      expect(find.text('இன்று உங்களுக்கு எவ்வாறு உள்ளது?'), findsOneWidget);
      expect(find.text('குரல்'), findsOneWidget);
      expect(find.text('உரை'), findsOneWidget);
      expect(find.text('விரைவு தேர்வு'), findsOneWidget);
    });

    testWidgets('11. Multilingual Hindi rendering', (tester) async {
      await tester.pumpWidget(createTestWidget(locale: const Locale('hi')));
      await tester.pumpAndSettle();

      expect(find.text('लक्षण ट्राइएज'), findsOneWidget);
      expect(find.text('आज आप कैसा महसूस कर रहे हैं?'), findsOneWidget);
      expect(find.text('आवाज'), findsOneWidget);
      expect(find.text('टेक्स्ट'), findsOneWidget);
      expect(find.text('त्वरित चयन'), findsOneWidget);
    });

    // TASK 07A SPECIFIC TESTS

    testWidgets('12. Voice Recognition: Tamil unsupported locale notice without silent language switch', (tester) async {
      final mockSpeech = MockSpeechToText(
        hasTamilLocale: false,
        simulateLanguageNotSupported: true,
      );

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('ta'),
        speechToText: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Switch to Voice tab
      await tester.tap(find.text('குரல்'));
      await tester.pumpAndSettle();

      // Tap mic to initiate
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      // Notice should appear explaining limitation
      expect(
        find.text('இந்த சாதனத்தின் பேச்சு சேவையில் தமிழ் குரல் உள்ளீடு கிடைக்கவில்லை. தட்டச்சு அல்லது விரைவு தேர்வைப் பயன்படுத்தவும்.'),
        findsOneWidget,
      );
      // Fallback buttons exist
      expect(find.widgetWithText(OutlinedButton, 'தட்டச்சு செய்'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'விரைவு தேர்வு'), findsOneWidget);

      // App language must remain Tamil!
      expect(find.text('அறிகுறி பரிசோதனை'), findsOneWidget);
    });

    testWidgets('13. Voice Recognition: English voice input recognizes text, shows I heard, and Edit button works', (tester) async {
      final mockSpeech = MockSpeechToText(
        recognizedTextToEmit: 'severe chest pain since yesterday',
      );

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('en'),
        speechToText: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Switch to Voice tab
      await tester.tap(find.text('Voice'));
      await tester.pumpAndSettle();

      // Tap mic to listen
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      // Should show 'I heard:' card with recognized words
      expect(find.text('I heard:'), findsOneWidget);
      expect(find.text('severe chest pain since yesterday'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Use this / Analyze'), findsOneWidget);

      // Tap Edit -> switches to Text mode with words pre-filled
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'severe chest pain since yesterday'), findsOneWidget);
    });

    testWidgets('14. Quick Select: 2-tier navigation works with categories and back button', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Quick Select
      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      // Browse by Category is visible
      expect(find.text('Browse by Category:'), findsOneWidget);
      expect(find.text('Pain'), findsOneWidget);
      expect(find.text('Breathing'), findsOneWidget);
      expect(find.text('Stomach / Digestion'), findsOneWidget);
      expect(find.text('Skin / Allergy'), findsOneWidget);

      // Tap Pain category
      await tester.tap(find.text('Pain'));
      await tester.pumpAndSettle();

      // Subcategory symptoms under Pain are shown
      expect(find.text('All Categories'), findsOneWidget);
      expect(find.text('Back pain'), findsOneWidget);
      expect(find.text('Joint pain'), findsOneWidget);
      expect(find.text('Tooth pain'), findsOneWidget);

      // Tap 'All Categories' to return
      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();

      expect(find.text('Browse by Category:'), findsOneWidget);
      expect(find.text('Common Symptoms:'), findsOneWidget);
    });

    testWidgets('15. Extraction Review: Allows editing severity and duration before confirming triage', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Enter symptom
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'headache');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Analyze Symptoms'));
      await tester.pumpAndSettle();

      expect(find.text('Agaram Care Understood'), findsOneWidget);
      expect(find.text('Is this correct? You can adjust before safety evaluation.'), findsOneWidget);

      // Adjust severity to Severe
      await tester.tap(find.widgetWithText(ChoiceChip, 'Severe'));
      await tester.pumpAndSettle();

      // Adjust duration
      final durationField = find.widgetWithText(TextField, '');
      if (durationField.evaluate().isNotEmpty) {
        await tester.enterText(durationField, 'since morning');
        await tester.pumpAndSettle();
      }

      // Confirm & Triage
      await tester.tap(find.widgetWithText(FilledButton, 'Confirm & Triage'));
      await tester.pumpAndSettle();

      // Disposition reached
      expect(find.text('Return to Home'), findsOneWidget);
    });

    testWidgets('16. Follow-up answers: Mild chest pain + answers No, No, Yes to worsening escalates to EMERGENCY', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'I have mild chest pain');
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Analyze Symptoms'));
      await tester.pumpAndSettle();

      expect(find.text('Agaram Care Understood'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Confirm & Triage'));
      await tester.pumpAndSettle();

      // Q1: breathing -> No
      expect(find.text('Follow-Up Question'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Q2: consciousness -> No
      expect(find.text('Follow-Up Question'), findsOneWidget);
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();

      // Q3: chest pain severe or getting worse -> Yes
      expect(find.text('Follow-Up Question'), findsOneWidget);
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      // Verify that disposition is EMERGENCY and Emergency Care
      expect(find.text('EMERGENCY'), findsWidgets);
      expect(find.text('Emergency Care'), findsWidgets);
    });

    testWidgets('17. Voice Recognition: Tamil voice input resolves actual supported Tamil locale on device', (tester) async {
      final mockSpeech = MockSpeechToText(
        hasTamilLocale: true,
        recognizedTextToEmit: 'நெஞ்சு வலி',
      );

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('ta'),
        speechToText: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Switch to Voice tab
      await tester.tap(find.text('குரல்'));
      await tester.pumpAndSettle();

      // Tap mic to initiate listening
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      // Unsupported notice MUST NOT appear when device supports Tamil
      expect(
        find.text('இந்த சாதனத்தின் பேச்சு சேவையில் தமிழ் குரல் உள்ளீடு கிடைக்கவில்லை. தட்டச்சு அல்லது விரைவு தேர்வைப் பயன்படுத்தவும்.'),
        findsNothing,
      );

      // Recognizer was called with the actual resolved Tamil locale
      expect(mockSpeech.lastListenLocaleId, equals('ta_IN'));

      // Spoken Tamil text was recognized and displayed
      expect(find.text('நான் கேட்டது:'), findsOneWidget);
      expect(find.text('நெஞ்சு வலி'), findsOneWidget);
    });

    testWidgets('18. Voice Recognition: Tamil voice handles empty or throwing locales() without falling into unsupported language', (tester) async {
      final mockSpeech = MockSpeechToText(
        localesThrow: true,
        recognizedTextToEmit: 'லேசான இருமல்',
      );

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('ta'),
        speechToText: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Switch to Voice tab
      await tester.tap(find.text('குரல்'));
      await tester.pumpAndSettle();

      // Tap mic to initiate listening
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      // Should attempt listening with default Tamil locale instead of prematurely declaring unsupported
      expect(
        find.text('இந்த சாதனத்தின் பேச்சு சேவையில் தமிழ் குரல் உள்ளீடு கிடைக்கவில்லை. தட்டச்சு அல்லது விரைவு தேர்வைப் பயன்படுத்தவும்.'),
        findsNothing,
      );
      expect(mockSpeech.lastListenLocaleId, equals('ta-IN'));
      expect(find.text('லேசான இருமல்'), findsOneWidget);
    });

    testWidgets('19. UI Layout: Unsupported language card produces NO RenderFlex overflow on narrow screen (320px width)', (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockSpeech = MockSpeechToText(
        hasTamilLocale: false,
        simulateLanguageNotSupported: true,
      );

      await tester.pumpWidget(createTestWidget(
        locale: const Locale('ta'),
        speechToText: mockSpeech,
      ));
      await tester.pumpAndSettle();

      // Switch to Voice tab
      await tester.tap(find.text('குரல்'));
      await tester.pumpAndSettle();

      // Tap mic to trigger unsupported language card
      await tester.tap(find.byIcon(Icons.mic_none));
      await tester.pumpAndSettle();

      // Verify card and both buttons are displayed without RenderFlex overflow
      expect(tester.takeException(), isNull);
      final typeButton = find.widgetWithText(OutlinedButton, 'தட்டச்சு செய்');
      final quickButton = find.widgetWithText(FilledButton, 'விரைவு தேர்வு');
      expect(typeButton, findsOneWidget);
      expect(quickButton, findsOneWidget);

      await tester.ensureVisible(typeButton);
      await tester.pumpAndSettle();

      // Verify button tap switches to text mode
      await tester.tap(typeButton);
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('20. Quick Select: All 10 top-level categories render and are accessible', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Switch to Quick Select tab
      await tester.tap(find.text('Quick Select'));
      await tester.pumpAndSettle();

      // All 10 categories must be present in the UI
      expect(find.text('Pain'), findsOneWidget);
      expect(find.text('Fever / Infection'), findsOneWidget);
      expect(find.text('Breathing'), findsOneWidget);
      expect(find.text('Stomach / Digestion'), findsOneWidget);
      expect(find.text('Head / Neurological'), findsOneWidget);
      expect(find.text('Skin / Allergy'), findsOneWidget);
      expect(find.text('Injury'), findsOneWidget);
      expect(find.text('Urinary'), findsOneWidget);
      expect(find.text("Women's / Pregnancy-related"), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });
  });
}

