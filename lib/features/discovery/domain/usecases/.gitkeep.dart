/// Clean Architecture — Domain Layer: Use Cases
///
/// Use cases encapsulate a single piece of business logic.
/// Each use case has one public method (`call` or `execute`).
///
/// Example:
/// ```dart
/// class GetRoutes {
///   final RouteRepository repository;
///   GetRoutes(this.repository);
///
///   Future<List<RouteEntity>> call({String? gradeFilter}) {
///     return repository.getRoutes(gradeFilter: gradeFilter);
///   }
/// }
/// ```
