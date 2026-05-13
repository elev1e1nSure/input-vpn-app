import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/globals/themes.dart';
import 'package:vpn/pages/split_tunneling_screen.dart';

@NowaGenerated()
class SettingsScreen extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() {
    return _SettingsScreenState();
  }
}

@NowaGenerated()
class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context, listen: true);
    final bool isDark = theme.brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          _buildSectionHeader(theme, 'ACCOUNT'),
          _buildListTile(
            theme,
            'Premium Status',
            CupertinoIcons.star_fill,
            trailingText: appState.isPremium ? 'Active' : 'Inactive',
            onTap: () => _showPremiumDialog(context, appState),
          ),
          _buildListTile(
            theme,
            'Manage Subscription',
            CupertinoIcons.creditcard,
            onTap: () => _showManageSubscription(context),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'CONNECTION'),
          _buildListTile(
            theme,
            'VPN Protocol',
            CupertinoIcons.shield_lefthalf_fill,
            trailingText: appState.vpnProtocol,
            onTap: () => _showProtocolDialog(context, appState),
          ),
          _buildSwitchTile(
            theme,
            'Kill Switch',
            CupertinoIcons.lock_shield,
            appState.killSwitch,
            (val) => appState.setKillSwitch(val),
          ),
          _buildSwitchTile(
            theme,
            'Connect on Boot',
            CupertinoIcons.power,
            appState.connectOnBoot,
            (val) => appState.setConnectOnBoot(val),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'APPEARANCE'),
          _buildSwitchTile(
            theme,
            'Dark Mode',
            CupertinoIcons.moon_fill,
            isDark,
            (val) {
              appState.changeTheme(val ? darkTheme : lightTheme);
            },
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'ADVANCED'),
          _buildListTile(
            theme,
            'Split Tunneling',
            CupertinoIcons.arrow_branch,
            onTap: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const SplitTunnelingScreen()),
            ),
          ),
          _buildListTile(
            theme,
            'Custom DNS',
            CupertinoIcons.globe,
            trailingText: appState.customDns,
            onTap: () => _showDnsDialog(context, appState),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(theme, 'ABOUT'),
          _buildListTile(
            theme,
            'Help & Support',
            CupertinoIcons.question_circle,
            onTap: () => _showHelpDialog(context),
          ),
          _buildListTile(
            theme,
            'Privacy Policy',
            CupertinoIcons.doc_text,
            onTap: () => _showPrivacyDialog(context),
          ),
          _buildListTile(
            theme,
            'Version',
            CupertinoIcons.info_circle,
            trailingText: '1.0.2',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildListTile(
    ThemeData theme,
    String title,
    IconData icon, {
    String? trailingText,
    required void Function() onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodyMedium?.color?.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            CupertinoIcons.chevron_forward,
            size: 16,
            color: theme.iconTheme.color?.withValues(alpha: 0.3),
          ),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
    ThemeData theme,
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      onTap: () => onChanged(!value),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
      leading: Icon(icon, color: theme.iconTheme.color),
      title: Text(title, style: theme.textTheme.bodyLarge),
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }

  void _showPremiumDialog(BuildContext context, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Premium Status'),
        content: Text(
          appState.isPremium
              ? 'Your premium subscription is active. Do you want to mock downgrading to free?'
              : 'You are on a free plan. Mock upgrading to premium?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              appState.togglePremium();
              Navigator.pop(ctx);
            },
            child: Text(appState.isPremium ? 'Downgrade' : 'Upgrade'),
          ),
        ],
      ),
    );
  }

  void _showManageSubscription(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Manage Subscription',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueAccent),
                color: Colors.blueAccent.withValues(alpha: 0.1),
              ),
              child: const Column(
                children: const [
                  Text(
                    'Pro Plan - \$9.99/mo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Next billing date: Jan 15, 2026',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel Subscription',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showProtocolDialog(BuildContext context, AppState appState) {
    final protocols = [
      'WireGuard',
      'OpenVPN (UDP)',
      'OpenVPN (TCP)',
      'IKEv2',
      'VLESS',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Protocol'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: protocols
              .map(
                (p) => ListTile(
                  title: Text(p),
                  trailing: appState.vpnProtocol == p
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Colors.blue,
                        )
                      : null,
                  onTap: () {
                    appState.setVpnProtocol(p);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showDnsDialog(BuildContext context, AppState appState) {
    final dnsList = [
      'Default',
      'Cloudflare (1.1.1.1)',
      'Google (8.8.8.8)',
      'AdGuard (94.140.14.14)',
    ];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Custom DNS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: dnsList
              .map(
                (d) => ListTile(
                  title: Text(d),
                  trailing: appState.customDns == d
                      ? const Icon(
                          CupertinoIcons.checkmark_alt,
                          color: Colors.blue,
                        )
                      : null,
                  onTap: () {
                    appState.setCustomDns(d);
                    Navigator.pop(ctx);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Help & Support'),
        content: const Text(
          'For support inquiries, please contact us at support@examplevpn.com or visit our knowledge base on the website.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'We take your privacy seriously. We maintain a strict no-logs policy, meaning we do not track or store any of your online activities. Your data remains encrypted and secure at all times.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
