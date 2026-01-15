import 'package:cloud_firestore/cloud_firestore.dart';

/// Gender preference for rides
enum GenderPreference { male, female, any }

/// Represents a rider/passenger in a ride
class RideParticipant {
  final String userId;
  final String displayName;
  final String? photoUrl;
  final int seatNumber;
  final DateTime joinedAt;
  final bool isCreator;

  RideParticipant({
    required this.userId,
    required this.displayName,
    this.photoUrl,
    required this.seatNumber,
    required this.joinedAt,
    this.isCreator = false,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'seatNumber': seatNumber,
    'joinedAt': Timestamp.fromDate(joinedAt),
    'isCreator': isCreator,
  };

  factory RideParticipant.fromMap(Map<String, dynamic> map) {
    return RideParticipant(
      userId: map['userId'] ?? '',
      displayName: map['displayName'] ?? 'Anonymous',
      photoUrl: map['photoUrl'],
      seatNumber: map['seatNumber'] ?? 1,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCreator: map['isCreator'] ?? false,
    );
  }
}

/// Main Ride model
class RideModel {
  final String id;
  final String creatorId;
  final String creatorName;
  final String? creatorPhotoUrl;
  final String startingPoint;
  final String destination;
  final DateTime rideDateTime;
  final GenderPreference genderPreference;
  final int totalSeats;
  final int availableSeats;
  final List<RideParticipant> participants;
  final DateTime createdAt;
  final bool isActive;

  RideModel({
    required this.id,
    required this.creatorId,
    required this.creatorName,
    this.creatorPhotoUrl,
    required this.startingPoint,
    required this.destination,
    required this.rideDateTime,
    required this.genderPreference,
    this.totalSeats = 6,
    required this.availableSeats,
    required this.participants,
    required this.createdAt,
    this.isActive = true,
  });

  /// Check if a user has joined this ride
  bool hasUserJoined(String userId) {
    return participants.any((p) => p.userId == userId);
  }

  /// Get occupied seats count
  int get occupiedSeats => participants.length;

  /// Check if ride is full
  bool get isFull => availableSeats <= 0;

  Map<String, dynamic> toFirestore() => {
    'creatorId': creatorId,
    'creatorName': creatorName,
    'creatorPhotoUrl': creatorPhotoUrl,
    'startingPoint': startingPoint,
    'destination': destination,
    'rideDateTime': Timestamp.fromDate(rideDateTime),
    'genderPreference': genderPreference.name,
    'totalSeats': totalSeats,
    'availableSeats': availableSeats,
    'participants': participants.map((p) => p.toMap()).toList(),
    'createdAt': Timestamp.fromDate(createdAt),
    'isActive': isActive,
  };

  factory RideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideModel(
      id: doc.id,
      creatorId: data['creatorId'] ?? '',
      creatorName: data['creatorName'] ?? 'Unknown',
      creatorPhotoUrl: data['creatorPhotoUrl'],
      startingPoint: data['startingPoint'] ?? '',
      destination: data['destination'] ?? '',
      rideDateTime:
          (data['rideDateTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      genderPreference: GenderPreference.values.firstWhere(
        (e) => e.name == data['genderPreference'],
        orElse: () => GenderPreference.any,
      ),
      totalSeats: data['totalSeats'] ?? 6,
      availableSeats: data['availableSeats'] ?? 6,
      participants:
          (data['participants'] as List<dynamic>?)
              ?.map((p) => RideParticipant.fromMap(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
    );
  }

  RideModel copyWith({
    String? id,
    String? creatorId,
    String? creatorName,
    String? creatorPhotoUrl,
    String? startingPoint,
    String? destination,
    DateTime? rideDateTime,
    GenderPreference? genderPreference,
    int? totalSeats,
    int? availableSeats,
    List<RideParticipant>? participants,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return RideModel(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      creatorName: creatorName ?? this.creatorName,
      creatorPhotoUrl: creatorPhotoUrl ?? this.creatorPhotoUrl,
      startingPoint: startingPoint ?? this.startingPoint,
      destination: destination ?? this.destination,
      rideDateTime: rideDateTime ?? this.rideDateTime,
      genderPreference: genderPreference ?? this.genderPreference,
      totalSeats: totalSeats ?? this.totalSeats,
      availableSeats: availableSeats ?? this.availableSeats,
      participants: participants ?? this.participants,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

/// Chat message model for ride chat
class RideChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderPhotoUrl;
  final String message;
  final DateTime sentAt;

  RideChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderPhotoUrl,
    required this.message,
    required this.sentAt,
  });

  Map<String, dynamic> toFirestore() => {
    'senderId': senderId,
    'senderName': senderName,
    'senderPhotoUrl': senderPhotoUrl,
    'message': message,
    'sentAt': Timestamp.fromDate(sentAt),
  };

  factory RideChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RideChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Unknown',
      senderPhotoUrl: data['senderPhotoUrl'],
      message: data['message'] ?? '',
      sentAt: (data['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
