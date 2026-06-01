import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:input_vpn/globals/app_state.dart';

import 'package:input_vpn/globals/themes.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:input_vpn/models/dns_preset.dart';
import 'package:input_vpn/pages/advanced_settings_screen.dart';
import 'package:input_vpn/pages/custom_dns_screen.dart';
import 'package:input_vpn/services/update_service.dart';
import 'package:input_vpn/widgets/settings_tiles.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _currentVersion = '1.1.0';
  bool _checking = false;
  bool _showAdvanced = false;
  UpdateInfo? _updateInfo;
  bool _downloadingUpdate = false;
  double _downloadProgress = 0;
  String? _downloadError;

  final UpdateService _updateService = UpdateService();

  Future<void> _checkForUpdates() async {
    setState(() {
      _checking = true;
      _downloadError = null;
    });
    try {
      final info = await _updateService.checkForUpdate(_currentVersion);
      if (!mounted) return;
      setState(() {
        _updateInfo = info;
        _checking = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _updateInfo = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final s = AppStrings.of(context);
    if (_showAdvanced) {
      return AdvancedSettingsScreen(
        onBack: () => setState(() => _showAdvanced = false),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(s.settings),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
              if (value == 'export') _exportSettings(appState, s);
              if (value == 'import') _importSettings(appState, s);
            },
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    const Icon(Icons.copy_all, size: 18),
                    const SizedBox(width: 12),
                    Text(s.exportSettings),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    const Icon(Icons.paste, size: 18),
                    const SizedBox(width: 12),
                    Text(s.importSettings),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
            Icons.language,
            trailingText:
                appState.locale.languageCode == 'ru' ? 'Русский' : 'English',
            onTap: () => _showLanguageDialog(context, appState),
          ),
          buildSettingsSwitchTile(
            theme,
            s.darkMode,
            Icons.dark_mode,
            isDark,
            (val) {
              appState.changeTheme(val ? darkTheme : lightTheme);
            },
          ),
          buildSettingsSwitchTile(
            theme,
            s.connectOnBoot,
            Icons.power_settings_new,
            appState.connectOnBoot,
            (val) => appState.setConnectOnBoot(val),
          ),
          if (Platform.isWindows)
            buildSettingsSwitchTile(
              theme,
              s.autoLaunch,
              Icons.launch,
              appState.autoLaunch,
              (val) => appState.setAutoLaunch(val),
            ),
          if (Platform.isWindows)
            buildSettingsSwitchTile(
              theme,
              s.minimizeToTray,
              Icons.web_asset_off,
              appState.minimizeToTray,
              (val) => appState.setMinimizeToTray(val),
            ),
          buildSettingsListTile(
            theme,
            s.advanced,
            Icons.settings,
            onTap: () => setState(() => _showAdvanced = true),
          ),
          const SizedBox(height: 24),
          // ── ABOUT ──
          buildSettingsSectionHeader(theme, s.about),
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
            leading: Icon(Icons.info, color: theme.iconTheme.color),
            title: Text(s.version, style: theme.textTheme.bodyLarge),
            subtitle: _updateInfo != null
                ? Text(
                    '${s.updateAvailable}: ${_updateInfo!.version}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  )
                : Text(
                    s.checkForUpdates,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.textTheme.bodyMedium?.color
                          ?.withValues(alpha: 0.4),
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
                    _updateInfo == null ? s.upToDate : _currentVersion,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _updateInfo == null
                          ? theme.colorScheme.primary
                          : theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.6),
                    ),
                  ),
            onTap: _checkForUpdates,
          ),
          if (Platform.isWindows && _updateInfo != null)
            _buildUpdateSection(theme, s),
        ],
      ),
    );
  }

  Widget _buildUpdateSection(ThemeData theme, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            s.updateAvailable,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.error),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _downloadingUpdate ? null : _startUpdate,
            icon: const Icon(Icons.system_update_alt),
            label: Text(
              _downloadingUpdate
                  ? '${s.downloadingUpdate} ${(_downloadProgress * 100).clamp(0, 100).toStringAsFixed(0)}%'
                  : s.updateNow,
            ),
          ),
          if (_downloadingUpdate) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: _downloadProgress == 0 ? null : _downloadProgress),
          ],
          if (_downloadError != null) ...[
            const SizedBox(height: 8),
            Text(
              _downloadError!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _startUpdate() async {
    final info = _updateInfo;
    if (!Platform.isWindows || info == null) return;
    final s = AppStrings.of(context);
    setState(() {
      _downloadingUpdate = true;
      _downloadProgress = 0;
      _downloadError = null;
    });

    try {
      final installerPath = await _updateService.downloadInstaller(
        info,
        onProgress: (received, total) {
          if (!mounted || total <= 0) return;
          setState(() => _downloadProgress = received / total);
        },
      );

      if (!mounted) return;
      final appState = AppState.of(context, listen: false);
      if (appState.isConnected) {
        await appState.toggleConnection();
      }

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(s.updateReady),
          content: Text(s.updateWillClose),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(s.updateNow),
            ),
          ],
        ),
      );

      await _updateService.installAndExit(installerPath);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _downloadError = s.unexpectedError;
      });
    } finally {
      if (mounted) {
        setState(() => _downloadingUpdate = false);
      }
    }
  }

  // ── DNS PRESET TILE ──
  Widget _buildDnsTile(
    BuildContext context,
    ThemeData theme,
    AppState appState,
    AppStrings s,
  ) {
    final current = DnsPreset.byId(appState.dnsPreset);
    final custom = appState.selectedCustomDnsProfile;
    final isRu = s.language == 'Язык';
    final display = custom != null
        ? custom.servers.join(', ')
        : (current != null && current.servers.isNotEmpty
            ? current.servers.join(', ')
            : (isRu ? 'По умолчанию системы' : 'System default'));
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(Icons.cloud, color: theme.iconTheme.color),
      title: Text(s.dnsServer, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            display,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
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
    final parentContext = context;
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
                  title: Text(
                    subtitle,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: selected ? theme.colorScheme.primary : null,
                      fontWeight: selected ? FontWeight.bold : null,
                    ),
                  ),
                  subtitle: Text(preset.label(isRu)),
                  trailing: selected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () {
                    appState.setDnsPreset(preset.id);
                    Navigator.pop(ctx);
                  },
                );
              }),
              if (appState.customDnsProfiles.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Text(
                      s.customDnsProfilesTitle,
                      style: theme.textTheme.titleSmall,
                    ),
                  ),
                ),
                ...appState.customDnsProfiles.map((profile) {
                  final selected = profile.id == appState.dnsCustomId;
                  return ListTile(
                    title: Text(
                      profile.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: selected ? theme.colorScheme.primary : null,
                        fontWeight: selected ? FontWeight.bold : null,
                      ),
                    ),
                    subtitle: Text(profile.servers.join(', ')),
                    trailing: selected
                        ? Icon(Icons.check, color: theme.colorScheme.primary)
                        : null,
                    onTap: () {
                      appState.selectCustomDns(profile.id);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
              const SizedBox(height: 8),
              ListTile(
                leading: Icon(Icons.tune, color: theme.iconTheme.color),
                title: Text(s.manageCustomDns),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.of(parentContext).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CustomDnsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportSettings(AppState appState, AppStrings s) async {
    final snapshot = appState.buildAnonymizedSettingsSnapshot();
    final json = const JsonEncoder.withIndent('  ').convert(snapshot);
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(s.settingsCopied)),
    );
  }

  Future<void> _importSettings(AppState appState, AppStrings s) async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text == null || data!.text!.trim().isEmpty) {
        throw const FormatException('empty clipboard');
      }
      final decoded = jsonDecode(data.text!);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('invalid json');
      }
      await appState.importAnonymizedSettings(decoded);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsImported)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.settingsImportFailed)),
      );
    }
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
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                appState.setLocale('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Русский'),
              trailing: appState.locale.languageCode == 'ru'
                  ? const Icon(Icons.check, color: Colors.blue)
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
