import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:marketplace/core/models/campaign_model.dart';
import 'package:marketplace/core/services/r2_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final campaignServiceProvider = Provider((ref) => CampaignService());

final activeCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return ref.watch(campaignServiceProvider).getActiveCampaigns();
});

final pendingCampaignsProvider = StreamProvider<List<CampaignModel>>((ref) {
  return ref.watch(campaignServiceProvider).getPendingCampaigns();
});

final designRequestedCampaignsProvider = StreamProvider<List<CampaignModel>>((
  ref,
) {
  return ref.watch(campaignServiceProvider).getDesignRequestedCampaigns();
});

class CampaignService {
  final _firestore = FirebaseFirestore.instance;
  final _r2Storage = R2StorageService();

  // Create Campaign
  Future<void> createCampaign({
    required String shopId,
    required String shopName,
    File? bannerImage,
    required CampaignType type,
    required int durationDays,
    required double amountPaid,
    String? transactionId,
  }) async {
    String? bannerUrl;

    if (bannerImage != null) {
      final result = await _r2Storage.uploadFromFile(
        file: bannerImage,
        folder: 'campaigns',
        contentType: 'image/jpeg',
      );

      if (result.success) {
        bannerUrl = result.url;
      } else {
        throw Exception('Failed to upload banner: ${result.error}');
      }
    }

    final campaign = CampaignModel(
      id: '',
      shopId: shopId,
      shopName: shopName,
      bannerUrl: bannerUrl,
      type: type,
      status: type == CampaignType.marketplace
          ? CampaignStatus.design_requested
          : CampaignStatus.pending,
      createdAt: DateTime.now(),
      durationDays: durationDays,
      amountPaid: amountPaid,
      transactionId: transactionId,
    );

    await _firestore.collection('campaigns').add(campaign.toFirestore());
  }

  // Get Active Campaigns for Popup can be filtered by logic if needed
  Stream<List<CampaignModel>> getActiveCampaigns() {
    return _firestore
        .collection('campaigns')
        .where('status', isEqualTo: CampaignStatus.active.name)
        .snapshots()
        .map((snapshot) {
          final campaigns = snapshot.docs
              .map((doc) => CampaignModel.fromFirestore(doc))
              .toList();
          // Filter expired ones locally if startDate query is complex or just do it here
          return campaigns.where((c) => c.isActive).toList();
        });
  }

  // Get Pending Campaigns for Admin
  Stream<List<CampaignModel>> getPendingCampaigns() {
    return _firestore
        .collection('campaigns')
        .where('status', isEqualTo: CampaignStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CampaignModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Approve Campaign
  Future<void> approveCampaign(String campaignId) async {
    await _firestore.collection('campaigns').doc(campaignId).update({
      'status': CampaignStatus.active.name,
      'startDate': Timestamp.now(),
    });
  }

  // Reject Campaign
  Future<void> rejectCampaign(String campaignId, String reason) async {
    await _firestore.collection('campaigns').doc(campaignId).update({
      'status': CampaignStatus.rejected.name,
      'adminNote': reason,
    });
  }

  // Get Design Requested Campaigns
  Stream<List<CampaignModel>> getDesignRequestedCampaigns() {
    return _firestore
        .collection('campaigns')
        .where('status', isEqualTo: CampaignStatus.design_requested.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => CampaignModel.fromFirestore(doc))
              .toList(),
        );
  }

  // Complete Design (Upload Banner & Move to Pending Approval)
  Future<void> completeDesign({
    required String campaignId,
    required File bannerImage,
  }) async {
    final result = await _r2Storage.uploadFromFile(
      file: bannerImage,
      folder: 'campaigns',
      contentType: 'image/jpeg',
    );

    if (result.success) {
      await _firestore.collection('campaigns').doc(campaignId).update({
        'bannerUrl': result.url,
        'status': CampaignStatus.pending.name,
      });
    } else {
      throw Exception('Failed to upload banner: ${result.error}');
    }
  }
}
