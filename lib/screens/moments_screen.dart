import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class MomentsScreen extends StatelessWidget {
  const MomentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = AdminService();
    return Scaffold(
      backgroundColor: kDarkBg,
      appBar: AppBar(
        backgroundColor: kDarkBg,
        elevation: 0,
        title: const Text('Moments',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: StreamBuilder<List<AdminMoment>>(
        stream: svc.getMoments(),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: kTangerine));
          }
          final moments = snap.data ?? [];
          if (moments.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('📖', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 16),
                  Text('No moments yet',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }
          return LayoutBuilder(builder: (ctx, box) {
            final cols = (box.maxWidth / 280).floor().clamp(1, 5);
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.78,
              ),
              itemCount: moments.length,
              itemBuilder: (_, i) =>
                  _MomentCard(moment: moments[i], svc: svc),
            );
          });
        },
      ),
    );
  }
}

class _MomentCard extends StatelessWidget {
  final AdminMoment moment;
  final AdminService svc;
  const _MomentCard({required this.moment, required this.svc});

  @override
  Widget build(BuildContext context) {
    final expired = DateTime.now().isAfter(moment.expiresAt);
    final created =
        DateFormat('MMM d, HH:mm').format(moment.createdAt);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / emoji preview
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                moment.imageUrl != null && moment.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: moment.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => Container(color: kSidebar),
                        errorWidget: (_, _, _) =>
                            Container(color: kSidebar),
                      )
                    : Container(
                        color: kSidebar,
                        child: Center(
                          child: Text(moment.text,
                              style: const TextStyle(
                                  fontSize: 32, color: Colors.white),
                              textAlign: TextAlign.center,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ),
                // Expired overlay
                if (expired)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Text('Expired',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
              ],
            ),
          ),
          // Author + time
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kTangerine,
                  backgroundImage: moment.authorPhotoUrl != null &&
                          moment.authorPhotoUrl!.isNotEmpty
                      ? CachedNetworkImageProvider(
                              moment.authorPhotoUrl!)
                          as ImageProvider
                      : null,
                  child: moment.authorPhotoUrl == null ||
                          moment.authorPhotoUrl!.isEmpty
                      ? const Icon(Icons.person,
                          size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(moment.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(created,
                style: const TextStyle(color: kMuted, fontSize: 11)),
          ),
          // Delete action
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: kDanger,
                side: const BorderSide(color: kDanger),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              icon: const Icon(Icons.delete_outline_rounded, size: 16),
              label: const Text('Delete', style: TextStyle(fontSize: 12)),
              onPressed: () => _confirmDelete(context),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        title: const Text('Delete Moment?',
            style: TextStyle(color: Colors.white)),
        content: Text(
            'Remove the moment by ${moment.displayName}. This cannot be undone.',
            style: const TextStyle(color: kMuted)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) await svc.deleteMoment(moment.id);
  }
}
