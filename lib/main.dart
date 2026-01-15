import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app_links/app_links.dart';
// --- ADDED THESE TWO IMPORTS ---
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
// -------------------------------
// -------------------------------

import 'core/theme/uber_money_theme.dart';
import 'core/services/push_notification_service.dart';
import 'firebase_options.dart';
import 'router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONCE (Removed the duplicate call)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Set up background message handler (must be before any other FCM code)
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // --- THE FIX FOR PHONE AUTH ERROR ---
  // This tells Firebase: "I am testing locally, stop asking for Play Integrity"
  if (kDebugMode) {
    try {
      await FirebaseAuth.instance.setSettings(
        appVerificationDisabledForTesting: true,
      );
      debugPrint("⚠️ Phone Auth Verification Disabled for Testing");
    } catch (e) {
      debugPrint("Error disabling verification: $e");
    }
  }
  // ------------------------------------

  // Initialize Push Notifications (skip on web for now)
  if (!kIsWeb) {
    await PushNotificationService().initialize();
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: UberMoneyTheme.backgroundPrimary,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const ProviderScope(child: MarketplaceApp()));
}

class MarketplaceApp extends ConsumerStatefulWidget {
  const MarketplaceApp({super.key});

  @override
  ConsumerState<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends ConsumerState<MarketplaceApp> {
  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,
      theme: UberMoneyTheme.themeData,
      routerConfig: router,
      builder: (context, child) {
        // Initialize deep link handling after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _initializeDeepLinks(context);
        });
        return child ?? const SizedBox.shrink();
      },
    );
  }

  bool _deepLinksInitialized = false;

  void _initializeDeepLinks(BuildContext context) async {
    if (_deepLinksInitialized) return;
    _deepLinksInitialized = true;

    // Import and use app_links for deep linking
    try {
      final appLinks = AppLinks();

      // Handle link that opened the app (cold start)
      final initialLink = await appLinks.getInitialLink();
      if (initialLink != null && context.mounted) {
        _handleDeepLink(initialLink, context);
      }

      // Handle links while app is running (warm start)
      appLinks.uriLinkStream.listen((uri) {
        if (context.mounted) {
          _handleDeepLink(uri, context);
        }
      });
    } catch (e) {
      debugPrint('Deep link initialization error: $e');
    }
  }

  void _handleDeepLink(Uri uri, BuildContext context) {
    debugPrint('Deep link received: $uri');
    final pathSegments = uri.pathSegments;

    // Handle: marketplace://shared/ride/{rideId}
    if (pathSegments.length >= 2 && pathSegments[0] == 'shared') {
      if (pathSegments[1] == 'ride' && pathSegments.length >= 3) {
        final rideId = pathSegments[2];
        debugPrint('Navigating to shared ride: $rideId');
        ref.read(routerProvider).go('/shared/ride/$rideId');
        return;
      }

      // Handle: marketplace://shared/post/{postId}
      if (pathSegments[1] == 'post' && pathSegments.length >= 3) {
        final postId = pathSegments[2];
        debugPrint('Navigating to shared post: $postId');
        ref.read(routerProvider).go('/shared/post/$postId');
        return;
      }
    }
  }
}
