import 'package:flutter/material.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:input_vpn/models/vpn_server.dart';

String _stripFlags(String s) =>
    s.replaceAll(RegExp(r'[\u{1F1E0}-\u{1F1FF}]', unicode: true), '').trim();

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
              color: theme.iconTheme.color?.withValues(alpha: 0.12),
            ),
            const SizedBox(height: 16),
            Text(s.noServersYet, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              s.addFirstConfigHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 13,
                color:
                    theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            _AddButton(label: s.addConfig, onTap: onSwitchToAddConfig),
          ],
        ),
      ),
    );
  }

  Widget _buildSubtitle(
      BuildContext context, AppState appState, VpnServer server) {
    final theme = Theme.of(context);
    final configs =
        appState.userConfigs.where((c) => c.id == server.configId).toList();
    if (configs.isEmpty) {
      return _subtitleText(theme, server.country);
    }

    final config = configs.first;
    if (config.type.name == 'subscription' && config.hasSubStats) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _subtitleText(theme, server.country),
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

    return _subtitleText(theme, server.country);
  }

  Text _subtitleText(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 13,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final theme = Theme.of(context);
    final servers = appState.userServers;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppStrings.of(context).myServers,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
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
                for (final config in appState.userConfigs) {
                  if (config.subUrl != null) {
                    await appState.refreshSubscriptionStats(config.id);
                  }
                }
              },
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                itemCount: servers.length,
                itemBuilder: (context, index) {
                  final server = servers[index];
                  final isSelected = appState.selectedServer?.id == server.id;
                  return _ServerTile(
                    server: server,
                    isSelected: isSelected,
                    subtitle: _buildSubtitle(context, appState, server),
                    onTap: () {
                      appState.selectServer(server);
                      onServerSelected();
                    },
                    onEdit: () => onEditServer(server),
                    onDelete: () => appState.removeConfig(server.configId),
                  );
                },
              ),
            ),
    );
  }
}

/// Single server row with hover state and selected indicator.
class _ServerTile extends StatefulWidget {
  const _ServerTile({
    required this.server,
    required this.isSelected,
    required this.subtitle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final VpnServer server;
  final bool isSelected;
  final Widget subtitle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ServerTile> createState() => _ServerTileState();
}

class _ServerTileState extends State<_ServerTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSelected = widget.isSelected;

    return Dismissible(
      key: Key(widget.server.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: theme.colorScheme.error,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: isSelected
          ? ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 6,
                  ),
                  onTap: widget.onTap,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        Icons.public,
                        size: 20,
                        color: primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  title: Text(
                    _stripFlags(widget.server.name),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  subtitle: widget.subtitle,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          icon: Icon(
                            Icons.edit,
                            size: 18,
                            color:
                                theme.iconTheme.color?.withValues(alpha: 0.3),
                          ),
                          onPressed: widget.onEdit,
                        ),
                      ),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IconButton(
                          icon: Icon(
                            Icons.delete,
                            size: 18,
                            color:
                                theme.colorScheme.error.withValues(alpha: 0.4),
                          ),
                          onPressed: widget.onDelete,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : MouseRegion(
              cursor: SystemMouseCursors.click,
              onEnter: (_) => setState(() => _hovered = true),
              onExit: (_) => setState(() => _hovered = false),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOutCubic,
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _hovered
                        ? Color.lerp(
                            theme.colorScheme.surface,
                            primary,
                            0.055,
                          )
                        : theme.colorScheme.surface.withValues(alpha: 0.78),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    onTap: widget.onTap,
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
                          color: theme.iconTheme.color?.withValues(alpha: 0.25),
                        ),
                      ),
                    ),
                    title: Text(
                      _stripFlags(widget.server.name),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: widget.subtitle,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(
                              Icons.edit,
                              size: 18,
                              color: theme.iconTheme.color?.withValues(
                                alpha: _hovered ? 0.6 : 0.3,
                              ),
                            ),
                            onPressed: widget.onEdit,
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: Icon(
                              Icons.delete,
                              size: 18,
                              color: theme.colorScheme.error.withValues(
                                alpha: _hovered ? 0.8 : 0.4,
                              ),
                            ),
                            onPressed: widget.onDelete,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

/// Просека-style button for empty state.
class _AddButton extends StatefulWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final baseColor = theme.colorScheme.surface.withValues(alpha: 0.78);
    final color = _hovered ? Color.lerp(baseColor, primary, 0.055) : baseColor;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              widget.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
