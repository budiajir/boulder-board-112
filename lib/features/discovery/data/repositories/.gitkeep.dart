/// Clean Architecture — Data Layer: Repository Implementations
///
/// Concrete implementations of domain repository contracts.
/// They coordinate between remote and local data sources.
///
/// Example:
/// ```dart
/// class RouteRepositoryImpl implements RouteRepository {
///   final RouteRemoteDataSource remote;
///   final RouteLocalDataSource local;
///
///   RouteRepositoryImpl({required this.remote, required this.local});
///
///   @override
///   Future<List<RouteEntity>> getRoutes() async {
///     try {
///       final routes = await remote.getRoutes();
///       await local.cacheRoutes(routes);
///       return routes;
///     } catch (e) {
///       return local.getCachedRoutes();
///     }
///   }
/// }
/// ```
