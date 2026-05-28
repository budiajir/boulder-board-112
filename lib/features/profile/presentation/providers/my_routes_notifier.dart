import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../../discovery/data/models/climbing_route_model.dart';
import '../../../discovery/data/repositories/route_repository_impl.dart';

class MyRoutesNotifier extends AsyncNotifier<List<ClimbingRouteModel>> {
  @override
  Future<List<ClimbingRouteModel>> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return [];

    final repo = RouteRepositoryImpl();
    return await repo.getUserRoutes(user.id);
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
      final repo = RouteRepositoryImpl();
      final routes = await repo.getUserRoutes(user.id);
      state = AsyncData(routes);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final myRoutesProvider = AsyncNotifierProvider<MyRoutesNotifier, List<ClimbingRouteModel>>(MyRoutesNotifier.new);
