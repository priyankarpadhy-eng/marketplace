import 'package:flutter/material.dart';
import '../../core/theme/uber_money_theme.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Activity'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No recent activity', style: UberMoneyTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
