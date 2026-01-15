import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/ride_model.dart';

import '../auth/auth_controller.dart';

/// Provider for all active rides stream
final ridesStreamProvider = StreamProvider<List<RideModel>>((ref) {
  // Watch auth state to force refresh when user verification status changes
  ref.watch(authControllerProvider);

  return FirebaseFirestore.instance
      .collection('rides')
      .where('isActive', isEqualTo: true)
      .where('rideDateTime', isGreaterThan: DateTime.now())
      .orderBy('rideDateTime', descending: false)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => RideModel.fromFirestore(doc)).toList(),
      );
});

/// Provider for a single ride
final rideProvider = StreamProvider.family<RideModel?, String>((ref, rideId) {
  return FirebaseFirestore.instance
      .collection('rides')
      .doc(rideId)
      .snapshots()
      .map((doc) {
        if (!doc.exists) return null;
        return RideModel.fromFirestore(doc);
      });
});

/// Provider for ride chat messages
final rideChatProvider = StreamProvider.family<List<RideChatMessage>, String>((
  ref,
  rideId,
) {
  return FirebaseFirestore.instance
      .collection('rides')
      .doc(rideId)
      .collection('chat')
      .orderBy('sentAt', descending: false)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs
            .map((doc) => RideChatMessage.fromFirestore(doc))
            .toList(),
      );
});

/// Ride Actions - Static methods for ride operations
class RideActions {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Create a new ride
  static Future<String?> createRide({
    required String startingPoint,
    required String destination,
    required DateTime rideDateTime,
    required GenderPreference genderPreference,
    required int totalSeats,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      // Get user info from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Check if user is shop
      if (userData['role'] == 'shop') {
        return null;
      }

      // Creator is automatically the first participant
      final creatorParticipant = RideParticipant(
        userId: user.uid,
        displayName: userData['displayName'] ?? user.displayName ?? 'User',
        photoUrl: userData['photoUrl'] ?? user.photoURL,
        seatNumber: 1,
        joinedAt: DateTime.now(),
        isCreator: true,
      );

      final ride = RideModel(
        id: '', // Will be set by Firestore
        creatorId: user.uid,
        creatorName: userData['displayName'] ?? user.displayName ?? 'User',
        creatorPhotoUrl: userData['photoUrl'] ?? user.photoURL,
        startingPoint: startingPoint,
        destination: destination,
        rideDateTime: rideDateTime,
        genderPreference: genderPreference,
        totalSeats: totalSeats,
        availableSeats: totalSeats - 1, // Creator takes one seat
        participants: [creatorParticipant],
        createdAt: DateTime.now(),
        isActive: true,
      );

      final docRef = await _firestore
          .collection('rides')
          .add(ride.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error creating ride: $e');
      return null;
    }
  }

  /// Join a ride
  static Future<bool> joinRide(String rideId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final ride = RideModel.fromFirestore(rideDoc);

      // Check if user already joined
      if (ride.hasUserJoined(user.uid)) return false;

      // Check if ride is full
      if (ride.isFull) return false;

      // Get user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      // Check if user is shop
      if (userData['role'] == 'shop') {
        return false;
      }

      final joinerName =
          userData['displayName'] ?? user.displayName ?? 'Someone';

      // Find next available seat
      final occupiedSeats = ride.participants.map((p) => p.seatNumber).toSet();
      int nextSeat = 1;
      for (int i = 1; i <= ride.totalSeats; i++) {
        if (!occupiedSeats.contains(i)) {
          nextSeat = i;
          break;
        }
      }

      final newParticipant = RideParticipant(
        userId: user.uid,
        displayName: joinerName,
        photoUrl: userData['photoUrl'] ?? user.photoURL,
        seatNumber: nextSeat,
        joinedAt: DateTime.now(),
        isCreator: false,
      );

      // Update ride with new participant
      await _firestore.collection('rides').doc(rideId).update({
        'participants': FieldValue.arrayUnion([newParticipant.toMap()]),
        'availableSeats': FieldValue.increment(-1),
      });

      // Create notification document for Cloud Function to process
      // This will trigger push notifications to ride creator and participants
      await _firestore.collection('ride_notifications').add({
        'type': 'new_rider',
        'rideId': rideId,
        'joinerId': user.uid,
        'joinerName': joinerName,
        'joinerPhotoUrl': userData['photoUrl'] ?? user.photoURL,
        'creatorId': ride.creatorId,
        'destination': ride.destination,
        'participantIds': ride.participants.map((p) => p.userId).toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      return true;
    } catch (e) {
      print('Error joining ride: $e');
      return false;
    }
  }

  /// Leave a ride
  static Future<bool> leaveRide(String rideId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final ride = RideModel.fromFirestore(rideDoc);

      // Find and remove participant
      final participantToRemove = ride.participants
          .where((p) => p.userId == user.uid && !p.isCreator)
          .toList();

      if (participantToRemove.isEmpty) return false;

      await _firestore.collection('rides').doc(rideId).update({
        'participants': FieldValue.arrayRemove([
          participantToRemove.first.toMap(),
        ]),
        'availableSeats': FieldValue.increment(1),
      });

      return true;
    } catch (e) {
      print('Error leaving ride: $e');
      return false;
    }
  }

  /// Cancel a ride (creator only)
  static Future<bool> cancelRide(String rideId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final ride = RideModel.fromFirestore(rideDoc);

      // Only creator can cancel
      if (ride.creatorId != user.uid) return false;

      await _firestore.collection('rides').doc(rideId).update({
        'isActive': false,
      });

      return true;
    } catch (e) {
      print('Error canceling ride: $e');
      return false;
    }
  }

  /// Send a chat message
  static Future<bool> sendChatMessage(String rideId, String message) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Verify user is a participant
      final rideDoc = await _firestore.collection('rides').doc(rideId).get();
      if (!rideDoc.exists) return false;

      final ride = RideModel.fromFirestore(rideDoc);
      if (!ride.hasUserJoined(user.uid)) return false;

      // Get user info
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data() ?? {};

      final chatMessage = RideChatMessage(
        id: '',
        senderId: user.uid,
        senderName: userData['displayName'] ?? user.displayName ?? 'User',
        senderPhotoUrl: userData['photoUrl'] ?? user.photoURL,
        message: message,
        sentAt: DateTime.now(),
      );

      await _firestore
          .collection('rides')
          .doc(rideId)
          .collection('chat')
          .add(chatMessage.toFirestore());

      return true;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
}
