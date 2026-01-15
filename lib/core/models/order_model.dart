import 'package:cloud_firestore/cloud_firestore.dart';

enum PaymentStatus { pending, verified, rejected }

class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final double amount;
  final List<String> items; // Simplified for now
  final String status; // 'verification_pending', 'confirmed', 'rejected'
  final String? userProvidedUTR;
  final String? transactionId;
  final bool isAiVerified;
  final DateTime timestamp;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.items,
    required this.status,
    this.userProvidedUTR,
    this.transactionId,
    this.isAiVerified = false,
    required this.timestamp,
  });

  PaymentStatus get paymentStatus {
    switch (status) {
      case 'confirmed':
        return PaymentStatus.verified;
      case 'rejected':
        return PaymentStatus.rejected;
      default:
        return PaymentStatus.pending;
    }
  }

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OrderModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown User',
      amount: (data['amount'] ?? 0).toDouble(),
      items: List<String>.from(data['items'] ?? []),
      status: data['status'] ?? 'verification_pending',
      userProvidedUTR: data['userProvidedUTR'],
      transactionId: data['transactionId'],
      isAiVerified: data['isAiVerified'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'userName': userName,
      'amount': amount,
      'items': items,
      'status': status,
      'userProvidedUTR': userProvidedUTR,
      'transactionId': transactionId,
      'isAiVerified': isAiVerified,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
