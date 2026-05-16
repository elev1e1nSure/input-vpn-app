import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:input_vpn/services/singbox_service_manager.dart';
import 'package:input_vpn/widgets/settings_tiles.dart';

@NowaGenerated()
class AdvancedSettingsScreen extends StatefulWidget {
  const AdvancedSettingsScreen({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  State<AdvancedSettingsScreen> createState() => _AdvancedSettingsScreenState();
}

class _AdvancedSettingsScreenState extends State<AdvancedSettingsScreen> {
  bool _serviceInstalled = false;
  bool _serviceBusy = false;

  @override
  void initState() {
    super.initState();
    if (Platform.isWindows) _checkService();
  }

  Future<void> _checkService() async {
    final installed = await SingboxServiceManager.isInstalled();
    if (mounted) setState(() => _serviceInstalled = installed);
  }

  Future<void> _installService(AppState appState, AppStrings s) async {
    setState(() => _serviceBusy = true);
    try {
      final exe = '${File(Platform.resolvedExecutable).parent.path}\\sing-box.exe';
      final base = await getApplicationSupportDirectory();
      final configPath = p.join(base.path, 'singbox', 'config.json');
      final ok = await SingboxServiceManager.install(exe, configPath);
      if (!mounted) return;
      if (ok) {
        setState(() => _serviceInstalled = true);
        await appState.setServiceMode(true);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.serviceInstalled)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.serviceInstallFailed)));
      }
    } finally {
      if (mounted) setState(() => _serviceBusy = false);
    }
  }

  Future<void> _removeService(AppState appState, AppStrings s) async {
    setState(() => _serviceBusy = true);
    try {
      await appState.setServiceMode(false);
      final ok = await SingboxServiceManager.remove();
      if (!mounted) return;
      if (ok) {
        setState(() => _serviceInstalled = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.serviceRemoved)));
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.serviceRemoveFailed)));
      }
    } finally {
      if (mounted) setState(() => _serviceBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.advanced),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 8),
          if (Platform.isWindows)
            buildSettingsSwitchTile(
              theme,
              s.proxyMode,
              CupertinoIcons.arrow_swap,
              appState.isProxyMode,
              (val) => appState.setProxyMode(val),
            ),
          if (Platform.isWindows) _buildServiceTile(context, theme, appState, s),
          _buildPortTile(context, theme, appState, s),
          buildSettingsDisabledListTile(
            theme,
            s.vpnProtocol,
            CupertinoIcons.shield_lefthalf_fill,
            trailingText: 'Auto',
          ),
          buildSettingsDisabledSwitchTile(
            theme,
            s.killSwitch,
            CupertinoIcons.lock_shield,
            false,
          ),
          buildSettingsDisabledListTile(
            theme,
            s.splitTunneling,
            CupertinoIcons.arrow_branch,
          ),
        ],
      ),
    );
  }

  Widget _buildPortTile(
    BuildContext context,
    ThemeData theme,
    AppState appState,
    AppStrings s,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(CupertinoIcons.number, color: theme.iconTheme.color),
      title: Text(s.proxyPort, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${appState.proxyPort}',
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
      onTap: () => _showPortDialog(context, appState, s),
    );
  }

  Widget _buildServiceTile(
    BuildContext context,
    ThemeData theme,
    AppState appState,
    AppStrings s,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.gear_alt, color: theme.iconTheme.color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.serviceModeTitle,
                        style: theme.textTheme.bodyLarge),
                    Text(
                      s.serviceModeSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              if (_serviceBusy)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Switch(
                  value: appState.isServiceMode,
                  onChanged: _serviceInstalled
                      ? (val) => val
                          ? appState.setServiceMode(true)
                          : appState.setServiceMode(false)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (!_serviceInstalled)
                FilledButton.tonal(
                  onPressed: _serviceBusy
                      ? null
                      : () => _installService(appState, s),
                  child: Text(s.installService),
                )
              else
                OutlinedButton(
                  onPressed: _serviceBusy
                      ? null
                      : () => _removeService(appState, s),
                  child: Text(s.removeService),
                ),
              const SizedBox(width: 8),
              Text(
                _serviceInstalled ? '✓ installed' : 'not installed',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _serviceInstalled
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
        ],
      ),
    );
  }

  void _showPortDialog(BuildContext context, AppState appState, AppStrings s) {
    final controller =
        TextEditingController(text: appState.proxyPort.toString());
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.proxyPort),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1080 – 65535',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.dismiss),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1024 && val <= 65535) {
                appState.setProxyPort(val);
              }
              Navigator.pop(ctx);
            },
            child: Text(s.copy),
          ),
        ],
      ),
    );
  }
}
