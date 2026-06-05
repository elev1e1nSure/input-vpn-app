import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:input_vpn/controllers/settings_controller.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/data/remote/ip_lookup_api.dart';
import 'package:input_vpn/data/remote/subscription_api.dart';
import 'package:input_vpn/services/dio_factory.dart';

final GetIt getIt = GetIt.instance;

/// Register all singletons and factories.
/// Must be called after [SharedPreferences.getInstance()] in [main()].
void configureDependencies(SharedPreferences prefs) {
  getIt
    // External
    ..registerSingleton<SharedPreferences>(prefs)
    // Data sources
    ..registerSingleton<PrefsDataSource>(
      PrefsDataSource(prefs),
    )
    // Controllers
    ..registerSingleton<SettingsController>(
      SettingsController(prefs: PrefsDataSource(prefs)),
    )
    // Remote APIs
    ..registerLazySingleton<SubscriptionApi>(
      () => SubscriptionApi(dio: DioFactory.forSubscriptions()),
    )
    ..registerLazySingleton<IpLookupApi>(
      () => IpLookupApi(dio: Dio()),
    );
}
