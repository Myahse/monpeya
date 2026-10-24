import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:immo/src/core/constants/immo.brand.dart';
import 'package:immo/src/features/collection/utils/collection_format.util.dart';
import 'package:immo/src/features/construction/models/construction.site.dart';
import 'package:immo/src/features/construction/models/house_plan.model.dart';
import 'package:immo/src/features/construction/models/metre.model.dart';
import 'package:immo/src/features/construction/services/construction.store.dart';
import 'package:immo/src/features/construction/widgets/construction_segment.style.dart';
import 'package:immo/src/features/construction/widgets/plan_editor.widget.dart';
import 'package:immo/src/features/construction/widgets/plan_view_3d.widget.dart';
import 'package:immo/src/shared/widgets/immo_layout.widget.dart';
import 'package:immo/src/shared/widgets/immo_sheet.widget.dart';

/// Métré & matériaux — the chef de chantier enters the house by dimensions,
/// the backend computes the materials, and the adjusted list becomes a
/// demande sent to the superviseur.
class MetreScreen extends StatefulWidget {
  const MetreScreen({
    super.key,
    required this.site,
    required this.store,
    required this.onClose,
  });

  final ConstructionSite site;
  final ConstructionStore store;
  final VoidCallback onClose;

  @override
  State<MetreScreen> createState() => _MetreScreenState();
}

class _MetreScreenState extends State<MetreScreen> {
  final _length = TextEditingController();
  final _width = TextEditingController();
  final _levels = TextEditingController(text: '1');
  final _height = TextEditingController(text: '2,8');
  final _doors = TextEditingController(text: '0');
  final _windows = TextEditingController(text: '0');
  final _interior = TextEditingController();
  final _waste = TextEditingController(text: '5');
  final _pitch = TextEditingController(text: '25');
  final _overhang = TextEditingController(text: '0,5');
  List<MetreRoom> _rooms = const [];
  int _blocks = 15;
  bool _flatRoof = false;
  bool _steelFrame = false;

  /// Drawn on the plan rather than typed in.
  bool _drawn = false;
  HousePlan _plan = const HousePlan();
  PlanTool _tool = PlanTool.room;

  bool _loading = true;
  bool _computing = false;
  bool _requesting = false;
  String? _error;
  SiteMetre? _metre;

