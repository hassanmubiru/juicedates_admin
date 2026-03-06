import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _svc       = AdminService();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl  = TextEditingController();
  final _formKey   = GlobalKey<FormState>();
  bool _sending    = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    await _svc.sendBroadcast(
        _titleCtrl.text.trim(), _bodyCtrl.text.trim());
    if (mounted) {
      _titleCtrl.clear();
      _bodyCtrl.clear();
      setState(() => _sending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Broadcast queued ✓'),
          backgroundColor: kSuccess,
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
        title: const Text('Notifications',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: LayoutBuilder(builder: (ctx, box) {
        final wide = box.maxWidth >= 800;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: wide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                        width: 340,
                        child: _ComposeCard(
                          formKey: _formKey,
                          titleCtrl: _titleCtrl,
                          bodyCtrl: _bodyCtrl,
                          sending: _sending,
                          onSend: _send,
                        )),
                    const SizedBox(width: 24),
                    Expanded(child: _HistoryList(svc: _svc)),
                  ],
                )
              : Column(
                  children: [
                    _ComposeCard(
                      formKey: _formKey,
                      titleCtrl: _titleCtrl,
                      bodyCtrl: _bodyCtrl,
                      sending: _sending,
                      onSend: _send,
                    ),
                    const SizedBox(height: 24),
                    Expanded(child: _HistoryList(svc: _svc)),
                  ],
                ),
        );
      }),
    );
  }
}

class _ComposeCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final bool sending;
  final VoidCallback onSend;
  const _ComposeCard({
    required this.formKey,
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: const [
                  Icon(Icons.campaign_rounded,
                      color: kTangerine, size: 20),
                  SizedBox(width: 8),
                  Text('Send Broadcast',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Delivered to all users via push notification',
                  style: TextStyle(color: kMuted, fontSize: 12)),
              const SizedBox(height: 20),
              TextFormField(
                controller: titleCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: bodyCtrl,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                    labelText: 'Message body'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 46,
                child: ElevatedButton.icon(
                  icon: sending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded),
                  label: Text(sending ? 'Sending…' : 'Send Broadcast'),
                  onPressed: sending ? null : onSend,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  final AdminService svc;
  const _HistoryList({required this.svc});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('History',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: svc.getNotificationHistory(),
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child:
                        CircularProgressIndicator(color: kTangerine));
              }
              final items = snap.data ?? [];
              if (items.isEmpty) {
                return const Center(
                    child: Text('No broadcasts sent yet.',
                        style: TextStyle(color: kMuted)));
              }
              return ListView.separated(
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) => _HistoryTile(data: items[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> data;
  const _HistoryTile({required this.data});

  @override
  Widget build(BuildContext context) {
    DateTime? ts;
    try {
      ts = (data['sentAt'] as dynamic)?.toDate() as DateTime?;
    } catch (_) {}
    final timeStr =
        ts != null ? DateFormat('MMM d, y — HH:mm').format(ts) : '—';
    final status = data['status'] as String? ?? 'queued';
    final statusColor = status == 'sent' ? kSuccess : kWarning;

    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: kTangerine.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.notifications_rounded,
              color: kTangerine, size: 20),
        ),
        title: Text(data['title'] as String? ?? '(no title)',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((data['body'] as String?) != null)
              Text(data['body'] as String,
                  style: const TextStyle(color: kMuted, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(timeStr,
                style: const TextStyle(color: kMuted, fontSize: 11)),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.4)),
          ),
          child: Text(status,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
