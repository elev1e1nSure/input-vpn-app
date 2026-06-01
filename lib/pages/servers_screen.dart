import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:input_vpn/vpn_server.dart';

class ServersScreen extends StatelessWidget {
  const ServersScreen({
    super.key,
    required this.onSwitchToAddConfig,
    required this.onServerSelected,
    required this.onBack,
    required this.onEditServer,
  });

  final VoidCallback onSwitchToAddConfig;
  final VoidCallback onServerSelected;
  final VoidCallback onBack;
  final void Function(VpnServer) onEditServer;

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.dns,
              size: 48,
              color: theme.iconTheme.color?.withValues(alpha: 0.15),
            ),
            const SizedBox(height: 16),
            Text(s.noServersYet, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              s.addFirstConfigHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              onPressed: onSwitchToAddConfig,
              child: Text(
                s.addConfig,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(BuildContext context, AppState appState, VpnServer server) {
    final theme = Theme.of(context);
    final configs = appState.userConfigs.where((c) => c.id == server.configId).toList();
    if (configs.isEmpty) {
      return Text(
        server.country,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: theme.textTheme.bodyMedium?.color?.withValues(
            alpha: 0.7,
          ),
        ),
      );
    }
    
    final config = configs.first;
    debugPrint('_buildSubtitle: config.type=${config.type.name}, hasSubStats=${config.hasSubStats}, subUpload=${config.subUpload}, subDownload=${config.subDownload}');
    // Check if this is a subscription with stats
    if (config.type.name == 'subscription' && config.hasSubStats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            server.country,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              color: theme.textTheme.bodyMedium?.color?.withValues(
                alpha: 0.7,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${config.subUsedHuman} / ${config.subTotalHuman}',
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 11,
              color: config.hasUnlimitedTraffic || config.subRemaining > 0 
                  ? theme.colorScheme.primary 
                  : theme.colorScheme.error,
            ),
          ),
        ],
      );
    }
    
    // Default: just show country
    return Text(
      server.country,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        color: theme.textTheme.bodyMedium?.color?.withValues(
          alpha: 0.7,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final theme = Theme.of(context);
    final servers = appState.userServers;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(AppStrings.of(context).myServers),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onSwitchToAddConfig,
            ),
          ),
        ],
      ),
      body: servers.isEmpty
          ? _buildEmptyState(context)
          : RefreshIndicator(
              onRefresh: () async {
                // Refresh stats for all subscription configs
                for (final config in appState.userConfigs) {
                  if (config.subUrl != null) {
                    await appState.refreshSubscriptionStats(config.id);
                  }
                }
              },
              child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: servers.length,
              separatorBuilder: (context, index) =>
                  Divider(color: theme.dividerTheme.color, indent: 64),
              itemBuilder: (context, index) {
                final server = servers[index];
                final isSelected = appState.selectedServer?.id == server.id;
                return Dismissible(
                  key: Key(server.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: theme.colorScheme.error,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) {
                    appState.removeConfig(server.configId);
                  },
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 4,
                    ),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.public,
                          size: 20,
                          color: theme.iconTheme.color?.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    title: Text(
                      server.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    subtitle: _buildSubtitle(context, appState, server),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(
                              Icons.edit_outlined,
                              size: 18,
                              color: theme.iconTheme.color?.withValues(alpha: 0.5),
                            ),
                            onPressed: () => onEditServer(server),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: theme.colorScheme.error
                                  .withValues(alpha: 0.7),
                            ),
                            onPressed: () {
                              appState.removeConfig(server.configId);
                            },
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      appState.selectServer(server);
                      onServerSelected();
                    },
                  ),
                );
              },
            ),
          ),
    );
  }
}
