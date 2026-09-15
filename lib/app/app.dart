import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_state.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class AgaramCareApp extends ConsumerWidget {
  const AgaramCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(selectedLocaleProvider);

    return MaterialApp.router(
      title: 'Agaram Care',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      locale: locale,
      routerConfig: appRouter,
    );
  }
}
