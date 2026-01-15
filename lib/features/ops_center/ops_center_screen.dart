import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/uber_money_theme.dart';

class OpsCenterScreen extends StatefulWidget {
  const OpsCenterScreen({super.key});

  @override
  State<OpsCenterScreen> createState() => _OpsCenterScreenState();
}

class _OpsCenterScreenState extends State<OpsCenterScreen> {
  int _selectedWorkspaceIndex = 0;
  // ignore: unused_field
  String? _selectedProjectId;
  String? _selectedItemId; // For detail panel

  @override
  Widget build(BuildContext context) {
    // Use LayoutBuilder to handle responsiveness, but strictly implementing the requested multi-column layout
    // Ideally this is viewed on a Tablet or Desktop (Landscape)
    return Scaffold(
      body: Row(
        children: [
          // 1. The Framework: Dark Navigation Rail (Far Left)
          _buildNavigationRail(),

          // 2. The Framework: Channel List (Project Navigation)
          // Collapsed on small screens, visible on large
          if (MediaQuery.of(context).size.width > 600)
            SizedBox(width: 250, child: _buildChannelList()),

          // 3. The Content Engine & 4. The Contextual Layer
          Expanded(
            child: Stack(
              children: [
                // Main Content (Map/Timeline)
                _buildContentEngine(),

                // Header Overlay
                Positioned(top: 0, left: 0, right: 0, child: _buildHeader()),

                // 4. The Contextual Layer (Supermoney Overlay)
                // Slides in from right when an item is selected
                if (_selectedItemId != null)
                  Positioned(
                    top: 60,
                    bottom: 0,
                    right: 0,
                    width: MediaQuery.of(context).size.width < 900
                        ? MediaQuery.of(context).size.width
                        : 400,
                    child: _buildContextualLayer(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 1. The Skeleton (Rail)
  // ==========================================
  Widget _buildNavigationRail() {
    return Container(
      width: 70,
      color: Colors.black, // "Dark navigation rail"
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildRailItem(Icons.grid_view, 0),
          _buildRailItem(Icons.chat_bubble_outline, 1),
          _buildRailItem(Icons.notifications_none, 2),
          const Spacer(),
          _buildRailItem(Icons.settings_outlined, 3),
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white24,
            child: Text(
              'JS',
              style: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildRailItem(IconData icon, int index) {
    final isSelected = _selectedWorkspaceIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedWorkspaceIndex = index),
      child: Container(
        height: 50,
        width: 50,
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected ? Border.all(color: Colors.white54) : null,
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white54,
          size: 24,
        ),
      ),
    );
  }

  // ==========================================
  // 2. The Channel List
  // ==========================================
  Widget _buildChannelList() {
    return Container(
      color: const Color(0xFF1E1E1E), // Slightly lighter dark
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'FinOps Center',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildSectionHeader('Live Operations'),
                _buildChannelItem('Fleet Alpha', 'active', true),
                _buildChannelItem('Fleet Beta', 'idle', false),
                _buildChannelItem('Hub Logistics', 'warning', false),
                const SizedBox(height: 20),
                _buildSectionHeader('Financials'),
                _buildChannelItem('Transactions', '', false),
                _buildChannelItem('Reconcile', '', false),
                _buildChannelItem('Audits', '', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          color: Colors.white54,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildChannelItem(String title, String status, bool isActive) {
    Color statusColor = Colors.transparent;
    if (status == 'active') statusColor = UberMoneyTheme.accent;
    if (status == 'warning') statusColor = UberMoneyTheme.warning;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        title: Text(
          title,
          style: GoogleFonts.inter(
            color: isActive ? Colors.white : Colors.white70,
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
        trailing: status.isNotEmpty
            ? Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              )
            : null,
      ),
    );
  }

  // ==========================================
  // 3. The Content Engine (Map Centric)
  // ==========================================
  Widget _buildContentEngine() {
    return Container(
      color: Colors.grey[100],
      child: FlutterMap(
        options: MapOptions(
          initialCenter: const LatLng(20.2961, 85.8245), // Bhubaneswar
          initialZoom: 13,
          onTap: (_, __) =>
              setState(() => _selectedItemId = null), // Deselect on map tap
        ),
        children: [
          TileLayer(
            // Dark mode map tiles for "Uber" aesthetic
            urlTemplate:
                'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
            userAgentPackageName: 'com.marketplace.app',
          ),
          MarkerLayer(
            markers: [
              _buildVehicleMarker('V001', 20.2961, 85.8245),
              _buildVehicleMarker('V002', 20.3061, 85.8345),
              _buildVehicleMarker('V003', 20.2861, 85.8145),
            ],
          ),
        ],
      ),
    );
  }

  Marker _buildVehicleMarker(String id, double lat, double lng) {
    bool isSelected = _selectedItemId == id;
    return Marker(
      point: LatLng(lat, lng),
      width: 50,
      height: 50,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedItemId = id;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: isSelected ? UberMoneyTheme.accent : Colors.black,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: (isSelected ? UberMoneyTheme.accent : Colors.black)
                    .withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            Icons.directions_car,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: Row(
        children: [
          Text(
            'Fleet Alpha Details',
            style: UberMoneyTheme.headlineMedium.copyWith(color: Colors.white),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, color: UberMoneyTheme.accent, size: 8),
                const SizedBox(width: 8),
                Text(
                  'Active',
                  style: UberMoneyTheme.labelMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. The Contextual Layer (Supermoney)
  // ==========================================
  Widget _buildContextualLayer() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD), // Very light cool grey
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 40,
            offset: Offset(0, 10),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Handle/Grabber (for mobile mainly, but looks good)
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vehicle ${_selectedItemId ?? ""}',
                          style: UberMoneyTheme.headlineLarge,
                        ),
                        Text(
                          'Toyota Camry • OD-02-AT-1234',
                          style: UberMoneyTheme.bodyMedium,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _selectedItemId = null),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Financial Cards
                _buildStatCard(
                  title: 'Total Earnings',
                  amount: '\$4,250.50',
                  trend: '+12.5%',
                  isPositive: true,
                ),
                const SizedBox(height: 16),

                _buildStatCard(
                  title: 'Operational Cost',
                  amount: '\$8,50.00',
                  trend: '-2.1%',
                  isPositive: true, // Lower cost is good
                ),
                const SizedBox(height: 32),

                // Chart Section
                Text('Performance Trend', style: UberMoneyTheme.titleLarge),
                const SizedBox(height: 16),
                Container(
                  height: 200,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: UberMoneyTheme.shadowSmall,
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 6,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 1),
                            FlSpot(2, 4),
                            FlSpot(3, 3),
                            FlSpot(4, 5),
                            FlSpot(5, 4),
                            FlSpot(6, 4.5),
                          ],
                          isCurved: true,
                          color: UberMoneyTheme.accentBlue,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: UberMoneyTheme.accentBlue.withOpacity(0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: UberButton(
                        text: 'Message Driver',
                        isOutlined: true,
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: UberButton(text: 'Full Report', onPressed: () {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String amount,
    required String trend,
    required bool isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: UberMoneyTheme.shadowMedium,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: UberMoneyTheme.labelMedium),
              const SizedBox(height: 8),
              Text(
                amount,
                style: UberMoneyTheme.displayMedium.copyWith(fontSize: 28),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isPositive
                  ? UberMoneyTheme.success.withOpacity(0.1)
                  : UberMoneyTheme.error.withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: isPositive
                      ? UberMoneyTheme.success
                      : UberMoneyTheme.error,
                ),
                const SizedBox(width: 4),
                Text(
                  trend,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isPositive
                        ? UberMoneyTheme.success
                        : UberMoneyTheme.error,
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
