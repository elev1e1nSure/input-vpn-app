import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class SplitTunnelingScreen extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const SplitTunnelingScreen({super.key});

  @override
  State<SplitTunnelingScreen> createState() {
    return _SplitTunnelingScreenState();
  }
}

@NowaGenerated()
class _SplitTunnelingScreenState extends State<SplitTunnelingScreen> {
  bool app1 = false;

  bool app2 = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Split Tunneling')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'Select apps that will bypass the VPN connection.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SwitchListTile(
            title: Text('Browser', style: theme.textTheme.bodyLarge),
            value: app1,
            onChanged: (v) => setState(() => app1 = v),
          ),
          SwitchListTile(
            title: Text('Banking App', style: theme.textTheme.bodyLarge),
            value: app2,
            onChanged: (v) => setState(() => app2 = v),
          ),
        ],
      ),
    );
  }
}
