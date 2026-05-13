import 'package:flutter/material.dart';
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
        child: Column(
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
                                ? countryCodeToEmoji(server!.flagCode)
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
                                  ? server!.name
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
      ),
    );
  }
}
