import '../../core/constants/hold_types.dart';

/// Represents a climbing route (problem) on the board.
class ClimbingRoute {
  const ClimbingRoute({
    required this.id,
    required this.name,
    required this.grade,
    required this.setter,
    required this.holds,
    this.angle = 40,
    this.description = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.sendCount = 0,
    this.isBenchmark = false,
    this.isDraft = false,
    this.createdAt,
    this.boardConfigId = 'standard_11x18',
  });

  final String id;
  final String name;
  final String grade; // e.g. "V3", "V5"
  final String setter; // Creator name
  final List<RouteHold> holds;
  final int angle; // Board angle in degrees
  final String description;
  final double rating; // Average star rating
  final int ratingCount;
  final int sendCount; // Total completions
  final bool isBenchmark;
  final bool isDraft;
  final DateTime? createdAt;
  final String boardConfigId;

  /// Number of moves (hand holds + start + finish).
  int get moveCount =>
      holds.where((h) => h.type != HoldType.foot).length;

  /// Get holds grouped by type.
  List<RouteHold> holdsByType(HoldType type) =>
      holds.where((h) => h.type == type).toList();

  ClimbingRoute copyWith({
    String? id,
    String? name,
    String? grade,
    String? setter,
    List<RouteHold>? holds,
    int? angle,
    String? description,
    double? rating,
    int? ratingCount,
    int? sendCount,
    bool? isBenchmark,
    bool? isDraft,
    DateTime? createdAt,
    String? boardConfigId,
  }) {
    return ClimbingRoute(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      setter: setter ?? this.setter,
      holds: holds ?? this.holds,
      angle: angle ?? this.angle,
      description: description ?? this.description,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      sendCount: sendCount ?? this.sendCount,
      isBenchmark: isBenchmark ?? this.isBenchmark,
      isDraft: isDraft ?? this.isDraft,
      createdAt: createdAt ?? this.createdAt,
      boardConfigId: boardConfigId ?? this.boardConfigId,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'grade': grade,
        'setter': setter,
        'holds': holds.map((h) => h.toJson()).toList(),
        'angle': angle,
        'description': description,
        'rating': rating,
        'ratingCount': ratingCount,
        'sendCount': sendCount,
        'isBenchmark': isBenchmark,
        'isDraft': isDraft,
        'createdAt': createdAt?.toIso8601String(),
        'boardConfigId': boardConfigId,
      };

  factory ClimbingRoute.fromJson(Map<String, dynamic> json) => ClimbingRoute(
        id: json['id'] as String,
        name: json['name'] as String,
        grade: json['grade'] as String,
        setter: json['setter'] as String,
        holds: (json['holds'] as List)
            .map((h) => RouteHold.fromJson(h))
            .toList(),
        angle: json['angle'] as int? ?? 40,
        description: json['description'] as String? ?? '',
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        ratingCount: json['ratingCount'] as int? ?? 0,
        sendCount: json['sendCount'] as int? ?? 0,
        isBenchmark: json['isBenchmark'] as bool? ?? false,
        isDraft: json['isDraft'] as bool? ?? false,
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'])
            : null,
        boardConfigId: json['boardConfigId'] as String? ?? 'standard_11x18',
      );
}

/// A hold assignment within a route.
class RouteHold {
  const RouteHold({
    required this.holdId,
    required this.type,
  });

  /// References HoldPosition.id from the BoardConfig.
  final int holdId;

  /// The functional type of this hold in the route.
  final HoldType type;

  Map<String, dynamic> toJson() => {
        'holdId': holdId,
        'type': type.name,
      };

  factory RouteHold.fromJson(Map<String, dynamic> json) => RouteHold(
        holdId: json['holdId'] as int,
        type: HoldType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => HoldType.hand,
        ),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RouteHold &&
          runtimeType == other.runtimeType &&
          holdId == other.holdId;

  @override
  int get hashCode => holdId.hashCode;
}
