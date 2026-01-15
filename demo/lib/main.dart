import 'package:flutter/material.dart';

void main() {
  runApp(const MarketplaceDemoApp());
}

class MarketplaceDemoApp extends StatelessWidget {
  const MarketplaceDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),
          secondary: Color(0xFF06B6D4),
          surface: Color(0xFF1A1A2E),
          error: Color(0xFFEF4444),
        ),
        fontFamily: 'Inter',
      ),
      home: const MainShell(),
    );
  }
}

// ============================================================================
// THEME CONSTANTS
// ============================================================================
class AppTheme {
  static const backgroundPrimary = Color(0xFF0D0D1A);
  static const backgroundCard = Color(0xFF1A1A2E);
  static const backgroundSecondary = Color(0xFF16213E);
  static const primary = Color(0xFF8B5CF6);
  static const accent = Color(0xFFFBBF24);
  static const teal = Color(0xFF06B6D4);
  static const pink = Color(0xFFEC4899);
  static const green = Color(0xFF10B981);
  static const orange = Color(0xFFF97316);
  static const textPrimary = Color(0xFFF8FAFC);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);
  static const border = Color(0xFF334155);

  static const borderRadiusMedium = BorderRadius.all(Radius.circular(16));
  static const borderRadiusLarge = BorderRadius.all(Radius.circular(24));

  static const shadowMedium = [
    BoxShadow(color: Color(0x40000000), blurRadius: 20, offset: Offset(0, 8)),
  ];

  static const headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const headlineMedium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textMuted,
  );
}

// ============================================================================
// MOCK DATA
// ============================================================================
class MockData {
  static const user = {
    'name': 'Priya Sharma',
    'email': 'priya@gmail.com',
    'nickname': 'priya_s',
    'role': 'Customer',
  };

  static const products = [
    {
      'name': 'Wireless Earbuds',
      'price': 2499,
      'shop': 'TechZone',
      'image': '🎧',
    },
    {'name': 'Smart Watch', 'price': 4999, 'shop': 'GadgetHub', 'image': '⌚'},
    {
      'name': 'Backpack Pro',
      'price': 1299,
      'shop': 'StyleCraft',
      'image': '🎒',
    },
    {
      'name': 'Coffee Maker',
      'price': 3499,
      'shop': 'HomeEssentials',
      'image': '☕',
    },
    {'name': 'Running Shoes', 'price': 2999, 'shop': 'SportMax', 'image': '👟'},
    {'name': 'Desk Lamp', 'price': 899, 'shop': 'LightWorld', 'image': '💡'},
  ];

  static const rides = [
    {
      'from': 'Patia Square',
      'to': 'Infocity',
      'driver': 'Rahul K.',
      'time': '10:30 AM',
      'seats': 2,
      'price': 45,
    },
    {
      'from': 'Jaydev Vihar',
      'to': 'Railway Station',
      'driver': 'Amit S.',
      'time': '11:00 AM',
      'seats': 3,
      'price': 60,
    },
    {
      'from': 'Saheed Nagar',
      'to': 'KIIT University',
      'driver': 'Sneha R.',
      'time': '2:00 PM',
      'seats': 1,
      'price': 80,
    },
  ];

  static const posts = [
    {
      'user': 'Ankit M.',
      'content': 'Just got my order from TechZone! Amazing delivery speed 🚀',
      'likes': 24,
      'time': '2h ago',
    },
    {
      'user': 'Priya S.',
      'content': 'Shared a ride to work today, saved ₹100! 🎉',
      'likes': 18,
      'time': '4h ago',
    },
    {
      'user': 'Rohit K.',
      'content': 'Check out this amazing coffee maker I bought!',
      'likes': 42,
      'time': '6h ago',
    },
  ];

  static const campaigns = [
    {'title': 'Winter Sale', 'discount': '50% OFF', 'color': AppTheme.pink},
    {'title': 'New Arrivals', 'discount': 'Shop Now', 'color': AppTheme.teal},
    {'title': 'Flash Deal', 'discount': '₹99 Only', 'color': AppTheme.orange},
  ];
}

