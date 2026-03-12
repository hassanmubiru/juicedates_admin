import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});
  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState extends State<ContentModerationScreen>
    with SingleTickerProviderStateMixin {
  final _svc = AdminService();
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ── Photo review actions ───────────────────────────────────────────────

  Future<void> _approveReview(PhotoReview review) async {
    await _svc.approvePhoto(review.id, review.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ Approved ${review.displayName}\'s photo'),
        backgroundColor: kSuccess,
      ));
    }
  }

  Future<void> _rejectReview(PhotoReview review) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(),
    );
    if (reason == null) return;
    await _svc.rejectPhoto(review.id, review.uid, reason: reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✗ Rejected ${review.displayName}\'s photo'),
        backgroundColor: kDanger,
      ));
    }
  }

  // ── User verification actions ─────────────────────────────────────────

  Future<void> _verifyUser(AdminUser user) async {
    await _svc.verifyUser(user.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✓ ${user.displayName} verified'),
        backgroundColor: kSuccess,
      ));
    }
  }

  Future<void> _rejectUser(AdminUser user) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(),
    );
    if (reason == null) return;
    // Flag the user and save a warning note so the reason is visible in Users screen
    await Future.wait([
      _svc.flagAsSuspicious(user.uid, reason),
      _svc.saveAdminNote(user.uid, 'Verification rejected: $reason'),
    ]);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('✗ Rejected ${user.displayName}\'s verification'),
        backgroundColor: kDanger,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Moderation',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kTangerine,
          labelColor: Colors.white,
          unselectedLabelColor: kMuted,
          tabs: const [
            Tab(icon: Icon(Icons.photo_library_rounded), text: 'Photo Queue'),
            Tab(icon: Icon(Icons.how_to_reg_rounded), text: 'Verify Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _PhotoQueueTab(
            svc: _svc,
            onApprove: _approveReview,
            onReject: _rejectReview,
          ),
          _VerifyUsersTab(
            svc: _svc,
            onVerify: _verifyUser,
            onReject: _rejectUser,
          ),
        ],
      ),
    );
  }
}

// ── Tab 1: photoReviews collection ────────────────────────────────────────
class _PhotoQueueTab extends StatelessWidget {
  final AdminService svc;
  final void Function(PhotoReview) onApprove;
  final void Function(PhotoReview) onReject;

  const _PhotoQueueTab(
      {required this.svc, required this.onApprove, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PhotoReview>>(
      stream: svc.getPendingPhotoReviews(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kTangerine));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: kDanger)));
        }
        final reviews = snap.data ?? [];
        if (reviews.isEmpty) {
          return const _EmptyState(
            icon: Icons.verified_user_rounded,
            title: 'No photo submissions',
            subtitle:
                'When users submit photos for review, they will appear here.',
          );
        }
        return _ReviewGrid<PhotoReview>(
          items: reviews,
          count: reviews.length,
          photoUrl: (r) => r.photoUrl,
          name: (r) => r.displayName,
          subtitle: (r) => r.submittedAt != null
              ? 'Submitted ${DateFormat('MMM d, HH:mm').format(r.submittedAt!)}'
              : '',
          onApprove: onApprove,
          onReject: onReject,
        );
      },
    );
  }
}

// ── Tab 2: unverified users with photos ───────────────────────────────────
class _VerifyUsersTab extends StatelessWidget {
  final AdminService svc;
  final void Function(AdminUser) onVerify;
  final void Function(AdminUser) onReject;

