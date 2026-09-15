import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/language_selection_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/role_selection_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/patient/presentation/patient_home_screen.dart';
import '../features/facilities/domain/facilities.dart';
import '../features/facilities/presentation/facilities_screen.dart';
import '../features/referrals/presentation/referrals_screen.dart';
import '../features/triage/presentation/triage_screen.dart';
import '../features/voice/presentation/voice_screen.dart';
import '../shared/widgets/feature_placeholder_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),

    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),

    GoRoute(
      path: '/role',
      builder: (context, state) => const RoleSelectionScreen(),
    ),

    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),

    GoRoute(
      path: '/patient',
      builder: (context, state) => const PatientHomeScreen(),
    ),

    // ============================================================
    // REAL VOICE ASSISTANT
    // ============================================================
    GoRoute(
      path: '/voice',
      builder: (context, state) => const VoiceScreen(),
    ),

    // ============================================================
    // Temporary feature screens
    // These will be replaced as we implement each feature.
    // ============================================================
    GoRoute(
      path: '/triage',
      builder: (context, state) => const TriageScreen(),
    ),

    GoRoute(
      path: '/consultation',
      builder: (context, state) => const FeaturePlaceholderScreen(
        icon: Icons.video_call_outlined,
      ),
    ),

    GoRoute(
      path: '/facilities',
      builder: (context, state) {
        final careRequest = state.extra is PatientCareRequest
            ? state.extra as PatientCareRequest
            : null;
        return FacilitiesScreen(initialCareRequest: careRequest);
      },
    ),

    // ============================================================
    // REAL REFERRALS SCREEN
    // ============================================================
    GoRoute(
      path: '/referrals',
      builder: (context, state) => const ReferralsScreen(),
    ),

    GoRoute(
      path: '/followup',
      builder: (context, state) => const FeaturePlaceholderScreen(
        icon: Icons.event_note_outlined,
      ),
    ),
  ],
);