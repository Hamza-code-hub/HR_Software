import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme_provider.dart';
import 'core/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: HRSaasApp(),
    ),
  );
}

class HRSaasApp extends ConsumerWidget {
  const HRSaasApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router    = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'HR & Accounting — CyberZeus',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme:      buildLightTheme(),
      darkTheme:  buildDarkTheme(),
      routerConfig: router,
    );
  }
}
