import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ReconciliationResult {
  final int totalScannedUTRs;
  final int matchedOrdersCount;
  final int unmatchedOrdersCount;
  final List<Map<String, dynamic>> matchedOrders;

  ReconciliationResult({
    required this.totalScannedUTRs,
    required this.matchedOrdersCount,
    required this.unmatchedOrdersCount,
    required this.matchedOrders,
  });
}

class ReconciliationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ReconciliationResult> processStatement(File statementImage) async {
    // 1. Text Recognition
    final inputImage = InputImage.fromFile(statementImage);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final RecognizedText recognizedText = await textRecognizer.processImage(
      inputImage,
    );

    String fullText = recognizedText.text;
    textRecognizer.close();

    // 2. Extract UTRs (12-digit patterns)
    // Regex for exactly 12 digits.
    // \b ensures word boundaries so we don't pick up parts of longer numbers if any,
    // though UPI IDs are usually 12 digits.
    final RegExp utrRegex = RegExp(r'\b\d{12}\b');

    // Normalize text: remove whitespace to handle cases like "1234 5678 9012" if OCR splits it?
    // Actually, bank statements usually have them contiguous. OCR might split lines.
    // Let's stick to standard regex finding on the raw text first.
    // We clean the text a bit to handle confusing O/0?
    // A simple approach is finding patterns in the raw text.

    final Iterable<Match> matches = utrRegex.allMatches(fullText);
    final Set<String> foundUTRs = matches.map((m) => m.group(0)!).toSet();

    // 3. Fetch Pending Orders
    // Ideally, we should filter by the shop's ID if we had that context,
    // but the prompt says "Fetch ALL orders where status == 'verification_pending'".
    // We will assume this service runs in context of the logged-in shop,
    // but for now let's just fetch all 'verification_pending' for simplicity or filter later.
    // Since we don't have the shopId here conveniently, let's fetch matching UTRs.

    // Actually, querying *all* pending orders might be okay if the volume is low,
    // but better to Query matching the UTRs?
    // No, UTRs are in the image. We can't query Firestore "where UTR in [list from image]" effectively if list is huge?
    // But usually a statement has 10-50 txns. Firestore 'in' query supports up to 10 or 30.
    // Better strategy: Fetch all 'verification_pending' orders (maybe limited to recent ones or this shop)
    // and checks if their 'userProvidedUTR' is in our foundUTRs set.

    final QuerySnapshot pendingOrdersSnapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: 'verification_pending')
        .get();

    final List<Map<String, dynamic>> matchedOrders = [];
    int unmatchedCount = 0;

    for (var doc in pendingOrdersSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String? userUTR = data['userProvidedUTR'];
      final String orderId = doc.id;

      if (userUTR != null && foundUTRs.contains(userUTR.trim())) {
        matchedOrders.add({'orderId': orderId, 'data': data});
      } else {
        // This order is pending but not found in this statement
        unmatchedCount++;
      }
    }

    return ReconciliationResult(
      totalScannedUTRs: foundUTRs.length,
      matchedOrdersCount: matchedOrders.length,
      unmatchedOrdersCount:
          unmatchedCount, // This is technically "Pending orders NOT in this statement"
      matchedOrders: matchedOrders,
    );
  }

  Future<void> confirmOrders(List<String> orderIds) async {
    final batch = _firestore.batch();

    for (var id in orderIds) {
      final docRef = _firestore.collection('orders').doc(id);
      batch.update(docRef, {'status': 'confirmed'});
    }

    await batch.commit();
  }
}
