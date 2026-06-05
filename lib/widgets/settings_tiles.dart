import 'package:flutter/material.dart';

/// A reusable section header for settings screens.
Widget buildSettingsSectionHeader(ThemeData theme, String title) {
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

/// A standard clickable list tile with an icon, title, and optional trailing text.
Widget buildSettingsListTile(
  ThemeData theme,
  String title,
  IconData icon, {
  String? trailingText,
  required VoidCallback onTap,
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
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
            ),
          ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: theme.iconTheme.color?.withValues(alpha: 0.3),
        ),
      ],
    ),
    onTap: onTap,
  );
}

/// A switch tile for settings screens.
Widget buildSettingsSwitchTile(
  ThemeData theme,
  String title,
  IconData icon,
  bool value,
  ValueChanged<bool> onChanged,
) {
  return ListTile(
    onTap: () => onChanged(!value),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    leading: Icon(icon, color: theme.iconTheme.color),
    title: Text(title, style: theme.textTheme.bodyLarge),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      thumbColor: WidgetStateProperty.all(Colors.white),
      trackColor: WidgetStateProperty.all(
        value
            ? theme.colorScheme.primary.withValues(alpha: 0.5)
            : theme.colorScheme.surfaceContainerHighest,
      ),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
    ),
  );
}

/// A dimmed (disabled) list tile used for stub settings.
Widget buildSettingsDisabledListTile(
  ThemeData theme,
  String title,
  IconData icon, {
  String? trailingText,
}) {
  final dimColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35);
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    leading: Icon(icon, color: dimColor),
    title: Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(color: dimColor),
    ),
    trailing: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (trailingText != null)
          Text(
            trailingText,
            style: theme.textTheme.bodyMedium?.copyWith(color: dimColor),
          ),
        const SizedBox(width: 8),
        Icon(
          Icons.chevron_right,
          size: 16,
          color: dimColor,
        ),
      ],
    ),
  );
}

/// A dimmed (disabled) switch tile used for stub settings.
Widget buildSettingsDisabledSwitchTile(
  ThemeData theme,
  String title,
  IconData icon,
  bool value,
) {
  final dimColor = theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.35);
  return ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
    leading: Icon(icon, color: dimColor),
    title: Text(
      title,
      style: theme.textTheme.bodyLarge?.copyWith(color: dimColor),
    ),
    trailing: Switch(value: value, onChanged: null),
  );
}
