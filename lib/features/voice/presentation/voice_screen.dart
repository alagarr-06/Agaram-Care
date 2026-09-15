import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../app/app_state.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _speechAvailable = false;
  bool _isListening = false;
  bool _isSpeaking = false;

  String _recognizedText = '';
  String _responseText = '';
  String? _selectedLocaleId;

  @override
  void initState() {
    super.initState();
    _initializeVoice();
  }

  Future<void> _initializeVoice() async {
    try {
      final available = await _speech.initialize(
        onStatus: _onSpeechStatus,
        onError: (error) {
          if (!mounted) return;

          setState(() {
            _isListening = false;
          });

          _showMessage(error.errorMsg);
        },
        options: <SpeechConfigOption>[
          SpeechToText.androidNoBluetooth,
        ],
      );

      await _tts.awaitSpeakCompletion(true);
      await _tts.setSpeechRate(0.48);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      if (!mounted) return;

      setState(() {
        _speechAvailable = available;
      });

      await _prepareLocale();
      await _debugSpeechLocales();
    } catch (error) {
      debugPrint('Voice initialization error: $error');

      if (!mounted) return;

      setState(() {
        _speechAvailable = false;
      });
    }
  }

  void _onSpeechStatus(String status) {
    if (!mounted) return;

    setState(() {
      _isListening = status == SpeechToText.listeningStatus;
    });

    debugPrint('Speech status: $status');
  }

  Future<void> _prepareLocale() async {
    if (!_speechAvailable) {
      return;
    }

    try {
      final availableLocales = await _speech.locales();

      final languageCode =
          ref.read(selectedLocaleProvider).languageCode;

      LocaleName? matchedLocale;

      for (final locale in availableLocales) {
        final localeId = locale.localeId.toLowerCase();

        if (languageCode == 'ta' && localeId.startsWith('ta')) {
          matchedLocale = locale;
          break;
        }

        if (languageCode == 'hi' && localeId.startsWith('hi')) {
          matchedLocale = locale;
          break;
        }

        if (languageCode == 'en' && localeId.startsWith('en')) {
          // Prefer Indian English when available.
          if (localeId == 'en_in' || localeId == 'en-in') {
            matchedLocale = locale;
            break;
          }

          matchedLocale ??= locale;
        }
      }

      debugPrint(
        'Requested app language: $languageCode',
      );

      debugPrint(
        'Selected speech locale: '
        '${matchedLocale?.localeId ?? 'NONE'}',
      );

      if (!mounted) return;

      setState(() {
        _selectedLocaleId = matchedLocale?.localeId;
      });
    } catch (error) {
      debugPrint('Speech locale error: $error');

      if (!mounted) return;

      setState(() {
        _selectedLocaleId = null;
      });
    }
  }

  Future<void> _debugSpeechLocales() async {
    try {
      final locales = await _speech.locales();

      debugPrint('========================================');
      debugPrint('AVAILABLE SPEECH LOCALES');
      debugPrint('========================================');

      for (final locale in locales) {
        debugPrint(
          'ID: ${locale.localeId} | NAME: ${locale.name}',
        );
      }

      debugPrint('========================================');
      debugPrint('CURRENT SELECTED LOCALE');
      debugPrint(
        _selectedLocaleId ?? 'NONE',
      );
      debugPrint('========================================');
    } catch (error) {
      debugPrint(
        'Could not read speech locales: $error',
      );
    }
  }

  Future<void> _startListening() async {
    if (!_speechAvailable) {
      _showMessage(_notAvailableMessage());
      return;
    }

    if (_isListening) {
      await _stopListening();
      return;
    }

    if (_selectedLocaleId == null) {
      _showMessage(_speechLanguageUnavailableMessage());
      return;
    }

    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _recognizedText = '';
      _responseText = '';
      _isSpeaking = false;
    });

    try {
      final listenOptions = SpeechListenOptions(
        cancelOnError: false,
        partialResults: true,
        onDevice: false,
        listenMode: ListenMode.confirmation,
        sampleRate: 0,
        autoPunctuation: true,
        enableHapticFeedback: false,
        localeId: _selectedLocaleId,
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 4),
      );

      debugPrint(
        'Starting speech recognition with locale: $_selectedLocaleId',
      );

      await _speech.listen(
        onResult: _onSpeechResult,
        listenOptions: listenOptions,
      );
    } catch (error) {
      debugPrint('Speech start error: $error');

      if (!mounted) return;

      setState(() {
        _isListening = false;
      });

      _showMessage(_notAvailableMessage());
    }
  }

  Future<void> _stopListening() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (_recognizedText.trim().isNotEmpty) {
      await _generateDemoResponse();
    }
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    if (!mounted) return;

    setState(() {
      _recognizedText = result.recognizedWords;
    });

    debugPrint(
      'Speech result: ${result.recognizedWords}',
    );

    if (result.finalResult) {
      _finishRecognition();
    }
  }

  Future<void> _finishRecognition() async {
    await _speech.stop();

    if (!mounted) return;

    setState(() {
      _isListening = false;
    });

    if (_recognizedText.trim().isNotEmpty) {
      await _generateDemoResponse();
    }
  }

  Future<void> _generateDemoResponse() async {
    final language =
        ref.read(selectedLocaleProvider).languageCode;

    final response = switch (language) {
      'ta' =>
        'உங்கள் உடல்நலக் கவலை எனக்குப் புரிகிறது. அடுத்ததாக சில கேள்விகளைக் கேட்டு, உங்களுக்கு சரியான அடுத்த கட்டத்தைத் தேர்வு செய்ய உதவுகிறேன்.',
      'hi' =>
        'मैं आपकी स्वास्थ्य चिंता समझ गया हूँ। अब मैं कुछ सवाल पूछकर आपके लिए अगला सही कदम चुनने में मदद करूंगा।',
      _ =>
        'I understand your health concern. Next, I will ask a few questions to help identify the right next step for your care.',
    };

    if (!mounted) return;

    setState(() {
      _responseText = response;
    });

    await _speak(response);
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.stop();

      final language =
          ref.read(selectedLocaleProvider).languageCode;

      final ttsLocale = switch (language) {
        'ta' => 'ta-IN',
        'hi' => 'hi-IN',
        _ => 'en-IN',
      };

      await _tts.setLanguage(ttsLocale);

      if (!mounted) return;

      setState(() {
        _isSpeaking = true;
      });

      await _tts.speak(text);

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });
    } catch (error) {
      debugPrint('TTS error: $error');

      if (!mounted) return;

      setState(() {
        _isSpeaking = false;
      });

      _showMessage(_ttsUnavailableMessage());
    }
  }

  Future<void> _stopSpeaking() async {
    await _tts.stop();

    if (!mounted) return;

    setState(() {
      _isSpeaking = false;
    });
  }

  String _notAvailableMessage() {
    final language =
        ref.read(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' =>
        'குரல் சேவை தற்போது கிடைக்கவில்லை. உங்கள் சாதனத்தின் குரல் அணுகலைச் சரிபார்க்கவும்.',
      'hi' =>
        'वॉइस सेवा अभी उपलब्ध नहीं है। अपने डिवाइस की वॉइस सेटिंग जांचें।',
      _ =>
        'Voice service is not available right now. Please check your device speech settings.',
    };
  }

  String _speechLanguageUnavailableMessage() {
    final language =
        ref.read(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' =>
        'இந்த சாதனத்தில் தமிழ் குரல் அங்கீகாரம் கிடைக்கவில்லை. சாதனத்தின் பேச்சு மொழிகளில் தமிழைச் சேர்க்கவும்.',
      'hi' =>
        'इस डिवाइस पर हिंदी भाषण पहचान उपलब्ध नहीं है। डिवाइस की स्पीच भाषाओं में हिंदी जोड़ें।',
      _ =>
        'The selected speech recognition language is not available on this device.',
    };
  }

  String _ttsUnavailableMessage() {
    final language =
        ref.read(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'குரல் பதில் வழங்க முடியவில்லை.',
      'hi' => 'वॉइस प्रतिक्रिया उपलब्ध नहीं है।',
      _ => 'Voice response is not available right now.',
    };
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _title() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'Agaram Care-ஐ அணுகுங்கள்',
      'hi' => 'Agaram Care से बात करें',
      _ => 'Talk to Agaram Care',
    };
  }

  String _subtitle() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'உங்கள் உடல்நலத்தைப் பற்றி பேசுங்கள்',
      'hi' => 'अपनी स्वास्थ्य चिंता के बारे में बोलें',
      _ => 'Tell me what is bothering you',
    };
  }

  String _listeningText() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'கேட்கிறேன்...',
      'hi' => 'सुन रहा हूँ...',
      _ => 'Listening...',
    };
  }

  String _tapToSpeakText() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'பேச மைக்கைத் தட்டவும்',
      'hi' => 'बोलने के लिए माइक्रोफ़ोन दबाएं',
      _ => 'Tap the microphone and speak',
    };
  }

  String _yourWordsText() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'நீங்கள் கூறியது',
      'hi' => 'आपने कहा',
      _ => 'You said',
    };
  }

  String _responseTextTitle() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'Agaram Care பதில்',
      'hi' => 'Agaram Care का जवाब',
      _ => 'Agaram Care response',
    };
  }

  String _stopText() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' => 'நிறுத்தவும்',
      'hi' => 'रोकें',
      _ => 'Stop',
    };
  }

  String _safetyText() {
    final language =
        ref.watch(selectedLocaleProvider).languageCode;

    return switch (language) {
      'ta' =>
        'Agaram Care ஒரு மருத்துவ வழிகாட்டல் தளம். இது தனியாக நோயறிதல் அல்லது மருந்து பரிந்துரை வழங்காது.',
      'hi' =>
        'Agaram Care एक स्वास्थ्य मार्गदर्शन प्लेटफ़ॉर्म है। यह अपने आप बीमारी का निदान या दवा नहीं बताता।',
      _ =>
        'Agaram Care is a healthcare navigation platform. It does not independently diagnose conditions or prescribe medicines.',
    };
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agaram Care'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Column(
            children: [
              const SizedBox(height: 12),

              Text(
                _title(),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                _subtitle(),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 36),

              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: _isListening ? 190 : 170,
                height: _isListening ? 190 : 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isListening
                      ? colorScheme.primary
                      : colorScheme.primaryContainer,
                  boxShadow: _isListening
                      ? [
                          BoxShadow(
                            color: colorScheme.primary.withValues(
                              alpha: 0.28,
                            ),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ]
                      : null,
                ),
                child: IconButton(
                  onPressed: _startListening,
                  iconSize: _isListening ? 72 : 64,
                  icon: Icon(
                    _isListening
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded,
                    color: _isListening
                        ? colorScheme.onPrimary
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _isListening
                    ? _listeningText()
                    : _tapToSpeakText(),
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

              if (!_speechAvailable) ...[
                const SizedBox(height: 10),
                Text(
                  _notAvailableMessage(),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.error,
                  ),
                ),
              ],

              const SizedBox(height: 28),

              if (_recognizedText.trim().isNotEmpty)
                _VoiceTextCard(
                  title: _yourWordsText(),
                  text: _recognizedText,
                  icon: Icons.record_voice_over_outlined,
                ),

              if (_recognizedText.trim().isNotEmpty)
                const SizedBox(height: 16),

              if (_responseText.trim().isNotEmpty)
                _VoiceTextCard(
                  title: _responseTextTitle(),
                  text: _responseText,
                  icon: Icons.health_and_safety_outlined,
                  trailing: _isSpeaking
                      ? IconButton(
                          onPressed: _stopSpeaking,
                          tooltip: _stopText(),
                          icon: const Icon(
                            Icons.stop_circle_outlined,
                          ),
                        )
                      : null,
                ),

              const SizedBox(height: 24),

              Card(
                elevation: 0,
                color: colorScheme.surfaceContainerLow,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _safetyText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceTextCard extends StatelessWidget {
  const _VoiceTextCard({
    required this.title,
    required this.text,
    required this.icon,
    this.trailing,
  });

  final String title;
  final String text;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    text,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            ?trailing,
          ],
        ),
      ),
    );
  }
}