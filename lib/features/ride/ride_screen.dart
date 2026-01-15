import 'package:cached_network_image/cached_network_image.dart';
import '../../core/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/layout/responsive_center.dart';
import '../../core/models/ride_model.dart';
import '../../core/services/share_service.dart';
import 'ride_provider.dart';
import '../auth/auth_controller.dart';

class RideScreen extends ConsumerStatefulWidget {
  const RideScreen({super.key});

  @override
  ConsumerState<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends ConsumerState<RideScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  GenderPreference? _selectedGenderFilter; // null means "All"

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<RideModel> _filterRides(List<RideModel> rides) {
    return rides.where((ride) {
      // Filter by search query
      final matchesSearch =
          _searchQuery.isEmpty ||
          ride.startingPoint.toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ) ||
          ride.destination.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          ride.creatorName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Filter by gender preference
      final matchesGender =
          _selectedGenderFilter == null ||
          ride.genderPreference == _selectedGenderFilter ||
          ride.genderPreference == GenderPreference.any;

      return matchesSearch && matchesGender;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ridesAsync = ref.watch(ridesStreamProvider);
    // Use authControllerProvider for real-time state updates (solves 'stuck' issue)
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.directions_car,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text('Ride Share', style: UberMoneyTheme.headlineMedium),
          ],
        ),
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        elevation: 0,
      ),
      body: Builder(
        builder: (context) {
          final authState = ref.watch(authControllerProvider);

          if (authState is AuthLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (authState is AuthError) {
            return Center(child: Text('Error: ${authState.message}'));
          }

          // If not authenticated, we might want to show login prompt or let them view but not create?
          // Requirement: "user/shop/admin... verified... allow them to join and see"
          // If guest, maybe block? Let's assume guest sees nothing or login prompt.
          // For now, if no user, standard logic, maybe empty state or prompt.
          // But here we are focusing on logged in users being verified.

          UserModel? user;
          if (authState is AuthAuthenticated) {
            user = authState.user;
          }

          if (user?.isShop == true) {
            // For shop, maybe show a different UI or just let them see but not interact (logic handled in provider)
            // User asked "shop role are not allowed to join and create ride".
            // They can probably still SEE rides.
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 900;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: Column(
                    children: [
                      // Search and Filter Section
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          isDesktop ? 24 : 16,
                          8,
                          isDesktop ? 24 : 16,
                          0,
                        ),
                        child: Column(
                          children: [
                            // Search Bar
                            Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: TextField(
                                controller: _searchController,
                                onChanged: (value) {
                                  setState(() => _searchQuery = value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search by location or name...',
                                  hintStyle: UberMoneyTheme.bodyMedium.copyWith(
                                    color: UberMoneyTheme.textMuted,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search,
                                    color: Color(0xFF6366F1),
                                  ),
                                  suffixIcon: _searchQuery.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            setState(() => _searchQuery = '');
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Gender Filter Chips
                            Row(
                              children: [
                                Text(
                                  'Filter: ',
                                  style: UberMoneyTheme.labelMedium.copyWith(
                                    color: UberMoneyTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(null, 'All', Icons.people),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  GenderPreference.male,
                                  'Male',
                                  Icons.male,
                                ),
                                const SizedBox(width: 8),
                                _buildFilterChip(
                                  GenderPreference.female,
                                  'Female',
                                  Icons.female,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Rides List
                      Expanded(
                        child: ridesAsync.when(
                          data: (rides) {
                            final filteredRides = _filterRides(rides);

                            if (rides.isEmpty) {
                              return _buildEmptyState();
                            }

                            if (filteredRides.isEmpty) {
                              return _buildNoResultsState();
                            }

                            return ResponsiveCenterWrapper(
                              maxContentWidth: 800,
                              child: ListView.builder(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 8,
                                  bottom: 120,
                                ),
                                itemCount: filteredRides.length,
                                itemBuilder: (context, index) {
                                  return _RideCard(ride: filteredRides[index]);
                                },
                              ),
                            );
                          },
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) =>
                              Center(child: Text('Error: $error')),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton:
          (currentUser != null &&
              (ref.watch(authControllerProvider) is AuthAuthenticated &&
                  !(ref.watch(authControllerProvider) as AuthAuthenticated)
                      .user
                      .isShop))
          ? Padding(
              padding: const EdgeInsets.only(bottom: 70),
              child: FloatingActionButton.extended(
                onPressed: () => _showCreateRideDialog(context),
                backgroundColor: UberMoneyTheme.primary,
                icon: const Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Create Ride',
                  style: UberMoneyTheme.labelLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_outlined,
              size: 64,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text('No rides available', style: UberMoneyTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Be the first to create a ride!',
            style: UberMoneyTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.search_off, size: 48, color: Colors.orange),
          ),
          const SizedBox(height: 16),
          Text('No rides found', style: UberMoneyTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: UberMoneyTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
                _selectedGenderFilter = null;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    GenderPreference? preference,
    String label,
    IconData icon,
  ) {
    final isSelected = _selectedGenderFilter == preference;
    Color chipColor;

    if (preference == GenderPreference.female) {
      chipColor = const Color(0xFFEC4899);
    } else if (preference == GenderPreference.male) {
      chipColor = const Color(0xFF3B82F6);
    } else {
      chipColor = const Color(0xFF6366F1);
    }

    return GestureDetector(
      onTap: () {
        setState(() => _selectedGenderFilter = preference);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? chipColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? chipColor : Colors.grey[300]!),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: chipColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _ensurePhoneNumber(BuildContext context) async {
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) return false;

    final user = authState.user;
    if (user.contactNumbers.isNotEmpty) return true;

    // Ask for phone number
    String? phoneNumber;
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        String inputNumber = '';
        return AlertDialog(
          title: const Text('Add Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'To create or join rides, we need your contact number for coordination.',
              ),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => inputNumber = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputNumber.length >= 10) {
                  phoneNumber = inputNumber;
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (success == true && phoneNumber != null) {
      final formatted = phoneNumber!.startsWith('+')
          ? phoneNumber!
          : '+91$phoneNumber';
      await ref
          .read(authControllerProvider.notifier)
          .addVerifiedContactNumber(formatted);
      return true;
    }

    return false;
  }

  void _showCreateRideDialog(BuildContext context) async {
    final hasPhone = await _ensurePhoneNumber(context);
    if (!hasPhone) return;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true, // Ensures modal respects safe area
      builder: (context) => Padding(
        // Add bottom padding for navbar
        padding: const EdgeInsets.only(bottom: 80),
        child: const _CreateRideSheet(),
      ),
    );
  }
}

/// Ride Card Widget
class _RideCard extends ConsumerWidget {
  final RideModel ride;

  const _RideCard({required this.ride});

  Future<bool> _ensurePhoneNumber(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authControllerProvider);
    if (authState is! AuthAuthenticated) return false;

    final user = authState.user;
    if (user.contactNumbers.isNotEmpty) return true;

    // Ask for phone number
    String? phoneNumber;
    final success = await showDialog<bool>(
      context: context,
      builder: (context) {
        String inputNumber = '';
        return AlertDialog(
          title: const Text('Add Phone Number'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('To join rides, please add your phone number.'),
              const SizedBox(height: 16),
              TextField(
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) => inputNumber = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (inputNumber.length >= 10) {
                  phoneNumber = inputNumber;
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (success == true && phoneNumber != null) {
      final formatted = phoneNumber!.startsWith('+')
          ? phoneNumber!
          : '+91$phoneNumber';
      await ref
          .read(authControllerProvider.notifier)
          .addVerifiedContactNumber(formatted);
      return true;
    }

    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasJoined =
        currentUser != null && ride.hasUserJoined(currentUser.uid);
    final isCreator = currentUser?.uid == ride.creatorId;
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with route info
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: ride.genderPreference == GenderPreference.female
                    ? [const Color(0xFFEC4899), const Color(0xFFF472B6)]
                    : ride.genderPreference == GenderPreference.male
                    ? [const Color(0xFF3B82F6), const Color(0xFF60A5FA)]
                    : [const Color(0xFF6366F1), const Color(0xFF8B5CF6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Route
                Row(
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.startingPoint,
                        style: UberMoneyTheme.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        ride.destination,
                        style: UberMoneyTheme.titleLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Date & Gender
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            dateFormat.format(ride.rideDateTime),
                            style: UberMoneyTheme.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            ride.genderPreference == GenderPreference.female
                                ? Icons.female
                                : ride.genderPreference == GenderPreference.male
                                ? Icons.male
                                : Icons.people,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            ride.genderPreference.name.toUpperCase(),
                            style: UberMoneyTheme.labelMedium.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Seats visualization
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Seats (${ride.occupiedSeats}/${ride.totalSeats})',
                  style: UberMoneyTheme.labelLarge,
                ),
                const SizedBox(height: 12),
                _buildSeatsRow(ride),
              ],
            ),
          ),

          // Creator info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: UberMoneyTheme.primary,
                  backgroundImage: ride.creatorPhotoUrl != null
                      ? CachedNetworkImageProvider(ride.creatorPhotoUrl!)
                      : null,
                  child: ride.creatorPhotoUrl == null
                      ? Text(
                          ride.creatorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created by ${ride.creatorName}',
                      style: UberMoneyTheme.labelMedium,
                    ),
                    Text(
                      isCreator ? 'You' : 'Organizer',
                      style: UberMoneyTheme.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                if (hasJoined) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/ride/${ride.id}/chat'),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6366F1),
                        side: const BorderSide(color: Color(0xFF6366F1)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  if (!isCreator) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () =>
                            _showLeaveConfirmation(context, ride.id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: UberMoneyTheme.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Leave'),
                      ),
                    ),
                  ],
                ] else if (currentUser != null && !ride.isFull) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final hasPhone = await _ensurePhoneNumber(context, ref);
                        if (hasPhone) {
                          _showJoinSafetyDialog(context, ride.id);
                        }
                      },
                      icon: const Icon(Icons.person_add),
                      label: const Text('Join Ride'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (ride.isFull) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Ride Full',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                // Share button at the end of the row
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => ShareService.shareRide(ride),
                  icon: const Icon(Icons.share_outlined),
                  tooltip: 'Share this ride',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                    foregroundColor: const Color(0xFF6366F1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatsRow(RideModel ride) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(ride.totalSeats, (index) {
        final seatNumber = index + 1;
        final participant = ride.participants
            .where((p) => p.seatNumber == seatNumber)
            .firstOrNull;
        final isOccupied = participant != null;

        return Tooltip(
          message: isOccupied ? participant.displayName : 'Available',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isOccupied
                  ? (participant.isCreator
                        ? const Color(0xFF6366F1)
                        : const Color(0xFFEF4444))
                  : const Color(0xFF22C55E),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color:
                      (isOccupied
                              ? (participant.isCreator
                                    ? const Color(0xFF6366F1)
                                    : const Color(0xFFEF4444))
                              : const Color(0xFF22C55E))
                          .withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isOccupied && participant.photoUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: CachedNetworkImage(
                      imageUrl: participant.photoUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : Icon(
                    isOccupied ? Icons.person : Icons.event_seat,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        );
      }),
    );
  }

  void _showJoinSafetyDialog(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.warning_amber, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            const Text('Safety Notice'),
          ],
        ),
        content: const Text(
          'Marketplace is just a platform connecting users.\n\n'
          '⚠️ It is highly recommended to physically meet your riders before the ride.\n\n'
          '⚠️ Choose rides based on your gender preference for your safety.\n\n'
          'Thank you for using our service responsibly!',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await RideActions.joinRide(rideId);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Successfully joined the ride!'
                          : 'Failed to join ride',
                    ),
                    backgroundColor: success
                        ? UberMoneyTheme.success
                        : UberMoneyTheme.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('I Agree & Join'),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(BuildContext context, String rideId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Leave Ride?'),
        content: const Text('Are you sure you want to leave this ride?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await RideActions.leaveRide(rideId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: UberMoneyTheme.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }
}

/// Create Ride Bottom Sheet
class _CreateRideSheet extends ConsumerStatefulWidget {
  const _CreateRideSheet();

  @override
  ConsumerState<_CreateRideSheet> createState() => _CreateRideSheetState();
}

class _CreateRideSheetState extends ConsumerState<_CreateRideSheet> {
  final _startingPointController = TextEditingController();
  final _destinationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  GenderPreference _genderPreference = GenderPreference.any;
  int _totalSeats = 6;
  bool _isLoading = false;

  @override
  void dispose() {
    _startingPointController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        // Handle keyboard insets + extra padding
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text('Create a Ride', style: UberMoneyTheme.headlineLarge),
            const SizedBox(height: 8),
            Text(
              'Share your ride with others',
              style: UberMoneyTheme.bodyMedium,
            ),
            const SizedBox(height: 24),

            // Starting Point
            TextField(
              controller: _startingPointController,
              decoration: InputDecoration(
                labelText: 'Starting Point',
                prefixIcon: const Icon(
                  Icons.trip_origin,
                  color: Color(0xFF6366F1),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: UberMoneyTheme.backgroundPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Destination
            TextField(
              controller: _destinationController,
              decoration: InputDecoration(
                labelText: 'Destination',
                prefixIcon: const Icon(
                  Icons.location_on,
                  color: Color(0xFFEF4444),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: UberMoneyTheme.backgroundPrimary,
              ),
            ),
            const SizedBox(height: 16),

            // Date & Time Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: UberMoneyTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                            style: UberMoneyTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: UberMoneyTheme.backgroundPrimary,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 20,
                            color: Color(0xFF6366F1),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedTime.format(context),
                            style: UberMoneyTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Gender Preference
            Text('Gender Preference', style: UberMoneyTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildGenderChip(GenderPreference.any, 'Any', Icons.people),
                const SizedBox(width: 8),
                _buildGenderChip(GenderPreference.male, 'Male', Icons.male),
                const SizedBox(width: 8),
                _buildGenderChip(
                  GenderPreference.female,
                  'Female',
                  Icons.female,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Seats
            Text('Number of Seats', style: UberMoneyTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: List.generate(5, (index) {
                final seats = index + 2; // 2 to 6
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text('$seats'),
                    selected: _totalSeats == seats,
                    onSelected: (selected) {
                      if (selected) setState(() => _totalSeats = seats);
                    },
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: _totalSeats == seats ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleCreate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Create Ride',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderChip(
    GenderPreference preference,
    String label,
    IconData icon,
  ) {
    final isSelected = _genderPreference == preference;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _genderPreference = preference),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? (preference == GenderPreference.female
                      ? const Color(0xFFEC4899)
                      : preference == GenderPreference.male
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF6366F1))
                : UberMoneyTheme.backgroundPrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? Colors.transparent : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _handleCreate() {
    if (_startingPointController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    // Show safety caution dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield, color: Color(0xFFF59E0B)),
            ),
            const SizedBox(width: 12),
            const Text('Safety Agreement'),
          ],
        ),
        content: const Text(
          'By creating this ride, you agree to:\n\n'
          '✓ Use this service with good intentions\n'
          '✓ Respect all riders and follow safety guidelines\n'
          '✓ Take responsibility for your actions\n\n'
          '⚠️ Marketplace is a platform connecting users. We are not responsible for any incidents that may occur during rides.\n\n'
          'Please ride safely!',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext); // Close dialog
              _createRide(); // This will close the bottom sheet on success
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E),
              foregroundColor: Colors.white,
            ),
            child: const Text('I Agree'),
          ),
        ],
      ),
    );
  }

  Future<void> _createRide() async {
    setState(() => _isLoading = true);

    final rideDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final rideId = await RideActions.createRide(
      startingPoint: _startingPointController.text.trim(),
      destination: _destinationController.text.trim(),
      rideDateTime: rideDateTime,
      genderPreference: _genderPreference,
      totalSeats: _totalSeats,
    );

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            rideId != null
                ? 'Ride created successfully!'
                : 'Failed to create ride',
          ),
          backgroundColor: rideId != null
              ? UberMoneyTheme.success
              : UberMoneyTheme.error,
        ),
      );
    }
  }
}
