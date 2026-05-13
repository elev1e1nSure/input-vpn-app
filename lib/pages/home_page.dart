import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/pages/settings_screen.dart';
import 'package:vpn/pages/servers_screen.dart';
import 'package:vpn/functions/country_code_to_emoji.dart';

@NowaGenerated()
class HomePage extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HomePage({super.key});

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context, listen: true);
    final theme = Theme.of(context);
    final bool isConnected = appState.isConnected;
    final bool isConnecting = appState.isConnecting;
    final server = appState.selectedServer;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('VPN Client'),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.settings),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const Spacer(flex: 1),
            Text(
              server == null
                  ? 'Setup Required'
                  : isConnecting
                  ? 'Connecting...'
                  : isConnected
                  ? 'Connected'
                  : 'Ready to Connect',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isConnected
                    ? theme.colorScheme.primary
                    : theme.textTheme.titleLarge?.color,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              server == null
                  ? 'Please add a configuration'
                  : isConnected
                  ? 'Your IP is hidden'
                  : 'Security level: High',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isConnected
                    ? theme.colorScheme.primary.withValues(alpha: 0.8)
                    : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
            if (appState.isTestMode) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => _showTestModeSheet(context, appState),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withValues(alpha: 0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.info_circle, size: 14, color: Colors.amber),
                      const SizedBox(width: 6),
                      Text('TEST MODE (SOCKS5 :1080)', style: theme.textTheme.labelSmall?.copyWith(color: Colors.amber, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
            const Spacer(flex: 1),
            GestureDetector(
              onTap: () {
                if (server == null) {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const ServersScreen(),
                    ),
                  );
                } else {
                  appState.toggleConnection();
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isConnected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surface,
                  border: Border.all(
                    color: isConnected
                        ? theme.colorScheme.primary
                        : theme.dividerTheme.color!,
                    width: 2,
                  ),
                  boxShadow: isConnected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: server == null
                          ? theme.colorScheme.surface
                          : isConnected
                          ? theme.colorScheme.primary
                          : const Color(0xFF3A3A3C),
                    ),
                    child: Center(
                      child: isConnecting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Icon(
                              server == null
                                  ? CupertinoIcons.add
                                  : CupertinoIcons.power,
                              size: 60,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(flex: 1),
            AnimatedOpacity(
              opacity: isConnected ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: isConnected
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatItem(
                          context,
                          'PING',
                          '${appState.ping} ms',
                          CupertinoIcons.wifi,
                        ),
                        _buildStatItem(
                          context,
                          'DOWNLOAD',
                          appState.downloadSpeed,
                          CupertinoIcons.arrow_down,
                        ),
                        _buildStatItem(
                          context,
                          'UPLOAD',
                          appState.uploadSpeed,
                          CupertinoIcons.arrow_up,
                        ),
                      ],
                    )
                  : const SizedBox(height: 68),
            ),
            const Spacer(flex: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    CupertinoPageRoute(
                      builder: (context) => const ServersScreen(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: theme.dividerTheme.color!),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            server != null
                                ? countryCodeToEmoji(server.flagCode)
                                : '?',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              server != null ? 'Selected Server' : 'No Server',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              server != null
                                  ? server.name
                                  : 'Add a configuration',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 16,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        CupertinoIcons.chevron_forward,
                        color: theme.iconTheme.color?.withValues(alpha: 0.5),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
            if (appState.lastError != null)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: _ErrorBanner(message: appState.lastError!),
              ),
          ],
        ),
      ),
    );
  }
}

void _showTestModeSheet(BuildContext context, AppState appState) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Test mode',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'sing-box is running as a local SOCKS5 proxy on '
              '127.0.0.1:1080. It does NOT touch system routes, so '
              'another VPN can run at the same time.\n\n'
              'To send traffic through it:\n'
              '  • Browser: set proxy to SOCKS5 127.0.0.1:1080\n'
              '  • Test:  curl --socks5 127.0.0.1:1080 https://ifconfig.me\n\n'
              'Switch to Full VPN mode when you are ready to route '
              'all system traffic. It will request admin (UAC) and '
              'replace any other VPN.',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Keep test mode'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      await appState.setFullVpnMode(true);
                    },
                    child: const Text('Enable Full VPN'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(CupertinoIcons.exclamationmark_triangle,
              color: Colors.red, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: SelectableText(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.red.shade100,
                fontFamily: 'monospace',
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 12,
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            icon: const Icon(CupertinoIcons.doc_on_clipboard,
                color: Colors.red, size: 18),
            onPressed: () =>
                Clipboard.setData(ClipboardData(text: message)),
          ),
          IconButton(
            tooltip: 'Dismiss',
            icon: const Icon(CupertinoIcons.xmark,
                color: Colors.red, size: 18),
            onPressed: () =>
                AppState.of(context, listen: false).clearError(),
          ),
        ],
      ),
    );
  }
}