// ============================================================================
// MAIN SHELL WITH BOTTOM NAV
// ============================================================================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    RideScreen(),
    MarketScreen(),
    SocialScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.backgroundCard,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isActive: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: Icons.directions_car_rounded,
                  label: 'Ride',
                  isActive: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: Icons.storefront_rounded,
                  label: 'Shop',
                  isActive: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                ),
                _NavItem(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Social',
                  isActive: _currentIndex == 3,
                  onTap: () => setState(() => _currentIndex = 3),
                ),
                _NavItem(
                  icon: Icons.person_rounded,
                  label: 'Profile',
                  isActive: _currentIndex == 4,
                  onTap: () => setState(() => _currentIndex = 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primary.withOpacity(0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? AppTheme.primary : AppTheme.textMuted,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primary : AppTheme.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// HOME SCREEN
// ============================================================================
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.teal],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Center(
                    child: Text(
                      'M',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Marketplace', style: AppTheme.headlineLarge),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Hello, ${MockData.user['name']}! 👋',
              style: AppTheme.bodyMedium,
            ),

            const SizedBox(height: 28),

            // Quick Actions Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _QuickActionCard(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Shop',
                  color: AppTheme.teal,
                  emoji: '🛍️',
                ),
                _QuickActionCard(
                  icon: Icons.directions_car_rounded,
                  label: 'Ride',
                  color: AppTheme.pink,
                  emoji: '🚗',
                ),
                _QuickActionCard(
                  icon: Icons.chat_bubble_rounded,
                  label: 'Social',
                  color: AppTheme.primary,
                  emoji: '💬',
                ),
                _QuickActionCard(
                  icon: Icons.auto_awesome,
                  label: 'More',
                  color: AppTheme.accent,
                  emoji: '✨',
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Campaigns Carousel
            const Text('🔥 Hot Deals', style: AppTheme.headlineMedium),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: MockData.campaigns.length,
                itemBuilder: (context, index) {
                  final campaign = MockData.campaigns[index];
                  return Container(
                    width: 260,
                    margin: EdgeInsets.only(
                      right: index < MockData.campaigns.length - 1 ? 16 : 0,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          campaign['color'] as Color,
                          (campaign['color'] as Color).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: AppTheme.borderRadiusMedium,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          campaign['title'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            campaign['discount'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 28),

            // Recent Activity
            const Text('Recent Activity', style: AppTheme.headlineMedium),
            const SizedBox(height: 16),
            ...MockData.posts.take(2).map((post) => _ActivityCard(post: post)),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String emoji;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.emoji,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.5)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppTheme.borderRadiusMedium,
          onTap: () {},
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text(label, style: AppTheme.titleMedium),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const _ActivityCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 16,
                child: Text(
                  post['user'][0],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 10),
              Text(post['user'], style: AppTheme.titleMedium),
              const Spacer(),
              Text(post['time'], style: AppTheme.caption),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            post['content'],
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.favorite_rounded, color: AppTheme.pink, size: 18),
              const SizedBox(width: 4),
              Text('${post['likes']}', style: AppTheme.caption),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// RIDE SCREEN
// ============================================================================
class RideScreen extends StatelessWidget {
  const RideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Map placeholder
          Container(
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.backgroundSecondary,
                  AppTheme.backgroundPrimary,
                ],
              ),
            ),
            child: Stack(
              children: [
                // Fake map grid
                CustomPaint(
                  size: const Size(double.infinity, 280),
                  painter: _MapGridPainter(),
                ),
                // Location marker
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                // Header
                Positioned(
                  top: 16,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      const Text(
                        '🚗 Find a Ride',
                        style: AppTheme.headlineMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Live',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Available Rides
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.backgroundPrimary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Text(
                          'Available Rides',
                          style: AppTheme.headlineMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${MockData.rides.length} nearby',
                          style: AppTheme.caption,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: MockData.rides.length,
                      itemBuilder: (context, index) {
                        final ride = MockData.rides[index];
                        return _RideCard(ride: ride);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 40) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RideCard extends StatelessWidget {
  final Map<String, dynamic> ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.directions_car,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride['driver'], style: AppTheme.titleMedium),
                    Text(
                      '${ride['seats']} seats available',
                      style: AppTheme.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${ride['price']}',
                    style: AppTheme.titleMedium.copyWith(color: AppTheme.green),
                  ),
                  Text(ride['time'], style: AppTheme.caption),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.circle, size: 10, color: AppTheme.green),
              const SizedBox(width: 8),
              Expanded(child: Text(ride['from'], style: AppTheme.bodyMedium)),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 4),
            height: 20,
            width: 2,
            color: AppTheme.border,
          ),
          Row(
            children: [
              const Icon(Icons.location_on, size: 10, color: AppTheme.pink),
              const SizedBox(width: 8),
              Expanded(child: Text(ride['to'], style: AppTheme.bodyMedium)),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Join Ride'),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// MARKET SCREEN
// ============================================================================
class MarketScreen extends StatelessWidget {
  const MarketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🛒 Marketplace', style: AppTheme.headlineLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'Discover amazing products',
                    style: AppTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  // Search Bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundCard,
                      borderRadius: AppTheme.borderRadiusMedium,
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: AppTheme.textMuted),
                        const SizedBox(width: 12),
                        Text(
                          'Search products...',
                          style: AppTheme.bodyMedium.copyWith(
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Categories
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _CategoryChip(label: 'All', isSelected: true),
                        _CategoryChip(label: 'Electronics'),
                        _CategoryChip(label: 'Fashion'),
                        _CategoryChip(label: 'Home'),
                        _CategoryChip(label: 'Sports'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = MockData.products[index];
                return _ProductCard(product: product);
              }, childCount: MockData.products.length),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;

  const _CategoryChip({required this.label, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : AppTheme.backgroundCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primary : AppTheme.border,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  product['image'],
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['name'],
                    style: AppTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(product['shop'], style: AppTheme.caption),
                  const Spacer(),
                  Row(
                    children: [
                      Text(
                        '₹${product['price']}',
                        style: AppTheme.titleMedium.copyWith(
                          color: AppTheme.green,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// SOCIAL SCREEN
// ============================================================================
class SocialScreen extends StatelessWidget {
  const SocialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('💬 Social Feed', style: AppTheme.headlineLarge),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: MockData.posts.length,
              itemBuilder: (context, index) {
                final post = MockData.posts[index];
                return _SocialPostCard(post: post);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialPostCard extends StatelessWidget {
  final Map<String, dynamic> post;

  const _SocialPostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primary,
                radius: 20,
                child: Text(
                  post['user'][0],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post['user'], style: AppTheme.titleMedium),
                  Text(post['time'], style: AppTheme.caption),
                ],
              ),
              const Spacer(),
              Icon(Icons.more_horiz, color: AppTheme.textMuted),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            post['content'],
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.border),
          const SizedBox(height: 8),
          Row(
            children: [
              _ActionButton(
                icon: Icons.favorite_border,
                label: '${post['likes']}',
                color: AppTheme.pink,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Comment',
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 24),
              _ActionButton(
                icon: Icons.share_outlined,
                label: 'Share',
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}

// ============================================================================
// PROFILE SCREEN
// ============================================================================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, AppTheme.teal],
                ),
                borderRadius: AppTheme.borderRadiusLarge,
                boxShadow: AppTheme.shadowMedium,
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Center(
                      child: Text('👤', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          MockData.user['name']!,
                          style: AppTheme.headlineMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '@${MockData.user['nickname']}',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.person,
                                size: 14,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                MockData.user['role']!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Menu Items
            _ProfileMenuItem(
              icon: Icons.history,
              title: 'Order History',
              iconColor: AppTheme.primary,
            ),
            _ProfileMenuItem(
              icon: Icons.favorite_border,
              title: 'Saved Items',
              iconColor: AppTheme.pink,
            ),
            _ProfileMenuItem(
              icon: Icons.location_on_outlined,
              title: 'Addresses',
              iconColor: AppTheme.teal,
            ),
            _ProfileMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              iconColor: AppTheme.orange,
            ),
            _ProfileMenuItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              iconColor: AppTheme.accent,
            ),
            _ProfileMenuItem(
              icon: Icons.settings_outlined,
              title: 'Settings',
              iconColor: AppTheme.textMuted,
            ),
            _ProfileMenuItem(
              icon: Icons.logout,
              title: 'Sign Out',
              iconColor: const Color(0xFFEF4444),
              textColor: const Color(0xFFEF4444),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color iconColor;
  final Color? textColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundCard,
        borderRadius: AppTheme.borderRadiusMedium,
        border: Border.all(color: AppTheme.border.withOpacity(0.3)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          title,
          style: AppTheme.titleMedium.copyWith(color: textColor),
        ),
        trailing: Icon(Icons.chevron_right, color: AppTheme.textMuted),
        onTap: () {},
      ),
    );
  }
}
