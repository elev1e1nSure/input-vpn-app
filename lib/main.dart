import 'package:shared_preferences/shared_preferences.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/globals/router.dart';
import 'package:vpn/globals/shared_prefs.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  sharedPrefs = await SharedPreferences.getInstance();

  runApp(const MyApp());
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
