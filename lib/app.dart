import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/providers/auth_notifier.dart';
import 'features/auth/screens/auth_screen.dart';
import 'navigation/app_router.dart';

/// Root widget for Boulder Board 112 app.
class BoulderBoardApp extends ConsumerWidget {
  const BoulderBoardApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return MaterialApp(
      title: 'Boulder Board 112',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: authState.isAuthenticated ? const AppRouter() : const AuthScreen(),
    );
  }
}
