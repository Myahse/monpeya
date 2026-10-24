import 'package:immo/src/features/construction/models/house_plan.model.dart';

/// Métré of a chantier — the dimensions entered and the materials computed
/// from them by `/api/chantiers/{id}/metre`.
class MetreRoom {
  const MetreRoom({required this.name, required this.length, required this.width});

  final String name;
  final double length;
  final double width;

  double get area => length * width;

  Map<String, dynamic> toJson() => {'nom': name, 'longueur': length, 'largeur': width};

  factory MetreRoom.fromJson(Map<String, dynamic> j) => MetreRoom(
        name: (j['nom'] as String?)?.trim().isNotEmpty == true ? j['nom'] as String : 'Pièce',
        length: _d(j['longueur']) ?? 0,
        width: _d(j['largeur']) ?? 0,
      );
}

class MetreOpening {
  const MetreOpening({required this.count, required this.width, required this.height});

  final int count;
  final double width;
  final double height;

  Map<String, dynamic> toJson() => {'nombre': count, 'largeur': width, 'hauteur': height};

  factory MetreOpening.fromJson(Map<String, dynamic>? j, MetreOpening fallback) => j == null
      ? fallback
      : MetreOpening(
          count: _i(j['nombre']) ?? fallback.count,
          width: _d(j['largeur']) ?? fallback.width,
          height: _d(j['hauteur']) ?? fallback.height,
        );
}

/// What the chef de chantier enters. The same layout is assumed on every level.
class MetreInput {
  const MetreInput({
    required this.length,
    required this.width,
    this.levels = 1,
    this.wallHeight = 2.8,
    this.rooms = const [],
    this.interiorWalls,
    this.doors = defaultDoors,
    this.windows = defaultWindows,
    this.blockThickness = 15,
    this.flatRoof = false,
    this.roofPitch = 25,
    this.roofOverhang = 0.5,
    this.steelFrame = false,
    this.waste = 0.05,
    this.exteriorWalls,
    this.footprintArea,
    this.plan,
  });

  static const defaultDoors = MetreOpening(count: 0, width: 0.9, height: 2.1);
  static const defaultWindows = MetreOpening(count: 0, width: 1.2, height: 1.2);

  final double length;
  final double width;
  final int levels;
  final double wallHeight;
  final List<MetreRoom> rooms;

  /// Overrides the interior wall length the backend derives from [rooms].
  final double? interiorWalls;
  final MetreOpening doors;
  final MetreOpening windows;

  /// 15 or 20 (cm).
  final int blockThickness;
  final bool flatRoof;

  /// Sheet roof (when not [flatRoof]): slope in degrees, overhang beyond the walls in metres,
  /// and a steel frame rather than a timber one.
  final double roofPitch;
  final double roofOverhang;
  final bool steelFrame;

  /// 0.05 = 5 %.
  final double waste;

  /// From a drawn plan: its real outline and area (an L shape is smaller than its rectangle).
  final double? exteriorWalls;
  final double? footprintArea;

  /// The drawing itself, when the house was drawn rather than typed.
  final HousePlan? plan;

  Map<String, dynamic> toJson() => {
        'longueur': length,
        'largeur': width,
        'niveaux': levels,
        'hauteurMur': wallHeight,
        'pieces': [for (final r in rooms) r.toJson()],
        'longueurMursInterieurs': ?interiorWalls,
        'portes': doors.toJson(),
        'fenetres': windows.toJson(),
        'epaisseurAgglo': blockThickness,
        'toitureTerrasse': flatRoof,
        'pente': roofPitch,
        'debordToiture': roofOverhang,
        'charpente': steelFrame ? 'METAL' : 'BOIS',
        'perte': waste,
        'longueurMursExterieurs': ?exteriorWalls,
        'surfaceEmprise': ?footprintArea,
        'plan': ?plan?.toJson(),
      };

  factory MetreInput.fromJson(Map<String, dynamic> j) => MetreInput(
        length: _d(j['longueur']) ?? 0,
        width: _d(j['largeur']) ?? 0,
        levels: _i(j['niveaux']) ?? 1,
        wallHeight: _d(j['hauteurMur']) ?? 2.8,
        rooms: [
          for (final r in (j['pieces'] as List? ?? const []))
            if (r is Map) MetreRoom.fromJson(Map<String, dynamic>.from(r)),
        ],
        interiorWalls: _d(j['longueurMursInterieurs']),
        doors: MetreOpening.fromJson(_map(j['portes']), defaultDoors),
        windows: MetreOpening.fromJson(_map(j['fenetres']), defaultWindows),
        blockThickness: _i(j['epaisseurAgglo']) == 20 ? 20 : 15,
        flatRoof: j['toitureTerrasse'] == true,
        roofPitch: _d(j['pente']) ?? 25,
        roofOverhang: _d(j['debordToiture']) ?? 0.5,
        steelFrame: '${j['charpente']}'.toUpperCase() == 'METAL',
        waste: _d(j['perte']) ?? 0.05,
        exteriorWalls: _d(j['longueurMursExterieurs']),
        footprintArea: _d(j['surfaceEmprise']),
        plan: _map(j['plan']) == null ? null : HousePlan.fromJson(_map(j['plan'])!),
      );
}

