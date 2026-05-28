import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../discovery/data/models/climbing_route_model.dart';

class FavoritesRepository {
  FavoritesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  static const _favoritesTable = 'favorite_routes';

  /// Get all favorite routes for a specific user
  Future<List<ClimbingRouteModel>> getUserFavorites(String userId) async {
    final response = await _client
        .from(_favoritesTable)
        .select('*, climbing_routes(*)')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List).map((row) {
      if (row is Map) {
        final routeMap = row['climbing_routes'] as Map<String, dynamic>;
        return ClimbingRouteModel.fromJson(routeMap);
      }
      throw Exception('Row is not a Map: $row');
    }).toList();
  }

  /// Add a route to favorites
  Future<void> addFavorite(String userId, String routeId) async {
    await _client.from(_favoritesTable).insert({
      'user_id': userId,
      'route_id': routeId,
    });
  }

  /// Remove a route from favorites
  Future<void> removeFavorite(String userId, String routeId) async {
    await _client
        .from(_favoritesTable)
        .delete()
        .eq('user_id', userId)
        .eq('route_id', routeId);
  }
}
