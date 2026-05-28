import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/hold_types.dart';
import '../../../discovery/data/models/climbing_route_model.dart';
import '../../../discovery/data/repositories/route_repository_impl.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../ble/presentation/providers/ble_notifier.dart';
import '../../../profile/data/models/draft_route_model.dart';

class EditorState {
  const EditorState({
    this.activeHoldType = HoldType.hand,
    this.selectedHolds = const {},
    this.routeName = '',
    this.routeGrade = 'V3',
    this.routeAngle = 40,
    this.routeDescription = '',
    this.isDraft = true,
    this.draftId,
  });

  final HoldType activeHoldType;
  final Map<int, HoldType> selectedHolds;
  final String routeName;
  final String routeGrade;
  final int routeAngle;
  final String routeDescription;
  final bool isDraft;
  final int? draftId;

  int get startCount => selectedHolds.values.where((t) => t == HoldType.start).length;
  int get handCount => selectedHolds.values.where((t) => t == HoldType.hand).length;
  int get footCount => selectedHolds.values.where((t) => t == HoldType.foot).length;
  int get finishCount => selectedHolds.values.where((t) => t == HoldType.finish).length;
  int get totalHolds => selectedHolds.length;

  EditorState copyWith({
    HoldType? activeHoldType,
    Map<int, HoldType>? selectedHolds,
    String? routeName,
    String? routeGrade,
    int? routeAngle,
    String? routeDescription,
    bool? isDraft,
    int? draftId,
  }) {
    return EditorState(
      activeHoldType: activeHoldType ?? this.activeHoldType,
      selectedHolds: selectedHolds ?? this.selectedHolds,
      routeName: routeName ?? this.routeName,
      routeGrade: routeGrade ?? this.routeGrade,
      routeAngle: routeAngle ?? this.routeAngle,
      routeDescription: routeDescription ?? this.routeDescription,
      isDraft: isDraft ?? this.isDraft,
      draftId: draftId ?? this.draftId,
    );
  }

  String? validate() {
    if (selectedHolds.isEmpty) return 'Add at least one hold.';
    if (startCount == 0) return 'Route must have at least one Start hold.';
    if (finishCount == 0) return 'Route must have at least one Finish hold.';
    if (handCount == 0) return 'Route must have at least one Hand hold.';
    if (routeName.trim().isEmpty) return 'Enter a route name.';
    return null;
  }
}

class EditorNotifier extends Notifier<EditorState> {
  @override
  EditorState build() => const EditorState();

  void setActiveHoldType(HoldType type) {
    state = state.copyWith(activeHoldType: type);
  }


  void toggleHold(int holdId) {
    final Map<int, HoldType> holds = Map.from(state.selectedHolds);
    if (holds.containsKey(holdId) && holds[holdId] == state.activeHoldType) {
      holds.remove(holdId);
    } else {
      holds[holdId] = state.activeHoldType;
    }
    state = state.copyWith(selectedHolds: holds);
    _syncToBle();
  }

  void cycleHold(int holdId, int row, int col) {
    final Map<int, HoldType> holds = Map.from(state.selectedHolds);
    final current = holds[holdId];
    final next = HoldType.cycleNext(current);
    if (next == null) {
      holds.remove(holdId);
    } else {
      holds[holdId] = next;
    }
    state = state.copyWith(selectedHolds: holds);
    _syncToBle();
  }

  void setRouteName(String name) => state = state.copyWith(routeName: name);
  void setRouteGrade(String grade) => state = state.copyWith(routeGrade: grade);
  void setRouteAngle(int angle) => state = state.copyWith(routeAngle: angle);
  void setRouteDescription(String desc) => state = state.copyWith(routeDescription: desc);

  Future<ClimbingRouteModel?> saveRoute() async {
    final error = state.validate();
    if (error != null) {
      throw Exception(error);
    }

    // Convert holds to RouteHoldEntry. Note: In a real app we need row/col from BoardConfig.
    // For now, we simulate x,y mapping. In the editor screen, we'll pass x,y properly or look it up.
    // Assuming standard 11x18 board: cols=11
    final holds = state.selectedHolds.entries.map((e) {
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

    final user = SupabaseService.client.auth.currentUser;

    final model = ClimbingRouteModel(
      name: state.routeName,
      grade: state.routeGrade,
      holds: holds,
      setterId: user?.id,
      setterName: user?.userMetadata?['display_name'] ?? 'Anonymous',
      angle: state.routeAngle,
      description: state.routeDescription,
      isDraft: false,
      moveCount: state.handCount + state.startCount + state.finishCount,
    );

    try {
      final repo = RouteRepositoryImpl();
      return await repo.createRoute(model);
    } catch (e) {
      rethrow;
    }
  }

  void clear() {
    state = const EditorState();
    _syncToBle();
  }

  void loadDraft(DraftRouteModel draft) {
    final Map<int, HoldType> selectedHolds = {};
    for (final h in draft.holds) {
      final type = HoldType.values.firstWhere(
        (t) => t.name == h.holdType,
        orElse: () => HoldType.hand,
      );
      final holdId = h.ledIndex ?? (h.y * 11 + h.x);
      selectedHolds[holdId] = type;
    }

    state = EditorState(
      activeHoldType: HoldType.hand,
      selectedHolds: selectedHolds,
      routeName: draft.name,
      routeGrade: draft.grade,
      routeAngle: draft.angle,
      routeDescription: draft.description,
      isDraft: true,
      draftId: draft.id,
    );
    _syncToBle();
  }

  void _syncToBle() {
    final bleState = ref.read(bleProvider);
    if (bleState.isConnected) {
      if (state.selectedHolds.isEmpty) {
        ref.read(bleProvider.notifier).sendPayload([0x02]); // Command: Turn OFF all LEDs
      } else {
        final List<int> payload = [0x01]; // Command: Turn ON
        
        // Add each selected hold to the payload using high-saturation pure colors
        state.selectedHolds.forEach((holdId, type) {
          payload.add(holdId);
          switch (type) {
            case HoldType.start:
              payload.addAll([0, 255, 0]); // Pure Green
              break;
            case HoldType.finish:
              payload.addAll([255, 0, 0]); // Pure Red
              break;
            case HoldType.foot:
              payload.addAll([255, 255, 0]); // Pure Yellow
              break;
            case HoldType.hand:
              payload.addAll([0, 0, 255]); // Pure Blue
              break;
          }
        });
        
        ref.read(bleProvider.notifier).sendPayload(payload);
      }
    }
  }
}

final editorProvider = NotifierProvider<EditorNotifier, EditorState>(EditorNotifier.new);
