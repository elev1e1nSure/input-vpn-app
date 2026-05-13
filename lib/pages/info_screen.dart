import 'package:flutter/material.dart';
import 'package:nowa_runtime/nowa_runtime.dart';

@NowaGenerated()
class InfoScreen extends StatelessWidget {
  @NowaGenerated({'loader': 'auto-constructor'})
  const InfoScreen({super.key, required this.title, required this.content});

  final String title;

  final String content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Text(
          content,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
        ),
      ),
    );
  }
}
