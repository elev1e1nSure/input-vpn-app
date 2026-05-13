import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
class AdvancedSettingsScreen extends StatelessWidget {
  const AdvancedSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context, listen: true);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.advanced),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          const SizedBox(height: 8),
          if (Platform.isWindows)
            _buildSwitchTile(
              theme,
              s.proxyMode,
              CupertinoIcons.arrow_swap,
              appState.isProxyMode,
              (val) => appState.setProxyMode(val),
            ),
          _buildPortTile(context, theme, appState, s),
          _buildDisabledListTile(
            theme,
            s.vpnProtocol,
            CupertinoIcons.shield_lefthalf_fill,
            trailingText: 'Auto',
          ),
          _buildDisabledSwitchTile(
            theme,
            s.killSwitch,
            CupertinoIcons.lock_shield,
            false,
          ),
          _buildDisabledListTile(
            theme,
            s.splitTunneling,
            CupertinoIcons.arrow_branch,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }

  Widget _buildDisabledListTile(
    ThemeData theme,
    String title,
    IconData icon, {
    String? trailingText,
  }) {
    final dimColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: dimColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: dimColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: theme.textTheme.bodyMedium?.copyWith(color: dimColor),
            ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: dimColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDisabledSwitchTile(
    ThemeData theme,
    String title,
    IconData icon,
    bool value,
  ) {
    final dimColor =
        theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: dimColor),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(color: dimColor),
      ),
      trailing: CupertinoSwitch(value: value, onChanged: null),
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

  void _showPortDialog(BuildContext context, AppState appState, AppStrings s) {
    final controller =
        TextEditingController(text: appState.proxyPort.toString());
    showDialog(
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
