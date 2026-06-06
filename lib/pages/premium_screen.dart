import 'package:flutter/material.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Subscription')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Premium Active',
              style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
            ),
            const SizedBox(height: 12),
            Text(
              'You have access to all servers and features.',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
