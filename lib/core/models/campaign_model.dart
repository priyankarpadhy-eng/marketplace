import 'package:cloud_firestore/cloud_firestore.dart';

enum CampaignType { self, marketplace }

enum CampaignStatus {
  pending,
  approved,
  rejected,
  active,
  expired,
  design_requested,
}

class CampaignModel {
  final String id;
  final String shopId;
  final String shopName;
  final String? bannerUrl; // Null if requested from marketplace initially
  final CampaignType type;
  final CampaignStatus status;
  final DateTime createdAt;
  final DateTime? startDate;
  final int durationDays;
  final double amountPaid;
  final String? transactionId;
  final String? adminNote;

  const CampaignModel({
    required this.id,
    required this.shopId,
    required this.shopName,
    this.bannerUrl,
    required this.type,
    required this.status,
    required this.createdAt,
    this.startDate,
    required this.durationDays,
    required this.amountPaid,
    this.transactionId,
    this.adminNote,
  });

  bool get isActive {
    if (status != CampaignStatus.active || startDate == null) return false;
    final endDate = startDate!.add(Duration(days: durationDays));
    return DateTime.now().isBefore(endDate);
  }

  factory CampaignModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CampaignModel(
      id: doc.id,
      shopId: data['shopId'] ?? '',
      shopName: data['shopName'] ?? '',
      bannerUrl: data['bannerUrl'],
      type: CampaignType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => CampaignType.self,
      ),
      status: CampaignStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => CampaignStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      durationDays: data['durationDays'] ?? 1,
      amountPaid: (data['amountPaid'] as num?)?.toDouble() ?? 0.0,
      transactionId: data['transactionId'],
      adminNote: data['adminNote'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'shopId': shopId,
      'shopName': shopName,
      'bannerUrl': bannerUrl,
      'type': type.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'durationDays': durationDays,
      'amountPaid': amountPaid,
      'transactionId': transactionId,
      'adminNote': adminNote,
    };
  }
}
