import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/presentation/cubits/settings_cubit.dart';
import 'package:input_vpn/presentation/cubits/vpn_cubit.dart';
import 'package:input_vpn/presentation/cubits/config_cubit.dart';
import 'package:input_vpn/presentation/cubits/network_info_cubit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:input_vpn/services/vpn/windows/network_utils.dart';
import 'package:input_vpn/services/app_logger.dart';
import 'package:input_vpn/services/vpn/windows/singbox_service_manager.dart';
import 'package:input_vpn/core/di.dart';
import 'package:input_vpn/globals/router.dart';
import 'package:input_vpn/globals/shared_prefs.dart';
import 'package:input_vpn/globals/themes.dart';
import 'package:input_vpn/l10n/app_strings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();
  configureDependencies(sharedPrefs);
  await AppLogger.init();

  // Cleanup any orphaned sing-box processes from previous runs
  if (Platform.isWindows) {
    await _cleanupSingBoxProcesses();
    // Check for and clean up unhealthy TUN adapters from previous crashes
    await NetworkUtils.cleanupIfUnhealthy();
    // Sync the serviceMode flag with reality (task may have been removed).
    await _syncServiceModeFlag();
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

  // Best-effort cleanup on Ctrl+C / terminal kill / app termination.
  if (Platform.isWindows) {
    ProcessSignal.sigint.watch().listen((_) async {
      await _cleanupSingBoxProcesses();
      await NetworkUtils.globalCleanup();
      exit(0);
    });
    ProcessSignal.sigterm.watch().listen((_) async {
      await _cleanupSingBoxProcesses();
      await NetworkUtils.globalCleanup();
      exit(0);
    });
  }

  runApp(const MyApp());
}

/// Sync the serviceMode preference with the actual task status.
/// The task is installed by the Inno Setup installer; we only verify here.
Future<void> _syncServiceModeFlag() async {
  try {
    final installed = await SingboxServiceManager.isInstalled();
    final currentFlag = sharedPrefs.getBool('serviceMode') ?? false;
    if (installed != currentFlag) {
      await sharedPrefs.setBool('serviceMode', installed);
      if (installed) {
        AppLogger.info('ServiceManager: task found — service mode enabled');
      } else {
        AppLogger.warn('ServiceManager: task missing — service mode disabled');
      }
    }
  } catch (e) {
    AppLogger.error('ServiceManager: _syncServiceModeFlag error: $e');
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<SettingsCubit>()),
        BlocProvider(create: (context) => getIt<VpnCubit>()),
        BlocProvider(create: (context) => getIt<ConfigCubit>()),
        BlocProvider(create: (context) => getIt<NetworkInfoCubit>()),
      ],
      child: Builder(
        builder: (context) => MaterialApp.router(
          theme: context.watch<SettingsCubit>().state.themeMode == ThemeMode.dark ? darkTheme : lightTheme,
          locale: context.watch<SettingsCubit>().state.locale,
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
      ),
    );
  }
}
