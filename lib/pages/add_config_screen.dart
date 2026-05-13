import 'package:flutter/material.dart';
import 'package:vpn/config_type.dart';
import 'package:nowa_runtime/nowa_runtime.dart';
import 'package:flutter/cupertino.dart';
import 'package:vpn/globals/app_state.dart';
import 'package:vpn/l10n/app_strings.dart';

@NowaGenerated()
class AddConfigScreen extends StatefulWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const AddConfigScreen({super.key});

  @override
  State<AddConfigScreen> createState() {
    return _AddConfigScreenState();
  }
}

@NowaGenerated()
class _AddConfigScreenState extends State<AddConfigScreen> {
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _configController = TextEditingController();

  ConfigType _selectedType = ConfigType.vless;

  Widget _buildLabel(ThemeData theme, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.bold,
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

  Widget _buildTypeItem(ConfigType type, String label) {
    final theme = Theme.of(context);
    final isSelected = _selectedType == type;
    return ListTile(
      onTap: () => setState(() => _selectedType = type),
      title: Text(label, style: theme.textTheme.bodyLarge),
      trailing: isSelected
          ? Icon(CupertinoIcons.checkmark_alt, color: theme.colorScheme.primary)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appState = AppState.of(context, listen: false);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(AppStrings.of(context).addConfiguration),
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            AppStrings.of(context).cancel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _nameController,
            builder: (context, nameValue, child) {
              return ValueListenableBuilder<TextEditingValue>(
                valueListenable: _configController,
                builder: (context, configValue, child) {
                  final bool canAdd = nameValue.text.isNotEmpty &&
                      configValue.text.isNotEmpty;
                  return TextButton(
                    onPressed: canAdd
                        ? () {
                            appState.addConfig(
                              _nameController.text,
                              _configController.text,
                              _selectedType,
                            );
                            Navigator.pop(context);
                          }
                        : null,
                    child: Text(
                      AppStrings.of(context).add,
                      style: TextStyle(
                        color: canAdd
                            ? theme.colorScheme.primary
                            : theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.3),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel(theme, AppStrings.of(context).displayName),
            _buildTextField(theme, _nameController, AppStrings.of(context).displayNameHint),
            const SizedBox(height: 24),
            _buildLabel(theme, AppStrings.of(context).type),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildTypeItem(ConfigType.vless, AppStrings.of(context).vlessVmessSs),
                  Divider(
                    height: 1,
                    color: theme.dividerTheme.color,
                    indent: 16,
                  ),
                  _buildTypeItem(ConfigType.subscription, AppStrings.of(context).subscriptionUrl),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildLabel(theme, AppStrings.of(context).configOrUrl),
            _buildTextField(
              theme,
              _configController,
              AppStrings.of(context).configOrUrl,
              maxLines: 5,
            ),
            const SizedBox(height: 40),
            Center(
              child: Text(
                AppStrings.of(context).supportedFormats,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  color: theme.textTheme.bodyMedium?.color?.withValues(
                    alpha: 0.5,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
