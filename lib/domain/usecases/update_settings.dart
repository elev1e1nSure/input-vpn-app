import 'package:flutter/material.dart';
import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/dns_profile.dart';
import 'package:input_vpn/domain/repositories/settings_repository.dart';

class UpdateSettings {
  final SettingsRepository repository;

  UpdateSettings(this.repository);

  Result<void> setLocale(String languageCode) {
    return repository.setLocale(languageCode);
  }

  Result<void> setThemeMode(ThemeMode mode) {
    return repository.setThemeMode(mode);
  }

  Result<void> setConnectOnBoot(bool value) {
    return repository.setConnectOnBoot(value);
  }

  Result<void> setAutoLaunch(bool value) {
    return repository.setAutoLaunch(value);
  }

  Result<void> setMinimizeToTray(bool value) {
    return repository.setMinimizeToTray(value);
  }

  Result<void> setDnsPreset(String preset) {
    return repository.setDnsPreset(preset);
  }

  Result<void> selectCustomDns(String profileId) {
    return repository.selectCustomDns(profileId);
  }

  Result<void> setProxyPort(int port) {
    return repository.setProxyPort(port);
  }

  Result<void> saveCustomDnsProfile(DnsProfile profile) {
    return repository.saveCustomDnsProfile(profile);
  }

  Result<void> deleteCustomDnsProfile(String id) {
    return repository.deleteCustomDnsProfile(id);
  }
}
