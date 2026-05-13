import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/globals/router.dart';
import 'package:vpn/globals/shared_prefs.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();

  // Cleanup any orphaned sing-box processes from previous runs
  if (Platform.isWindows) {
    await _cleanupSingBoxProcesses();
  }

  if (!kIsWeb && Platform.isWindows) {
    try {
      await windowManager.ensureInitialized();
      await windowManager.setPreventClose(true);
    } catch (e) {
      // Plugin unavailable during hot restart or unsupported platform.
      debugPrint('Window init failed: $e');
    }
  }

  runApp(const MyApp());
}

/// Kill any orphaned sing-box.exe processes to clean up TUN adapters.
Future<void> _cleanupSingBoxProcesses() async {
  try {
    await Process.run('taskkill', ['/IM', 'sing-box.exe', '/F']);
    debugPrint('Cleaned up orphaned sing-box processes');
  } catch (_) {
    // No sing-box processes running or taskkill failed - that's OK
  }
}

@NowaGenerated({'visibleInNowa': false})
class MyApp extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppState>(create: (context) => AppState()),
      ],
      builder: (context, child) => MaterialApp.router(
        theme: AppState.of(context).theme,
        locale: AppState.of(context).locale,
        localizationsDelegates: const [
          AppStringsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ru'),
        ],
        builder: (context, child) {
          // Ensure AppStrings is loaded before the router builds pages.
          // Fallback to English during the first frame if needed.
          final _ = AppStrings.of(context);
          return child!;
        },
        routerConfig: appRouter,
      ),
    );
  }
}
