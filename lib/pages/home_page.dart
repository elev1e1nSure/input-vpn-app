import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/pages/settings_screen.dart';
import 'package:vpn/pages/servers_screen.dart';
import 'package:vpn/pages/add_config_screen.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
class HomePage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        _Sidebar(
          expanded: _sidebarExpanded,
          selectedIndex: _selectedIndex,
          onItemSelected: (i) => setState(() => _selectedIndex = i),
          onToggleExpand: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
        ),
        VerticalDivider(
          width: 1,
          color: theme.dividerTheme.color,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },
            child: KeyedSubtree(
              key: ValueKey<int>(_selectedIndex),
              child: [
                const _HomeTab(),
                const ServersScreen(),
                const SettingsScreen(),
              ][_selectedIndex],
            ),
          ),
        ),
      ],
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.expanded,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onToggleExpand,
  });

  final bool expanded;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: expanded ? 200 : 64,
      color: theme.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 48,
              child: Center(
                child: IconButton(
                  icon: Icon(
                    expanded ? Icons.menu_open : Icons.menu,
                    size: 20,
                    color: theme.iconTheme.color?.withValues(alpha: 0.6),
                  ),
                  onPressed: onToggleExpand,
                ),
              ),
            ),
            Divider(
              height: 1,
              color: theme.dividerTheme.color,
            ),
            const SizedBox(height: 8),
            _SidebarItem(
              expanded: expanded,
              icon: Icons.shield,
              label: s.vpnLabel,
              selected: selectedIndex == 0,
              onTap: () => onItemSelected(0),
            ),
            _SidebarItem(
              expanded: expanded,
              icon: Icons.dns,
              label: s.myServers,
              selected: selectedIndex == 1,
              onTap: () => onItemSelected(1),
            ),
            _SidebarItem(
              expanded: expanded,
              icon: Icons.settings,
              label: s.settings,
              selected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.expanded,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final bool expanded;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: widget.selected
                ? theme.colorScheme.primary.withValues(alpha: 0.12)
                : _hovered
                    ? theme.colorScheme.onSurface.withValues(alpha: 0.04)
                    : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Center(
                  child: Icon(
                    widget.icon,
                    size: 20,
                    color: widget.selected
                        ? theme.colorScheme.primary
                        : theme.iconTheme.color?.withValues(alpha: 0.5),
                  ),
                ),
              ),
              AnimatedOpacity(
                opacity: widget.expanded ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: SizedBox(
                  width: widget.expanded ? null : 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        widget.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 13,
                          fontWeight: widget.selected ? FontWeight.w600 : FontWeight.normal,
                          color: widget.selected
                              ? theme.colorScheme.primary
                              : theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

@NowaGenerated()
class _HomeTab extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const _HomeTab();

  Widget _buildModeToggle(BuildContext context, AppState appState) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final isProxy = appState.isProxyMode;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => appState.setProxyMode(!isProxy),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: theme.dividerTheme.color ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ModePill(
                label: s.vpnLabel,
                icon: Icons.shield,
                active: !isProxy,
                theme: theme,
              ),
              _ModePill(
                label: s.socks5Label,
                icon: Icons.wifi_tethering,
                active: isProxy,
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

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
          size: 20,
          color: theme.iconTheme.color?.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildTrustInfo(BuildContext context) {
    final s = AppStrings.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.lock,
          size: 10,
          color: muted,
        ),
        const SizedBox(width: 4),
        Text(
          s.configsStoredLocally,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: muted,
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          Icons.verified_user,
          size: 10,
          color: muted,
        ),
        const SizedBox(width: 4),
        Text(
          s.supportsWireGuardOpenVPN,
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 10,
            color: muted,
          ),
        ),
      ],
    );
  }

  IconData _mainButtonIcon(AppState appState) {
    if (appState.selectedServer == null) return Icons.add;
    if (appState.isConnecting) return Icons.pause;
    if (appState.isConnected) return Icons.power_settings_new;
    return Icons.power_settings_new;
  }

  void _openAddConfig(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => const AddConfigScreen(),
      ),
    );
  }

  void _goToServers(BuildContext context) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => const ServersScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState.of(context);
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final bool isConnected = appState.isConnected;
    final bool isConnecting = appState.isConnecting;
    final server = appState.selectedServer;
    final hasServer = server != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _openAddConfig(context),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Text(
                    hasServer
                        ? (isConnecting
                            ? s.connecting
                            : isConnected
                                ? s.connected
                                : s.readyToConnect)
                        : s.connectInOneMinute,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: isConnected
                          ? theme.colorScheme.primary
                          : theme.textTheme.titleLarge?.color,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasServer
                        ? (isConnected
                            ? s.yourIpIsHidden
                            : s.securityLevelHigh)
                        : s.emptyStateSubtitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isConnected
                          ? theme.colorScheme.primary.withValues(alpha: 0.8)
                          : theme.textTheme.bodyMedium?.color
                              ?.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (Platform.isWindows) ...[
                    _buildModeToggle(context, appState),
                    const SizedBox(height: 24),
                  ],
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        if (!hasServer) {
                          _goToServers(context);
                        } else {
                          appState.toggleConnection();
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isConnected
                                  ? theme.colorScheme.primary
                                      .withValues(alpha: 0.12)
                                  : theme.colorScheme.surface,
                              border: Border.all(
                                color: isConnected
                                    ? theme.colorScheme.primary
                                    : theme.dividerTheme.color ??
                                        theme.colorScheme.onSurface
                                            .withValues(alpha: 0.15),
                                width: 2,
                              ),
                              boxShadow: isConnected
                                  ? [
                                      BoxShadow(
                                        color: theme.colorScheme.primary
                                            .withValues(alpha: 0.25),
                                        blurRadius: 32,
                                        spreadRadius: 6,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                                width: hasServer ? 120 : 110,
                                height: hasServer ? 120 : 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isConnected
                                      ? theme.colorScheme.primary
                                      : hasServer
                                          ? const Color(0xFF3A3A3C)
                                          : theme.colorScheme.surface,
                                ),
                                child: Center(
                                  child: AnimatedSwitcher(
                                    duration:
                                        const Duration(milliseconds: 250),
                                    transitionBuilder: (child, animation) {
                                      return ScaleTransition(
                                        scale: animation,
                                        child: child,
                                      );
                                    },
                                    child: isConnecting
                                        ? const SizedBox(
                                            width: 32,
                                            height: 32,
                                            child:
                                                CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 3,
                                            ),
                                          )
                                        : Icon(
                                            _mainButtonIcon(appState),
                                            key: ValueKey<bool>(hasServer),
                                            size: hasServer ? 48 : 40,
                                            color: Colors.white,
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AnimatedOpacity(
                    opacity: isConnected ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: isConnected
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatItem(
                                context,
                                s.ping,
                                '${appState.ping} ms',
                                Icons.network_check,
                              ),
                              _buildStatItem(
                                context,
                                s.download,
                                appState.downloadSpeed,
                                Icons.download,
                              ),
                              _buildStatItem(
                                context,
                                s.upload,
                                appState.uploadSpeed,
                                Icons.upload,
                              ),
                            ],
                          )
                        : const SizedBox(height: 52),
                  ),
                  const SizedBox(height: 20),
                  if (!hasServer) ...[
                    _buildTrustInfo(context),
                    const SizedBox(height: 20),
                  ],
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          CupertinoPageRoute<void>(
                            builder: (context) => const ServersScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color ??
                              theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.dividerTheme.color ??
                                theme.colorScheme.onSurface
                                    .withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    server != null
                                        ? s.selectedServer
                                        : s.noServer,
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontSize: 11),
                                  ),
                                  const SizedBox(height: 2),
                                  if (server != null)
                                    Text(
                                      server.name,
                                      style: theme.textTheme.titleLarge
                                          ?.copyWith(fontSize: 15),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                            if (server != null)
                              IconButton(
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
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            if (appState.lastError != null)
              Positioned(
                bottom: 12,
                left: 16,
                right: 16,
                child: _ErrorBanner(message: appState.lastError!),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModePill extends StatelessWidget {
  const _ModePill({
    required this.label,
    required this.icon,
    required this.active,
    required this.theme,
  });

  final String label;
  final IconData icon;
  final bool active;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: active ? theme.colorScheme.primary : null,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: active
                ? Colors.white
                : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: active
                  ? Colors.white
                  : theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
              fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.error,
            color: theme.colorScheme.error,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontSize: 12,
                height: 1.3,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Clipboard.setData(ClipboardData(text: message)),
            child: Icon(
              Icons.content_copy,
              color: theme.colorScheme.error,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => AppState.of(context, listen: false).clearError(),
            child: Icon(
              Icons.close,
              color: theme.colorScheme.error,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }
}
