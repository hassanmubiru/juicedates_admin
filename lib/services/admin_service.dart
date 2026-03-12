import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';

/// All Firestore/backend calls used by the admin panel.
class AdminService {
  final _db = FirebaseFirestore.instance;

  // ── Users ──────────────────────────────────────────────────────────────

  Future<List<AdminUser>> getUsersOnce() async {
    final snap = await _db.collection('users').get();
    final users = snap.docs.map(AdminUser.fromDoc).toList();
    users.sort((a, b) {
      if (a.createdAt == null && b.createdAt == null) return 0;
      if (a.createdAt == null) return 1;
      if (b.createdAt == null) return -1;
      return b.createdAt!.compareTo(a.createdAt!);
    });
    return users;
  }

  /// Lightweight single-aggregate count — no document reads.
  Future<int> getUserCount() async {
    try {
      final result = await _db.collection('users').count().get();
      return result.count ?? 0;
    } catch (_) {
      // Fallback for environments where aggregate queries aren't supported.
      final snap = await _db.collection('users').get();
      return snap.size;
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    // Use client-side counting to avoid aggregation query requirements
    final results = await Future.wait([
      _db.collection('users').get(),
      _db.collection('matches').get(),
      _db.collection('reports').where('resolved', isEqualTo: false).get(),
      _db.collection('moments').get(),
      _db.collection('winks').get(),
      _db.collection('photoReviews').where('status', isEqualTo: 'pending').get(),
    ]);
    final userDocs = (results[0] as QuerySnapshot).docs;
    int premiumUsers = 0, bannedUsers = 0, verifiedUsers = 0;
    for (final doc in userDocs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['isPremium'] == true) premiumUsers++;
      if (d['isBanned'] == true) bannedUsers++;
      if (d['isVerified'] == true) verifiedUsers++;
    }
    return {
      'totalUsers':    userDocs.length,
      'premiumUsers':  premiumUsers,
      'totalMatches':  (results[1] as QuerySnapshot).docs.length,
      'openReports':   (results[2] as QuerySnapshot).docs.length,
      'moments':       (results[3] as QuerySnapshot).docs.length,
      'winks':         (results[4] as QuerySnapshot).docs.length,
      'bannedUsers':   bannedUsers,
      'verifiedUsers': verifiedUsers,
      'pendingPhotos': (results[5] as QuerySnapshot).docs.length,
    };
  }

  Future<List<Map<String, dynamic>>> getSignupsByDay(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('users')
        .where('createdAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('createdAt')
        .get();
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

  Future<List<Map<String, dynamic>>> getMatchesByDay(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _db
        .collection('matches')
        .where('matchedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('matchedAt')
        .get();
    final Map<String, int> counts = {};
    for (final doc in snap.docs) {
      final ts = doc.data()['matchedAt'];
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
    await _db.collection('users').doc(uid).update({
      'isBanned': true,
      'deletedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> grantPremium(String uid, {String tier = 'gold'}) async {
    await _db.collection('users').doc(uid).update({
      'isPremium': true,
      'subscriptionTier': tier,
      'subscribedAt': FieldValue.serverTimestamp(),
      'subscriptionExpiry': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30))),
    });
  }

  Future<void> revokePremium(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isPremium': false,
      'subscriptionTier': 'free',
      'subscriptionExpiry': null,
    });
  }

  Future<void> saveAdminNote(String uid, String note) async {
    await _db.collection('users').doc(uid).update({'warningNote': note});
  }

  Future<void> verifyUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isVerified': true});
  }

  Future<void> unverifyUser(String uid) async {
    await _db.collection('users').doc(uid).update({'isVerified': false});
  }

