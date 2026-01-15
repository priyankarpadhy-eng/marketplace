import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/uber_money_theme.dart';
import '../auth/auth_controller.dart';
import '../../core/models/user_model.dart';

/// MenuItem Model for data-driven UI
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });
}

/// Profile Screen with "Become a Shop" workflow
/// Refactored for Responsiveness (LayoutBuilder)
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user;
    final isAdmin = user.isAdmin;

    // Define Menu Items
    final menuItems = [
      _MenuItem(
        icon: Icons.history,
        title: 'Order History',
        onTap: () {},
        iconColor: UberMoneyTheme.purple,
      ),
      _MenuItem(
        icon: Icons.favorite_border,
        title: 'Saved Items',
        onTap: () {},
        iconColor: UberMoneyTheme.pink,
      ),
      _MenuItem(
        icon: Icons.location_on_outlined,
        title: 'Addresses',
        onTap: () {},
        iconColor: UberMoneyTheme.teal,
      ),
      _MenuItem(
        icon: Icons.payment_outlined,
        title: 'Payment Methods',
        onTap: () {},
        iconColor: UberMoneyTheme.orange,
      ),
      _MenuItem(
        icon: Icons.notifications_none,
        title: 'Activity',
        onTap: () => context.push('/activity'),
        iconColor: UberMoneyTheme.yellow,
      ),
      if (isAdmin)
        _MenuItem(
          icon: Icons.admin_panel_settings,
          title: 'Admin Panel',
          onTap: () => context.push('/admin'),
          textColor: UberMoneyTheme.accentBlue,
          iconColor: UberMoneyTheme.accentBlue,
        ),
      // Designer Panel option for designers
      if (user.role == UserRole.designer)
        _MenuItem(
          icon: Icons.design_services,
          title: 'Designer Panel',
          onTap: () => context.push('/designer'),
          textColor: const Color(0xFF8B5CF6),
          iconColor: const Color(0xFF8B5CF6),
        ),
      _MenuItem(
        icon: Icons.logout,
        title: 'Sign Out',
        textColor: UberMoneyTheme.error,
        iconColor: UberMoneyTheme.error,
        onTap: () async {
          await ref.read(authControllerProvider.notifier).signOut();
          if (context.mounted) {
            context.go('/login');
          }
        },
      ),
    ];

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        elevation: 0,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        title: Text('Profile', style: UberMoneyTheme.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 600) {
            return _buildDesktopLayout(context, user, menuItems, ref);
          } else {
            return _buildMobileLayout(context, user, menuItems, ref);
          }
        },
      ),
    );
  }

  // ==========================================
  // MOBILE LAYOUT
  // ==========================================
  Widget _buildMobileLayout(
    BuildContext context,
    UserModel user,
    List<_MenuItem> menuItems,
    WidgetRef ref,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(
        left: UberMoneyTheme.spacingMD,
        right: UberMoneyTheme.spacingMD,
        top: UberMoneyTheme.spacingMD,
        bottom: 100, // Extra padding to avoid navbar overlap
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: UberMoneyTheme.spacingMD),
          _buildNicknameSection(context, user, ref),
          const SizedBox(height: UberMoneyTheme.spacingMD),
          _buildPasswordSection(context, ref),
          const SizedBox(height: UberMoneyTheme.spacingLG),
          _buildShopStatusSection(context, user),
          const SizedBox(height: UberMoneyTheme.spacingLG),
          _buildMenuSectionMobile(menuItems),
        ],
      ),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT
  // ==========================================
  Widget _buildDesktopLayout(
    BuildContext context,
    UserModel user,
    List<_MenuItem> menuItems,
    WidgetRef ref,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(UberMoneyTheme.spacingLG),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section (Full Width in constraint)
              _buildProfileHeader(user),
              const SizedBox(height: UberMoneyTheme.spacingMD),

              // Nickname Section
              _buildNicknameSection(context, user, ref),
              const SizedBox(height: UberMoneyTheme.spacingMD),

              // Password Section
              _buildPasswordSection(context, ref),
              const SizedBox(height: UberMoneyTheme.spacingLG),

              // Shop Banner
              _buildShopStatusSection(context, user),
              const SizedBox(height: UberMoneyTheme.spacingXL),

              // Grid Menu Items
              Text('Account Settings', style: UberMoneyTheme.headlineMedium),
              const SizedBox(height: UberMoneyTheme.spacingMD),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 300,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.5, // Wider cards
                ),
                itemCount: menuItems.length,
                itemBuilder: (context, index) {
                  return _GridMenuItemCard(item: menuItems[index]);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // SHARED WIDGETS
  // ==========================================

  Widget _buildProfileHeader(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            UberMoneyTheme.purple.withOpacity(0.8),
            UberMoneyTheme.blue.withOpacity(0.8),
          ],
        ),
        borderRadius: UberMoneyTheme.borderRadiusLarge,
        boxShadow: UberMoneyTheme.shadowLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: Colors.white, width: 3),
            ),
            child: ClipOval(
              child: user.photoUrl != null
                  ? Image.network(
                      user.photoUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(),
                    )
                  : _buildAvatarPlaceholder(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Show nickname first if set, otherwise displayName
                Text(
                  user.publicName,
                  style: UberMoneyTheme.headlineMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                // Show nickname badge if set
                if (user.nickname != null && user.nickname!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '@${user.nickname}',
                      style: UberMoneyTheme.labelMedium.copyWith(
                        color: Colors.white60,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                _buildRoleBadge(user),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarPlaceholder() {
    return Container(
      color: UberMoneyTheme.primary,
      child: const Icon(Icons.person, color: Colors.white, size: 36),
    );
  }

  Widget _buildRoleBadge(UserModel user) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    if (user.isShop) {
      backgroundColor = UberMoneyTheme.accent;
      textColor = UberMoneyTheme.primary;
      text = 'Shop Owner';
      icon = Icons.storefront;
    } else if (user.isShopPending) {
      backgroundColor = UberMoneyTheme.warning.withOpacity(0.2);
      textColor = const Color(0xFFB8860B);
      text = 'Application Pending';
      icon = Icons.pending;
    } else if (user.isAdmin) {
      backgroundColor = UberMoneyTheme.accentBlue;
      textColor = Colors.white;
      text = 'Admin';
      icon = Icons.admin_panel_settings;
    } else {
      backgroundColor = UberMoneyTheme.backgroundPrimary;
      textColor = UberMoneyTheme.textSecondary;
      text = 'Customer';
      icon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: UberMoneyTheme.labelMedium.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNicknameSection(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) {
    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: BoxDecoration(
        color: UberMoneyTheme.backgroundCard,
        borderRadius: UberMoneyTheme.borderRadiusMedium,
        border: Border.all(color: UberMoneyTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: UberMoneyTheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.alternate_email,
              color: UberMoneyTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nickname',
                  style: UberMoneyTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  user.nickname?.isNotEmpty == true
                      ? '@${user.nickname}'
                      : 'Add a nickname for your account',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: user.nickname?.isNotEmpty == true
                        ? UberMoneyTheme.textPrimary
                        : UberMoneyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _showNicknameDialog(context, user, ref),
            child: Text(
              user.nickname?.isNotEmpty == true ? 'Edit' : 'Add',
              style: const TextStyle(
                color: UberMoneyTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNicknameDialog(
    BuildContext context,
    UserModel user,
    WidgetRef ref,
  ) {
    final controller = TextEditingController(text: user.nickname ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set Nickname'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your nickname will be visible across all services (rides, posts, etc.)',
              style: UberMoneyTheme.bodyMedium.copyWith(
                color: UberMoneyTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLength: 20,
              decoration: InputDecoration(
                labelText: 'Nickname',
                prefixText: '@',
                hintText: 'Enter nickname',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• 3-20 characters\n• No spaces or special characters',
              style: UberMoneyTheme.caption.copyWith(
                color: UberMoneyTheme.textMuted,
              ),
            ),
          ],
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final nickname = controller.text.trim();
              if (nickname.length >= 3 && nickname.length <= 20) {
                final success = await ref
                    .read(authControllerProvider.notifier)
                    .updateNickname(nickname);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Nickname updated successfully!'),
                        backgroundColor: UberMoneyTheme.success,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to update nickname'),
                        backgroundColor: UberMoneyTheme.error,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordSection(BuildContext context, WidgetRef ref) {
    final authController = ref.read(authControllerProvider.notifier);
    final hasPassword = authController.hasPasswordLinked();

    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: BoxDecoration(
        color: UberMoneyTheme.backgroundCard,
        borderRadius: UberMoneyTheme.borderRadiusMedium,
        border: Border.all(color: UberMoneyTheme.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasPassword
                  ? UberMoneyTheme.success.withOpacity(0.1)
                  : UberMoneyTheme.warning.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasPassword ? Icons.lock : Icons.lock_open,
              color: hasPassword
                  ? UberMoneyTheme.success
                  : UberMoneyTheme.warning,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email Login',
                  style: UberMoneyTheme.titleMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasPassword
                      ? 'Password is set up for email login'
                      : 'Set up a password to login with email',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: hasPassword
                        ? UberMoneyTheme.textSecondary
                        : UberMoneyTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              if (hasPassword) {
                _showEditPasswordDialog(context, ref);
              } else {
                _showSetupPasswordDialog(context, ref);
              }
            },
            child: Text(
              hasPassword ? 'Edit' : 'Set Up',
              style: const TextStyle(
                color: UberMoneyTheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSetupPasswordDialog(BuildContext context, WidgetRef ref) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UberMoneyTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_outline,
                  color: UberMoneyTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Set Up Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a password to enable email login. You can use this password along with your Gmail address to sign in.',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: UberMoneyTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter password (min 6 characters)',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscurePassword = !obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Re-enter password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: UberMoneyTheme.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 18,
                        color: UberMoneyTheme.info,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Password must be at least 6 characters',
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
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final result = await ref
                          .read(authControllerProvider.notifier)
                          .setupPassword(
                            password: passwordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );
                      setState(() => isLoading = false);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.success
                                  ? 'Password set up successfully! You can now login with email.'
                                  : result.error ?? 'Failed to set up password',
                            ),
                            backgroundColor: result.success
                                ? UberMoneyTheme.success
                                : UberMoneyTheme.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: UberMoneyTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Set Up', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditPasswordDialog(BuildContext context, WidgetRef ref) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: UberMoneyTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.edit,
                  color: UberMoneyTheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text('Change Password'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your current password and set a new one.',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: UberMoneyTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    hintText: 'Enter current password',
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscureCurrent = !obscureCurrent),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () => setState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    hintText: 'Re-enter new password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      setState(() => isLoading = true);
                      final result = await ref
                          .read(authControllerProvider.notifier)
                          .updatePassword(
                            currentPassword: currentPasswordController.text,
                            newPassword: newPasswordController.text,
                            confirmPassword: confirmPasswordController.text,
                          );
                      setState(() => isLoading = false);

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              result.success
                                  ? 'Password changed successfully!'
                                  : result.error ?? 'Failed to change password',
                            ),
                            backgroundColor: result.success
                                ? UberMoneyTheme.success
                                : UberMoneyTheme.error,
                          ),
                        );
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: UberMoneyTheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Update', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShopStatusSection(BuildContext context, UserModel user) {
    if (user.isShop) {
      return _buildShopDashboard(context, user);
    }
    if (user.isShopPending) {
      return _buildPendingApplicationCard();
    }
    return _buildBecomeShopCard(context);
  }

  Widget _buildBecomeShopCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/shop-apply'),
      child: Container(
        padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF000000), Color(0xFF1A1A2E)],
          ),
          borderRadius: UberMoneyTheme.borderRadiusLarge,
          boxShadow: UberMoneyTheme.shadowLarge,
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: UberMoneyTheme.accent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.storefront,
                color: UberMoneyTheme.primary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Open Your Shop',
                    style: UberMoneyTheme.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Start selling on the marketplace today',
                    style: UberMoneyTheme.bodyMedium.copyWith(
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingApplicationCard() {
    return Container(
      padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
      decoration: BoxDecoration(
        color: UberMoneyTheme.warning.withOpacity(0.1),
        borderRadius: UberMoneyTheme.borderRadiusMedium,
        border: Border.all(
          color: UberMoneyTheme.warning.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: UberMoneyTheme.warning.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.hourglass_empty,
              color: Color(0xFFB8860B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Under Review',
                  style: UberMoneyTheme.titleMedium.copyWith(
                    color: const Color(0xFFB8860B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'We\'ll notify you once your shop is approved',
                  style: UberMoneyTheme.bodyMedium.copyWith(
                    color: UberMoneyTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopDashboard(BuildContext context, UserModel user) {
    return GestureDetector(
      onTap: () => context.push('/shop-dashboard'),
      child: Container(
        padding: const EdgeInsets.all(UberMoneyTheme.spacingMD),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0b486b), Color(0xFFf56217)],
          ),
          borderRadius: UberMoneyTheme.borderRadiusMedium,
          boxShadow: UberMoneyTheme.shadowCard,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Your Shop',
                  style: UberMoneyTheme.titleLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.shopName ?? 'My Shop',
              style: UberMoneyTheme.headlineMedium.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.shopCategory ?? 'General',
              style: UberMoneyTheme.bodyMedium.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            // Placeholder stats could be re-added here if needed
          ],
        ),
      ),
    );
  }

  Widget _buildMenuSectionMobile(List<_MenuItem> items) {
    return Container(
      decoration: UberMoneyTheme.cardDecoration,
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isLast = index == items.length - 1;
          return Column(
            children: [
              _MenuTileMobile(item: item),
              if (!isLast) const Divider(height: 1, indent: 56),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuTileMobile extends StatelessWidget {
  final _MenuItem item;

  const _MenuTileMobile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color:
                      (item.iconColor ??
                              item.textColor ??
                              UberMoneyTheme.textPrimary)
                          .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  item.icon,
                  color:
                      item.iconColor ??
                      item.textColor ??
                      UberMoneyTheme.textPrimary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.title,
                  style: UberMoneyTheme.titleMedium.copyWith(
                    color: item.textColor,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: item.textColor ?? UberMoneyTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GridMenuItemCard extends StatelessWidget {
  final _MenuItem item;

  const _GridMenuItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: UberMoneyTheme.shadowSmall,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color:
                    (item.iconColor ??
                            item.textColor ??
                            UberMoneyTheme.textPrimary)
                        .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                item.icon,
                color:
                    item.iconColor ??
                    item.textColor ??
                    UberMoneyTheme.textPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                item.title,
                style: UberMoneyTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: item.textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
