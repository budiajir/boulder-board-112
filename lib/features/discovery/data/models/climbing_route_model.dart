import 'dart:ui';

/// A single hold within a climbing route, stored as JSONB in Supabase.
///
/// Each hold maps to a physical position on the board grid (x, y)
/// and carries a LED hex color string for hardware rendering.
///
/// JSONB shape in Supabase:
/// ```json
/// { "x": 5, "y": 2, "hold_type": "start", "led_color": "#00FF66", "led_index": 27 }
/// ```
class RouteHoldEntry {
  const RouteHoldEntry({
    required this.x,
    required this.y,
    required this.holdType,
    required this.ledColor,
    this.ledIndex,
  });

  /// Column position on the board grid (0-indexed from left).
  final int x;

  /// Row position on the board grid (0-indexed from top).
  final int y;

  /// Functional type: "start", "hand", "foot", or "finish".
  final String holdType;

  /// LED color as a hex string (e.g. "#00FF66", "#3B82F6").
  final String ledColor;

  /// Physical LED strip index for BLE payload (optional).
  final int? ledIndex;

  /// Default LED hex colors per hold type.
  static const Map<String, String> defaultColors = {
    'start':  '#00FF66', // Green
    'hand':   '#3B82F6', // Blue
    'foot':   '#F97316', // Orange
    'finish': '#EF4444', // Red
  };

  /// Create from a Supabase JSONB map.
  factory RouteHoldEntry.fromJson(Map<String, dynamic> json) {
    return RouteHoldEntry(
      x: json['x'] as int,
      y: json['y'] as int,
      holdType: json['hold_type'] as String? ?? 'hand',
      ledColor: json['led_color'] as String? ?? defaultColors['hand']!,
      ledIndex: json['led_index'] as int?,
    );
  }

  /// Serialize to a Supabase-compatible JSONB map.
  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'hold_type': holdType,
        'led_color': ledColor,
        if (ledIndex != null) 'led_index': ledIndex,
      };

  /// Parse the [ledColor] hex string into a Flutter [Color].
  Color toFlutterColor() {
    final hex = ledColor.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteHoldEntry &&
          runtimeType == other.runtimeType &&
          x == other.x &&
          y == other.y;

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => 'Hold($holdType @($x,$y) $ledColor)';
}

/// Data-layer model mapping 1:1 to the Supabase `climbing_routes` table.
///
/// Uses **snake_case** keys in [fromJson]/[toJson] to match Supabase columns.
/// Holds are stored as `List<Map<String, dynamic>>` (JSONB array) with
/// each entry containing x, y grid coordinates and a LED hex color.
///
/// ```dart
/// // Fetch from Supabase
/// final rows = await SupabaseService.from('climbing_routes').select();
/// final routes = rows.map((r) => ClimbingRouteModel.fromJson(r)).toList();
///
/// // Insert to Supabase
/// await SupabaseService.from('climbing_routes').insert(route.toJson());
/// ```
class ClimbingRouteModel {
  const ClimbingRouteModel({
    this.id,
    required this.name,
    required this.grade,
    required this.holds,
    this.setterId,
    this.setterName = 'Anonymous',
    this.description = '',
    this.angle = 0,
    this.moveCount = 0,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.sendCount = 0,
    this.isBenchmark = false,
    this.isDraft = false,
    this.boardLayout = '11x18',
    this.createdAt,
    this.updatedAt,
  });

  /// UUID primary key (null when creating a new route — Supabase auto-generates).
  final String? id;

  /// Route display name.
  final String name;

  /// V-scale grade string (e.g. "V0", "V5", "V12").
  final String grade;

  /// Hold positions as a list of maps with x, y coordinates and LED hex colors.
  ///
  /// Each entry shape:
  /// ```json
  /// { "x": 5, "y": 2, "hold_type": "start", "led_color": "#00FF66", "led_index": 27 }
  /// ```
  final List<RouteHoldEntry> holds;

  /// UUID of the route setter (references profiles.id).
  final String? setterId;

  /// Cached display name of the setter.
  final String setterName;

  /// Optional description or beta.
  final String description;

  /// Board angle in degrees.
  final int angle;