  Future<void> flagAsSuspicious(String uid, String reason) async {
    await _db.collection('users').doc(uid).update({
      'isSuspicious': true,
      'suspicionReason': reason,
      'suspicionFlaggedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unflagSuspicious(String uid) async {
    await _db.collection('users').doc(uid).update({
      'isSuspicious': false,
      'suspicionReason': FieldValue.delete(),
    });
  }

  Future<List<Map<String, dynamic>>> getSubscriptionsByDay(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    // Fetch all premium users client-side to avoid composite index requirement
    final snap = await _db
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .get();
    final Map<String, int> counts = {};
    for (final doc in snap.docs) {
      final ts = doc.data()['subscribedAt'];
      if (ts == null) continue;
      final dt = (ts as Timestamp).toDate();
      if (dt.isBefore(cutoff)) continue; // filter in Dart
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    return counts.entries
        .map((e) => {'date': e.key, 'count': e.value})
        .toList()
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
  }

  // ── Matches ────────────────────────────────────────────────────────────

  Stream<List<AdminMatch>> getMatches({int limit = 200}) {
    return _db
        .collection('matches')
        .orderBy('matchedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdminMatch.fromDoc(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> deleteMatch(String matchId) async {
    await _db.collection('matches').doc(matchId).delete();
  }

  // ── Reports ────────────────────────────────────────────────────────────

  Stream<List<AdminReport>> getReports({bool unresolvedOnly = false}) {
    return _db
        .collection('reports')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((s) {
          final docs = s.docs
              .map((d) => AdminReport.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>))
              .toList();
          if (unresolvedOnly) {
            return docs.where((r) => !r.resolved).toList();
          }
          return docs;
        });
  }

  Future<void> resolveReport(String reportId) async {
    await _db.collection('reports').doc(reportId).update(
        {'resolved': true, 'resolvedAt': FieldValue.serverTimestamp()});
  }

  Future<void> dismissReport(String reportId) async {
    await resolveReport(reportId);
  }

  // ── Moments ────────────────────────────────────────────────────────────

  Stream<List<AdminMoment>> getMoments() {
    return _db
        .collection('moments')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => AdminMoment.fromDoc(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
  }

  Future<void> deleteMoment(String momentId) async {
    await _db.collection('moments').doc(momentId).delete();
  }

  // ── Notifications ──────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getNotificationHistory() {
    return _db
        .collection('adminNotifications')
        .orderBy('sentAt', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  Future<void> sendBroadcast(String title, String body,
      {String segment = 'all', String cityTarget = ''}) async {
    await _db.collection('adminNotifications').add({
      'title': title,
      'body': body,
      'segment': segment,
      if (cityTarget.isNotEmpty) 'cityTarget': cityTarget,
      'sentAt': FieldValue.serverTimestamp(),
      'status': 'queued',
    });
  }

  // ── Winks ──────────────────────────────────────────────────────────────

  Stream<List<Map<String, dynamic>>> getWinks() {
    return _db
        .collection('winks')
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ── Photo Reviews ──────────────────────────────────────────────────────

  Stream<List<PhotoReview>> getPendingPhotoReviews() {
    return _db
        .collection('photoReviews')
        .snapshots()
        .map((s) {
          final reviews = s.docs
              .map((d) => PhotoReview.fromDoc(
                  d as DocumentSnapshot<Map<String, dynamic>>))
              .where((r) => r.status == 'pending')
              .toList()
            ..sort((a, b) => (a.submittedAt ?? DateTime(0))
                .compareTo(b.submittedAt ?? DateTime(0)));
          return reviews;
        });
  }

  Future<void> approvePhoto(String reviewId, String uid) async {
    final batch = _db.batch();
    batch.update(_db.collection('photoReviews').doc(reviewId),
        {'status': 'approved', 'reviewedAt': FieldValue.serverTimestamp()});
    batch.update(_db.collection('users').doc(uid), {'isVerified': true});
    await batch.commit();
  }

  Future<void> rejectPhoto(String reviewId, String uid,
      {String reason = 'Does not meet guidelines'}) async {
    final batch = _db.batch();
    batch.update(_db.collection('photoReviews').doc(reviewId), {
      'status': 'rejected',
      'rejectReason': reason,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('users').doc(uid), {'isVerified': false});
    await batch.commit();
  }

  // ── Subscriptions ──────────────────────────────────────────────────────

  Stream<List<AdminUser>> getVerifiedUsers() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) {
          final users = <AdminUser>[];
          for (final doc in s.docs) {
            try {
              final u = AdminUser.fromDoc(doc);
              if (u.isVerified && !u.isBanned) users.add(u);
            } catch (_) {}
          }
          users.sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
          return users;
        });
  }

  Stream<List<AdminUser>> getUnverifiedUsersWithPhotos() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) {
          final users = <AdminUser>[];
          for (final doc in s.docs) {
            try {
              final u = AdminUser.fromDoc(doc);
              if (!u.isVerified &&
                  !u.isBanned &&
                  u.photoUrl != null &&
                  u.photoUrl!.isNotEmpty) {
                users.add(u);
              }
            } catch (_) {}
          }
          users.sort((a, b) => (b.createdAt ?? DateTime(0))
              .compareTo(a.createdAt ?? DateTime(0)));
          return users;
        });
  }

  Future<List<AdminUser>> getPremiumUsers() async {
    final snap = await _db
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .get();
    final users = snap.docs.map(AdminUser.fromDoc).toList();
    users.sort((a, b) => (b.createdAt ?? DateTime(0))
        .compareTo(a.createdAt ?? DateTime(0)));
    return users;
  }

  Future<Map<String, int>> getSubscriptionBreakdown() async {
    // Fetch all users client-side to avoid needing multiple single-field indexes
    final snap = await _db.collection('users').get();
    int plus = 0, gold = 0, platinum = 0;
    for (final doc in snap.docs) {
      final tier = doc.data()['subscriptionTier'] as String? ?? '';
      if (tier == 'plus') {
        plus++;
      } else if (tier == 'gold') {
        gold++;
      } else if (tier == 'platinum') {
        platinum++;
      }
    }
    // Include total so callers don't need a separate count query
    return {'plus': plus, 'gold': gold, 'platinum': platinum, 'total': snap.size};
  }

  // ── App Config ────────────────────────────────────────────────────────

  Future<AppConfig> getAppConfig() async {
    final doc = await _db.collection('appConfig').doc('global').get();
    if (!doc.exists) return const AppConfig();
    return AppConfig.fromMap(doc.data() ?? {});
  }

  Future<void> saveAppConfig(AppConfig config) async {
    await _db
        .collection('appConfig')
        .doc('global')
        .set(config.toMap(), SetOptions(merge: true));
  }
}