  /// Chef's adjustments of the computed totals, by material code.
  final Map<String, int> _quantities = {};
  final Map<String, double> _prices = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_length, _width, _levels, _height, _doors, _windows, _interior, _waste, _pitch, _overhang]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final r = await widget.store.loadMetre(widget.site);
    if (!mounted) return;
    setState(() {
      _loading = false;
      _error = r.error;
      if (r.metre != null) _show(r.metre!, fillForm: true);
    });
  }

  void _show(SiteMetre metre, {bool fillForm = false}) {
    _metre = metre;
    _quantities
      ..clear()
      ..addAll({for (final t in metre.result.totals) t.code: t.quantity.ceil()});
    if (!fillForm) return;
    final i = metre.input;
    _length.text = formatNumber(i.length);
    _width.text = formatNumber(i.width);
    _levels.text = '${i.levels}';
    _height.text = formatNumber(i.wallHeight);
    _doors.text = '${i.doors.count}';
    _windows.text = '${i.windows.count}';
    _interior.text = i.interiorWalls == null ? '' : formatNumber(i.interiorWalls!);
    _waste.text = formatNumber(i.waste * 100);
    _rooms = i.rooms;
    _blocks = i.blockThickness;
    _flatRoof = i.flatRoof;
    _pitch.text = formatNumber(i.roofPitch);
    _overhang.text = formatNumber(i.roofOverhang);
    _steelFrame = i.steelFrame;
    _drawn = i.plan != null;
    _plan = i.plan ?? const HousePlan();
  }

  MetreInput? _input() {
    if (_drawn) {
      if (_plan.isEmpty) {
        setState(() => _error = 'Dessinez au moins une pièce.');
        return null;
      }
      return _plan.toInput(_typed(0, 0));
    }
    final length = parseNumber(_length.text);
    final width = parseNumber(_width.text);
    if (length == null || width == null || length <= 0 || width <= 0) {
      setState(() => _error = 'Saisissez la longueur et la largeur du bâtiment.');
      return null;
    }
    return _typed(length, width);
  }

  /// The métré as typed in the form (levels, height and options are shared with the plan).
  MetreInput _typed(double length, double width) {
    final previous = _metre?.input;
    return MetreInput(
      length: length,
      width: width,
      levels: (parseNumber(_levels.text) ?? 1).round().clamp(1, 10),
      wallHeight: parseNumber(_height.text) ?? 2.8,
      rooms: _rooms,
      interiorWalls: parseNumber(_interior.text),
      doors: MetreOpening(
        count: (parseNumber(_doors.text) ?? 0).round(),
        width: previous?.doors.width ?? MetreInput.defaultDoors.width,
        height: previous?.doors.height ?? MetreInput.defaultDoors.height,
      ),
      windows: MetreOpening(
        count: (parseNumber(_windows.text) ?? 0).round(),
        width: previous?.windows.width ?? MetreInput.defaultWindows.width,
        height: previous?.windows.height ?? MetreInput.defaultWindows.height,
      ),
      blockThickness: _blocks,
      flatRoof: _flatRoof,
      roofPitch: parseNumber(_pitch.text) ?? 25,
      roofOverhang: parseNumber(_overhang.text) ?? 0.5,
      steelFrame: _steelFrame,
      waste: (parseNumber(_waste.text) ?? 5) / 100,
    );
  }

  /// Typed ↔ drawn. Going back to the form fills it from the drawing.
  void _switchEntry(bool drawn) {
    setState(() {
      _drawn = drawn;
      _error = null;
      if (!drawn && !_plan.isEmpty) {
        final i = _plan.toInput(_typed(0, 0));
        _length.text = formatNumber(i.length);
        _width.text = formatNumber(i.width);
        _rooms = i.rooms;
        _doors.text = '${i.doors.count}';
        _windows.text = '${i.windows.count}';
        _interior.text = formatNumber(i.interiorWalls ?? 0);
      }
    });
  }

  Future<void> _addDrawnRoom(PlanRoom drawn) async {
    final result = await _planRoomSheet(drawn.copyWith(name: 'Pièce ${_plan.rooms.length + 1}'));
    final room = result?.room;
    if (room == null) return;
    setState(() => _plan = _plan.copyWith(rooms: [..._plan.rooms, room]));
  }

  Future<void> _editPlanRoom(int index) async {
    final result = await _planRoomSheet(_plan.rooms[index], index: index);
    if (result == null) return;
    setState(() {
      final rooms = [..._plan.rooms];
      if (result.deleted) {
        rooms.removeAt(index);
      } else {
        rooms[index] = result.room!;
      }
      _plan = _plan.copyWith(rooms: rooms);
    });
  }

  Future<_PlanRoomResult?> _planRoomSheet(PlanRoom room, {int? index}) => showImmoSheet<_PlanRoomResult>(
        context,
        title: index == null ? 'Nouvelle pièce' : 'Modifier la pièce',
        builder: (_) => _PlanRoomForm(
          room: room,
          canDelete: index != null,
          overlaps: (r) => _plan.overlaps(r, except: index),
        ),
      );

  Future<void> _clearPlan() async {
    final ok = await showImmoConfirm(
      context,
      title: 'Effacer le plan ?',
      message: 'Toutes les pièces, portes et fenêtres dessinées seront retirées.',
      confirmLabel: 'Effacer',
    );
    if (ok && mounted) setState(() => _plan = const HousePlan());
  }

  Future<void> _compute() async {
    FocusScope.of(context).unfocus();
    final input = _input();
    if (input == null) return;
    setState(() {
      _computing = true;
      _error = null;
    });
    final r = await widget.store.saveMetre(widget.site, input);
    if (!mounted) return;
    setState(() {
      _computing = false;
      _error = r.error;
      if (r.metre != null) _show(r.metre!);
    });
  }

  Future<void> _request() async {
    final metre = _metre;
    if (metre == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final lines = [
      for (final t in metre.result.totals)
        if ((_quantities[t.code] ?? 0) > 0)
          MaterialRequestLine(
            code: t.code,
            label: t.label,
            unit: t.unit,
            quantity: _quantities[t.code]!,
            unitPrice: _prices[t.code],
          ),
    ];
    if (lines.isEmpty) {
      setState(() => _error = 'Gardez au moins un matériau avec une quantité.');
      return;
    }
    final ok = await showImmoConfirm(
      context,
      title: 'Envoyer la demande ?',
      message: '${lines.length} matériaux pour « ${widget.site.name} » seront envoyés '
          'au superviseur pour validation.',
      confirmLabel: 'Envoyer',
    );
    if (!ok || !mounted) return;
    setState(() {
      _requesting = true;
      _error = null;
    });
    final r = await widget.store.requestMaterials(widget.site, lines);
    if (!mounted) return;
    setState(() {
      _requesting = false;
      _error = r.error;
      if (r.metre != null) _metre = r.metre;
    });
    if (r.error == null) {
      messenger.showSnackBar(const SnackBar(content: Text('Demande envoyée au superviseur')));
    }
  }

  Future<void> _editRoom([int? index]) async {
    final room = await showImmoSheet<MetreRoom>(
      context,
      title: index == null ? 'Nouvelle pièce' : 'Modifier la pièce',
      builder: (_) => _RoomForm(room: index == null ? null : _rooms[index]),
    );
    if (room == null) return;
    setState(() {
      _rooms = [..._rooms];
      if (index == null) {
        _rooms.add(room);
      } else {
        _rooms[index] = room;
      }
    });
  }

  Future<void> _editLine(MetreLine line) async {
    final edited = await showImmoSheet<(int, double?)>(
      context,
      title: line.label,
      builder: (_) => _LineForm(
        line: line,
        quantity: _quantities[line.code] ?? line.quantity.ceil(),
        price: _prices[line.code],
      ),
    );
    if (edited == null) return;
    setState(() {
      _quantities[line.code] = edited.$1;
      if (edited.$2 == null) {
        _prices.remove(line.code);
      } else {
        _prices[line.code] = edited.$2!;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: ColoredBox(
        color: b.header,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImmoPageHeader(
              title: 'Métré & matériaux',
              subtitle: widget.site.name,
              onBack: widget.onClose,
            ),
            Expanded(
              child: ImmoSheet(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView(
                        padding: EdgeInsets.fromLTRB(
                          ImmoSpacing.lg,
                          ImmoSpacing.lg,
                          ImmoSpacing.lg,
                          ImmoSpacing.xl + MediaQuery.viewPaddingOf(context).bottom,
                        ),
                        children: [..._form(b), ..._results(b)],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _form(ImmoRentalPalette b) {
    final levels = _pair(
      _NumberField(label: 'Niveaux', controller: _levels, decimal: false),
      _NumberField(label: 'Hauteur des murs', controller: _height, suffix: 'm'),
    );
    return [
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Dimensions'), icon: Icon(Icons.straighten_rounded)),
          ButtonSegment(value: true, label: Text('Plan'), icon: Icon(Icons.draw_outlined)),
        ],
        selected: {_drawn},
        showSelectedIcon: false,
        onSelectionChanged: (s) => _switchEntry(s.first),
        style: constructionSegmentStyle(b),
      ),
      const SizedBox(height: ImmoSpacing.md),
      if (_drawn) ...[
        ..._planSection(b),
        const SizedBox(height: ImmoSpacing.sm),
        const ImmoSectionTitle('Élévation'),
        levels,
        if (!_plan.isEmpty) ..._view3dSection(b),
      ] else
        ..._dimensionFields(b, levels),
      ..._options(b),
    ];
  }

  List<Widget> _planSection(ImmoRentalPalette b) {
    final walls = _plan.walls();
    final hint = switch (_tool) {
      PlanTool.room => 'Glissez pour dessiner une pièce. Touchez une pièce pour la modifier.',
      PlanTool.door => 'Touchez un mur pour ajouter ou retirer une porte.',
      PlanTool.window => 'Touchez un mur pour ajouter ou retirer une fenêtre.',
    };
    return [
      // The action stays (disabled when empty) so the canvas never shifts under a finger
      ImmoSectionTitle('Plan', action: 'Tout effacer', onAction: _plan.isEmpty ? null : _clearPlan),
      SegmentedButton<PlanTool>(
        segments: const [
          ButtonSegment(value: PlanTool.room, label: Text('Pièce'), icon: Icon(Icons.crop_square_rounded)),
          ButtonSegment(value: PlanTool.door, label: Text('Porte'), icon: Icon(Icons.door_front_door_outlined)),
          ButtonSegment(value: PlanTool.window, label: Text('Fenêtre'), icon: Icon(Icons.window_outlined)),
        ],
        selected: {_tool},
        showSelectedIcon: false,
        onSelectionChanged: (s) => setState(() => _tool = s.first),
        style: constructionSegmentStyle(b),
      ),
      const SizedBox(height: ImmoSpacing.sm),
      Text(hint, style: TextStyle(fontSize: 12.5, color: b.muted, height: 1.4)),
      const SizedBox(height: ImmoSpacing.sm),
      Container(
        padding: const EdgeInsets.all(6),
        decoration: ImmoDecor.card(context),
        child: PlanEditor(
          plan: _plan,
          tool: _tool,
          onChanged: (p) => setState(() => _plan = p),
          onRoomDrawn: _addDrawnRoom,
          onRoomTapped: _editPlanRoom,
        ),
      ),
      const SizedBox(height: ImmoSpacing.sm),
      Text(
        [
          '1 carreau = 1 m',
          if (!_plan.isEmpty) ...[
            'emprise ${formatNumber(_plan.floorArea)} m²',
            'murs ext. ${formatNumber(walls.exterior)} m',
            'int. ${formatNumber(walls.interior)} m',
            '${_plan.count(OpeningKind.door)} portes',
            '${_plan.count(OpeningKind.window)} fenêtres',
          ],
        ].join(' · '),
        style: TextStyle(fontSize: 12.5, color: b.muted, height: 1.4),
      ),
      if (!_plan.isEmpty) ...[
        const SizedBox(height: ImmoSpacing.md),
        for (var i = 0; i < _plan.rooms.length; i++)
          ImmoListTile(
            icon: Icons.crop_square_rounded,
            title: _plan.rooms[i].name,
            subtitle: '${formatNumber(_plan.rooms[i].w * HousePlan.cell)} × '
                '${formatNumber(_plan.rooms[i].h * HousePlan.cell)} m · '
                '${formatNumber(_plan.rooms[i].w * _plan.rooms[i].h * HousePlan.cell * HousePlan.cell)} m²',
            onTap: () => _editPlanRoom(i),
          ),
      ],
    ];
  }

  /// The drawing in 3D, at the levels and wall height typed under Élévation.
  List<Widget> _view3dSection(ImmoRentalPalette b) {
    return [
      const SizedBox(height: ImmoSpacing.sm),
      const ImmoSectionTitle('Vue 3D'),
      ListenableBuilder(
        listenable: Listenable.merge([_levels, _height, _pitch, _overhang]),
        builder: (context, _) {
          final input = _plan.toInput(_typed(0, 0));
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Glissez pour tourner la maison.',
                style: TextStyle(fontSize: 12.5, color: b.muted, height: 1.4),
              ),
              const SizedBox(height: ImmoSpacing.sm),
              Container(
                padding: const EdgeInsets.all(ImmoSpacing.sm),
                decoration: ImmoDecor.card(context),
                child: PlanView3D.ofInput(input),
              ),
            ],
          );
        },
      ),
    ];
  }

  List<Widget> _dimensionFields(ImmoRentalPalette b, Widget levels) {
    return [
      const ImmoSectionTitle('Bâtiment'),
      _pair(
        _NumberField(label: 'Longueur', controller: _length, suffix: 'm'),
        _NumberField(label: 'Largeur', controller: _width, suffix: 'm'),
      ),
      levels,
      const SizedBox(height: ImmoSpacing.sm),
      ImmoSectionTitle('Pièces', action: 'Ajouter', onAction: _editRoom),
      if (_rooms.isEmpty)
        ImmoListTile(
          icon: Icons.add_rounded,
          title: 'Ajouter une pièce',
          subtitle: 'Sans pièces, seuls les murs extérieurs sont comptés.',
          onTap: _editRoom,
        )
      else
        for (var i = 0; i < _rooms.length; i++)
          ImmoListTile(
            icon: Icons.crop_square_rounded,
            title: _rooms[i].name,
            subtitle: '${formatNumber(_rooms[i].length)} × ${formatNumber(_rooms[i].width)} m · '
                '${formatNumber(_rooms[i].area)} m²',
            trailing: IconButton(
              tooltip: 'Supprimer la pièce',
              icon: Icon(Icons.delete_outline_rounded, color: b.muted),
              onPressed: () => setState(() => _rooms = [..._rooms]..removeAt(i)),
            ),
            onTap: () => _editRoom(i),
          ),
      const SizedBox(height: ImmoSpacing.sm),
      const ImmoSectionTitle('Ouvertures'),
      _pair(
        _NumberField(label: 'Portes', controller: _doors, decimal: false, helper: '0,9 × 2,1 m · par niveau'),
        _NumberField(label: 'Fenêtres', controller: _windows, decimal: false, helper: '1,2 × 1,2 m · par niveau'),
      ),
    ];
  }

  List<Widget> _options(ImmoRentalPalette b) {
    final interiorHint = _metre == null ? 'Auto' : 'Auto : ${formatNumber(_metre!.result.interiorWalls)}';
    return [
      const SizedBox(height: ImmoSpacing.sm),
      const ImmoSectionTitle('Options'),
      for (final t in const [15, 20])
        ImmoListTile(
          icon: Icons.view_module_outlined,
          title: 'Agglos de $t',
          subtitle: t == 15 ? 'Murs courants' : 'Murs porteurs ou de clôture',
          trailing: Icon(
            _blocks == t ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: _blocks == t ? b.primary : b.muted,
          ),
          onTap: () => setState(() => _blocks = t),
        ),
      for (final flat in const [false, true])
        ImmoListTile(
          icon: Icons.roofing_rounded,
          title: flat ? 'Toiture terrasse' : 'Toiture en tôles',
          subtitle: flat ? 'Dalle de toit en béton armé, étanchéité' : 'Deux pans : tôles, charpente et pignons',
          trailing: Icon(
            _flatRoof == flat ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            color: _flatRoof == flat ? b.primary : b.muted,
          ),
          onTap: () => setState(() => _flatRoof = flat),
        ),
      if (!_flatRoof) ...[
        for (final steel in const [false, true])
          ImmoListTile(
            icon: Icons.architecture_rounded,
            title: steel ? 'Charpente métallique' : 'Charpente bois',
            subtitle: steel ? 'Tubes acier 40 × 40' : 'Bois de charpente 8 × 8',
            trailing: Icon(
              _steelFrame == steel ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
              color: _steelFrame == steel ? b.primary : b.muted,
            ),
            onTap: () => setState(() => _steelFrame = steel),
          ),
        _pair(
          _NumberField(label: 'Pente du toit', controller: _pitch, suffix: '°'),
          _NumberField(label: 'Débord', controller: _overhang, suffix: 'm'),
        ),
      ],
      _pair(
        _NumberField(label: 'Pertes', controller: _waste, suffix: '%'),
        // Drawn plans give their own interior walls
        _drawn
            ? const SizedBox.shrink()
            : _NumberField(label: 'Murs intérieurs', controller: _interior, suffix: 'm', hint: interiorHint),
      ),
      if (_error != null) ...[
        const SizedBox(height: 4),
        Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
      ],
      const SizedBox(height: ImmoSpacing.md),
      _PrimaryButton(
        label: _metre == null ? 'Calculer les matériaux' : 'Recalculer',
        busy: _computing,
        onPressed: _requesting ? null : _compute,
      ),
    ];
  }

  List<Widget> _results(ImmoRentalPalette b) {
    final metre = _metre;
    if (metre == null) return const [];
    final r = metre.result;
    return [
      const SizedBox(height: ImmoSpacing.lg),
      const ImmoSectionTitle('Résultat'),
      ImmoStatRow(stats: [
        ImmoStat(label: 'Murs (m²)', value: formatNumber(r.wallArea), icon: Icons.view_module_outlined),
        ImmoStat(label: 'Béton (m³)', value: formatNumber(r.concreteVolume), icon: Icons.foundation_rounded),
        ImmoStat(label: 'Sol (m²)', value: formatNumber(r.floorArea), icon: Icons.grid_on_rounded),
      ]),
      const SizedBox(height: ImmoSpacing.md),
      const ImmoSectionTitle('Matériaux'),
      for (final t in r.totals)
        ImmoListTile(
          icon: _icon(t.code),
          title: t.label,
          subtitle: [
            '${formatNumber(_quantities[t.code] ?? t.quantity)} ${_unit(t)}',
            if (_prices[t.code] != null)
              formatFcfa((_quantities[t.code] ?? 0) * _prices[t.code]!),
            if ((_quantities[t.code] ?? 0) == 0) 'exclu de la demande',
          ].join(' · '),
          onTap: () => _editLine(t),
        ),
      const SizedBox(height: ImmoSpacing.sm),
      const ImmoSectionTitle('Détail par phase'),
      for (final p in r.phases)
        if (p.lines.isNotEmpty)
          ImmoListTile(
            icon: Icons.layers_outlined,
            title: p.label,
            subtitle: [for (final l in p.lines) _phaseItem(l)].join(' · '),
          ),
      const SizedBox(height: ImmoSpacing.sm),
      const ImmoSectionTitle('Hypothèses'),
      for (final h in r.assumptions)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('• $h', style: TextStyle(fontSize: 12.5, color: b.muted, height: 1.4)),
        ),
      const SizedBox(height: ImmoSpacing.md),
      if (metre.requestId != null)
        const ImmoListTile(
          icon: Icons.task_alt_rounded,
          title: 'Demande envoyée',
          subtitle: 'En attente de validation par le superviseur.',
        ),
      _PrimaryButton(
        label: metre.requestId == null ? 'Créer la demande de matériaux' : 'Envoyer une nouvelle demande',
        busy: _requesting,
        onPressed: _computing ? null : _request,
      ),
    ];
  }

  static Widget _pair(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Expanded(child: a), const SizedBox(width: 12), Expanded(child: b)],
      );

  static String _unit(MetreLine t) => switch (t.code) {
        'CIMENT' => 'sacs de 50 kg',
        'FER_HA10' => 'barres de 12 m',
        'AGGLO_15' || 'AGGLO_20' => 'agglos',
        _ => t.unit,
      };

  /// Plural unit for fields: sacs, agglos, barres; m³, m², L as they are.
  static String shortUnit(MetreLine t) => switch (t.code) {
        'CIMENT' => 'sacs',
        'FER_HA10' => 'barres',
        'AGGLO_15' || 'AGGLO_20' => 'agglos',
        _ => t.unit,
      };

  /// Phase detail as a site order reads: "473 agglos de 20", "4,8 m³ de sable".
  static String _phaseItem(MetreLine l) {
    final whole = l.quantity.round();
    final tenth = formatNumber((l.quantity * 10).round() / 10);
    String n(String one, String many) => '${formatNumber(whole)} ${whole <= 1 ? one : many}';
    return switch (l.code) {
      'CIMENT' => n('sac de ciment', 'sacs de ciment'),
      'SABLE' => '$tenth m³ de sable',
      'GRAVIER' => '$tenth m³ de gravier',
      'AGGLO_15' => n('agglo de 15', 'agglos de 15'),
      'AGGLO_20' => n('agglo de 20', 'agglos de 20'),
      'FER_HA10' => n('barre HA10', 'barres HA10'),
      'CARRELAGE' => '${formatNumber(whole)} m² de carrelage',
      'PEINTURE' => '${formatNumber(whole)} L de peinture',
      _ => '$tenth ${l.unit} — ${l.label}',
    };
  }

  static IconData _icon(String code) => switch (code) {
        'CIMENT' => Icons.inventory_2_outlined,
        'SABLE' => Icons.grain_rounded,
        'GRAVIER' => Icons.terrain_outlined,
        'AGGLO_15' || 'AGGLO_20' => Icons.view_module_outlined,
        'FER_HA10' => Icons.straighten_rounded,
        'CARRELAGE' => Icons.grid_on_rounded,
        'PEINTURE' => Icons.format_paint_outlined,
        _ => Icons.category_outlined,
      };
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.label,
    required this.controller,
    this.suffix,
    this.hint,
    this.helper,
    this.decimal = true,
  });

  final String label;
  final TextEditingController controller;
  final String? suffix;
  final String? hint;
  final String? helper;
  final bool decimal;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ImmoFieldLabel(label),
          TextField(
            controller: controller,
            keyboardType: TextInputType.numberWithOptions(decimal: decimal),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(decimal ? r'[0-9.,]' : r'[0-9]')),
            ],
            style: TextStyle(color: b.text),
            decoration: immoFieldDecoration(context, hintText: hint, suffixText: suffix)
                .copyWith(helperText: helper),
          ),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.busy, required this.onPressed});

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return FilledButton(
      onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: b.primary,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      ),
      child: busy
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(label),
    );
  }
}

