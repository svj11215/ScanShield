import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/scan_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user data
  Future<UserModel> getUserData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) {
      throw 'User document not found';
    }
    return UserModel.fromMap(doc.data()!);
  }

  // Get all user scans ordered by scanned_at desc
  Future<List<ScanModel>> getUserScans(String uid) async {
    final querySnapshot = await _firestore
        .collection('scans')
        .where('user_id', isEqualTo: uid)
        .orderBy('scanned_at', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => ScanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Get recent scans (limit = 3)
  Future<List<ScanModel>> getRecentScans(String uid, {int limit = 3}) async {
    final querySnapshot = await _firestore
        .collection('scans')
        .where('user_id', isEqualTo: uid)
        .orderBy('scanned_at', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs
        .map((doc) => ScanModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // Stream user data
  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          return UserModel.fromMap(doc.data()!);
        });
  }

  // Calculate stats from a list of scan models
  static Map<String, int> calculateStats(List<ScanModel> scans) {
    int totalScans = scans.length;
    int maliciousCount = 0;
    int safeCount = 0;

    for (var scan in scans) {
      final level = scan.riskLevel.toLowerCase();
      if (level == 'high' || level == 'malicious') {
        maliciousCount++;
      } else if (level == 'low' || level == 'safe') {
        safeCount++;
      }
    }

    return {
      'totalScans': totalScans,
      'maliciousCount': maliciousCount,
      'safeCount': safeCount,
    };
  }

  // Get user stats (totalScans, maliciousCount, safeCount)
  Future<Map<String, int>> getUserStats(String uid) async {
    final scans = await getUserScans(uid);
    return calculateStats(scans);
  }

  // Save scan result to scans collection
  Future<String> saveScanResult(ScanModel scan) async {
    final docRef = await _firestore.collection('scans').add(scan.toMap());
    
    // Increment stats
    await incrementTotalScans(scan.userId);
    await updateThreatStats(scan.riskLevel);
    
    return docRef.id;
  }

  // Get all user scans as a stream for real-time updates
  Stream<List<ScanModel>> getUserScansStream(String uid) {
    return _firestore
        .collection('scans')
        .where('user_id', isEqualTo: uid)
        .orderBy('scanned_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScanModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Delete multiple scans using a batch operation
  Future<void> deleteMultipleScans(List<String> scanIds) async {
    final batch = _firestore.batch();
    for (final scanId in scanIds) {
      final docRef = _firestore.collection('scans').doc(scanId);
      batch.delete(docRef);
    }
    await batch.commit();
  }

  // Query scans with specific filters and sorting options
  Future<List<ScanModel>> getScansByFilter(
    String uid, {
    String? level,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
  }) async {
    Query query = _firestore.collection('scans').where('user_id', isEqualTo: uid);

    if (level != null && level.isNotEmpty) {
      query = query.where('risk_level', isEqualTo: level);
    }

    if (dateFrom != null) {
      query = query.where('scanned_at', isGreaterThanOrEqualTo: Timestamp.fromDate(dateFrom));
    }

    if (dateTo != null) {
      query = query.where('scanned_at', isLessThanOrEqualTo: Timestamp.fromDate(dateTo));
    }

    // Default sorting logic
    String field = 'scanned_at';
    bool descending = true;

    if (sortBy != null) {
      switch (sortBy) {
        case 'Oldest First':
          field = 'scanned_at';
          descending = false;
          break;
        case 'Highest Risk Score':
          field = 'overall_risk';
          descending = true;
          break;
        case 'Lowest Risk Score':
          field = 'overall_risk';
          descending = false;
          break;
        case 'Name (A-Z)':
          field = 'file_name';
          descending = false;
          break;
        case 'Newest First':
        default:
          field = 'scanned_at';
          descending = true;
          break;
      }
    }

    // If sorting by name or risk score, we still need to apply ordering, 
    // note: Firestore might require composite indexes if combined with range filters.
    // To avoid index requirements in local testing, we order client-side, but keep orderBy structured.
    final querySnapshot = await query.get();
    var scans = querySnapshot.docs
        .map((doc) => ScanModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();

    // Sort client-side to guarantee compatibility without index restrictions
    scans.sort((a, b) {
      int comparison = 0;
      if (field == 'scanned_at') {
        comparison = a.scannedAt.compareTo(b.scannedAt);
      } else if (field == 'overall_risk' || field == 'risk_score') {
        comparison = a.overallRisk.compareTo(b.overallRisk);
      } else if (field == 'file_name' || field == 'apk_name') {
        comparison = a.fileName.toLowerCase().compareTo(b.fileName.toLowerCase());
      }
      return descending ? -comparison : comparison;
    });

    return scans;
  }

  // Delete scan
  Future<void> deleteScan(String scanId) async {
    await _firestore.collection('scans').doc(scanId).delete();
  }

  // Increment total scans in user doc
  Future<void> incrementTotalScans(String uid) async {
    await _firestore.collection('users').doc(uid).update({
      'total_scans': FieldValue.increment(1),
    });
  }

  // Update threat stats / global stats
  Future<void> updateThreatStats(String level) async {
    final docRef = _firestore.collection('stats').doc('global_stats');
    final levelField = '${level.toLowerCase()}_count';

    await docRef.set({
      'total_scans': FieldValue.increment(1),
      levelField: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
