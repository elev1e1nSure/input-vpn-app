import 'package:flutter/material.dart';
import 'package:input_vpn/globals/app_state.dart';
import 'package:input_vpn/l10n/app_strings.dart';
import 'package:input_vpn/models/custom_dns_profile.dart';

class CustomDnsScreen extends StatefulWidget {
  const CustomDnsScreen({super.key});

  @override
  State<CustomDnsScreen> createState() => _CustomDnsScreenState();
}

class _CustomDnsScreenState extends State<CustomDnsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    final appState = AppState.of(context);
    final profiles = appState.customDnsProfiles;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(s.customDnsProfilesTitle)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showEditor(appState, s),
        child: const Icon(Icons.add),
      ),
      body: profiles.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  s.customDnsEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodyMedium?.color
                        ?.withValues(alpha: 0.7),
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(profile.name),
                    subtitle: Text(profile.servers.join(', ')),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () =>
                                _showEditor(appState, s, profile: profile),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _confirmDelete(appState, s, profile),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showEditor(AppState appState, AppStrings s,
      {CustomDnsProfile? profile}) {
    final nameCtrl = TextEditingController(text: profile?.name ?? '');
    final primaryCtrl = TextEditingController(text: profile?.primary ?? '');
    final secondaryCtrl = TextEditingController(text: profile?.secondary ?? '');
    String? error;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                profile == null ? s.add : s.editConfiguration,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: s.displayName),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: primaryCtrl,
                decoration: InputDecoration(labelText: s.primaryDns),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: secondaryCtrl,
                decoration: InputDecoration(labelText: s.secondaryDns),
                keyboardType: TextInputType.url,
              ),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.cancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = nameCtrl.text.trim();
                      final primary = primaryCtrl.text.trim();
                      if (name.isEmpty || primary.isEmpty) {
                        setModalState(() {
                          error = s.unexpectedError;
                        });
                        return;
                      }
                      final secondary = secondaryCtrl.text.trim();
                      final newProfile = CustomDnsProfile(
                        id: profile?.id ??
                            DateTime.now().millisecondsSinceEpoch.toString(),
                        name: name,
                        primary: primary,
                        secondary: secondary.isEmpty ? null : secondary,
                      );
                      appState.saveCustomDnsProfile(newProfile);
                      Navigator.pop(context);
                    },
                    child: Text(s.save),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      AppState appState, AppStrings s, CustomDnsProfile profile) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.delete),
        content: Text(profile.name),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () {
              appState.deleteCustomDnsProfile(profile.id);
              Navigator.pop(ctx);
            },
            child: Text(s.delete),
          ),
        ],
      ),
    );
  }
}
