import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:input_vpn/data/local/prefs_data_source.dart';
import 'package:input_vpn/data/remote/ip_lookup_api.dart';
import 'package:input_vpn/data/remote/subscription_api.dart';
import 'package:input_vpn/data/repositories/config_repository_impl.dart';
import 'package:input_vpn/data/repositories/network_info_repository_impl.dart';
import 'package:input_vpn/data/repositories/settings_repository_impl.dart';
import 'package:input_vpn/data/repositories/vpn_repository_impl.dart';
import 'package:input_vpn/domain/repositories/config_repository.dart';
import 'package:input_vpn/domain/repositories/network_info_repository.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';
import 'package:input_vpn/domain/repositories/vpn_repository.dart';
import 'package:input_vpn/domain/usecases/add_config.dart';
import 'package:input_vpn/domain/usecases/refresh_network_info.dart';
import 'package:input_vpn/domain/usecases/refresh_subscription_stats.dart';
import 'package:input_vpn/domain/usecases/remove_config.dart';
import 'package:input_vpn/domain/usecases/toggle_vpn_connection.dart';
import 'package:input_vpn/domain/usecases/update_config.dart';
import 'package:input_vpn/presentation/cubits/config_cubit.dart';
import 'package:input_vpn/presentation/cubits/network_info_cubit.dart';
import 'package:input_vpn/presentation/cubits/settings_cubit.dart';
import 'package:input_vpn/presentation/cubits/vpn_cubit.dart';
import 'package:input_vpn/services/dio_factory.dart';
import 'package:input_vpn/services/singbox_vpn_service.dart';
import 'package:input_vpn/services/subscription_service.dart';
import 'package:input_vpn/services/vpn_service.dart';

final GetIt getIt = GetIt.instance;

VpnService _defaultVpnBackend() {
  if (!kIsWeb && Platform.isWindows && SingBoxVpnService.isSupported) {
    final proxy = prefs.getBool('proxyMode') ?? false;
    final service = prefs.getBool('serviceMode') ?? false;
    return SingBoxVpnService(proxyMode: proxy, serviceMode: service);
  }
  return MockVpnService();
}

late SharedPreferences prefs;

/// Register all singletons and factories.
/// Must be called after [SharedPreferences.getInstance()] in [main()].
void configureDependencies(SharedPreferences sharedPreferences) {
  prefs = sharedPreferences;
  getIt
    // External
    ..registerSingleton<SharedPreferences>(sharedPreferences)
    // Data sources
    ..registerSingleton<PrefsDataSource>(
      PrefsDataSource(sharedPreferences),
    )
    // Remote APIs
    ..registerLazySingleton<SubscriptionApi>(
      () => SubscriptionApi(dio: DioFactory.forSubscriptions()),
    )
    ..registerLazySingleton<IpLookupApi>(
      () => IpLookupApi(dio: Dio()),
    )
    // Services
    ..registerLazySingleton<SubscriptionService>(
      () => SubscriptionService(),
    )
    ..registerLazySingleton<VpnService>(
      () => _defaultVpnBackend(),
    )
    // Repositories
    ..registerLazySingleton<VpnRepository>(
      () => VpnRepositoryImpl(vpnService: getIt<VpnService>()),
    )
    ..registerLazySingleton<ConfigRepository>(
      () => ConfigRepositoryImpl(
        subscriptionService: getIt<SubscriptionService>(),
      ),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(prefs: getIt<PrefsDataSource>()),
    )
    ..registerLazySingleton<NetworkInfoRepository>(
      () => NetworkInfoRepositoryImpl(),
    )
    // Use cases
    ..registerFactory<ToggleVpnConnection>(
      () => ToggleVpnConnection(getIt<VpnRepository>()),
    )
    ..registerFactory<AddConfig>(
      () => AddConfig(getIt<ConfigRepository>()),
    )
    ..registerFactory<RemoveConfig>(
      () => RemoveConfig(getIt<ConfigRepository>()),
    )
    ..registerFactory<UpdateConfig>(
      () => UpdateConfig(getIt<ConfigRepository>()),
    )
    ..registerFactory<RefreshSubscriptionStats>(
      () => RefreshSubscriptionStats(getIt<ConfigRepository>()),
    )
    ..registerFactory<RefreshNetworkInfo>(
      () => RefreshNetworkInfo(getIt<NetworkInfoRepository>()),
    )
    // Cubits
    ..registerFactory<VpnCubit>(
      () => VpnCubit(
        vpnRepository: getIt<VpnRepository>(),
        toggleVpnConnection: getIt<ToggleVpnConnection>(),
      ),
    )
    ..registerFactory<ConfigCubit>(
      () => ConfigCubit(
        configRepository: getIt<ConfigRepository>(),
        addConfig: getIt<AddConfig>(),
        removeConfig: getIt<RemoveConfig>(),
        updateConfig: getIt<UpdateConfig>(),
        refreshSubscriptionStats: getIt<RefreshSubscriptionStats>(),
      ),
    )
    ..registerFactory<SettingsCubit>(
      () => SettingsCubit(
        settingsRepository: getIt<SettingsRepository>(),
      ),
    )
    ..registerFactory<NetworkInfoCubit>(
      () => NetworkInfoCubit(
        networkInfoRepository: getIt<NetworkInfoRepository>(),
        refreshNetworkInfo: getIt<RefreshNetworkInfo>(),
      ),
    );
}
