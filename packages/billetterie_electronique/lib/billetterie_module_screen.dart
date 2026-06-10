import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'constants/billetterie_prefs.dart';
import 'navigation/billetterie_main_navigation.dart';
import 'screens/onboarding_screen.dart';
import 'screens/organizer_dashboard_screen.dart';
import 'screens/scanner_home_screen.dart';
import 'screens/ticket_purpose_screen.dart';

/// Entry point for Billetterie électronique inside Mon Peya.
class BilletterieModuleScreen extends StatefulWidget {
  const BilletterieModuleScreen({super.key});

  @override
  State<BilletterieModuleScreen> createState() => _BilletterieModuleScreenState();
}

class _BilletterieModuleScreenState extends State<BilletterieModuleScreen> {
  bool _prefsLoaded = false;
  bool _showOnboarding = false;
  TicketPurpose? _purpose = TicketPurpose.buyer;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool(BilletteriePrefs.onboardingSeen) ?? false;
    final purposeRaw = prefs.getString(BilletteriePrefs.ticketPurpose);
    TicketPurpose? purpose;
    if (purposeRaw == 'buyer') purpose = TicketPurpose.buyer;
    if (purposeRaw == 'organizer') purpose = TicketPurpose.organizer;
    if (purposeRaw == 'scanner') purpose = TicketPurpose.scanner;

    if (!mounted) return;
    setState(() {
      _showOnboarding = !onboardingSeen;
      _purpose = purpose ?? TicketPurpose.buyer;
      _prefsLoaded = true;
    });
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(BilletteriePrefs.onboardingSeen, true);
    setState(() => _showOnboarding = false);
  }

  Future<void> _selectPurpose(TicketPurpose purpose) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(BilletteriePrefs.ticketPurpose, purpose.name);
    setState(() => _purpose = purpose);
  }

  Future<void> _resetPurpose() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(BilletteriePrefs.ticketPurpose);
    setState(() => _purpose = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_prefsLoaded && _showOnboarding) {
      return BilletterieOnboardingScreen(onComplete: _completeOnboarding);
    }

    if (_prefsLoaded && _purpose == null) {
      return BilletterieTicketPurposeScreen(onSelect: _selectPurpose);
    }

    return switch (_purpose!) {
      TicketPurpose.buyer => BilletterieMainNavigation(onResetPurpose: _resetPurpose),
      TicketPurpose.organizer => OrganizerDashboardScreen(onResetPurpose: _resetPurpose),
      TicketPurpose.scanner => ScannerHomeScreen(onResetPurpose: _resetPurpose),
    };
  }
}