  const _VerifyUsersTab(
      {required this.svc, required this.onVerify, required this.onReject});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminUser>>(
      stream: svc.getUnverifiedUsersWithPhotos(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: kTangerine));
        }
        if (snap.hasError) {
          return Center(
              child: Text('Error: ${snap.error}',
                  style: const TextStyle(color: kDanger)));
        }
        final users = snap.data ?? [];
        if (users.isEmpty) {
          return const _EmptyState(
            icon: Icons.how_to_reg_rounded,
            title: 'All users verified',
            subtitle: 'No unverified accounts with photos at this time.',
          );
        }
        return _ReviewGrid<AdminUser>(
          items: users,
          count: users.length,
          photoUrl: (u) => u.photoUrl ?? '',
          name: (u) => u.displayName,
          subtitle: (u) {
            final parts = <String>[];
            if (u.age > 0) parts.add('${u.age}');
            if (u.gender.isNotEmpty) parts.add(u.gender);
            if (u.city.isNotEmpty) parts.add(u.city);
            return parts.join(' · ');
          },
          onApprove: onVerify,
          onReject: onReject,
        );
      },
    );
  }
}

// ── Generic review grid ───────────────────────────────────────────────────
class _ReviewGrid<T> extends StatelessWidget {
  final List<T> items;
  final int count;
  final String Function(T) photoUrl;
  final String Function(T) name;
  final String Function(T) subtitle;
  final void Function(T) onApprove;
  final void Function(T) onReject;

  const _ReviewGrid({
    required this.items,
    required this.count,
    required this.photoUrl,
    required this.name,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
          child: Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: kWarning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: kWarning.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$count pending',
                  style: const TextStyle(
                      color: kWarning,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Review each photo and approve or reject.',
                  style: TextStyle(color: kMuted, fontSize: 12)),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(builder: (_, box) {
            final cols = (box.maxWidth / 300).floor().clamp(1, 4);
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.72,
              ),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return _ReviewCard(
                  photoUrl: photoUrl(item),
                  name: name(item),
                  subtitle: subtitle(item),
                  onApprove: () => onApprove(item),
                  onReject: () => onReject(item),
                );
              },
            );
          }),
        ),
      ],
    );
  }
}

// ── Review card ───────────────────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final String photoUrl;
  final String name;
  final String subtitle;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewCard({
    required this.photoUrl,
    required this.name,
    required this.subtitle,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                        color: kSidebar,
                        child: const Center(
                            child: CircularProgressIndicator(
                                color: kTangerine, strokeWidth: 2))),
                    errorWidget: (_, _, _) => Container(
                        color: kSidebar,
                        child: const Icon(Icons.broken_image_rounded,
                            color: kMuted, size: 40)),
                  )
                : Container(
                    color: kSidebar,
                    child: const Icon(Icons.person_rounded,
                        color: kMuted, size: 40)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style:
                          const TextStyle(color: kMuted, fontSize: 11),
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: kDanger,
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          side: BorderSide(
                              color: kDanger.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject',
                            style: TextStyle(fontSize: 12)),
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: kSuccess,
                          padding:
                              const EdgeInsets.symmetric(vertical: 6),
                          side: BorderSide(
                              color: kSuccess.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve',
                            style: TextStyle(fontSize: 12)),
                        onPressed: onApprove,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState(
      {required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: kSuccess),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(color: kMuted),
                textAlign: TextAlign.center),
          ],
        ),
      );
}

