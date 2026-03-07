import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// All Firestore/backend calls used by the admin panel.
class AdminService {
  final _db = FirebaseFirestore.instance;

  // ── Users ─────────────────────────────────────────────────────────────

  Stream<List<AdminUser>> getAllUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) {
          final users = s.docs.map(AdminUser.fromDoc).toList();
          users.sort((a, b) {
            if (a.createdAt == null && b.createdAt == null) return 0;
            if (a.createdAt == null) return 1;
            if (b.createdAt == null) return -1;
            return b.createdAt!.compareTo(a.createdAt!);
          });
          return users;
        });
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    final results = await Future.wait([
      _db.collection('users').count().get(),
      _db.collection('users').where('isPremium', isEqualTo: true).count().get(),
      _db.collection('matches').count().get(),
      _db.collection('reports').where('resolved', isEqualTo: false).count().get(),
      _db.collection('moments').count().get(),
      _db.collection('winks').count().get(),
    ]);
    return {
      'totalUsers':   results[0].count ?? 0,
      'premiumUsers': results[1].count ?? 0,
      'totalMatches': results[2].count ?? 0,
      'openReports':  results[3].count ?? 0,
      'moments':      results[4].count ?? 0,
      'winks':        results[5].count ?? 0,
    };
  }

  Future<List<Map<String, dynamic>>> getSignupsByDay(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('createdAt')
        .get();
    // Group by date string
    final Map<String, int> counts = {};
    for (final doc in snap.docs) {
      final ts = doc.data()['createdAt'];
      if (ts == null) continue;
      final dt = (ts as Timestamp).toDate();
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => {'date': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  Future<void> banUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isBanned': true});
  }

  Future<void> unbanUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isBanned': false});
  }

  Future<void> promoteToAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({'isAdmin': true});
  }

  Future<void> demoteFromAdmin(String uid) async {
    await _db.collection('users').doc(uid).update({'isAdmin': false});
  }

  Future<void> deleteUser(String uid) async {
    // Soft delete — mark hidden so feed excludes them; hard delete via Cloud Functions
    await _db.collection('users').doc(uid).update({
      'isBanned': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> grantPremium(String uid) async {
    await _db.collection('users').doc(uid).update({'isPremium': true});
  }

  Future<void> revokePremium(String uid) async {
    await _db.collection('users').doc(uid).update({'isPremium': false});
  }

  // ── Reports ──────────────────────────────────────────────────────────

  Stream<List<AdminReport>> getReports({bool unresolvedOnly = false}) {
    Query q = _db.collection('reports').orderBy('timestamp', descending: true);
    if (unresolvedOnly) q = q.where('resolved', isEqualTo: false);
    return q.snapshots().map(
        (s) => s.docs.map((d) => AdminReport.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>)).toList());
  }

  Future<void> resolveReport(String reportId) async {
    await _db
        .collection('reports')
        .doc(reportId)
        .update({'resolved': true, 'resolvedAt': FieldValue.serverTimestamp()});
  }

  Future<void> dismissReport(String reportId) async {
    await resolveReport(reportId);
  }

  // ── Moments ──────────────────────────────────────────────────────────

  Stream<List<AdminMoment>> getMoments() {
    return _db
        .collection('moments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => AdminMoment.fromDoc(d as DocumentSnapshot<Map<String, dynamic>>)).toList());
  }

  Future<void> deleteMoment(String momentId) async {
    await _db.collection('moments').doc(momentId).delete();
  }

  // ── Notifications ─────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getNotificationHistory() {
    return _db
        .collection('adminNotifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendBroadcast(String title, String body) async {
    await _db.collection('adminNotifications').add({
      'title': title,
      'body': body,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'queued',
    });
  }

  // ── Winks ─────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getWinks() {
    return _db
        .collection('winks')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }
}