class MetreLine {
  const MetreLine({required this.code, required this.label, required this.quantity, required this.unit});

  /// CIMENT, SABLE, GRAVIER, AGGLO_15, AGGLO_20, FER_HA10, CARRELAGE, PEINTURE, COFFRAGE, POINTES,
  /// FIL_ATTACHE, TOLE, VIS_TOLE, FAITIERE, BOIS_CHARPENTE, TUBE_CHARPENTE, ETANCHEITE, PORTE, FENETRE.
  final String code;
  final String label;
  final double quantity;
  final String unit;

  factory MetreLine.fromJson(Map<String, dynamic> j) => MetreLine(
        code: (j['code'] ?? '').toString(),
        label: (j['libelle'] ?? '').toString(),
        quantity: _d(j['quantite']) ?? 0,
        unit: (j['unite'] ?? '').toString(),
      );
}

class MetrePhase {
  const MetrePhase({required this.code, required this.label, required this.lines});

  final String code;
  final String label;
  final List<MetreLine> lines;

  factory MetrePhase.fromJson(Map<String, dynamic> j) => MetrePhase(
        code: (j['code'] ?? '').toString(),
        label: (j['libelle'] ?? '').toString(),
        lines: _lines(j['lignes']),
      );
}

class MetreResult {
  const MetreResult({
    required this.wallArea,
    required this.floorArea,
    required this.concreteVolume,
    required this.interiorWalls,
    required this.phases,
    required this.totals,
    required this.assumptions,
  });

  final double wallArea;
  final double floorArea;
  final double concreteVolume;
  final double interiorWalls;
  final List<MetrePhase> phases;

  /// Whole units per material — what the demande orders.
  final List<MetreLine> totals;
  final List<String> assumptions;

  factory MetreResult.fromJson(Map<String, dynamic> j) {
    final s = _map(j['surfaces']) ?? const {};
    return MetreResult(
      wallArea: _d(s['surfaceMursNette']) ?? 0,
      floorArea: _d(s['surfaceSol']) ?? 0,
      concreteVolume: _d(s['volumeBeton']) ?? 0,
      interiorWalls: _d(s['longueurMursInterieurs']) ?? 0,
      phases: [
        for (final p in (j['phases'] as List? ?? const []))
          if (p is Map) MetrePhase.fromJson(Map<String, dynamic>.from(p)),
      ],
      totals: _lines(j['totaux']),
      assumptions: [for (final h in (j['hypotheses'] as List? ?? const [])) h.toString()],
    );
  }
}

/// A chantier's saved métré.
class SiteMetre {
  const SiteMetre({required this.input, required this.result, this.requestId, this.updatedAt});

  final MetreInput input;
  final MetreResult result;

  /// Demande last created from it.
  final String? requestId;
  final DateTime? updatedAt;

  factory SiteMetre.fromJson(Map<String, dynamic> j) => SiteMetre(
        input: MetreInput.fromJson(_map(j['donnees']) ?? const {}),
        result: MetreResult.fromJson(_map(j['resultat']) ?? const {}),
        requestId: j['demandesId']?.toString(),
        updatedAt: DateTime.tryParse('${j['updatedAt']}'),
      );
}

/// One line of the material demande, as the chef de chantier adjusted it.
class MaterialRequestLine {
  const MaterialRequestLine({
    required this.code,
    required this.label,
    required this.unit,
    required this.quantity,
    this.unitPrice,
  });

  final String code;
  final String label;
  final String unit;
  final int quantity;
  final double? unitPrice;

  Map<String, dynamic> toJson() => {
        'code': code,
        'libelle': label,
        'unite': unit,
        'quantite': quantity,
        'prixUnitaire': ?unitPrice,
      };
}

List<MetreLine> _lines(Object? raw) => [
      for (final l in (raw as List? ?? const []))
        if (l is Map) MetreLine.fromJson(Map<String, dynamic>.from(l)),
    ];

Map<String, dynamic>? _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : null;

double? _d(Object? v) => v == null ? null : double.tryParse('$v');

int? _i(Object? v) => v == null ? null : int.tryParse('$v') ?? double.tryParse('$v')?.round();
