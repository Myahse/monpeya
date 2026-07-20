import 'package:flutter/material.dart';

import 'package:billetterie/src/core/constants/billetterie.brand.dart';
import 'package:billetterie/src/features/transport/services/billetterie_notification.store.dart';

/// Inbox for billetterie alerts (purchases, validation, etc.).
class TransportNotificationsScreen extends StatefulWidget {
  const TransportNotificationsScreen({super.key});

  @override
  State<TransportNotificationsScreen> createState() =>
      _TransportNotificationsScreenState();
}

class _TransportNotificationsScreenState
    extends State<TransportNotificationsScreen> {
  final _store = BilletterieNotificationStore();
  List<BilletterieNotification> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    setState(() => _loading = true);
    final items = await _store.load();
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _markAllRead() async {
    final items = await _store.markAllRead();
    if (!mounted) return;
    setState(() => _items = items);
  }

  Future<void> _openItem(BilletterieNotification item) async {
    if (item.read) return;
    final items = await _store.markRead(item.id);
    if (!mounted) return;
    setState(() => _items = items);
  }

  String _timeLabel(DateTime at) {
    final now = DateTime.now();
    final diff = now.difference(at);
    if (diff.inMinutes < 1) return "A l'instant";
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    final d = at.day.toString().padLeft(2, '0');
    final m = at.month.toString().padLeft(2, '0');
    return '$d/$m/${at.year}';
  }

  IconData _iconFor(BilletterieNotification item) {
    return switch (item.type) {
      'purchase' => Icons.confirmation_number_outlined,
      'security' => Icons.lock_outline_rounded,
      _ => Icons.notifications_none_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final brand = BilletterieBrand.of(context);
    final textTheme = Theme.of(context).textTheme;
    final hasUnread = _items.any((e) => !e.read);

    return Scaffold(
      backgroundColor: brand.bg,
      appBar: AppBar(
        backgroundColor: brand.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: brand.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Alertes & notifications',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: brand.text,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: hasUnread ? _markAllRead : null,
            child: Text(
              'Tout lire',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: hasUnread ? brand.primaryDark : brand.muted,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: brand.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 40,
                          color: brand.muted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucune notification',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                            color: brand.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Material(
                      color: brand.card,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: () => _openItem(item),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: item.read
                                  ? brand.border
                                  : brand.primary.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: brand.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _iconFor(item),
                                  color: brand.primaryDark,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: textTheme.bodyMedium?.copyWith(
                                              fontSize: 14,
                                              fontWeight: item.read
                                                  ? FontWeight.w500
                                                  : FontWeight.w700,
                                              color: brand.text,
                                            ),
                                          ),
                                        ),
                                        if (!item.read)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: brand.primaryDark,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.body,
                                      style: textTheme.bodySmall?.copyWith(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: brand.muted,
                                        height: 1.35,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _timeLabel(item.createdAt),
                                      style: textTheme.labelSmall?.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                        color: brand.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
