import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'features/security/domain/pin_lock_provider.dart';
import 'features/security/presentation/pin_lock_screen.dart';
import 'features/settings/presentation/settings_screen.dart';

class CatatUangApp extends ConsumerWidget {
  const CatatUangApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(darkModeProvider);
    final pinState = ref.watch(pinLockProvider);

    return MaterialApp.router(
      title: 'Catat Uang Pribadi',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        if (pinState.isLoaded && pinState.hasPin && !pinState.isUnlocked) {
          return const PinLockScreen();
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
