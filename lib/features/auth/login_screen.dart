import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/models/user_model.dart';
import '../auth/auth_controller.dart';

/// Login Screen with Uber-style design
/// Supports Google Sign In
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  void _navigateBasedOnRole() {
    final authState = ref.read(authControllerProvider);
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.role == UserRole.admin) {
        context.go('/admin');
      } else if (user.role == UserRole.shop) {
        context.go('/shop-dashboard');
      } else {
        // Designers and regular users go to the normal app
        // Designers can access their panel from Profile
        context.go('/ride');
      }
    } else {
      context.go('/ride');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Top half - Map background
          Positioned.fill(
            child: Column(
              children: [
                Expanded(flex: 5, child: _buildMapBackground()),
                Expanded(
                  flex: 5,
                  child: Container(color: UberMoneyTheme.backgroundPrimary),
                ),
              ],
            ),
          ),

          // Bottom sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: _buildLoginSheet(),
              ),
            ),
          ),

          // Logo overlay on map
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 24,
            right: 24,
            child: _buildLogoSection(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: Stack(
        children: [
          ClipRect(
            child: Opacity(
              opacity: 0.7,
              child: FlutterMap(
                options: MapOptions(
                  initialCenter: const LatLng(20.2961, 85.8245), // Bhubaneswar
                  initialZoom: 14,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.marketplace.app',
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  UberMoneyTheme.backgroundPrimary.withOpacity(0.3),
                  UberMoneyTheme.backgroundPrimary,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Logo Image
        Container(
          height: 80,
          decoration: BoxDecoration(
            borderRadius: UberMoneyTheme.borderRadiusMedium,
          ),
          child: Image.asset(
            'assets/images/app_logo.png',
            height: 80,
            fit: BoxFit.contain,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Buy, Sell, Ride',
          style: UberMoneyTheme.titleLarge.copyWith(
            color: UberMoneyTheme.textLight.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginSheet() {
    return Container(
      decoration: BoxDecoration(
        color: UberMoneyTheme.backgroundCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: UberMoneyTheme.shadowLarge,
      ),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: UberMoneyTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Text('Welcome Back', style: UberMoneyTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Sign in to continue using Marketplace',
              style: UberMoneyTheme.bodyMedium,
            ),
            const SizedBox(height: 32),

            // Web & Desktop: Google Sign-In with Popup
            if (kIsWeb || Platform.isWindows || Platform.isMacOS)
              _GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: _signInWithGooglePopup,
              ),

            // Mobile: Google Sign-In with Native Plugin
            if (!kIsWeb && !Platform.isWindows && !Platform.isMacOS)
              _GoogleSignInButton(
                isLoading: _isLoading,
                onPressed: () async {
                  setState(() => _isLoading = true);
                  final success = await ref
                      .read(authControllerProvider.notifier)
                      .signInWithGoogle();

                  if (mounted) {
                    if (success) {
                      _navigateBasedOnRole();
                    } else {
                      setState(() => _isLoading = false);
                      // Check for error state
                      final authState = ref.read(authControllerProvider);
                      if (authState is AuthError) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(authState.message)),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Google Sign-In failed or cancelled'),
                          ),
                        );
                      }
                    }
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  /// Sign in with Google for Web/Desktop (uses signInWithPopup)
  Future<void> _signInWithGooglePopup() async {
    setState(() => _isLoading = true);

    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .signInWithGooglePopup();

      if (mounted) {
        if (success) {
          _navigateBasedOnRole();
        } else {
          setState(() => _isLoading = false);
          final authState = ref.read(authControllerProvider);
          if (authState is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(authState.message)));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Google Sign-In failed: $e')));
      }
    }
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: UberMoneyTheme.primary,
            borderRadius: UberMoneyTheme.borderRadiusMedium,
            boxShadow: UberMoneyTheme.shadowMedium,
          ),
          child: widget.isLoading
              ? const Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: Text(
                          'G',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Continue with Google',
                      style: UberMoneyTheme.titleMedium.copyWith(
                        color: UberMoneyTheme.textLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Email Login Button with expandable form
class _EmailLoginButton extends ConsumerStatefulWidget {
  final bool isLoading;
  final VoidCallback onLoginSuccess;

  const _EmailLoginButton({
    required this.isLoading,
    required this.onLoginSuccess,
  });

  @override
  ConsumerState<_EmailLoginButton> createState() => _EmailLoginButtonState();
}

class _EmailLoginButtonState extends ConsumerState<_EmailLoginButton> {
  bool _isExpanded = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await ref
        .read(authControllerProvider.notifier)
        .signInWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result.success) {
        widget.onLoginSuccess();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Login failed'),
            backgroundColor: UberMoneyTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      // Show button to expand email login form
      return GestureDetector(
        onTap: widget.isLoading
            ? null
            : () => setState(() => _isExpanded = true),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: UberMoneyTheme.borderRadiusMedium,
            border: Border.all(color: UberMoneyTheme.border, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.email_outlined,
                color: UberMoneyTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sign in with Email',
                style: UberMoneyTheme.titleMedium.copyWith(
                  color: UberMoneyTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Expanded email login form
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Collapse button
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() => _isExpanded = false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: UberMoneyTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Enter your Gmail address',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: 'Enter your password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Login button
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Sign In',
                    style: UberMoneyTheme.titleMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),

          const SizedBox(height: 12),

          // Info text
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: UberMoneyTheme.info.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: UberMoneyTheme.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use the password you set up in your Profile settings',
                    style: UberMoneyTheme.caption.copyWith(
                      color: UberMoneyTheme.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
