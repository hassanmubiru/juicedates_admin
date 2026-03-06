import 'package:cloud_firestore/cloud_firestore.dart';

// ── AdminUser ─────────────────────────────────────────────────────────────
class AdminUser {
  final String uid;
  final String displayName;
  final String? email;
  final String? photoUrl;
  final String city;
  final bool isPremium;
  final bool isAdmin;
  final bool isBanned;
  final DateTime? createdAt;

  const AdminUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.city,
    required this.isPremium,
    required this.isAdmin,
    required this.isBanned,
    this.createdAt,
  });

  factory AdminUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    if (d['createdAt'] is Timestamp) {
      created = (d['createdAt'] as Timestamp).toDate();
    }
    return AdminUser(
      uid: doc.id,
      displayName: d['displayName'] as String? ?? 'Unknown',
      email: d['email'] as String?,
      photoUrl: d['photoUrl'] as String?,
      city: d['city'] as String? ?? '',
      isPremium: d['isPremium'] as bool? ?? false,
      isAdmin: d['isAdmin'] as bool? ?? false,
      isBanned: d['isBanned'] as bool? ?? false,
      createdAt: created,
    );
  }
}

// ── AdminReport ───────────────────────────────────────────────────────────
class AdminReport {
  final String id;
  final String reporterUid;
  final String reportedUid;
  final String reason;
  final bool resolved;
  final DateTime? timestamp;

  const AdminReport({
    required this.id,
    required this.reporterUid,
    required this.reportedUid,
    required this.reason,
    required this.resolved,
    this.timestamp,
  });

  factory AdminReport.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? ts;
    if (d['timestamp'] is Timestamp) {
      ts = (d['timestamp'] as Timestamp).toDate();
    }
    return AdminReport(
      id: doc.id,
      reporterUid: d['reporterUid'] as String? ?? '',
      reportedUid: d['reportedUid'] as String? ?? '',
      reason: d['reason'] as String? ?? '',
      resolved: d['resolved'] as bool? ?? false,
      timestamp: ts,
    );
  }
}

// ── AdminMoment ───────────────────────────────────────────────────────────
class AdminMoment {
  final String id;
  final String uid;
  final String displayName;
  final String? authorPhotoUrl;
  final String text;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime expiresAt;

  const AdminMoment({
    required this.id,
    required this.uid,
    required this.displayName,
    this.authorPhotoUrl,
    required this.text,
    this.imageUrl,
    required this.createdAt,
    required this.expiresAt,
  });

  factory AdminMoment.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime parse(dynamic v) =>
        v is Timestamp ? v.toDate() : DateTime.now();
    return AdminMoment(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      authorPhotoUrl: d['authorPhotoUrl'] as String?,
      text: d['text'] as String? ?? '',
      imageUrl: d['imageUrl'] as String?,
      createdAt: parse(d['createdAt']),
      expiresAt: parse(d['expiresAt']),
    );
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
