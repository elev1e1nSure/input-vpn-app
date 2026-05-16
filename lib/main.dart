import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/singbox_service_manager.dart';
import 'package:input_vpn/globals/router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:input_vpn/globals/shared_prefs.dart';
import 'package:input_vpn/l10n/app_strings.dart';

@NowaGenerated()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  await AppLogger.init();

  // Cleanup any orphaned sing-box processes from previous runs
  if (Platform.isWindows) {
    await _cleanupSingBoxProcesses();
    // Install sing-box as a Windows Service on first launch (one UAC prompt).
    // After that, connections require no elevation at all.
    unawaited(_ensureServiceInstalled());
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

/// Installs sing-box as a Windows Service on first launch.
/// Runs silently in the background — one UAC prompt then never again.
Future<void> _ensureServiceInstalled() async {
  try {
    final alreadyInstalled = await SingboxServiceManager.isInstalled();
    if (alreadyInstalled) {
      // Already installed — make sure serviceMode flag matches reality.
      if (!(sharedPrefs.getBool('serviceMode') ?? false)) {
        await sharedPrefs.setBool('serviceMode', true);
      }
      AppLogger.info('ServiceManager: service already installed, skipping');
      return;
    }

    // Service not installed but flag says it is — reset flag so app uses
    // legacy elevated mode and doesn't throw on connect.
    if (sharedPrefs.getBool('serviceMode') ?? false) {
      await sharedPrefs.setBool('serviceMode', false);
      AppLogger.warn('ServiceManager: flag was true but service missing — reset to false');
    }

    AppLogger.info('ServiceManager: first launch — installing service');
    final exe = '${File(Platform.resolvedExecutable).parent.path}\\sing-box.exe';
    final base = await getApplicationSupportDirectory();
    final configPath = p.join(base.path, 'singbox', 'config.json');

    final ok = await SingboxServiceManager.install(exe, configPath);
    if (ok) {
      // Double-check: sc query must confirm the service actually exists.
      final verified = await SingboxServiceManager.isInstalled();
      if (verified) {
        await sharedPrefs.setBool('serviceMode', true);
        AppLogger.info('ServiceManager: installed and verified — service mode enabled');
      } else {
        AppLogger.error('ServiceManager: install() returned true but sc query '
            'failed — service mode NOT enabled (UAC may have been denied)');
      }
    } else {
      AppLogger.warn('ServiceManager: installation failed — falling back to UAC mode');
    }
  } catch (e) {
    AppLogger.error('ServiceManager: _ensureServiceInstalled error: $e');
  }
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
