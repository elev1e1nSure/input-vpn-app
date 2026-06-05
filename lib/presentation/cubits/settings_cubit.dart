import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';
import 'package:input_vpn/domain/entities/dns_profile.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/presentation/cubits/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    _load();
  }

  final SettingsRepository _settingsRepository;

  Future<void> _load() async {
    final loadResult = await _settingsRepository.load();
    if (loadResult.isFailure) return;
    
    final localeResult = _settingsRepository.getLocale();
    final themeModeResult = _settingsRepository.getThemeMode();
    final connectOnBootResult = _settingsRepository.getConnectOnBoot();
    final autoLaunchResult = _settingsRepository.getAutoLaunch();
    final minimizeToTrayResult = _settingsRepository.getMinimizeToTray();
    final dnsPresetResult = _settingsRepository.getDnsPreset();
    final dnsCustomIdResult = _settingsRepository.getDnsCustomId();
    final proxyPortResult = _settingsRepository.getProxyPort();
    final customDnsProfilesResult = _settingsRepository.getCustomDnsProfiles();
    
    emit(SettingsState(
      locale: localeResult.getOrElse(const Locale('en')),
      themeMode: themeModeResult.getOrElse(ThemeMode.dark),
      connectOnBoot: connectOnBootResult.getOrElse(false),
      autoLaunch: autoLaunchResult.getOrElse(false),
      minimizeToTray: minimizeToTrayResult.getOrElse(false),
      dnsPreset: dnsPresetResult.getOrElse('cloudflare'),
      dnsCustomId: dnsCustomIdResult.value,
      proxyPort: proxyPortResult.getOrElse(11080),
      customDnsProfiles: customDnsProfilesResult.getOrElse(const <DnsProfile>[]).map((dp) => CustomDnsProfile(
        id: dp.id,
        name: dp.name,
        primary: dp.primary,
        secondary: dp.secondary,
      )).toList(),
    ));
  }

  Future<void> setLocale(String languageCode) async {
    await _settingsRepository.setLocale(languageCode);
    final result = _settingsRepository.getLocale();
    emit(state.copyWith(locale: result.getOrElse(state.locale)));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsRepository.setThemeMode(mode);
    final result = _settingsRepository.getThemeMode();
    emit(state.copyWith(themeMode: result.getOrElse(state.themeMode)));
  }

  Future<void> setConnectOnBoot(bool value) async {
    await _settingsRepository.setConnectOnBoot(value);
    final result = _settingsRepository.getConnectOnBoot();
    emit(state.copyWith(connectOnBoot: result.getOrElse(state.connectOnBoot)));
  }

  Future<void> setAutoLaunch(bool value) async {
    await _settingsRepository.setAutoLaunch(value);
    final result = _settingsRepository.getAutoLaunch();
    emit(state.copyWith(autoLaunch: result.getOrElse(state.autoLaunch)));
  }

  Future<void> setMinimizeToTray(bool value) async {
    await _settingsRepository.setMinimizeToTray(value);
    final result = _settingsRepository.getMinimizeToTray();
    emit(state.copyWith(minimizeToTray: result.getOrElse(state.minimizeToTray)));
  }

  Future<void> setDnsPreset(String preset) async {
    await _settingsRepository.setDnsPreset(preset);
    final dnsPresetResult = _settingsRepository.getDnsPreset();
    final dnsCustomIdResult = _settingsRepository.getDnsCustomId();
    emit(state.copyWith(
      dnsPreset: dnsPresetResult.getOrElse(state.dnsPreset),
      dnsCustomId: dnsCustomIdResult.value,
    ));
  }

  Future<void> selectCustomDns(String profileId) async {
    await _settingsRepository.selectCustomDns(profileId);
    final result = _settingsRepository.getDnsCustomId();
    emit(state.copyWith(dnsCustomId: result.value));
  }

  Future<void> setProxyPort(int port) async {
    await _settingsRepository.setProxyPort(port);
    final result = _settingsRepository.getProxyPort();
    emit(state.copyWith(proxyPort: result.getOrElse(state.proxyPort)));
  }

  Future<void> saveCustomDnsProfile(CustomDnsProfile profile) async {
    final dnsProfile = DnsProfile(
      id: profile.id,
      name: profile.name,
      primary: profile.primary,
      secondary: profile.secondary,
    );
    await _settingsRepository.saveCustomDnsProfile(dnsProfile);
    final result = _settingsRepository.getCustomDnsProfiles();
    emit(state.copyWith(
      customDnsProfiles: result.getOrElse(const <DnsProfile>[]).map((dp) => CustomDnsProfile(
        id: dp.id,
        name: dp.name,
        primary: dp.primary,
        secondary: dp.secondary,
      )).toList(),
    ));
  }

  Future<void> deleteCustomDnsProfile(String id) async {
    await _settingsRepository.deleteCustomDnsProfile(id);
    final customDnsResult = _settingsRepository.getCustomDnsProfiles();
    final dnsCustomIdResult = _settingsRepository.getDnsCustomId();
    emit(state.copyWith(
      customDnsProfiles: customDnsResult.getOrElse(const <DnsProfile>[]).map((dp) => CustomDnsProfile(
        id: dp.id,
        name: dp.name,
        primary: dp.primary,
        secondary: dp.secondary,
      )).toList(),
      dnsCustomId: dnsCustomIdResult.value,
    ));
  }

  List<String> getCurrentDnsServers() {
    final result = _settingsRepository.getCurrentDnsServers();
    return result.getOrElse(const ['1.1.1.1', '8.8.8.8']);
  }
}
