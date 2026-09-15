import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isTamil => locale.languageCode == 'ta';
  bool get isHindi => locale.languageCode == 'hi';

  // ------------------------------------------------------------
  // Brand
  // ------------------------------------------------------------

  String get appName => 'Agaram Care';

  String get tagline => switch (locale.languageCode) {
        'ta' => 'சரியான நேரத்தில் சரியான சிகிச்சை',
        'hi' => 'सही समय पर सही देखभाल',
        _ => 'Right Care at the Right Time',
      };

  // ------------------------------------------------------------
  // Language
  // ------------------------------------------------------------

  String get chooseLanguage => switch (locale.languageCode) {
        'ta' => 'உங்கள் மொழியைத் தேர்வு செய்யவும்',
        'hi' => 'अपनी भाषा चुनें',
        _ => 'Choose your language',
      };

  String get continueText => switch (locale.languageCode) {
        'ta' => 'தொடரவும்',
        'hi' => 'जारी रखें',
        _ => 'Continue',
      };

  // ------------------------------------------------------------
  // Role Selection
  // ------------------------------------------------------------

  String get chooseRole => switch (locale.languageCode) {
        'ta' => 'உங்களைப் பற்றித் தெரிவிக்கவும்',
        'hi' => 'अपनी भूमिका चुनें',
        _ => 'Tell us how you will use Agaram Care',
      };

  String get patient => switch (locale.languageCode) {
        'ta' => 'நோயாளர்',
        'hi' => 'मरीज़',
        _ => 'Patient',
      };

  String get patientDescription => switch (locale.languageCode) {
        'ta' => 'உங்கள் உடல்நலம் மற்றும் சிகிச்சையை நிர்வகிக்க',
        'hi' => 'अपनी देखभाल और स्वास्थ्य यात्रा के लिए',
        _ => 'Manage your care and health journey',
      };

  String get vhn => switch (locale.languageCode) {
        'ta' => 'சுகாதார பணியாளர்',
        'hi' => 'स्वास्थ्य कार्यकर्ता',
        _ => 'Health Worker',
      };

  String get vhnDescription => switch (locale.languageCode) {
        'ta' => 'சமூகத்தில் நோயாளிகளுக்கு உதவ',
        'hi' => 'समुदाय में मरीजों की सहायता के लिए',
        _ => 'Assist patients in the community',
      };

  String get doctor => switch (locale.languageCode) {
        'ta' => 'மருத்துவர்',
        'hi' => 'डॉक्टर',
        _ => 'Doctor',
      };

  String get doctorDescription => switch (locale.languageCode) {
        'ta' => 'ஆலோசனை மற்றும் தொடர்ச்சியான சிகிச்சைக்காக',
        'hi' => 'परामर्श और देखभाल प्रबंधन के लिए',
        _ => 'For consultations and care management',
      };

  // ------------------------------------------------------------
  // Login
  // ------------------------------------------------------------

  String get login => switch (locale.languageCode) {
        'ta' => 'உள்நுழைவு',
        'hi' => 'लॉग इन',
        _ => 'Sign in',
      };

  String get phoneNumber => switch (locale.languageCode) {
        'ta' => 'தொலைபேசி எண்',
        'hi' => 'फ़ोन नंबर',
        _ => 'Phone number',
      };

  String get password => switch (locale.languageCode) {
        'ta' => 'கடவுச்சொல்',
        'hi' => 'पासवर्ड',
        _ => 'Password',
      };

  String get loginDescription => switch (locale.languageCode) {
        'ta' => 'தொடர உங்கள் கணக்கில் உள்நுழையவும்',
        'hi' => 'जारी रखने के लिए अपने खाते में लॉग इन करें',
        _ => 'Sign in to continue to your care',
      };

  String get demoNotice => switch (locale.languageCode) {
        'ta' => 'இது தற்போது முன்மாதிரி உள்நுழைவு.',
        'hi' => 'यह अभी प्रोटोटाइप लॉगिन है।',
        _ => 'This is a prototype login for now.',
      };

  // ------------------------------------------------------------
  // Patient Dashboard
  // ------------------------------------------------------------

  String get patientHomeSubtitle => switch (locale.languageCode) {
        'ta' => 'உங்கள் சிகிச்சையில் அடுத்த கட்டம், இலகுவாக.',
        'hi' => 'आपकी देखभाल का अगला कदम, अब और आसान।',
        _ => 'Your next step in care, made simpler.',
      };

  String get talkToAgaramCare => switch (locale.languageCode) {
        'ta' => 'Agaram Care-ஐ அணுகுங்கள்',
        'hi' => 'Agaram Care से बात करें',
        _ => 'Talk to Agaram Care',
      };

  String get voiceCtaSubtitle => switch (locale.languageCode) {
        'ta' => 'தமிழில் பேசுங்கள்',
        'hi' => 'हिंदी में बोलें',
        _ => 'Speak in English',
      };

  String get whatDoYouNeed => switch (locale.languageCode) {
        'ta' => 'உங்களுக்கு என்ன தேவை?',
        'hi' => 'आपको क्या चाहिए?',
        _ => 'What do you need?',
      };

  String get checkMyHealth => switch (locale.languageCode) {
        'ta' => 'என் உடல்நலத்தைப் பார்க்க',
        'hi' => 'अपनी सेहत जांचें',
        _ => 'Check My Health',
      };

  String get checkMyHealthDescription => switch (locale.languageCode) {
        'ta' => 'உங்கள் அறிகுறிகளைப் புரிந்துகொள்ளுங்கள்',
        'hi' => 'अपने लक्षणों को समझें',
        _ => 'Understand your symptoms',
      };

  String get consultDoctor => switch (locale.languageCode) {
        'ta' => 'மருத்துவரை அணுகுங்கள்',
        'hi' => 'डॉक्टर से सलाह लें',
        _ => 'Consult Doctor',
      };

  String get consultDoctorDescription => switch (locale.languageCode) {
        'ta' => 'சிகிச்சையுடன் இணைக்கப்படுங்கள்',
        'hi' => 'सही सहायता से जुड़ें',
        _ => 'Get connected to care',
      };

  String get findHealthcare => switch (locale.languageCode) {
        'ta' => 'சுகாதார சேவையைத் தேடுங்கள்',
        'hi' => 'स्वास्थ्य सेवा खोजें',
        _ => 'Find Healthcare',
      };

  String get findHealthcareDescription => switch (locale.languageCode) {
        'ta' => 'அரசு மற்றும் தனியார் மருத்துவ நிலையங்கள்',
        'hi' => 'सरकारी और निजी अस्पताल',
        _ => 'Government & private facilities',
      };

  String get myReferrals => switch (locale.languageCode) {
        'ta' => 'எனது பரிந்துரைகள்',
        'hi' => 'मेरे रेफरल',
        _ => 'My Referrals',
      };

  String get myReferralsDescription => switch (locale.languageCode) {
        'ta' => 'உங்கள் சிகிச்சைப் பயணத்தைப் பின்தொடருங்கள்',
        'hi' => 'अपनी देखभाल यात्रा को ट्रैक करें',
        _ => 'Track your care journey',
      };

  String get continueYourCare => switch (locale.languageCode) {
        'ta' => 'உங்கள் சிகிச்சையைத் தொடருங்கள்',
        'hi' => 'अपनी देखभाल जारी रखें',
        _ => 'Continue your care',
      };

  String get noPendingFollowUps => switch (locale.languageCode) {
        'ta' => 'நிலுவையில் தொடர்ச்சிச் சிகிச்சைகள் இல்லை',
        'hi' => 'फ़िलहाल कोई फॉलो-अप लंबित नहीं है',
        _ => 'No pending follow-ups',
      };

  String get activeCareTasksPlaceholder => switch (locale.languageCode) {
        'ta' => 'உங்கள் செயலில் உள்ள சிகிச்சைப் பணிகள் இங்கே தோன்றும்.',
        'hi' => 'आपके चल रहे देखभाल कार्य यहाँ दिखाई देंगे।',
        _ => 'Your active care tasks will appear here.',
      };

  // ------------------------------------------------------------
  // Navigation
  // ------------------------------------------------------------

  String get navHome => switch (locale.languageCode) {
        'ta' => 'முகப்பு',
        'hi' => 'होम',
        _ => 'Home',
      };

  String get navCare => switch (locale.languageCode) {
        'ta' => 'சிகிச்சை',
        'hi' => 'देखभाल',
        _ => 'Care',
      };

  String get navProfile => switch (locale.languageCode) {
        'ta' => 'சுயவிவரம்',
        'hi' => 'प्रोफ़ाइल',
        _ => 'Profile',
      };

  String get notifications => switch (locale.languageCode) {
        'ta' => 'அறிவிப்புகள்',
        'hi' => 'सूचनाएं',
        _ => 'Notifications',
      };

  // ------------------------------------------------------------
  // Exit Dialog
  // ------------------------------------------------------------

  String get exitDialogTitle => switch (locale.languageCode) {
        'ta' => 'செயலியிலிருந்து வெளியேறவா?',
        'hi' => 'ऐप से बाहर निकलें?',
        _ => 'Exit Application',
      };

  String get exitDialogMessage => switch (locale.languageCode) {
        'ta' => 'நீங்கள் Agaram Care செயலியில் இருந்து வெளியேற விரும்புகிறீர்களா?',
        'hi' => 'क्या आप वाकई Agaram Care से बाहर निकलना चाहते हैं?',
        _ => 'Are you sure you want to exit Agaram Care?',
      };

  String get cancel => switch (locale.languageCode) {
        'ta' => 'ரத்து செய்',
        'hi' => 'रद्द करें',
        _ => 'Cancel',
      };

  String get exit => switch (locale.languageCode) {
        'ta' => 'வெளியேறு',
        'hi' => 'बाहर निकलें',
        _ => 'Exit',
      };

  // ------------------------------------------------------------
  // Temporary Feature Screens
  // ------------------------------------------------------------

  String get featureComingSoon => switch (locale.languageCode) {
        'ta' => 'இந்த அம்சம் அடுத்த கட்டத்தில் வரும்',
        'hi' => 'यह सुविधा अगले चरण में आएगी',
        _ => 'This feature is coming next',
      };

  String get featureComingSoonDescription => switch (locale.languageCode) {
        'ta' =>
          'Agaram Care-இன் இந்த பகுதி அடுத்த கட்ட வளர்ச்சியில் செயல்படுத்தப்படும்.',
        'hi' =>
          'Agaram Care का यह भाग अगले विकास चरण में जोड़ा जाएगा।',
        _ =>
          'This part of Agaram Care will be implemented in the next development task.',
      };
}