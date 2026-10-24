import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/rental/auth/scopes/rental_session.scope.dart';
import 'package:immo/src/features/rental/models/rental.contract.dart';
import 'package:immo/src/features/rental/navigation/rental_bottom.navigation.dart';
import 'package:immo/src/features/rental/theme/themes/rental.theme.dart';
import 'package:immo/src/features/rental/widgets/rental_layout_widgets.widget.dart';

/// Mes documents — home-page layout (green header + white sheet).
class ContractsScreen extends StatefulWidget {
  const ContractsScreen({
    super.key,
    required this.onBack,
    this.onViewContract,
  });

  final VoidCallback onBack;
  final ValueChanged<String>? onViewContract;

  @override
  State<ContractsScreen> createState() => _ContractsScreenState();
}

class _ContractsScreenState extends State<ContractsScreen> {
  List<RentalContract> _docs = const [];
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
      final userId = session.userId;
      final contracts = userId == null || userId.isEmpty
          ? const <RentalContract>[]
          : await session.api.contracts.fetchOwnerContracts(userId: userId);
      if (!mounted) return;
      setState(() {
        _docs = contracts;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible de charger vos documents.';
        _docs = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    final topPad = MediaQuery.paddingOf(context).top;
    final headerBand = topPad + 132.0;
    final toSign = _docs.where((d) => d.isToSign).toList();
    final active = _docs.where((d) => d.isActive).toList();
    final others = _docs.where((d) => !d.isToSign && !d.isActive).toList();

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
            child: _DocumentsHeader(onBack: widget.onBack),
          ),
          Positioned(
            top: headerBand,
            left: 0,
            right: 0,
            bottom: 0,
            child: RentalWhiteSheet(
              child: RefreshIndicator(
                onRefresh: _load,
                color: RentalTheme.greenMid,
                child: _loading && _docs.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Center(child: CircularProgressIndicator()),
                        ],
                      )
                    : ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.only(
                          top: RentalTheme.spacingMd,
                          bottom:
                              RentalBottomNavigation.contentBottomPadding(
                                    context,
                                  ) +
                                  16,
                        ),
                        children: [
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: RentalTheme.spacingLg,
                                vertical: 32,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _error!,
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
                            )
                          else if (_docs.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: RentalTheme.spacingLg,
                                vertical: 40,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.folder_open_outlined,
                                    size: 48,
                                    color: b.muted,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'Aucun document pour le moment',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: b.text,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Vos contrats de location apparaîtront ici dès qu’un bail est créé.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: b.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else ...[
                            if (toSign.isNotEmpty) ...[
                              RentalSectionHeader(
                                title: 'À signer',
                                subtitle:
                                    '${toSign.length} document${toSign.length > 1 ? 's' : ''}',
                              ),
                              const SizedBox(height: RentalTheme.spacingMd),
                              for (final doc in toSign)
                                _DocumentCard(
                                  document: doc,
                                  onTap: widget.onViewContract == null
                                      ? null
                                      : () =>
                                          widget.onViewContract!(doc.id),
                                ),
                              const SizedBox(height: RentalTheme.spacingXl),
                            ],
                            RentalSectionHeader(
                              title: 'Actifs',
                              subtitle: active.isEmpty
                                  ? null
                                  : '${active.length} document${active.length > 1 ? 's' : ''}',
                            ),
                            const SizedBox(height: RentalTheme.spacingMd),
                            if (active.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: RentalTheme.spacingLg,
                                ),
                                child: Text(
                                  'Aucun contrat actif.',
                                  style: TextStyle(color: b.muted, fontSize: 13),
                                ),
                              )
                            else
                              for (final doc in active)
                                _DocumentCard(
                                  document: doc,
                                  onTap: widget.onViewContract == null
                                      ? null
                                      : () =>
                                          widget.onViewContract!(doc.id),
                                ),
                            if (others.isNotEmpty) ...[
                              const SizedBox(height: RentalTheme.spacingXl),
                              RentalSectionHeader(
                                title: 'Autres',
                                subtitle:
                                    '${others.length} document${others.length > 1 ? 's' : ''}',
                              ),
                              const SizedBox(height: RentalTheme.spacingMd),
                              for (final doc in others)
                                _DocumentCard(
                                  document: doc,
                                  onTap: widget.onViewContract == null
                                      ? null
                                      : () =>
                                          widget.onViewContract!(doc.id),
                                ),
                            ],
                          ],
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentsHeader extends StatelessWidget {
  const _DocumentsHeader({required this.onBack});

  final VoidCallback onBack;

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
              'Mes documents',
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
              'Contrats et baux de location',
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

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({
    required this.document,
    this.onTap,
  });

  final RentalContract document;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    // Running leases and those waiting on the owner stand out
    final active = document.isActive || document.isToSign;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        RentalTheme.spacingLg,
        0,
        RentalTheme.spacingLg,
        12,
      ),
      child: Material(
        color: b.card,
        borderRadius: BorderRadius.circular(16),
        elevation: b.isDark ? 0 : 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: b.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: b.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: b.primaryDark,
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
                              document.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: b.text,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // A long status ("Résiliation demandée") is cut rather than overflow,
                          // and the title keeps the rest of the row
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 132),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: active
                                    ? b.primary.withValues(alpha: 0.12)
                                    : b.searchFill,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                document.statusLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: active ? b.primaryDark : b.muted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        document.documentType,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: b.muted,
                        ),
                      ),
                      if (document.tenantName != null &&
                          document.tenantName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Locataire · ${document.tenantName}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: b.text,
                          ),
                        ),
                      ],
                      if (document.propertyAddress != null &&
                          document.propertyAddress!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          document.propertyAddress!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: b.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onTap != null)
                  Icon(Icons.chevron_right_rounded, color: b.muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
