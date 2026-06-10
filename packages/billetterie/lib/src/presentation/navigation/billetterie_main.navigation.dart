import 'package:flutter/material.dart';

import 'package:billetterie/src/presentation/constants/billetterie.brand.dart';
import 'package:billetterie/src/core/host/billetterie_host.bridge.dart';
import 'package:billetterie/src/presentation/screens/create_ticket.screen.dart';
import 'package:billetterie/src/presentation/screens/event_detail.screen.dart';
import 'package:billetterie/src/presentation/screens/events.screen.dart';
import 'package:billetterie/src/presentation/screens/my_tickets.screen.dart';
import 'package:billetterie/src/presentation/screens/order_success.screen.dart';
import 'package:billetterie/src/presentation/screens/service_home.screen.dart';
import 'package:billetterie/src/presentation/screens/settings.screen.dart';
import 'package:billetterie/src/presentation/screens/ticket_details.screen.dart';
import 'package:billetterie/src/presentation/screens/ticket_types.screen.dart';
import 'package:billetterie/src/presentation/screens/tickets_home.screen.dart';

enum BilletterieTab { home, settings }

class BilletterieMainNavigation extends StatefulWidget {
  const BilletterieMainNavigation({super.key, required this.onResetPurpose});

  final VoidCallback onResetPurpose;

  @override
  State<BilletterieMainNavigation> createState() => _BilletterieMainNavigationState();
}

class _BilletterieMainNavigationState extends State<BilletterieMainNavigation> {
  BilletterieTab _tab = BilletterieTab.home;
  String? _overlay;

  // Events flow
  String? _eventId;
  OrderSuccessArgs? _orderSuccess;

  // Cars/tickets flow
  String? _ticketId;

  void _openEvents() => setState(() => _overlay = 'events');
  void _openTickets() => setState(() => _overlay = 'tickets');

  @override
  Widget build(BuildContext context) {
    final body = _buildBody();

    return Scaffold(
      backgroundColor: BilletterieBrand.surface,
      body: body,
      bottomNavigationBar: _overlay == null
          ? NavigationBar(
              selectedIndex: _tab.index,
              indicatorColor: BilletterieBrand.primary.withValues(alpha: 0.18),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              backgroundColor: BilletterieBrand.bg,
              surfaceTintColor: BilletterieBrand.bg,
              onDestinationSelected: (i) => setState(() {
                _tab = BilletterieTab.values[i];
                _overlay = null;
              }),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Accueil',
                ),
                NavigationDestination(
                  icon: Icon(Icons.settings_outlined),
                  selectedIcon: Icon(Icons.settings),
                  label: 'Paramètres',
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_orderSuccess != null) {
      return OrderSuccessScreen(
        args: _orderSuccess!,
        onDone: () => setState(() {
          _orderSuccess = null;
          _eventId = null;
          _overlay = 'events';
        }),
      );
    }

    if (_eventId != null) {
      return EventDetailScreen(
        eventId: _eventId!,
        onBack: () => setState(() => _eventId = null),
        onPurchased: (args) => setState(() {
          _orderSuccess = args;
          _eventId = null;
        }),
      );
    }

    if (_ticketId != null) {
      return TicketDetailsScreen(
        ticketId: _ticketId!,
        onBack: () => setState(() => _ticketId = null),
      );
    }

    switch (_overlay) {
      case 'events':
        return EventsScreen(
          onBack: () => setState(() => _overlay = null),
          onEventTap: (id) => setState(() => _eventId = id),
        );
      case 'tickets':
        return _buildTicketsFlow();
      default:
        return switch (_tab) {
          BilletterieTab.home => ServiceHomeScreen(
              onOpenEvents: _openEvents,
              onOpenTickets: _openTickets,
              onOpenMonPeya: () => BilletterieHostBridge.exitModule(context),
            ),
          BilletterieTab.settings => BilletterieSettingsScreen(
              onResetPurpose: widget.onResetPurpose,
              onExit: () => BilletterieHostBridge.exitModule(context),
            ),
        };
    }
  }

  Widget _buildTicketsFlow() {
    return Navigator(
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/types':
            return MaterialPageRoute(
              builder: (_) => TicketTypesScreen(
                onBack: () => Navigator.of(context).pop(),
              ),
            );
          case '/create':
            return MaterialPageRoute(
              builder: (_) => CreateTicketScreen(
                onBack: () => Navigator.of(context).pop(),
                onSaved: () => Navigator.of(context).pushReplacementNamed('/list'),
              ),
            );
          case '/list':
            return MaterialPageRoute(
              builder: (_) => MyTicketsScreen(
                onBack: () => Navigator.of(context).pop(),
                onTicketTap: (id) => setState(() => _ticketId = id),
              ),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => TicketsHomeScreen(
                onBack: () => setState(() => _overlay = null),
                onOpenTypes: () => Navigator.of(context).pushNamed('/types'),
                onCreateTicket: () => Navigator.of(context).pushNamed('/create'),
                onMyTickets: () => Navigator.of(context).pushNamed('/list'),
              ),
            );
        }
      },
    );
  }
}

class OrderSuccessArgs {
  const OrderSuccessArgs({
    required this.eventName,
    required this.ticketLabel,
    required this.total,
  });

  final String eventName;
  final String ticketLabel;
  final int total;
}
