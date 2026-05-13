import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/pages/add_config_screen.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/functions/country_code_to_emoji.dart';

@NowaGenerated()
class ServersScreen extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const ServersScreen({super.key});

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.add_circled,
              size: 80,
              color: theme.iconTheme.color?.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text('No Servers Yet', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              'Add your first configuration or subscription link to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const AddConfigScreen(),
                  ),
                );
              },
              child: const Text('Add Config'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context, listen: true);
    final theme = Theme.of(context);
    final servers = appState.userServers;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('My Servers'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(CupertinoIcons.add),
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute(
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
                    leading: Text(
                      countryCodeToEmoji(server.flagCode),
                      style: const TextStyle(fontSize: 28),
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
                      '${server.city}, ${server.country}',
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
                          size: 20,
                          color: server.signalQuality > 80
                              ? theme.colorScheme.primary
                              : server.signalQuality > 50
                              ? Colors.orange
                              : theme.colorScheme.error,
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 16),
                          Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 20,
                            color: theme.colorScheme.primary,
                          ),
                        ],
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
