import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.contract.dart';
import 'package:immo/src/features/rental/models/rental.tenant.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';

/// Document detail — same home layout (green header + white sheet).
class ContractDetailScreen extends StatefulWidget {
  const ContractDetailScreen({
    super.key,
    required this.contractId,
    required this.onBack,
  });

  final String contractId;
  final VoidCallback onBack;

  @override
  State<ContractDetailScreen> createState() => _ContractDetailScreenState();
}

class _ContractDetailScreenState extends State<ContractDetailScreen> {
  RentalContract? _doc;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final session = RentalSessionScope.of(context);
      final tenants = await session.api.tenants.fetchTenants(
        userId: session.userId,
      );
      if (!mounted) return;
      final tenant =
          tenants.where((t) => t.id == widget.contractId).firstOrNull;
      if (tenant == null) {
        setState(() {
          _error = 'Document introuvable.';
          _loading = false;
        });
        return;
      }
      setState(() {
        _doc = _fromTenant(tenant);
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger ce document.';
        _loading = false;
      });
    }
  }

  RentalContract _fromTenant(RentalTenant t) {
    final property = (t.propertyName?.trim().isNotEmpty == true)
        ? t.propertyName!.trim()
        : 'Bien locatif';
    return RentalContract(
      id: t.id,
      title: 'Bail — $property',
      status: t.status,
      propertyName: t.propertyName,
      propertyAddress: t.propertyAddress,
      tenantId: t.id,
      tenantName: t.fullName,
      tenantPhone: t.phone,
      documentType: 'Contrat de location',
    );
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final headerBand = topPad + 132.0;
    final doc = _doc;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: b.header),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _DetailHeader(
              onBack: widget.onBack,
              subtitle: doc?.documentType ?? 'Contrat de location',
            ),
          ),
          Positioned(
            top: headerBand,
            left: 0,
            right: 0,
            bottom: 0,
            child: RentalWhiteSheet(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null || doc == null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _error ?? 'Document introuvable.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: b.muted),
                                ),
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _load,
                                  child: const Text('Réessayer'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView(
                          padding: EdgeInsets.fromLTRB(
                            RentalTheme.spacingLg,
                            RentalTheme.spacingLg,
                            RentalTheme.spacingLg,
                            RentalBottomNavigation.contentBottomPadding(
                                  context,
                                ) +
                                16,
                          ),
                          children: [
                            RentalSectionHeader(title: 'Détails'),
                            const SizedBox(height: RentalTheme.spacingMd),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    doc.title,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: b.text,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: doc.isActive
                                        ? b.primary.withValues(alpha: 0.12)
                                        : b.searchFill,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    doc.statusLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: doc.isActive
                                          ? b.primaryDark
                                          : b.muted,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _DetailGroup(
                              title: 'Bien',
                              rows: [
                                _DetailRow(
                                  label: 'Nom',
                                  value: doc.propertyName?.trim().isNotEmpty ==
                                          true
                                      ? doc.propertyName!
                                      : '—',
                                ),
                                _DetailRow(
                                  label: 'Adresse',
                                  value: doc.propertyAddress
                                              ?.trim()
                                              .isNotEmpty ==
                                          true
                                      ? doc.propertyAddress!
                                      : '—',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Locataire',
                              rows: [
                                _DetailRow(
                                  label: 'Nom',
                                  value: doc.tenantName?.trim().isNotEmpty == true
                                      ? doc.tenantName!
                                      : '—',
                                ),
                                _DetailRow(
                                  label: 'Contact',
                                  value: doc.tenantPhone?.trim().isNotEmpty ==
                                          true
                                      ? doc.tenantPhone!
                                      : '—',
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _DetailGroup(
                              title: 'Document',
                              rows: [
                                _DetailRow(
                                  label: 'Type',
                                  value: doc.documentType,
                                ),
                                _DetailRow(
                                  label: 'Référence',
                                  value: doc.id,
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.onBack,
    required this.subtitle,
  });

  final VoidCallback onBack;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final b = ImmoBrand.rentalOf(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        8,
        top + RentalTheme.spacingMd,
        RentalTheme.spacingLg,
        RentalTheme.spacingXl + 8,
      ),
      color: b.header,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Expanded(
                child: Text(
                  'Mr Immo location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.92),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(left: RentalTheme.spacingLg - 8),
            child: Text(
              'Document',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: RentalTheme.spacingLg - 8),
            child: Text(
              subtitle,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailGroup extends StatelessWidget {
  const _DetailGroup({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<_DetailRow> rows;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: b.searchFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: b.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: b.muted,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            rows[i],
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: b.muted,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: b.text,
            ),
          ),
        ),
      ],
    );
  }
}
