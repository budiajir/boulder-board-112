import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/hold_types.dart';
import '../../../../core/services/local_database_service.dart';
import '../../../discovery/data/models/climbing_route_model.dart';
import '../../data/models/draft_route_model.dart';

/// Riverpod notifier responsible for managing local draft route states via SQLite.
class DraftsNotifier extends AsyncNotifier<List<DraftRouteModel>> {
  final _db = LocalDatabaseService.instance;

  @override
  Future<List<DraftRouteModel>> build() async {
    return await _db.getDrafts();
  }

  /// Manually force-refresh drafts from the local SQLite database.
  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _db.getDrafts());
  }

  /// Save or update a local draft climbing route.
  /// If [id] is provided, updates the existing draft; otherwise, inserts a new one.
  Future<void> saveDraft({
    int? id,
    required String name,
    required String grade,
    required int angle,
    required String description,
    required Map<int, HoldType> selectedHolds,
  }) async {
    // Map selectedHolds into structured RouteHoldEntry data
    final holds = selectedHolds.entries.map((e) {
      final col = e.key % 11;
      final row = e.key ~/ 11;
      return RouteHoldEntry(
        x: col,
        y: row,
        holdType: e.value.name,
        ledColor: RouteHoldEntry.defaultColors[e.value.name]!,
        ledIndex: e.key,
      );
    }).toList();

    final draft = DraftRouteModel(
      id: id,
      name: name.trim().isEmpty ? 'Unnamed Draft' : name.trim(),
      grade: grade,
      angle: angle,
      description: description,
      holds: holds,
      createdAt: DateTime.now(),
    );

    state = const AsyncLoading();
    try {
      if (id != null) {
        await _db.updateDraft(draft);
      } else {
        await _db.insertDraft(draft);
      }
      final drafts = await _db.getDrafts();
      state = AsyncData(drafts);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// Delete a local draft climbing route from the database.
  Future<void> deleteDraft(int id) async {
    state = const AsyncLoading();
    try {
      await _db.deleteDraft(id);
      final drafts = await _db.getDrafts();
      state = AsyncData(drafts);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

/// Global provider for local draft climbing routes.
final draftsProvider =
    AsyncNotifierProvider<DraftsNotifier, List<DraftRouteModel>>(
  DraftsNotifier.new,
);
