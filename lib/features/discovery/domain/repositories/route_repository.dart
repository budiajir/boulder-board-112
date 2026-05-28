import '../../../discovery/data/models/climbing_route_model.dart';

/// Abstract contract for route data operations.
///
/// Defines the interface that the domain layer depends on.
/// Concrete implementations (e.g. [RouteRepositoryImpl]) live in the
/// data layer and can be swapped for testing or different backends.
abstract class RouteRepository {
  /// Fetch all published routes, ordered by most recent first.
  Future<List<ClimbingRouteModel>> getRoutes();

  /// Fetch a single route by its UUID.
  Future<ClimbingRouteModel?> getRouteById(String id);

  /// Fetch all routes created by a specific user.
  Future<List<ClimbingRouteModel>> getUserRoutes(String userId);

  /// Create a new route and return it with server-generated fields.
  Future<ClimbingRouteModel> createRoute(ClimbingRouteModel route);

  /// Update an existing route.
  Future<void> updateRoute(ClimbingRouteModel route);

  /// Delete a route by its UUID.
  Future<void> deleteRoute(String id);

  /// Set the active route on the physical board.
  ///
  /// Updates the `active_board_route` row (board_id = 'default')
  /// with the given [routeId], caching the route's name, grade,
  /// and holds for instant LED rendering.
  Future<void> updateActiveRoute(String routeId);
}
