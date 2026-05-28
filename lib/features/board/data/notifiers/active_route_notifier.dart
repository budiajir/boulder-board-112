import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../discovery/data/repositories/route_repository_impl.dart';
import '../../../ble/presentation/providers/ble_notifier.dart';
import '../models/active_board_route_model.dart';

/// Riverpod [AsyncNotifier] that subscribes to Supabase Realtime
/// changes on the `active_board_route` table.
///
/// The notifier:
/// 1. Fetches the initial active board state on [build].
/// 2. Opens a Supabase Realtime stream via `.stream()`.
/// 3. Automatically updates [state] whenever the row changes
///    (from any client — including other phones in the gym).
///
/// Usage in a widget:
/// ```dart
/// class BoardScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final activeRoute = ref.watch(activeRouteProvider);
///     return activeRoute.when(
///       data: (model) => Text(model.routeName),
///       loading: () => CircularProgressIndicator(),
///       error: (e, _) => Text('Error: $e'),
///     );
///   }
/// }
/// ```
class ActiveRouteNotifier extends AsyncNotifier<ActiveBoardRouteModel> {
  static const _table = 'active_board_route';
  static const _defaultBoardId = 'default';

  StreamSubscription<List<Map<String, dynamic>>>? _subscription;

  @override
  Future<ActiveBoardRouteModel> build() async {
    // Clean up the stream when the notifier is disposed
    ref.onDispose(_disposeStream);

    // 1. Fetch the initial state
    final initial = await _fetchCurrent();

    // 2. Subscribe to realtime changes
    _listenToRealtimeStream();

    // 3. Automatically sync physical BLE board when state changes!
    ref.listenSelf((previous, next) {
      final model = next.valueOrNull;
      if (model != null) {
        final bleState = ref.read(bleProvider);
        if (bleState.isConnected) {
          ref.read(bleProvider.notifier).sendPayload(model.toBlePayload());
        }
      }
    });

    return initial;
  }

  // ─── Realtime stream ──────────────────────────────────────

  /// Subscribe to Supabase Realtime via the `.stream()` API.
  ///
  /// `.stream(primaryKey:)` returns a `Stream<List<Map<String, dynamic>>>`
  /// that emits the full row(s) on every INSERT, UPDATE, or DELETE.
  void _listenToRealtimeStream() {
    final client = SupabaseService.client;

    final stream = client
        .from(_table)
        .stream(primaryKey: ['board_id'])
        .eq('board_id', _defaultBoardId);

    _subscription = stream.listen(
      (rows) {
        if (rows.isNotEmpty) {
          final model = ActiveBoardRouteModel.fromJson(rows.first);
          state = AsyncData(model);
        } else {
          // Row was deleted — reset to empty state
          state = const AsyncData(ActiveBoardRouteModel());
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        state = AsyncError(error, stackTrace);
      },
    );
  }

  /// Fetch the current active board route via a normal SELECT.
  Future<ActiveBoardRouteModel> _fetchCurrent() async {
    final response = await SupabaseService.client
        .from(_table)
        .select()
        .eq('board_id', _defaultBoardId)
        .maybeSingle();

    if (response == null) return const ActiveBoardRouteModel();
    return ActiveBoardRouteModel.fromJson(response);
  }

  /// Cancel the realtime subscription.
  void _disposeStream() {
    _subscription?.cancel();
    _subscription = null;
  }

  // ─── Public actions ───────────────────────────────────────

  /// Activate a route on the board by its UUID.
  ///
  /// Delegates to [RouteRepositoryImpl.updateActiveRoute] which
  /// upserts the `active_board_route` row. The realtime stream
  /// will automatically pick up the change and update [state].
  Future<void> activateRoute(String routeId) async {
    state = const AsyncLoading();
    try {
      final repo = RouteRepositoryImpl();
      await repo.updateActiveRoute(routeId);
      // No need to manually update state — the realtime stream
      // will emit the new row and update state automatically.
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Turn the LEDs on or off without changing the route.
  Future<void> toggleLeds({bool? on}) async {
    final current = state.valueOrNull;
    if (current == null) return;

    final newValue = on ?? !current.ledsOn;
    
    // Optimistic update so the UI reacts instantly
    state = AsyncData(current.copyWith(ledsOn: newValue));

    try {
      await SupabaseService.client
          .from(_table)
          .update({'leds_on': newValue})
          .eq('board_id', _defaultBoardId);
      // Realtime stream will update state again if successful
    } catch (e, st) {
      // Revert to old state on failure
      state = AsyncData(current);
      state = AsyncError(e, st);
    }
  }



  /// Clear the active route (turn off LEDs and unset route).
  Future<void> clearActiveRoute() async {
    try {
      await SupabaseService.client.from(_table).update({
        'route_id': null,
        'route_name': '',
        'route_grade': '',
        'holds': [],
        'leds_on': false,
      }).eq('board_id', _defaultBoardId);
      // Realtime stream will update state
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

// ─── Provider ───────────────────────────────────────────────

/// Global provider for the active board route state.
///
/// ```dart
/// // Watch in a widget
/// final activeRoute = ref.watch(activeRouteProvider);
///
/// // Call actions
/// ref.read(activeRouteProvider.notifier).activateRoute(routeId);
/// ref.read(activeRouteProvider.notifier).toggleLeds();
/// ref.read(activeRouteProvider.notifier).setBrightness(0.5);
/// ```
final activeRouteProvider =
    AsyncNotifierProvider<ActiveRouteNotifier, ActiveBoardRouteModel>(
  ActiveRouteNotifier.new,
);
