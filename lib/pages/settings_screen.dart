import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:vpn/globals/themes.dart';
import 'package:vpn/l10n/app_strings.dart';
import 'package:vpn/models/dns_preset.dart';
import 'package:vpn/pages/advanced_settings_screen.dart';
import 'package:vpn/widgets/settings_tiles.dart';

@NowaGenerated()
class SettingsScreen extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

@NowaGenerated()
class _SettingsScreenState extends State<SettingsScreen> {
  static const String _currentVersion = '1.0.2';
  String? _latestVersion;
  bool _checking = false;

  Future<void> _checkForUpdates() async {
    setState(() => _checking = true);
    try {
      final response = await Dio().get<dynamic>(
        'https://api.github.com/repos/elev1e1nSure/input-vpn-app/releases/latest',
        options: Options(
          headers: {'Accept': 'application/vnd.github.v3+json'},
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final tag = (response.data['tag_name'] as String?)?.replaceFirst('v', '');
      if (mounted) {
        setState(() {
          _latestVersion = tag;
          _checking = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final s = AppStrings.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.settings),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(CupertinoIcons.back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 8),
          // ── BASIC ──
          buildSettingsSectionHeader(theme, s.basic),
          _buildDnsTile(context, theme, appState, s),
          buildSettingsListTile(
            theme,
            s.language,
            CupertinoIcons.globe,
            trailingText: appState.locale.languageCode == 'ru' ? 'Русский' : 'English',
            onTap: () => _showLanguageDialog(context, appState),
          ),
          buildSettingsSwitchTile(
            theme,
            s.darkMode,
            CupertinoIcons.moon_fill,
            isDark,
            (val) {
              appState.changeTheme(val ? darkTheme : lightTheme);
            },
          ),
          buildSettingsSwitchTile(
            theme,
            s.connectOnBoot,
            CupertinoIcons.power,
            appState.connectOnBoot,
            (val) => appState.setConnectOnBoot(val),
          ),
          if (Platform.isWindows)
            buildSettingsSwitchTile(
              theme,
              s.autoLaunch,
              CupertinoIcons.arrow_up_circle_fill,
              appState.autoLaunch,
              (val) => appState.setAutoLaunch(val),
            ),
          buildSettingsListTile(
            theme,
            s.advanced,
            CupertinoIcons.gear_alt_fill,
            onTap: () {
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (_) => const AdvancedSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          // ── ABOUT ──
          buildSettingsSectionHeader(theme, s.about),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            leading: Icon(CupertinoIcons.info_circle, color: theme.iconTheme.color),
            title: Text(s.version, style: theme.textTheme.bodyLarge),
            subtitle: _latestVersion != null && _latestVersion != _currentVersion
                ? Text(
                    '${s.updateAvailable}: $_latestVersion',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                : Text(
                    s.checkForUpdates,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                    ),
                  ),
            trailing: _checking
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.primary,
                    ),
                  )
                : Text(
                    _latestVersion == _currentVersion ? s.upToDate : _currentVersion,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _latestVersion == _currentVersion
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                    ),
                  ),
            onTap: _checkForUpdates,
          ),
        ],
      ),
    );
  }

  // ── DNS PRESET TILE ──
  Widget _buildDnsTile(
    BuildContext context,
    ThemeData theme,
    AppState appState,
    AppStrings s,
  ) {
    final current = DnsPreset.byId(appState.dnsPreset);
    final isRu = s.language == 'Язык';
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(current?.icon ?? CupertinoIcons.globe, color: theme.iconTheme.color),
      title: Text(s.dnsServer, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            current?.label(isRu) ?? '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: theme.iconTheme.color?.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: () => _showDnsPicker(context, appState, s),
    );
  }

  void _showDnsPicker(BuildContext context, AppState appState, AppStrings s) {
    final theme = Theme.of(context);
    final isRu = s.language == 'Язык';
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerTheme.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                s.dnsServer,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...DnsPreset.presets.map((preset) {
                final selected = preset.id == appState.dnsPreset;
                final subtitle = preset.servers.isNotEmpty
                    ? preset.servers.join(', ')
                    : (isRu ? 'По умолчанию системы' : 'System default');
                return ListTile(
                  leading: Icon(
                    preset.icon,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color,
                  ),
                  title: Text(
                    preset.label(isRu),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected ? theme.colorScheme.primary : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(subtitle),
                  trailing: selected
                      ? Icon(CupertinoIcons.checkmark_alt,
                          color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    appState.setDnsPreset(preset.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppState appState) {
    final s = AppStrings.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.language),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              trailing: appState.locale.languageCode == 'en'
                  ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.blue)
                  : null,
              onTap: () {
                appState.setLocale('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Русский'),
              trailing: appState.locale.languageCode == 'ru'
                  ? const Icon(CupertinoIcons.checkmark_alt, color: Colors.blue)
                  : null,
              onTap: () {
                appState.setLocale('ru');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
