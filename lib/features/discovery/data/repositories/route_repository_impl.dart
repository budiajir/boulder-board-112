import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/route_repository.dart';
import '../models/climbing_route_model.dart';

/// Supabase implementation of [RouteRepository].
///
/// All queries go through [SupabaseService.client] and map directly
/// to the `climbing_routes` and `active_board_route` tables defined
/// in `assets/schema.sql`.
class RouteRepositoryImpl implements RouteRepository {
  RouteRepositoryImpl({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  // ─── Table names ──────────────────────────────────────────
  static const _routesTable = 'climbing_routes';
  static const _activeBoardTable = 'active_board_route';
  static const _defaultBoardId = 'default';

  // ─── Read operations ──────────────────────────────────────

  /// Fetch all published routes ordered by newest first.
  ///
  /// Excludes drafts unless they belong to the current user.
  @override
  Future<List<ClimbingRouteModel>> getRoutes() async {
    try {
      final dynamic response = await _client
          .from(_routesTable)
          .select()
          .eq('is_draft', false)
          .order('created_at', ascending: false);

      if (response == null) return [];
      if (response is! Iterable) {
        print('Warning: Supabase returned non-iterable for routes: $response');
        return [];
      }

      return response.map((row) {
        if (row is Map) {
          return ClimbingRouteModel.fromJson(Map<String, dynamic>.from(row));
        }
        throw Exception('Row is not a Map: $row');
      }).toList();
    } on TypeError catch (e) {
      if (e.toString().contains("type 'Null' is not a subtype of type 'Iterable<dynamic>'") ||
          e.toString().contains("type 'Null' is not a subtype of type 'iterable<dynamic>'")) {
        print('Caught Supabase empty table bug, returning empty list.');
        return [];
      }
      rethrow;
    } catch (e) {
      print('RouteRepositoryImpl.getRoutes Error: $e');
      rethrow;
    }
  }

  /// Fetch a single route by UUID.
  ///
  /// Returns `null` if not found.
  @override
  Future<ClimbingRouteModel?> getRouteById(String id) async {
    final response = await _client
        .from(_routesTable)
        .select()
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return ClimbingRouteModel.fromJson(response);
  }

  /// Fetch all routes created by a specific user.
  @override
  Future<List<ClimbingRouteModel>> getUserRoutes(String userId) async {
    try {
      final dynamic response = await _client
          .from(_routesTable)
          .select()
          .eq('setter_id', userId)
          .order('created_at', ascending: false);

      if (response == null) return [];
      if (response is! Iterable) return [];

      return response.map((row) {
        if (row is Map) {
          return ClimbingRouteModel.fromJson(Map<String, dynamic>.from(row));
        }
        throw Exception('Row is not a Map: $row');
      }).toList();
    } catch (e) {
      print('RouteRepositoryImpl.getUserRoutes Error: $e');
      rethrow;
    }
  }

  // ─── Write operations ─────────────────────────────────────

  /// Insert a new route and return it with server-generated id + timestamps.
  @override
  Future<ClimbingRouteModel> createRoute(ClimbingRouteModel route) async {
    final response = await _client
        .from(_routesTable)
        .insert(route.toJson())
        .select()
        .single();

    return ClimbingRouteModel.fromJson(response);
  }

  /// Update an existing route by its id.
  ///
  /// Throws if [route.id] is null.
  @override
  Future<void> updateRoute(ClimbingRouteModel route) async {
    assert(route.id != null, 'Cannot update a route without an id');

    await _client
        .from(_routesTable)
        .update(route.toJson())
        .eq('id', route.id!);
  }

  /// Delete a route by UUID.
  @override
  Future<void> deleteRoute(String id) async {
    await _client
        .from(_routesTable)
        .delete()
        .eq('id', id);
  }

  // ─── Active board route ───────────────────────────────────

  /// Update the active route displayed on the physical board.
  ///
  /// 1. Fetches the full route by [routeId] to get name, grade, and holds.
  /// 2. Upserts the `active_board_route` row (board_id = 'default')
  ///    with the route data and sets `leds_on = true`.
  ///
  /// This triggers a Supabase Realtime broadcast to all connected
  /// clients since `active_board_route` has realtime replication enabled.
  @override
  Future<void> updateActiveRoute(String routeId) async {
    // Fetch the route to cache its data in the active row
    final route = await getRouteById(routeId);
    if (route == null) {
      throw Exception('Route $routeId not found');
    }

    final currentUserId = _client.auth.currentUser?.id;

    await _client.from(_activeBoardTable).upsert({
      'board_id': _defaultBoardId,
      'route_id': routeId,
      'route_name': route.name,
      'route_grade': route.grade,
      'holds': route.holds.map((h) => h.toJson()).toList(),
      'leds_on': true,
      'activated_by': currentUserId,
      'activated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }
}
