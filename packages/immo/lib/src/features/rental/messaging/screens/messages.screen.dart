import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.message.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key, this.onChatModeChanged});

  final ValueChanged<bool>? onChatModeChanged;

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  List<RentalConversation> _conversations = const [];
  RentalConversation? _selected;
  List<RentalMessage> _messages = const [];
  final _input = TextEditingController();
  final _search = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadConversations());
  }

  @override
  void dispose() {
    _input.dispose();
    _search.dispose();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    final session = RentalSessionScope.of(context);
    final userId = session.userId;
    if (userId == null || userId.isEmpty) return;
    final items = await session.api.messages.fetchConversations(userId);
    if (!mounted) return;
    setState(() => _conversations = items);
  }

  void _setChatMode(bool inChat) {
    widget.onChatModeChanged?.call(inChat);
  }

  Future<void> _openChat(RentalConversation conv) async {
    setState(() {
      _selected = conv;
      _messages = const [];
    });
    _setChatMode(true);
    final session = RentalSessionScope.of(context);
    final userId = session.userId!;
    final msgs = await session.api.messages.fetchMessages(
      userId: userId,
      otherUserId: conv.userId,
    );
    if (!mounted) return;
    setState(() => _messages = msgs);
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    final conv = _selected;
    if (text.isEmpty || conv == null) return;

    final session = RentalSessionScope.of(context);
    final userId = session.userId;
    if (userId == null) return;

    _input.clear();
    await session.api.messages.sendMessage(
      senderId: userId,
      receiverId: conv.userId,
      content: text,
    );
    await _openChat(conv);
  }

  List<RentalConversation> get _filteredConversations {
    if (_searchQuery.isEmpty) return _conversations;
    final q = _searchQuery.toLowerCase();
    return _conversations
        .where((c) =>
            c.userName.toLowerCase().contains(q) ||
            c.lastMessage.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) return _chatView();
    return _listView();
  }

  Widget _listView() {
    final b = RentalTheme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: b.bg,
        child: Column(
          children: [
            RentalGradientPageHeader(
              title: 'Messages',
              paddingTop: 48,
              paddingBottom: 24,
              leading: const SizedBox(width: 36),
              trailing: Material(
                color: Colors.white.withValues(alpha: 0.2),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: () {},
                  customBorder: const CircleBorder(),
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.add, color: Colors.white),
                  ),
                ),
              ),
            ),
            ColoredBox(
              color: b.card,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  RentalTheme.spacingLg,
                  RentalTheme.spacingMd,
                  RentalTheme.spacingLg,
                  RentalTheme.spacingMd,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: b.searchFill,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _search,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(color: b.text),
                    decoration: InputDecoration(
                      hintText: 'Rechercher une conversation…',
                      hintStyle: TextStyle(color: b.muted),
                      prefixIcon: Icon(Icons.search, color: b.muted, size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: b.card,
                child: RefreshIndicator(
                  onRefresh: _loadConversations,
                  color: RentalTheme.green,
                  child: _filteredConversations.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 80),
                            const Center(child: Text('💬', style: TextStyle(fontSize: 64))),
                            const SizedBox(height: RentalTheme.spacingMd),
                            Center(
                              child: Text(
                                'Aucune conversation',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: b.text,
                                ),
                              ),
                            ),
                            const SizedBox(height: RentalTheme.spacingSm),
                            Center(
                              child: Text(
                                'Appuyez sur + pour démarrer',
                                style: TextStyle(color: b.muted),
                              ),
                            ),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: RentalTheme.scrollBottomPad),
                          itemCount: _filteredConversations.length,
                          itemBuilder: (context, i) {
                            final c = _filteredConversations[i];
                            return _ConversationTile(
                              conversation: c,
                              onTap: () => _openChat(c),
                            );
                          },
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chatView() {
    final b = RentalTheme.of(context);
    final conv = _selected!;
    final userId = RentalSessionScope.of(context).userId;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: b.bg,
        body: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                8,
                MediaQuery.paddingOf(context).top + 8,
                8,
                RentalTheme.spacingLg,
              ),
              decoration: const BoxDecoration(gradient: RentalTheme.headerGradient),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      setState(() => _selected = null);
                      _setChatMode(false);
                    },
                    icon: const Text('‹', style: TextStyle(color: Colors.white, fontSize: 36)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: RentalTheme.green,
                        child: Text(
                          conv.userName.isNotEmpty ? conv.userName[0].toUpperCase() : '?',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          conv.userName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'En ligne',
                          style: TextStyle(fontSize: 12, color: Color(0xE6FFFFFF)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _messages = const []),
                    icon: const Text('🗑️', style: TextStyle(fontSize: 20)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (context, i) {
                  final m = _messages[i];
                  final mine = m.senderId == userId;
                  return Align(
                    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                      decoration: BoxDecoration(
                        color: mine ? RentalTheme.green : b.card,
                        borderRadius: BorderRadius.circular(16),
                        border: mine ? null : Border.all(color: b.border),
                      ),
                      child: Text(
                        m.content,
                        style: TextStyle(
                          color: mine ? Colors.white : b.text,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    Material(
                      color: b.searchFill,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: () {},
                        customBorder: const CircleBorder(),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Icon(Icons.attach_file, color: b.muted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _input,
                        style: TextStyle(color: b.text),
                        decoration: InputDecoration(
                          hintText: 'Écrire un message…',
                          hintStyle: TextStyle(color: b.muted),
                          filled: true,
                          fillColor: b.card,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: b.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: b.border),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: RentalTheme.green,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _send,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 44,
                          height: 44,
                          child: Icon(Icons.send, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  final RentalConversation conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final b = RentalTheme.of(context);
    final initials = conversation.userName
        .split(' ')
        .where((p) => p.isNotEmpty)
        .map((p) => p[0])
        .take(2)
        .join()
        .toUpperCase();

    return Material(
      color: b.card,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: RentalTheme.spacingLg,
            vertical: RentalTheme.spacingMd,
          ),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: b.border)),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: RentalTheme.green,
                    child: Text(
                      initials.isNotEmpty ? initials : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: RentalTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.userName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: b.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isNotEmpty
                                ? conversation.lastMessage
                                : 'Aucun message',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: b.muted,
                            ),
                          ),
                        ),
                        if (conversation.unreadCount > 0)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                            decoration: BoxDecoration(
                              color: RentalTheme.green,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${conversation.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
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
