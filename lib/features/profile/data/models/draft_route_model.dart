import 'dart:convert';
import '../../../discovery/data/models/climbing_route_model.dart';

/// Data model representing a local draft climbing route stored in SQLite.
class DraftRouteModel {
  const DraftRouteModel({
    this.id,
    required this.name,
    required this.grade,
    required this.angle,
    this.description = '',
    required this.holds,
    required this.createdAt,
  });

  /// SQLite autoincrement ID. Null when not yet saved in database.
  final int? id;

  /// Display name of the route.
  final String name;

  /// V-scale grade (e.g. "V3").
  final String grade;

  /// Wall inclination angle in degrees.
  final int angle;

  /// Optional setter notes or beta.
  final String description;

  /// Grid holds included in this draft.
  final List<RouteHoldEntry> holds;

  /// Timestamp when this draft was created.
  final DateTime createdAt;

  /// Create a draft route from a SQLite database row.
  factory DraftRouteModel.fromMap(Map<String, dynamic> map) {
    final holdsJson = map['holds'] as String;
    final List<dynamic> parsedHolds = jsonDecode(holdsJson) as List<dynamic>;
    
    return DraftRouteModel(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unnamed Draft',
      grade: map['grade'] as String? ?? 'V3',
      angle: map['angle'] as int? ?? 40,
      description: map['description'] as String? ?? '',
      holds: parsedHolds
          .map((h) => RouteHoldEntry.fromJson(Map<String, dynamic>.from(h as Map)))
          .toList(),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// Serialize this draft route into a map for SQLite insertions/updates.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'grade': grade,
      'angle': angle,
      'description': description,
      'holds': jsonEncode(holds.map((h) => h.toJson()).toList()),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Convert this local draft into a standard [ClimbingRouteModel]
  /// ready to be uploaded/published to Supabase.
  ClimbingRouteModel toClimbingRoute({
    required String? setterId,
    required String setterName,
  }) {
    return ClimbingRouteModel(
      name: name,
      grade: grade,
      holds: holds,
      setterId: setterId,
      setterName: setterName,
      description: description,
      angle: angle,
      isDraft: false,
      moveCount: holds.where((h) => h.holdType != 'foot').length,
    );
  }

  /// Create an immutable copy with updated properties.
  DraftRouteModel copyWith({
    int? id,
    String? name,
    String? grade,
    int? angle,
    String? description,
    List<RouteHoldEntry>? holds,
    DateTime? createdAt,
  }) {
    return DraftRouteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      grade: grade ?? this.grade,
      angle: angle ?? this.angle,
      description: description ?? this.description,
      holds: holds ?? this.holds,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
