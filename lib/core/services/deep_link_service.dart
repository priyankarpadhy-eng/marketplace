import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Service to handle deep links from shared URLs
/// Supports: marketplace://shared/ride/{rideId}
///           marketplace://shared/post/{postId}
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  BuildContext? _context;

  /// Initialize deep link handling
  Future<void> initialize(BuildContext context) async {
    _context = context;
    _appLinks = AppLinks();

    // Handle link when app is already running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('Deep link received (running): $uri');
      _handleDeepLink(uri);
    });

    // Handle link that opened the app
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('Deep link received (initial): $initialUri');
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial deep link: $e');
    }
  }

  /// Update context (call this when context changes)
  void updateContext(BuildContext context) {
    _context = context;
  }

  /// Handle incoming deep link
  void _handleDeepLink(Uri uri) {
    if (_context == null) {
      debugPrint('No context available for deep link navigation');
      return;
    }

    final path = uri.path;
    final pathSegments = uri.pathSegments;

    debugPrint('Deep link path: $path');
    debugPrint('Deep link segments: $pathSegments');

    // Handle: marketplace://shared/ride/{rideId}
    if (pathSegments.length >= 2 && pathSegments[0] == 'shared') {
      if (pathSegments[1] == 'ride' && pathSegments.length >= 3) {
        final rideId = pathSegments[2];
        debugPrint('Navigating to shared ride: $rideId');
        _context!.go('/shared/ride/$rideId');
        return;
      }

      // Handle: marketplace://shared/post/{postId}
      if (pathSegments[1] == 'post' && pathSegments.length >= 3) {
        final postId = pathSegments[2];
        debugPrint('Navigating to shared post: $postId');
        _context!.go('/shared/post/$postId');
        return;
      }
    }

    // Fallback: go to home
    debugPrint('Unknown deep link, going to home');
    _context!.go('/ride');
  }

  /// Dispose subscription
  void dispose() {
    _linkSubscription?.cancel();
  }
}