  /// Number of non-foot moves.
  final int moveCount;

  /// Average community rating (0.00–5.00).
  final double rating;

  /// Number of ratings received.
  final int ratingCount;

  /// Total number of successful sends.
  final int sendCount;

  /// Whether this is an official benchmark problem.
  final bool isBenchmark;

  /// Whether the route is a draft (only visible to the setter).
  final bool isDraft;

  /// Grid dimensions string (e.g. "11x18").
  final String boardLayout;

  /// Server-set creation timestamp.
  final DateTime? createdAt;

  /// Server-set last-update timestamp.
  final DateTime? updatedAt;

  // ─── Serialization ────────────────────────────────────────

  /// Deserialize from a Supabase row (snake_case keys).
  factory ClimbingRouteModel.fromJson(Map<String, dynamic> json) {
    return ClimbingRouteModel(
      id: json['id'] as String?,
      name: json['name'] as String,
      grade: json['grade'] as String,
      holds: _parseHolds(json['holds']),
      setterId: json['setter_id'] as String?,
      setterName: json['setter_name'] as String? ?? 'Anonymous',
      description: json['description'] as String? ?? '',
      angle: json['angle'] as int? ?? 0,
      moveCount: json['move_count'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      ratingCount: json['rating_count'] as int? ?? 0,
      sendCount: json['send_count'] as int? ?? 0,
      isBenchmark: json['is_benchmark'] as bool? ?? false,
      isDraft: json['is_draft'] as bool? ?? false,
      boardLayout: json['board_layout'] as String? ?? '11x18',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  static List<RouteHoldEntry> _parseHolds(dynamic holdsJson) {
    if (holdsJson == null) return [];
    if (holdsJson is Iterable) {
      final list = <RouteHoldEntry>[];
      for (final h in holdsJson) {
        if (h is Map) {
          list.add(RouteHoldEntry.fromJson(Map<String, dynamic>.from(h)));
        }
      }
      return list;
    }
    return [];
  }

  /// Serialize to a Supabase-compatible map (snake_case keys).
  ///
  /// Omits `id`, `created_at`, and `updated_at` — these are
  /// managed by Supabase (auto-generated UUID and server timestamps).
  Map<String, dynamic> toJson() => {
        'name': name,
        'grade': grade,
        'holds': holds.map((h) => h.toJson()).toList(),
        'setter_id': setterId,
        'setter_name': setterName,
        'description': description,
        'angle': angle,
        'move_count': moveCount,
        'rating': rating,
        'rating_count': ratingCount,
        'send_count': sendCount,
        'is_benchmark': isBenchmark,
        'is_draft': isDraft,
        'board_layout': boardLayout,
      };

  /// Serialize including all fields (for reads/caching, not inserts).
  Map<String, dynamic> toFullJson() => {
        'id': id,
        ...toJson(),
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };

  // ─── Helpers ──────────────────────────────────────────────

  /// Immutable copy with modified fields.
  ClimbingRouteModel copyWith({
    String? id,
    String? name,
    String? grade,
    List<RouteHoldEntry>? holds,
    String? setterId,
    String? setterName,
    String? description,
    int? angle,
    int? moveCount,
    double? rating,
    int? ratingCount,
    int? sendCount,
    bool? isBenchmark,
    bool? isDraft,
    String? boardLayout,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClimbingRouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      holds: holds ?? this.holds,
      setterId: setterId ?? this.setterId,
      setterName: setterName ?? this.setterName,
      description: description ?? this.description,
      angle: angle ?? this.angle,
      moveCount: moveCount ?? this.moveCount,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      sendCount: sendCount ?? this.sendCount,
      isBenchmark: isBenchmark ?? this.isBenchmark,
      isDraft: isDraft ?? this.isDraft,
      boardLayout: boardLayout ?? this.boardLayout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Filter holds by type.
  List<RouteHoldEntry> holdsByType(String type) =>
      holds.where((h) => h.holdType == type).toList();

  /// Computed move count (non-foot holds).
  int get computedMoveCount =>
      holds.where((h) => h.holdType != 'foot').length;

  @override
  String toString() => 'ClimbingRouteModel($id, "$name", $grade, ${holds.length} holds)';
}