/// Name and dimensions of one room. Pops the room.
class _RoomForm extends StatefulWidget {
  const _RoomForm({this.room});

  final MetreRoom? room;

  @override
  State<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends State<_RoomForm> {
  late final _name = TextEditingController(text: widget.room?.name ?? '');
  late final _length = TextEditingController(
      text: widget.room == null ? '' : formatNumber(widget.room!.length));
  late final _width = TextEditingController(
      text: widget.room == null ? '' : formatNumber(widget.room!.width));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  void _save() {
    final length = parseNumber(_length.text);
    final width = parseNumber(_width.text);
    if (length == null || width == null || length <= 0 || width <= 0) {
      setState(() => _error = 'Saisissez la longueur et la largeur de la pièce.');
      return;
    }
    final name = _name.text.trim();
    Navigator.pop(context, MetreRoom(name: name.isEmpty ? 'Pièce' : name, length: length, width: width));
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImmoFieldLabel('Nom'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: b.text),
          decoration: immoFieldDecoration(context, hintText: 'Ex. Salon, Chambre 1'),
        ),
        const SizedBox(height: 12),
        _MetreScreenState._pair(
          _NumberField(label: 'Longueur', controller: _length, suffix: 'm'),
          _NumberField(label: 'Largeur', controller: _width, suffix: 'm'),
        ),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: ImmoSpacing.sm),
        _PrimaryButton(label: 'Enregistrer', busy: false, onPressed: _save),
      ],
    );
  }
}

