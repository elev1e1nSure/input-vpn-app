import 'package:flutter/material.dart';
import 'package:vpn/config_type.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
class AddConfigScreen extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const AddConfigScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<AddConfigScreen> createState() {
    return _AddConfigScreenState();
  }
}

@NowaGenerated()
class _AddConfigScreenState extends State<AddConfigScreen> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _configController = TextEditingController();

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildTextField(
    ThemeData theme,
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.dividerTheme.color ??
                  theme.colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    final appState = AppState.of(context, listen: false);
    appState.addConfig(
      _nameController.text,
      _configController.text,
      ConfigType.vless,
    );
    widget.onBack();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = AppStrings.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: IconButton(
                    icon: const Icon(CupertinoIcons.back),
                    onPressed: widget.onBack,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  s.addConfiguration,
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _nameController,
                  builder: (context, nameValue, child) {
                    return ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _configController,
                      builder: (context, configValue, child) {
                        final bool canAdd = nameValue.text.isNotEmpty &&
                            configValue.text.isNotEmpty;
                        return MouseRegion(
                          cursor: canAdd ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
                          child: IconButton(
                            icon: Icon(
                              CupertinoIcons.checkmark_alt,
                              color: canAdd
                                  ? theme.colorScheme.primary
                                  : theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.3),
                            ),
                            onPressed: canAdd ? () => _submit(context) : null,
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(theme, s.displayName),
                  _buildTextField(
                    theme,
                    _nameController,
                    s.displayNameHint,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildActionChip(
                        icon: CupertinoIcons.arrow_down_doc,
                        label: s.importFromFile,
                        onTap: () {
                          // TODO: implement file import
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('File import coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildActionChip(
                        icon: CupertinoIcons.qrcode,
                        label: s.scanQRCode,
                        onTap: () {
                          // TODO: implement QR scan
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('QR scan coming soon'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildLabel(theme, s.configOrUrl),
                  _buildTextField(
                    theme,
                    _configController,
                    'vless://user@host:443?security=tls...',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
