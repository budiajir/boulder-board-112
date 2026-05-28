/// Clean Architecture — Domain Layer: Repository Contracts
///
/// Abstract repository interfaces define the contract between
/// the domain and data layers. Implementations live in `data/repositories/`.
///
/// Example:
/// ```dart
/// abstract class RouteRepository {
///   Future<List<RouteEntity>> getRoutes();
///   Future<RouteEntity> getRouteById(String id);
///   Future<void> saveRoute(RouteEntity route);
/// }
/// ```
