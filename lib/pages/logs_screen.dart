import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:input_vpn/services/app_logger.dart';

/// Full-featured debug log page.
///
/// Shows two tabs:
///   • Events — app.log (written by [AppLogger])
///   • sing-box — sing-box.log (raw VPN engine output)
///
/// Auto-refreshes every 2 s while the page is visible.
/// Toolbar: Copy, Save, Clear (Events tab only).
class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _eventsScroll = ScrollController();
  final _singboxScroll = ScrollController();

  String _eventsText = '';
  String _singboxText = '';
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _load();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _load());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _tabs.dispose();
    _eventsScroll.dispose();
    _singboxScroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final events = await AppLogger.readAll();
    final singbox = await _readSingboxLog();
    if (!mounted) return;
    setState(() {
      _eventsText = events;
      _singboxText = singbox;
    });
    // Auto-scroll to bottom.
    _scrollToBottom(_eventsScroll);
    _scrollToBottom(_singboxScroll);
  }

  Future<String> _readSingboxLog() async {
    try {
      final base = await getApplicationSupportDirectory();
      final f = File(p.join(base.path, 'singbox', 'sing-box.log'));
      if (!f.existsSync()) return '';
      return await f.readAsString();
    } catch (e) {
      return '<read error: $e>';
    }
  }

  void _scrollToBottom(ScrollController ctrl) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ctrl.hasClients) {
        ctrl.animateTo(
          ctrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _currentText => _tabs.index == 0 ? _eventsText : _singboxText;

  Future<void> _copyLog(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: _currentText));
    if (!context.mounted) return;
    final s = AppStrings.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(s.logsCopied),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _saveLog(BuildContext context) async {
    try {
      final base = await getApplicationSupportDirectory();
      final dir = Directory(p.join(base.path, 'singbox'));
      final tag = _tabs.index == 0 ? 'events' : 'singbox';
      final ts = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final file = File(p.join(dir.path, 'log_${tag}_$ts.txt'));
      await file.writeAsString(_currentText);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _clearLog(BuildContext context) async {
    await AppLogger.clear();
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(s.logs),
        bottom: TabBar(
          controller: _tabs,
          onTap: (_) => _load(),
          tabs: [
            Tab(text: s.logsEvents),
            Tab(text: s.logsSingbox),
          ],
        ),
        actions: [
          // Copy
          Tooltip(
            message: s.copyLog,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: IconButton(
                icon: const Icon(Icons.copy, size: 20),
                onPressed: () => _copyLog(context),
              ),
            ),
          ),
          // Save to file
          Tooltip(
            message: s.saveLog,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: IconButton(
                icon: const Icon(Icons.save, size: 20),
                onPressed: () => _saveLog(context),
              ),
            ),
          ),
          // Clear (events only)
          if (_tabs.index == 0)
            Tooltip(
              message: s.clearLog,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () => _clearLog(context),
                ),
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _LogView(
            text: _eventsText,
            scrollController: _eventsScroll,
            emptyMessage: s.logsEmpty,
          ),
          _LogView(
            text: _singboxText,
            scrollController: _singboxScroll,
            emptyMessage: s.logsEmpty,
          ),
        ],
      ),
    );
  }
}

class _LogView extends StatelessWidget {
  const _LogView({
    required this.text,
    required this.scrollController,
    required this.emptyMessage,
  });

  final String text;
  final ScrollController scrollController;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (text.trim().isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
    }

    final lines = text.split('\n');

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: ListView.builder(
        controller: scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: lines.length,
        itemBuilder: (context, i) {
          final line = lines[i];
          return _LogLine(line: line, theme: theme);
        },
      ),
    );
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.line, required this.theme});

  final String line;
  final ThemeData theme;

  Color _lineColor() {
    final upper = line.toUpperCase();
    if (upper.contains('ERROR') || upper.contains('FATAL')) {
      return Colors.red.shade300;
    }
    if (upper.contains('WARN')) {
      return Colors.orange.shade300;
    }
    return theme.colorScheme.onSurface.withValues(alpha: 0.75);
  }

  @override
  Widget build(BuildContext context) {
    if (line.isEmpty) return const SizedBox(height: 4);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Text(
        line,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11.5,
          height: 1.5,
          color: _lineColor(),
        ),
      ),
    );
  }
}