/// Quantity (0 leaves the material out) and optional unit price. Pops (quantity, price).
class _LineForm extends StatefulWidget {
  const _LineForm({required this.line, required this.quantity, this.price});

  final MetreLine line;
  final int quantity;
  final double? price;

  @override
  State<_LineForm> createState() => _LineFormState();
}

class _LineFormState extends State<_LineForm> {
  late final _quantity = TextEditingController(text: '${widget.quantity}');
  late final _price = TextEditingController(
      text: widget.price == null ? '' : formatNumber(widget.price!));

  @override
  void dispose() {
    _quantity.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Calculé : ${formatNumber(widget.line.quantity)} ${_MetreScreenState._unit(widget.line)}. '
          'Mettez 0 pour l’exclure de la demande.',
          style: TextStyle(fontSize: 13.5, color: b.muted, height: 1.4),
        ),
        const SizedBox(height: ImmoSpacing.md),
        _MetreScreenState._pair(
          _NumberField(
            label: 'Quantité',
            controller: _quantity,
            decimal: false,
            suffix: _MetreScreenState.shortUnit(widget.line),
          ),
          _NumberField(label: 'Prix unitaire', controller: _price, suffix: 'FCFA', hint: 'Facultatif'),
        ),
        const SizedBox(height: ImmoSpacing.sm),
        _PrimaryButton(
          label: 'Enregistrer',
          busy: false,
          onPressed: () => Navigator.pop(
            context,
            ((parseNumber(_quantity.text) ?? 0).round(), parseNumber(_price.text)),
          ),
        ),
      ],
    );
  }
}

