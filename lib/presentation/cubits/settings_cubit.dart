import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';
import 'package:input_vpn/presentation/cubits/settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository {
    _load();
  }

  final SettingsRepository _settingsRepository;

  Future<void> _load() async {
    await _settingsRepository.load();
    emit(SettingsState(
      locale: _settingsRepository.locale,
      themeMode: _settingsRepository.themeMode,
      connectOnBoot: _settingsRepository.connectOnBoot,
      autoLaunch: _settingsRepository.autoLaunch,
      minimizeToTray: _settingsRepository.minimizeToTray,
      dnsPreset: _settingsRepository.dnsPreset,
      dnsCustomId: _settingsRepository.dnsCustomId,
      proxyPort: _settingsRepository.proxyPort,
      customDnsProfiles: _settingsRepository.customDnsProfiles,
    ));
  }

  Future<void> setLocale(String languageCode) async {
    await _settingsRepository.setLocale(languageCode);
    emit(state.copyWith(locale: _settingsRepository.locale));
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _settingsRepository.setThemeMode(mode);
    emit(state.copyWith(themeMode: _settingsRepository.themeMode));
  }

  Future<void> setConnectOnBoot(bool value) async {
    await _settingsRepository.setConnectOnBoot(value);
    emit(state.copyWith(connectOnBoot: _settingsRepository.connectOnBoot));
  }

  Future<void> setAutoLaunch(bool value) async {
    await _settingsRepository.setAutoLaunch(value);
    emit(state.copyWith(autoLaunch: _settingsRepository.autoLaunch));
  }

  Future<void> setMinimizeToTray(bool value) async {
    await _settingsRepository.setMinimizeToTray(value);
    emit(state.copyWith(minimizeToTray: _settingsRepository.minimizeToTray));
  }

  Future<void> setDnsPreset(String preset) async {
    await _settingsRepository.setDnsPreset(preset);
    emit(state.copyWith(
      dnsPreset: _settingsRepository.dnsPreset,
      dnsCustomId: _settingsRepository.dnsCustomId,
    ));
  }

  Future<void> selectCustomDns(String profileId) async {
    await _settingsRepository.selectCustomDns(profileId);
    emit(state.copyWith(dnsCustomId: _settingsRepository.dnsCustomId));
  }

  Future<void> setProxyPort(int port) async {
    await _settingsRepository.setProxyPort(port);
    emit(state.copyWith(proxyPort: _settingsRepository.proxyPort));
  }

  Future<void> saveCustomDnsProfile(CustomDnsProfile profile) async {
    await _settingsRepository.saveCustomDnsProfile(profile);
    emit(state.copyWith(
      customDnsProfiles: _settingsRepository.customDnsProfiles,
    ));
  }

  Future<void> deleteCustomDnsProfile(String id) async {
    await _settingsRepository.deleteCustomDnsProfile(id);
    emit(state.copyWith(
      customDnsProfiles: _settingsRepository.customDnsProfiles,
      dnsCustomId: _settingsRepository.dnsCustomId,
    ));
  }

  List<String> getCurrentDnsServers() => _settingsRepository.getCurrentDnsServers();
}
