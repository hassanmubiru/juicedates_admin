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

  Future<Map<String, dynamic>> getAdminStats() async {
    final results = await Future.wait([
      _db.collection('users').count().get(),
      _db.collection('users').where('isPremium', isEqualTo: true).count().get(),
      _db.collection('matches').count().get(),
      _db.collection('reports').where('resolved', isEqualTo: false).count().get(),
      _db.collection('moments').count().get(),
      _db.collection('winks').count().get(),
      _db.collection('users').where('isBanned', isEqualTo: true).count().get(),
      _db.collection('users').where('isVerified', isEqualTo: true).count().get(),
      _db.collection('photoReviews').where('status', isEqualTo: 'pending').count().get(),
    ]);
    return {
      'totalUsers':    results[0].count ?? 0,
      'premiumUsers':  results[1].count ?? 0,
      'totalMatches':  results[2].count ?? 0,
      'openReports':   results[3].count ?? 0,
      'moments':       results[4].count ?? 0,
      'winks':         results[5].count ?? 0,
      'bannedUsers':   results[6].count ?? 0,
      'verifiedUsers': results[7].count ?? 0,
      'pendingPhotos': results[8].count ?? 0,
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
    final snap = await _db
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .where('subscribedAt', isGreaterThan: Timestamp.fromDate(cutoff))
        .orderBy('subscribedAt')
        .get();
    final Map<String, int> counts = {};
    for (final doc in snap.docs) {
      final ts = doc.data()['subscribedAt'];
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
    Query q =
        _db.collection('reports').orderBy('timestamp', descending: true);
    if (unresolvedOnly) q = q.where('resolved', isEqualTo: false);
    return q.snapshots().map((s) => s.docs
        .map((d) => AdminReport.fromDoc(
            d as DocumentSnapshot<Map<String, dynamic>>))
        .toList());
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
        .where('status', isEqualTo: 'pending')
        .orderBy('submittedAt', descending: false)
        .snapshots()
        .map((s) => s.docs
            .map((d) => PhotoReview.fromDoc(
                d as DocumentSnapshot<Map<String, dynamic>>))
            .toList());
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
          final users = s.docs
              .map(AdminUser.fromDoc)
              .where((u) => u.isVerified && !u.isBanned)
              .toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
          return users;
        });
  }

  Stream<List<AdminUser>> getUnverifiedUsersWithPhotos() {
    return _db
        .collection('users')
        .snapshots()
        .map((s) {
          final users = s.docs
              .map(AdminUser.fromDoc)
              .where((u) =>
                  !u.isVerified &&
                  !u.isBanned &&
                  u.photoUrl != null &&
                  u.photoUrl!.isNotEmpty)
              .toList()
            ..sort((a, b) => (b.createdAt ?? DateTime(0))
                .compareTo(a.createdAt ?? DateTime(0)));
          return users;
        });
  }

  Future<List<AdminUser>> getPremiumUsers() async {
    final snap = await _db
        .collection('users')
        .where('isPremium', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map(AdminUser.fromDoc).toList();
  }

  Future<Map<String, int>> getSubscriptionBreakdown() async {
    final results = await Future.wait([
      _db.collection('users').where('subscriptionTier', isEqualTo: 'plus').count().get(),
      _db.collection('users').where('subscriptionTier', isEqualTo: 'gold').count().get(),
      _db.collection('users').where('subscriptionTier', isEqualTo: 'platinum').count().get(),
    ]);
    return {
      'plus':     results[0].count ?? 0,
      'gold':     results[1].count ?? 0,
      'platinum': results[2].count ?? 0,
    };
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
