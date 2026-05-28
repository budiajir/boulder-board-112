import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../discovery/data/models/climbing_route_model.dart';
import '../../data/repositories/favorites_repository.dart';

class FavoritesNotifier extends AsyncNotifier<List<ClimbingRouteModel>> {
  @override
  Future<List<ClimbingRouteModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return [];

    final repo = FavoritesRepository();
    return await repo.getUserFavorites(user.id);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }

    try {
      final repo = FavoritesRepository();
      final routes = await repo.getUserFavorites(user.id);
      state = AsyncData(routes);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> toggleFavorite(ClimbingRouteModel route) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || !state.hasValue) return;

    final currentFavorites = state.value!;
    final isFavorite = currentFavorites.any((r) => r.id == route.id);
    final routeId = route.id!;

    try {
      final repo = FavoritesRepository();
      
      // Optimistic update
      if (isFavorite) {
        state = AsyncData(currentFavorites.where((r) => r.id != routeId).toList());
        await repo.removeFavorite(user.id, routeId);
      } else {
        state = AsyncData([...currentFavorites, route]);
        await repo.addFavorite(user.id, routeId);
      }
    } catch (e) {
      // Revert on error by refreshing
      refresh();
      rethrow;
    }
  }

  bool isFavorite(String routeId) {
    if (!state.hasValue) return false;
    return state.value!.any((r) => r.id == routeId);
  }
}

final favoritesProvider = AsyncNotifierProvider<FavoritesNotifier, List<ClimbingRouteModel>>(FavoritesNotifier.new);