class _PlanRoomResult {
  const _PlanRoomResult.saved(PlanRoom this.room) : deleted = false;
  const _PlanRoomResult.deleted()
      : room = null,
        deleted = true;

  final PlanRoom? room;
  final bool deleted;
}

/// Name and exact size of a drawn room (sizes snap to 50 cm). Pops a [_PlanRoomResult].
class _PlanRoomForm extends StatefulWidget {
  const _PlanRoomForm({required this.room, required this.canDelete, required this.overlaps});

  final PlanRoom room;
  final bool canDelete;
  final bool Function(PlanRoom) overlaps;

  @override
  State<_PlanRoomForm> createState() => _PlanRoomFormState();
}

class _PlanRoomFormState extends State<_PlanRoomForm> {
  late final _name = TextEditingController(text: widget.room.name);
  late final _length = TextEditingController(text: formatNumber(widget.room.w * HousePlan.cell));
  late final _width = TextEditingController(text: formatNumber(widget.room.h * HousePlan.cell));
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _length.dispose();
    _width.dispose();
    super.dispose();
  }

  void _save() {
    final length = parseNumber(_length.text);
    final width = parseNumber(_width.text);
    if (length == null || width == null || length < 1 || width < 1) {
      setState(() => _error = 'Une pièce mesure au moins 1 m de côté.');
      return;
    }
    final name = _name.text.trim();
    final room = widget.room.copyWith(
      name: name.isEmpty ? 'Pièce' : name,
      w: (length / HousePlan.cell).round(),
      h: (width / HousePlan.cell).round(),
    );
    if (room.x + room.w > HousePlan.columns || room.y + room.h > HousePlan.rows) {
      setState(() => _error = 'La pièce dépasse de la zone de dessin.');
      return;
    }
    if (widget.overlaps(room)) {
      setState(() => _error = 'À cette taille, la pièce chevauche une autre pièce.');
      return;
    }
    Navigator.pop(context, _PlanRoomResult.saved(room));
  }

  @override
  Widget build(BuildContext context) {
    final b = ImmoBrand.rentalOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ImmoFieldLabel('Nom'),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          style: TextStyle(color: b.text),
          decoration: immoFieldDecoration(context, hintText: 'Ex. Salon, Chambre 1'),
        ),
        const SizedBox(height: 12),
        _MetreScreenState._pair(
          _NumberField(label: 'Longueur', controller: _length, suffix: 'm'),
          _NumberField(label: 'Largeur', controller: _width, suffix: 'm'),
        ),
        if (_error != null) ...[
          Text(_error!, style: TextStyle(color: b.danger, fontSize: 13.5)),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: ImmoSpacing.sm),
        _PrimaryButton(label: 'Enregistrer', busy: false, onPressed: _save),
        if (widget.canDelete)
          TextButton(
            onPressed: () => Navigator.pop(context, const _PlanRoomResult.deleted()),
            style: TextButton.styleFrom(foregroundColor: b.danger),
            child: const Text('Supprimer la pièce'),
          ),
      ],
    );
  }
}
