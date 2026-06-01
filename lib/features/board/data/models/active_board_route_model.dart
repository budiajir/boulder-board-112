import '../../../discovery/data/models/climbing_route_model.dart';
import '../../../../data/models/board_config.dart';

/// Data model mapping 1:1 to the Supabase `active_board_route` table.
///
/// Represents the real-time LED state of a physical climbing board.
/// This table has Supabase Realtime replication enabled, so any
/// changes broadcast instantly to all connected clients.
class ActiveBoardRouteModel {
  const ActiveBoardRouteModel({
    this.boardId = 'default',
    this.routeId,
    this.routeName = '',
    this.routeGrade = '',
    this.holds = const [],
    this.brightness = 1.0,
    this.ledsOn = false,
    this.activatedBy,
    this.activatedAt,
    this.updatedAt,
  });

  /// Physical board identifier (primary key).
  final String boardId;

  /// UUID of the currently active climbing route.
  final String? routeId;

  /// Cached route name for display without a join.
  final String routeName;

  /// Cached V-scale grade string.
  final String routeGrade;

  /// Cached hold data for instant LED rendering.
  final List<RouteHoldEntry> holds;

  /// LED brightness level (0.0–1.0).
  final double brightness;

  /// Whether the LEDs are currently on.
  final bool ledsOn;

  /// UUID of the user who activated this route.
  final String? activatedBy;

  /// When the route was activated.
  final DateTime? activatedAt;

  /// Last update timestamp.
  final DateTime? updatedAt;

  /// Whether a route is currently loaded.
  bool get hasActiveRoute => routeId != null;

  // ─── Serialization ────────────────────────────────────────

  factory ActiveBoardRouteModel.fromJson(Map<String, dynamic> json) {
    return ActiveBoardRouteModel(
      boardId: json['board_id'] as String? ?? 'default',
      routeId: json['route_id'] as String?,
      routeName: json['route_name'] as String? ?? '',
      routeGrade: json['route_grade'] as String? ?? '',
      holds: (json['holds'] as List<dynamic>?)
              ?.map((h) => RouteHoldEntry.fromJson(
                  Map<String, dynamic>.from(h as Map)))
              .toList() ??
          [],
      brightness: (json['brightness'] as num?)?.toDouble() ?? 1.0,
      ledsOn: json['leds_on'] as bool? ?? false,
      activatedBy: json['activated_by'] as String?,
      activatedAt: json['activated_at'] != null
          ? DateTime.parse(json['activated_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'board_id': boardId,
        'route_id': routeId,
        'route_name': routeName,
        'route_grade': routeGrade,
        'holds': holds.map((h) => h.toJson()).toList(),
        'brightness': brightness,
        'leds_on': ledsOn,
        'activated_by': activatedBy,
      };

  ActiveBoardRouteModel copyWith({
    String? boardId,
    String? routeId,
    String? routeName,
    String? routeGrade,
    List<RouteHoldEntry>? holds,
    double? brightness,
    bool? ledsOn,
    String? activatedBy,
    DateTime? activatedAt,
    DateTime? updatedAt,
  }) {
    return ActiveBoardRouteModel(
      boardId: boardId ?? this.boardId,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      routeGrade: routeGrade ?? this.routeGrade,
      holds: holds ?? this.holds,
      brightness: brightness ?? this.brightness,
      ledsOn: ledsOn ?? this.ledsOn,
      activatedBy: activatedBy ?? this.activatedBy,
      activatedAt: activatedAt ?? this.activatedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Generate a raw byte array payload for the physical board via BLE.
  /// Format: [CMD, LED1, R, G, B, LED2, R, G, B...]
  /// CMD 0x01 = Turn ON, 0x02 = Turn OFF.
  List<int> toBlePayload() {
    if (!ledsOn || !hasActiveRoute || holds.isEmpty) {
      return [0x02]; // Turn OFF all LEDs
    }

    final payload = <int>[0x01]; // Command: Turn ON

    for (final h in holds) {
      // Use central HoldPosition helper for dynamic wiring pattern mapping
      final index = h.ledIndex ?? HoldPosition.calculateLedIndex(h.x, h.y);
      payload.add(index);

      // Map holdType to RGB color
      switch (h.holdType) {
        case 'start':
          payload.addAll([0, 255, 0]); // Green
          break;
        case 'finish':
          payload.addAll([255, 0, 0]); // Red
          break;
        case 'foot':
          payload.addAll([255, 255, 0]); // Yellow
          break;
        case 'hand':
        default:
          payload.addAll([0, 0, 255]); // Blue
          break;
      }
    }
    return payload;
  }

  @override
  String toString() =>
      'ActiveBoardRoute($boardId, route=$routeId, leds=${ledsOn ? "ON" : "OFF"})';
}
