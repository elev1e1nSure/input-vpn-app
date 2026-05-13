import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/pages/add_config_screen.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
class ServersScreen extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const ServersScreen({super.key});

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
              CupertinoIcons.globe,
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
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (context) => const AddConfigScreen(),
                  ),
                );
              },
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

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final theme = Theme.of(context);
    final servers = appState.userServers;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.of(context).myServers),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (context) => const AddConfigScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: servers.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
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
                      CupertinoIcons.trash,
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
                          CupertinoIcons.globe,
                          size: 18,
                          color: theme.iconTheme.color?.withValues(alpha: 0.4),
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
                    subtitle: Text(
                      server.country,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: theme.textTheme.bodyMedium?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.wifi,
                          size: 18,
                          color: server.signalQuality > 80
                              ? theme.colorScheme.primary
                              : server.signalQuality > 50
                              ? Colors.orange
                              : theme.colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: Icon(
                            CupertinoIcons.trash,
                            size: 18,
                            color: theme.colorScheme.error
                                .withValues(alpha: 0.7),
                          ),
                          onPressed: () {
                            appState.removeConfig(server.configId);
                          },
                        ),
                      ],
                    ),
                    onTap: () {
                      appState.selectServer(server);
                      Navigator.of(context).pop();
                    },
                  ),
                );
              },
            ),
    );
  }
}