// ── Reject reason dialog ──────────────────────────────────────────────────
class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  String? _selected;
  final _custom = TextEditingController();
  static const _reasons = [
    'Does not show face clearly',
    'Inappropriate or explicit content',
    'Appears to be underage',
    'Not a real photo (cartoon, meme, etc.)',
    'Contains personal information (phone, email)',
    'Copyrighted celebrity/brand image',
  ];

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCard,
      title: const Text('Rejection Reason',
          style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _reasons
                    .map((r) => RadioListTile<String>(
                          value: r,
                          fillColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                                ? kTangerine
                                : null,
                          ),
                          title: Text(r,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _custom,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Custom reason (optional)…'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selected != null || _custom.text.isNotEmpty)
              ? () => Navigator.pop(
                  context,
                  _custom.text.isNotEmpty
                      ? _custom.text.trim()
                      : _selected)
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}


class ContentModerationScreen extends StatefulWidget {
  const ContentModerationScreen({super.key});
  @override
  State<ContentModerationScreen> createState() =>
      _ContentModerationScreenState();
}

class _ContentModerationScreenState
    extends State<ContentModerationScreen> {
  final _svc = AdminService();

  Future<void> _approve(PhotoReview review) async {
    await _svc.approvePhoto(review.id, review.uid);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Approved ${review.displayName}\'s photo'),
          backgroundColor: kSuccess,
        ),
      );
    }
  }

  Future<void> _reject(PhotoReview review) async {
    String? reason;
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _RejectReasonDialog(),
    );
    if (selected == null) return;
    reason = selected;
    await _svc.rejectPhoto(review.id, review.uid, reason: reason);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✗ Rejected ${review.displayName}\'s photo'),
          backgroundColor: kDanger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Photo Moderation',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<PhotoReview>>(
        stream: _svc.getPendingPhotoReviews(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          final reviews = snap.data ?? [];

          if (reviews.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified_user_rounded,
                      size: 64, color: kSuccess),
                  SizedBox(height: 16),
                  Text('All caught up!',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('No photos pending review.',
                      style: TextStyle(color: kMuted)),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: kWarning.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: kWarning.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        '${reviews.length} pending',
                        style: const TextStyle(
                            color: kWarning,
                            fontWeight: FontWeight.w600,
                            fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Review each photo and approve or reject.',
                      style: TextStyle(color: kMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (_, box) {
                    final cols = (box.maxWidth / 300).floor().clamp(1, 4);
                    return GridView.builder(
                      padding: const EdgeInsets.all(24),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      itemCount: reviews.length,
                      itemBuilder: (_, i) => _ReviewCard(
                        review: reviews[i],
                        onApprove: () => _approve(reviews[i]),
                        onReject: () => _reject(reviews[i]),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final PhotoReview review;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _ReviewCard(
      {required this.review,
      required this.onApprove,
      required this.onReject});

  @override
  Widget build(BuildContext context) {
    final ts = review.submittedAt != null
        ? DateFormat('MMM d, HH:mm').format(review.submittedAt!)
        : '—';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo
          Expanded(
            child: review.photoUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: review.photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Container(color: kSidebar,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: kTangerine, strokeWidth: 2))),
                    errorWidget: (_, _, _) => Container(
                        color: kSidebar,
                        child: const Icon(Icons.broken_image_rounded,
                            color: kMuted, size: 40)),
                  )
                : Container(
                    color: kSidebar,
                    child: const Icon(Icons.image_rounded,
                        color: kMuted, size: 40)),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(review.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(ts,
                    style:
                        const TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: kDanger,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: BorderSide(
                              color: kDanger.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject', style: TextStyle(fontSize: 12)),
                        onPressed: onReject,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: kSuccess,
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          side: BorderSide(
                              color: kSuccess.withValues(alpha: 0.5)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Approve', style: TextStyle(fontSize: 12)),
                        onPressed: onApprove,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RejectReasonDialog extends StatefulWidget {
  @override
  State<_RejectReasonDialog> createState() => _RejectReasonDialogState();
}

class _RejectReasonDialogState extends State<_RejectReasonDialog> {
  String? _selected;
  final _custom = TextEditingController();
  static const _reasons = [
    'Does not show face clearly',
    'Inappropriate or explicit content',
    'Appears to be underage',
    'Not a real photo (cartoon, meme, etc.)',
    'Contains personal information (phone, email)',
    'Copyrighted celebrity/brand image',
  ];

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kCard,
      title: const Text('Rejection Reason',
          style: TextStyle(color: Colors.white)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioGroup<String>(
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: _reasons
                    .map((r) => RadioListTile<String>(
                          value: r,
                          fillColor: WidgetStateProperty.resolveWith(
                            (s) => s.contains(WidgetState.selected)
                                ? kTangerine
                                : null,
                          ),
                          title: Text(r,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                        ))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _custom,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                  hintText: 'Custom reason (optional)…'),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: (_selected != null || _custom.text.isNotEmpty)
              ? () => Navigator.pop(
                  context,
                  _custom.text.isNotEmpty
                      ? _custom.text.trim()
                      : _selected)
              : null,
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}
