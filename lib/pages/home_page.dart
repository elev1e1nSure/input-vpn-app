import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/pages/settings_screen.dart';
import 'package:input_vpn/pages/servers_screen.dart';
import 'package:input_vpn/pages/add_config_screen.dart';
import 'package:input_vpn/pages/logs_screen.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:window_manager/window_manager.dart';
import 'package:input_vpn/services/network_utils.dart';
import 'package:input_vpn/services/tray_manager.dart';
import 'package:input_vpn/functions/country_code_to_emoji.dart';
import 'package:input_vpn/models/connection_status.dart';
import 'package:input_vpn/models/vpn_stats.dart';
import 'package:input_vpn/vpn_server.dart';
import 'package:provider/provider.dart';

@NowaGenerated()
class HomePage extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WindowListener {
  int _selectedIndex = 0;
  bool _sidebarExpanded = true;
  bool _trayInitialized = false;
  VpnServer? _editingServer;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && Platform.isWindows) {
      try {
        windowManager.addListener(this);
        final appState = AppState.of(context, listen: false);
        if (appState.minimizeToTray) {
          TrayManager.init(appState);
          _trayInitialized = true;
        }
        // Listen to minimizeToTray changes
        appState.addListener(_onMinimizeToTrayChanged);
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isWindows) {
      try {
        windowManager.removeListener(this);
        AppState.of(context, listen: false).removeListener(_onMinimizeToTrayChanged);
        if (_trayInitialized) {
          TrayManager.destroy();
        }
      } catch (_) {}
    }
    super.dispose();
  }

  void _onMinimizeToTrayChanged() {
    final appState = AppState.of(context, listen: false);
    if (!kIsWeb && Platform.isWindows) {
      if (appState.minimizeToTray && !_trayInitialized) {
        TrayManager.init();
        _trayInitialized = true;
      } else if (!appState.minimizeToTray && _trayInitialized) {
        TrayManager.destroy();
        _trayInitialized = false;
      }
    }
  }

  @override
  void onWindowClose() async {
    final appState = AppState.of(context, listen: false);
    debugPrint('onWindowClose triggered, minimizeToTray=${appState.minimizeToTray}');

    if (appState.minimizeToTray) {
      try {
        await windowManager.hide();
        debugPrint('Window hidden to tray, VPN remains connected');
      } catch (e) {
        debugPrint('onWindowClose: hide error: $e');
      }
      return;
    }

    // Disconnect VPN with a hard timeout so the app never hangs on close.
    if (appState.isConnected) {
      debugPrint('onWindowClose: disconnecting VPN...');
      try {
        await appState.toggleConnection().timeout(const Duration(seconds: 10));
      } catch (e) {
        debugPrint('onWindowClose: disconnect failed or timed out ($e), forcing cleanup');
        // Best-effort fallback: remove the TUN adapter and reset DNS.
        await NetworkUtils.globalCleanup();
      }
    }

    // Always destroy the window — even if disconnect above failed.
    debugPrint('onWindowClose: destroying window');
    try {
      await windowManager.destroy();
    } catch (e) {
      debugPrint('onWindowClose: destroy error: $e');
    }
  }

  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _HomeTab(onSwitchToServers: () => setState(() => _selectedIndex = 1));
      case 1:
        return ServersScreen(
          onSwitchToAddConfig: () => setState(() => _selectedIndex = 3),
          onServerSelected: () => setState(() => _selectedIndex = 0),
          onBack: () => setState(() => _selectedIndex = 0),
          onEditServer: (server) {
            setState(() {
              _editingServer = server;
              _selectedIndex = 4;
            });
          },
        );
      case 2:
        return const SettingsScreen();
      case 3:
        return AddConfigScreen(onBack: () => setState(() => _selectedIndex = 1));
      case 4:
        return AddConfigScreen(
          onBack: () => setState(() => _selectedIndex = 1),
          initialName: _editingServer?.name,
          initialConfig: _editingServer?.rawConfig,
          configId: _editingServer?.configId,
        );
      case 5:
        return const LogsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

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
          child: RepaintBoundary(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final positionAnimation = Tween<Offset>(
                  begin: const Offset(0.03, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));
                final scaleAnimation = Tween<double>(
                  begin: 0.97,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                ));
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: positionAnimation,
                    child: ScaleTransition(
                      scale: scaleAnimation,
                      child: child,
                    ),
                  ),
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_selectedIndex),
                child: _buildBody(),
              ),
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
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
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
              icon: Icons.article_outlined,
              label: s.logs,
              selected: selectedIndex == 5,
              onTap: () => onItemSelected(5),
            ),
            _SidebarItem(
              expanded: expanded,
              icon: Icons.settings,
              label: s.settings,
              selected: selectedIndex == 2,
              onTap: () => onItemSelected(2),
            ),
            const Spacer(),
            _SidebarStatus(expanded: expanded),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// Status dot + version label at the bottom of the sidebar.
