import 'package:flutter/material.dart';

import 'package:app/src/core/navigation/app.navigation.dart';
import 'package:app/src/core/utils/status_bar.util.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  static const routeName = '/notifications';

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationItem {
  const _NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    required this.icon,
    this.unread = true,
  });

  final String id;
  final String title;
  final String message;
  final String timeLabel;
  final IconData icon;
  final bool unread;

  _NotificationItem copyWith({bool? unread}) => _NotificationItem(
        id: id,
        title: title,
        message: message,
        timeLabel: timeLabel,
        icon: icon,
        unread: unread ?? this.unread,
      );
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _green = Color(0xFF006D56);

  List<_NotificationItem> _items = [];

  void _markAllRead() {
    if (_items.every((item) => !item.unread)) return;
    setState(() {
      _items = [
        for (final item in _items) item.copyWith(unread: false),
      ];
    });
  }

  void _openItem(_NotificationItem item) {
    if (!item.unread) return;
    setState(() {
      _items = [
        for (final entry in _items)
          entry.id == item.id ? entry.copyWith(unread: false) : entry,
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = cs.brightness == Brightness.dark;
    final bg = isDark ? cs.surface : const Color(0xFFFFFFFF);
    final ink = isDark ? cs.onSurface : const Color(0xFF111827);
    final muted = isDark ? cs.onSurfaceVariant : const Color(0xFF6B7280);
    final border = isDark ? cs.outlineVariant : const Color(0xFFE5E7EB);
    final hasUnread = _items.any((item) => item.unread);

    return Scaffold(
      backgroundColor: bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, shellContentTop(context), 16, 12),
            child: SizedBox(
              height: 44,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => AppNavigation.pop(context),
                    borderRadius: BorderRadius.circular(999),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Icon(Icons.chevron_left_rounded, size: 28, color: ink),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Notifications',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
                    ),
                  ),
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: TextButton(
                      onPressed: hasUnread ? _markAllRead : null,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(44, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Tout lire',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: hasUnread ? _green : muted.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _items.isEmpty
                ? _EmptyNotifications(ink: ink, muted: muted)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _NotificationTile(
                        item: item,
                        ink: ink,
                        muted: muted,
                        border: border,
                        isDark: isDark,
                        surface: isDark ? cs.surfaceContainerHighest : const Color(0xFFF9FAFB),
                        onTap: () => _openItem(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications({required this.ink, required this.muted});

  final Color ink;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 52, color: muted.withValues(alpha: 0.8)),
            const SizedBox(height: 14),
            Text(
              'Aucune notification',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: ink),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos alertes de paiement, transferts et actualités Mon Peya apparaîtront ici.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: muted, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.ink,
    required this.muted,
    required this.border,
    required this.isDark,
    required this.surface,
    required this.onTap,
  });

  final _NotificationItem item;
  final Color ink;
  final Color muted;
  final Color border;
  final bool isDark;
  final Color surface;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF006D56).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(item.icon, size: 20, color: const Color(0xFF006D56)),
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
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: ink,
                            ),
                          ),
                        ),
                        if (item.unread)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(left: 8, top: 4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF006D56),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.message,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: muted, height: 1.35),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.timeLabel,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: muted.withValues(alpha: 0.85)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
