import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/ride_model.dart';
import '../models/social_post_model.dart';

/// Service for sharing rides and posts with deep links
class ShareService {
  // Custom URL scheme for deep links - opens the app directly
  // Format: marketplace://shared/ride/{rideId}
  static const String appScheme = 'marketplace://';

  // Web fallback URL (for users without the app installed)
  static const String webFallback = 'https://marketplace.app';

  /// Generate a shareable link for a ride
  /// Uses custom scheme for direct app opening
  static String generateRideLink(String rideId) {
    return '${appScheme}shared/ride/$rideId';
  }

  /// Generate a shareable link for a post
  static String generatePostLink(String postId) {
    return '${appScheme}shared/post/$postId';
  }

  /// Generate ride share text with all relevant details
  static String generateRideShareText(RideModel ride) {
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    final buffer = StringBuffer();
    buffer.writeln('🚗 Ride Share Invitation');
    buffer.writeln('');
    buffer.writeln('📍 From: ${ride.startingPoint}');
    buffer.writeln('📍 To: ${ride.destination}');
    buffer.writeln('');
    buffer.writeln('📅 Date: ${dateFormat.format(ride.rideDateTime)}');
    buffer.writeln('⏰ Time: ${timeFormat.format(ride.rideDateTime)}');
    buffer.writeln('');
    buffer.writeln('👤 Organized by: ${ride.creatorName}');
    buffer.writeln(
      '💺 Seats Available: ${ride.availableSeats}/${ride.totalSeats}',
    );

    // Gender preference
    if (ride.genderPreference != GenderPreference.any) {
      final genderText = ride.genderPreference == GenderPreference.male
          ? '👨 Male Only'
          : '👩 Female Only';
      buffer.writeln('🚻 $genderText');
    }

    buffer.writeln('');
    buffer.writeln('Join the ride 👇');
    buffer.writeln(generateRideLink(ride.id));

    return buffer.toString();
  }

  /// Generate post share text
  static String generatePostShareText(SocialPost post) {
    final buffer = StringBuffer();
    buffer.writeln('📱 Check out this post on Marketplace!');
    buffer.writeln('');
    buffer.writeln('👤 Posted by: ${post.authorName}');

    if (post.textContent != null && post.textContent!.isNotEmpty) {
      // Truncate long text
      final content = post.textContent!.length > 100
          ? '${post.textContent!.substring(0, 100)}...'
          : post.textContent!;
      buffer.writeln('');
      buffer.writeln('"$content"');
    }

    buffer.writeln('');
    buffer.writeln('❤️ ${post.likes} likes · 💬 ${post.commentCount} comments');
    buffer.writeln('');
    buffer.writeln('View the full post 👇');
    buffer.writeln(generatePostLink(post.id));

    return buffer.toString();
  }

  /// Share a ride via system share dialog
  static Future<void> shareRide(RideModel ride, {BuildContext? context}) async {
    final shareText = generateRideShareText(ride);

    await Share.share(
      shareText,
      subject: '🚗 Ride from ${ride.startingPoint} to ${ride.destination}',
    );
  }

  /// Share a post via system share dialog
  static Future<void> sharePost(
    SocialPost post, {
    BuildContext? context,
  }) async {
    final shareText = generatePostShareText(post);

    await Share.share(
      shareText,
      subject: '📱 Post by ${post.authorName} on Marketplace',
    );
  }

  /// Copy ride link to clipboard
  static Future<void> copyRideLink(RideModel ride, BuildContext context) async {
    final link = generateRideLink(ride.id);
    await Clipboard.setData(ClipboardData(text: link));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Copy post link to clipboard
  static Future<void> copyPostLink(
    SocialPost post,
    BuildContext context,
  ) async {
    final link = generatePostLink(post.id);
    await Clipboard.setData(ClipboardData(text: link));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Link copied to clipboard!'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Show share bottom sheet with options
  static void showShareBottomSheet({
    required BuildContext context,
    required String title,
    required String shareText,
    required String link,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Share',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ),

              // Share Options
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ShareOption(
                      icon: Icons.share,
                      label: 'Share',
                      color: const Color(0xFF6366F1),
                      onTap: () {
                        Navigator.pop(context);
                        Share.share(shareText, subject: title);
                      },
                    ),
                    _ShareOption(
                      icon: Icons.copy,
                      label: 'Copy Link',
                      color: const Color(0xFF22C55E),
                      onTap: () async {
                        await Clipboard.setData(ClipboardData(text: link));
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Link copied!'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    _ShareOption(
                      icon: Icons.message,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        Navigator.pop(context);
                        // WhatsApp sharing via URL scheme
                        Share.share(shareText, subject: title);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget for share option in bottom sheet
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
