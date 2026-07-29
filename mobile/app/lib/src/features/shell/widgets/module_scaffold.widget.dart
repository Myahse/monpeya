import 'package:flutter/material.dart';

class ModuleScaffold extends StatelessWidget {
  const ModuleScaffold({
    super.key,
    required this.title,
    required this.children,
    this.showAppBar = true,
    this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 24),
  });

  final String title;
  final List<Widget> children;
  final bool showAppBar;
  /// Scrollable inset — when the user scrolls up, content can move behind the status bar.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: PageStorageKey<String>('module-scroll-$title'),
      clipBehavior: Clip.none,
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        if (showAppBar) SliverAppBar(pinned: true, title: Text(title)),
        SliverPadding(
          padding: padding,
          sliver: SliverList(delegate: SliverChildListDelegate.fixed(children)),
        ),
      ],
    );
  }
}

class ModuleHeader extends StatelessWidget {
  const ModuleHeader({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [cs.primaryContainer, cs.surfaceContainerHighest]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
