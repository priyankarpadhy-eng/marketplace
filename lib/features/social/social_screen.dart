import 'package:flutter/material.dart';
import '../../core/theme/uber_money_theme.dart';

import 'create_post_screen.dart';

class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: const Text('Social Feed'),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (context, index) {
          final color = UberMoneyTheme
              .vibrantColors[index % UberMoneyTheme.vibrantColors.length];

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: UberMoneyTheme.shadowSmall,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(2), // Border width
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [color, color.withOpacity(0.5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.white,
                          radius: 20,
                          child: Icon(Icons.person, color: color),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'User $index',
                            style: UberMoneyTheme.titleMedium,
                          ),
                          Text('@user$index', style: UberMoneyTheme.caption),
                        ],
                      ),
                      const Spacer(),
                      Icon(Icons.more_horiz, color: UberMoneyTheme.textMuted),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image,
                        size: 48,
                        color: color.withOpacity(0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Just experiencing the #colorful life! 🎨',
                    style: UberMoneyTheme.bodyLarge,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.favorite_border, color: color),
                      const SizedBox(width: 4),
                      Text(
                        '${index * 50 + 20}',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 24),
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: UberMoneyTheme.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text('${index * 5}', style: UberMoneyTheme.caption),
                      const Spacer(),
                      const Icon(
                        Icons.share_outlined,
                        color: UberMoneyTheme.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const CreatePostScreen()),
          );
        },
        backgroundColor: UberMoneyTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
