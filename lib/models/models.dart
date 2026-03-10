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
  final bool isVerified;
  final int age;
  final String gender;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final int reportCount;
  final String? warningNote;
  final String subscriptionTier;
  final DateTime? subscriptionExpiry;
  final String? bio;
  final bool isSuspicious;
  final String? suspicionReason;

  const AdminUser({
    required this.uid,
    required this.displayName,
    this.email,
    this.photoUrl,
    required this.city,
    required this.isPremium,
    required this.isAdmin,
    required this.isBanned,
    this.isVerified = false,
    this.age = 0,
    this.gender = '',
    this.createdAt,
    this.lastActive,
    this.reportCount = 0,
    this.warningNote,
    this.subscriptionTier = '',
    this.subscriptionExpiry,
    this.bio,
    this.isSuspicious = false,
    this.suspicionReason,
  });

  factory AdminUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    if (d['createdAt'] is Timestamp) {
      created = (d['createdAt'] as Timestamp).toDate();
    }
    DateTime? lastActive;
    if (d['lastActive'] is Timestamp) {
      lastActive = (d['lastActive'] as Timestamp).toDate();
    }
    DateTime? subscriptionExpiry;
    if (d['subscriptionExpiry'] is Timestamp) {
      subscriptionExpiry = (d['subscriptionExpiry'] as Timestamp).toDate();
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
      isVerified: d['isVerified'] as bool? ?? false,
      age: d['age'] as int? ?? 0,
      gender: d['gender'] as String? ?? '',
      createdAt: created,
      lastActive: lastActive,
      reportCount: d['reportCount'] as int? ?? 0,
      warningNote: d['warningNote'] as String?,
      subscriptionTier: d['subscriptionTier'] as String? ?? '',
      subscriptionExpiry: subscriptionExpiry,
      bio: d['bio'] as String?,
      isSuspicious: d['isSuspicious'] as bool? ?? false,
      suspicionReason: d['suspicionReason'] as String?,
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

// ── AdminMatch ────────────────────────────────────────────────────────────
class AdminMatch {
  final String id;
  final String uid1;
  final String uid2;
  final String name1;
  final String name2;
  final DateTime? matchedAt;
  final bool hasConversation;
  final int messageCount;

  const AdminMatch({
    required this.id,
    required this.uid1,
    required this.uid2,
    this.name1 = '',
    this.name2 = '',
    this.matchedAt,
    this.hasConversation = false,
    this.messageCount = 0,
  });

  factory AdminMatch.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? ts;
    if (d['matchedAt'] is Timestamp) ts = (d['matchedAt'] as Timestamp).toDate();
    return AdminMatch(
      id: doc.id,
      uid1: d['uid1'] as String? ?? '',
      uid2: d['uid2'] as String? ?? '',
      name1: d['name1'] as String? ?? '',
      name2: d['name2'] as String? ?? '',
      matchedAt: ts,
      hasConversation: d['hasConversation'] as bool? ?? false,
      messageCount: d['messageCount'] as int? ?? 0,
    );
  }
}

// ── PhotoReview ───────────────────────────────────────────────────────────
class PhotoReview {
  final String id;
  final String uid;
  final String displayName;
  final String photoUrl;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime? submittedAt;

  const PhotoReview({
    required this.id,
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.status,
    this.submittedAt,
  });

  factory PhotoReview.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    DateTime? ts;
    if (d['submittedAt'] is Timestamp) ts = (d['submittedAt'] as Timestamp).toDate();
    return PhotoReview(
      id: doc.id,
      uid: d['uid'] as String? ?? '',
      displayName: d['displayName'] as String? ?? '',
      photoUrl: d['photoUrl'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      submittedAt: ts,
    );
  }
}

// ── AppConfig ─────────────────────────────────────────────────────────────
class AppConfig {
  final bool maintenanceMode;
  final bool registrationEnabled;
  final int freeDailyLikes;
  final int premiumDailyLikes;
  final int boostDurationMinutes;
  final double boostPriceUsd;
  final double premiumMonthlyUsd;
  final int minAge;
  final int maxAge;
  final double maxDistanceKm;
  final bool photoVerificationRequired;
  final bool ageVerificationRequired;

  const AppConfig({
    this.maintenanceMode = false,
    this.registrationEnabled = true,
    this.freeDailyLikes = 20,
    this.premiumDailyLikes = 999,
    this.boostDurationMinutes = 30,
    this.boostPriceUsd = 3.99,
    this.premiumMonthlyUsd = 9.99,
    this.minAge = 18,
    this.maxAge = 65,
    this.maxDistanceKm = 100,
    this.photoVerificationRequired = false,
    this.ageVerificationRequired = true,
  });

  factory AppConfig.fromMap(Map<String, dynamic> d) {
    return AppConfig(
      maintenanceMode: d['maintenanceMode'] as bool? ?? false,
      registrationEnabled: d['registrationEnabled'] as bool? ?? true,
      freeDailyLikes: d['freeDailyLikes'] as int? ?? 20,
      premiumDailyLikes: d['premiumDailyLikes'] as int? ?? 999,
      boostDurationMinutes: d['boostDurationMinutes'] as int? ?? 30,
      boostPriceUsd: (d['boostPriceUsd'] as num?)?.toDouble() ?? 3.99,
      premiumMonthlyUsd: (d['premiumMonthlyUsd'] as num?)?.toDouble() ?? 9.99,
      minAge: d['minAge'] as int? ?? 18,
      maxAge: d['maxAge'] as int? ?? 65,
      maxDistanceKm: (d['maxDistanceKm'] as num?)?.toDouble() ?? 100,
      photoVerificationRequired: d['photoVerificationRequired'] as bool? ?? false,
      ageVerificationRequired: d['ageVerificationRequired'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'maintenanceMode': maintenanceMode,
        'registrationEnabled': registrationEnabled,
        'freeDailyLikes': freeDailyLikes,
        'premiumDailyLikes': premiumDailyLikes,
        'boostDurationMinutes': boostDurationMinutes,
        'boostPriceUsd': boostPriceUsd,
        'premiumMonthlyUsd': premiumMonthlyUsd,
        'minAge': minAge,
        'maxAge': maxAge,
        'maxDistanceKm': maxDistanceKm,
        'photoVerificationRequired': photoVerificationRequired,
        'ageVerificationRequired': ageVerificationRequired,
      };
}
