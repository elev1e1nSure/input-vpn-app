import 'package:flutter/material.dart';
import 'package:input_vpn/core/result.dart';
import 'package:input_vpn/domain/entities/dns_profile.dart';

abstract class SettingsRepository {
  Result<Locale> getLocale();
  Result<ThemeMode> getThemeMode();
  Result<bool> getConnectOnBoot();
  Result<bool> getAutoLaunch();
  Result<bool> getMinimizeToTray();
  Result<String> getDnsPreset();
  Result<String?> getDnsCustomId();
  Result<int> getProxyPort();
  Result<List<DnsProfile>> getCustomDnsProfiles();

  Result<List<String>> getCurrentDnsServers();
  Result<DnsProfile?> getSelectedCustomDnsProfile();

  Result<void> setLocale(String languageCode);
  Result<void> setThemeMode(ThemeMode mode);
  Result<void> setConnectOnBoot(bool value);
  Result<void> setAutoLaunch(bool value);
  Result<void> setMinimizeToTray(bool value);
  Result<void> setDnsPreset(String preset);
  Result<void> selectCustomDns(String profileId);
  Result<void> setProxyPort(int port);
  Result<void> saveCustomDnsProfile(DnsProfile profile);
  Result<void> deleteCustomDnsProfile(String id);

  Result<void> load();
}
