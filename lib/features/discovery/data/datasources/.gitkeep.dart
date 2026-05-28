/// Clean Architecture — Data Layer: Data Sources
///
/// Data sources handle raw data access. Two common types:
/// - **Remote**: Supabase, REST API, GraphQL
/// - **Local**: SQLite (sqflite), SharedPreferences, Hive
///
/// Example:
/// ```dart
/// class RouteRemoteDataSource {
///   final SupabaseClient client;
///   RouteRemoteDataSource(this.client);
///
///   Future<List<RouteModel>> getRoutes() async {
///     final response = await client.from('routes').select();
///     return response.map((e) => RouteModel.fromJson(e)).toList();
///   }
/// }
/// ```