class _SidebarStatus extends StatelessWidget {
  const _SidebarStatus({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected =
        context.select<AppState, bool>((a) => a.isConnected);
    final dotColor = isConnected
        ? const Color(0xFF34C759)
        : theme.colorScheme.onSurface.withValues(alpha: 0.25);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: AnimatedOpacity(
        opacity: expanded ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: expanded
            ? Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      boxShadow: isConnected
                          ? [BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 6)]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.45),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v1.0.5',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                    ),
                  ),
                ],
              )
            : Center(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    boxShadow: isConnected
                        ? [BoxShadow(color: dotColor.withValues(alpha: 0.6), blurRadius: 6)]
                        : null,
                  ),
                ),
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
  const _HomeTab({required this.onSwitchToServers});

  final VoidCallback onSwitchToServers;

  void _goToServers() {
    onSwitchToServers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);

    final appState = AppState.of(context, listen: false);

    final hasServer =
        context.select<AppState, bool>((a) => a.selectedServer != null);
    final isConnected =
        context.select<AppState, bool>((a) => a.isConnected);
    final isConnecting =
        context.select<AppState, bool>((a) => a.isConnecting);
    final isDisconnecting =
        context.select<AppState, bool>((a) => a.isDisconnecting);
    final isReconnecting =
        context.select<AppState, bool>((a) => a.isReconnecting);
    final reconnectAttempt =
        context.select<AppState, int>((a) => a.reconnectAttempt);

    final statusText = !hasServer
        ? s.connectInOneMinute
        : isReconnecting
            ? s.reconnecting(reconnectAttempt, 3)
            : isConnecting
                ? s.connecting
                : isDisconnecting
                    ? s.disconnecting
                    : isConnected
                        ? s.connected
                        : s.readyToConnect;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: isConnected
            ? _SessionTimer(fallback: statusText)
            : Text(statusText),
        titleTextStyle: Theme.of(context).appBarTheme.titleTextStyle,
        centerTitle: false,
        actions: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: IconButton(
              icon: const Icon(Icons.add),
              onPressed: onSwitchToServers,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 90,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      height: constraints.maxHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 8),
                          RepaintBoundary(
                            child: _ConnectButton(
                              hasServer: hasServer,
                              onTap: () {
                                if (!hasServer) {
                                  _goToServers();
                                } else {
                                  appState.toggleConnection();
                                }
                              },
                            ),
                          ),
                          if (hasServer) ...[
                            const SizedBox(height: 16),
                            const _StatsRow(),
                          ],
                          if (hasServer) ...[
                            const SizedBox(height: 8),
                            _PublicIpText(theme: theme),
                          ],
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: 12,
              left: 24,
              right: 24,
              child: _ServerCard(
                onTap: onSwitchToServers,
                theme: theme,
                s: s,
              ),
            ),
            Builder(builder: (context) {
              final error =
                  context.select<AppState, String?>((a) => a.lastError);
              if (error == null) return const SizedBox.shrink();
              return Positioned(
                bottom: 110,
                left: 16,
                right: 16,
                child: _ErrorBanner(message: error),
              );
            }),
          ],
        ),
      ),
    );
  }
}

/// Animated connect/disconnect button — isolated repaint boundary target.
/// Selects only isConnected, isConnecting, isDisconnecting, selectedServer.
class _ConnectButton extends StatelessWidget {
  const _ConnectButton({
    required this.hasServer,
    required this.onTap,
  });

  final bool hasServer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isConnected =
        context.select<AppState, bool>((a) => a.isConnected);
    final isConnecting =
        context.select<AppState, bool>((a) => a.isConnecting);
    final isDisconnecting =
        context.select<AppState, bool>((a) => a.isDisconnecting);

