import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/ride_model.dart';
import '../../core/theme/uber_money_theme.dart';
import '../../core/services/share_service.dart';
import 'ride_provider.dart';

/// Screen to display a shared ride when opened from a deep link
/// Shows ride details and allows joining if user is logged in
class SharedRideScreen extends ConsumerStatefulWidget {
  final String rideId;

  const SharedRideScreen({super.key, required this.rideId});

  @override
  ConsumerState<SharedRideScreen> createState() => _SharedRideScreenState();
}

class _SharedRideScreenState extends ConsumerState<SharedRideScreen> {
  bool _isLoading = true;
  RideModel? _ride;
  String? _error;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadRide();
  }

  Future<void> _loadRide() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId)
          .get();

      if (!doc.exists) {
        setState(() {
          _error = 'This ride no longer exists';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _ride = RideModel.fromFirestore(doc);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load ride details';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinRide() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      // Navigate to login
      context.go('/login');
      return;
    }

    if (_ride == null) return;

    setState(() => _isJoining = true);

    try {
      await RideActions.joinRide(_ride!.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the ride!'),
            backgroundColor: UberMoneyTheme.success,
          ),
        );
        // Navigate to ride chat
        context.go('/ride/${_ride!.id}/chat');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: UberMoneyTheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: UberMoneyTheme.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: UberMoneyTheme.backgroundPrimary,
        title: Text('Ride Details', style: UberMoneyTheme.headlineMedium),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/ride'),
        ),
        actions: [
          if (_ride != null)
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => ShareService.shareRide(_ride!),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading ride details...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: UberMoneyTheme.error,
            ),
            const SizedBox(height: 16),
            Text(_error!, style: UberMoneyTheme.titleLarge),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/ride'),
              icon: const Icon(Icons.home),
              label: const Text('Go to Rides'),
            ),
          ],
        ),
      );
    }

    final ride = _ride!;
    final currentUser = FirebaseAuth.instance.currentUser;
    final hasJoined =
        currentUser != null && ride.hasUserJoined(currentUser.uid);
    final isCreator = currentUser?.uid == ride.creatorId;
    final dateFormat = DateFormat('EEEE, MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
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
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // From
                Row(
                  children: [
                    const Icon(
                      Icons.trip_origin,
                      color: Colors.white70,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'FROM',
                            style: UberMoneyTheme.caption.copyWith(
                              color: Colors.white60,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ride.startingPoint,
                            style: UberMoneyTheme.titleLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Arrow
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      Container(width: 2, height: 30, color: Colors.white30),
                    ],
                  ),
                ),

                // To
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TO',
                            style: UberMoneyTheme.caption.copyWith(
                              color: Colors.white60,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            ride.destination,
                            style: UberMoneyTheme.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
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

          const SizedBox(height: 24),

          // Date & Time Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: UberMoneyTheme.shadowMedium,
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  Icons.calendar_today,
                  'Date',
                  dateFormat.format(ride.rideDateTime),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  Icons.access_time,
                  'Time',
                  timeFormat.format(ride.rideDateTime),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Creator Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: UberMoneyTheme.shadowMedium,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: UberMoneyTheme.primary,
                  backgroundImage: ride.creatorPhotoUrl != null
                      ? CachedNetworkImageProvider(ride.creatorPhotoUrl!)
                      : null,
                  child: ride.creatorPhotoUrl == null
                      ? Text(
                          ride.creatorName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ride.creatorName, style: UberMoneyTheme.titleMedium),
                      Text('Ride Organizer', style: UberMoneyTheme.caption),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_seat,
                        size: 16,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${ride.availableSeats}/${ride.totalSeats}',
                        style: UberMoneyTheme.labelMedium.copyWith(
                          color: const Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Gender Preference
          if (ride.genderPreference != GenderPreference.any)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: ride.genderPreference == GenderPreference.female
                    ? const Color(0xFFEC4899).withOpacity(0.1)
                    : const Color(0xFF3B82F6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: ride.genderPreference == GenderPreference.female
                      ? const Color(0xFFEC4899).withOpacity(0.3)
                      : const Color(0xFF3B82F6).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    ride.genderPreference == GenderPreference.female
                        ? Icons.female
                        : Icons.male,
                    color: ride.genderPreference == GenderPreference.female
                        ? const Color(0xFFEC4899)
                        : const Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${ride.genderPreference.name.toUpperCase()} ONLY Ride',
                    style: UberMoneyTheme.labelLarge.copyWith(
                      color: ride.genderPreference == GenderPreference.female
                          ? const Color(0xFFEC4899)
                          : const Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),

          // Participants
          Text('Passengers', style: UberMoneyTheme.titleLarge),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(ride.totalSeats, (index) {
              final seatNumber = index + 1;
              final participant = ride.participants
                  .where((p) => p.seatNumber == seatNumber)
                  .firstOrNull;
              final isOccupied = participant != null;

              return Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: isOccupied
                      ? (participant.isCreator
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFEF4444))
                      : const Color(0xFF22C55E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isOccupied && participant.photoUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: participant.photoUrl!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        isOccupied ? Icons.person : Icons.event_seat,
                        color: Colors.white,
                        size: 24,
                      ),
              );
            }),
          ),

          const SizedBox(height: 32),

          // Action Button
          if (!hasJoined && !isCreator && !ride.isFull)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isJoining ? null : _joinRide,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF22C55E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isJoining
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.person_add),
                label: Text(_isJoining ? 'Joining...' : 'Join This Ride'),
              ),
            )
          else if (hasJoined)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/ride/${ride.id}/chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble),
                label: const Text('Open Ride Chat'),
              ),
            )
          else if (ride.isFull)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text(
                  'This ride is full',
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 80), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF6366F1), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: UberMoneyTheme.caption),
              const SizedBox(height: 2),
              Text(value, style: UberMoneyTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}
