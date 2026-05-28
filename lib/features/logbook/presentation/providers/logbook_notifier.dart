import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/providers/auth_notifier.dart';
import '../../data/models/log_entry.dart';
import '../../data/repositories/logbook_repository.dart';

class LogbookState {
  const LogbookState({
    this.entries = const [],
    this.isLoading = false,
  });

  final List<LogEntry> entries;
  final bool isLoading;

  int get totalSends => entries.where((e) => e.isSent).length;
  int get totalAttempts => entries.fold(0, (sum, e) => sum + e.attempts);

  int get thisMonthSends {
    final now = DateTime.now();
    return entries.where((e) => e.isSent && e.date.year == now.year && e.date.month == now.month).length;
  }

  double get averageGrade {
    final sent = entries.where((e) => e.isSent).toList();
    if (sent.isEmpty) return 0;
    final total = sent.fold<int>(0, (sum, e) {
      final num = int.tryParse(e.routeGrade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
      return sum + num;
    });
    return total / sent.length;
  }

  Map<String, int> get gradeDistribution {
    final dist = <String, int>{};
    for (final entry in entries.where((e) => e.isSent)) {
      dist[entry.routeGrade] = (dist[entry.routeGrade] ?? 0) + 1;
    }
    final sorted = Map.fromEntries(
      dist.entries.toList()
        ..sort((a, b) {
          final aNum = int.tryParse(a.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final bNum = int.tryParse(b.key.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return aNum.compareTo(bNum);
        }),
    );
    return sorted;
  }

  LogbookState copyWith({
    List<LogEntry>? entries,
    bool? isLoading,
  }) {
    return LogbookState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class LogbookNotifier extends AsyncNotifier<LogbookState> {
  @override
  Future<LogbookState> build() async {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    if (user == null) return const LogbookState(entries: [], isLoading: false);

    final repo = LogbookRepository();
    final entries = await repo.getUserLogs(user.id);
    return LogbookState(entries: entries, isLoading: false);
  }

  Future<void> addEntry(LogEntry entry) async {
    final authState = ref.read(authProvider);
    final user = authState.user;
    if (user == null || !state.hasValue) return;
    
    try {
      final repo = LogbookRepository();
      final newLog = await repo.addLog(entry, user.id);
      
      final current = state.value!;
      final updated = List<LogEntry>.from(current.entries)..insert(0, newLog);
      state = AsyncData(current.copyWith(entries: updated));
    } catch (e) {
      // Typically show error via UI, throwing for now
      rethrow;
    }
  }

  Future<void> removeEntry(String entryId) async {
    if (!state.hasValue) return;
    try {
      final repo = LogbookRepository();
      await repo.deleteLog(entryId);
      
      final current = state.value!;
      final updated = List<LogEntry>.from(current.entries)..removeWhere((e) => e.id == entryId);
      state = AsyncData(current.copyWith(entries: updated));
    } catch (e) {
      rethrow;
    }
  }
}

final logbookProvider = AsyncNotifierProvider<LogbookNotifier, LogbookState>(LogbookNotifier.new);