    IconData icon;
    if (!hasServer) {
      icon = Icons.add;
    } else if (isConnecting) {
      icon = Icons.pause;
    } else {
      icon = Icons.power_settings_new;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
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
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.colorScheme.surface,
                border: Border.all(
                  color: isConnected
                      ? theme.colorScheme.primary
                      : theme.dividerTheme.color ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.15),
                  width: 2,
                ),
                boxShadow: isConnected
                    ? [
                        BoxShadow(
                          color:
                              theme.colorScheme.primary.withValues(alpha: 0.25),
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
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (child, animation) => ScaleTransition(
                        scale: animation,
                        child: child,
                      ),
                      child: isConnecting || isDisconnecting
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                          : Icon(
                              icon,
                              key: ValueKey<bool>(hasServer),
                              size: hasServer ? 48 : 40,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Displays the current public IP — only rebuilds when publicIp changes.
class _PublicIpText extends StatelessWidget {
  const _PublicIpText({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final ip = context.select<AppState, String?>((a) => a.publicIp);
    return Text(
      ip != null ? 'IP: $ip' : 'IP: ---',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
        fontSize: 13,
      ),
    );
  }
}

/// Server card at the bottom — only rebuilds when selectedServer changes.
class _ServerCard extends StatelessWidget {
  const _ServerCard({
    required this.onTap,
    required this.theme,
    required this.s,
  });

  final VoidCallback onTap;
  final ThemeData theme;
  final AppStrings s;

  @override
  Widget build(BuildContext context) {
    final server =
        context.select<AppState, VpnServer?>((a) => a.selectedServer);
    final serverAddress =
        context.select<AppState, String?>((a) => a.selectedServerAddress);
    final selectedServerIp =
        serverAddress?.trim().isNotEmpty == true ? serverAddress!.trim() : '—';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.dividerTheme.color ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Country flag or fallback globe icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: server != null && server.flagCode.isNotEmpty
                      ? Text(
                          countryCodeToEmoji(server.flagCode),
                          style: const TextStyle(fontSize: 20),
                        )
                      : Icon(
                          Icons.public,
                          size: 20,
                          color: theme.iconTheme.color?.withValues(alpha: 0.3),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      server != null ? server.name : s.noServer,
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    if (server != null)
                      Text(
                        selectedServerIp,
                        style:
                            theme.textTheme.titleLarge?.copyWith(fontSize: 15),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Ping badge when connected
              _PingBadge(theme: theme),

            ],
          ),
        ),
      ),
    );
  }
}


/// Session timer shown in AppBar when connected.
/// Uses StreamBuilder on statusStream — no notifyListeners needed.
class _SessionTimer extends StatefulWidget {
  const _SessionTimer({required this.fallback});
  final String fallback;

  @override
  State<_SessionTimer> createState() => _SessionTimerState();
}

class _SessionTimerState extends State<_SessionTimer> {
  Timer? _tick;
  DateTime? _since;

  @override
  void initState() {
    super.initState();
    final appState = AppState.of(context, listen: false);
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Pull the connected-since time from the current status.
    appState.statusStream.listen((status) {
      if (!mounted) return;
      if (status is Connected) {
        setState(() => _since = status.since);
      } else {
        setState(() => _since = null);
      }
    });
    // Seed from current status immediately.
    final cur = appState.statusStream;
    cur.first.then((s) {
      if (!mounted) return;
      if (s is Connected) setState(() => _since = s.since);
    }).ignore();
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final since = _since;
    if (since == null) return Text(widget.fallback);
    final elapsed = DateTime.now().difference(since);
    return Text('${widget.fallback}  ·  ${_fmt(elapsed)}');
  }
}

/// Download / Upload speed row — uses StreamBuilder, zero AppState rebuilds.
class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context, listen: false);
    final isConnected = context.select<AppState, bool>((a) => a.isConnected);

    if (!isConnected) return const SizedBox.shrink();

    return StreamBuilder<VpnStats>(
      stream: appState.statsStream,
      initialData: VpnStats.empty,
      builder: (context, snap) {
        final stats = snap.data ?? VpnStats.empty;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _StatChip(
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF34C759),
              label: stats.downloadHuman,
              theme: theme,
            ),
            const SizedBox(width: 16),
            _StatChip(
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFF007AFF),
              label: stats.uploadHuman,
              theme: theme,
            ),
            if (stats.pingMs > 0) ...[
              const SizedBox(width: 16),
              _StatChip(
                icon: Icons.network_ping_rounded,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                label: '${stats.pingMs} ms',
                theme: theme,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.theme,
  });
  final IconData icon;
  final Color color;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

/// Ping indicator in server card — updates via statsStream.
class _PingBadge extends StatelessWidget {
  const _PingBadge({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final isConnected = context.select<AppState, bool>((a) => a.isConnected);
    if (!isConnected) return const SizedBox.shrink();
    final appState = AppState.of(context, listen: false);
    return StreamBuilder<VpnStats>(
      stream: appState.statsStream,
      builder: (context, snap) {
        final ping = snap.data?.pingMs ?? 0;
        if (ping <= 0) return const SizedBox.shrink();
        final color = ping < 100
            ? const Color(0xFF34C759)
            : ping < 250
                ? const Color(0xFFFF9500)
                : const Color(0xFFFF3B30);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$ping ms',
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        );
      },
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
