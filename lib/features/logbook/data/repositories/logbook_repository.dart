import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/log_entry.dart';

class LogbookRepository {
  LogbookRepository({SupabaseClient? client})
      : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;
  static const _logsTable = 'user_climb_logs';

  /// Get all logs for a specific user, joining with climbing_routes
  Future<List<LogEntry>> getUserLogs(String userId) async {
    final response = await _client
        .from(_logsTable)
        .select('*, climbing_routes(name, grade)')
        .eq('user_id', userId)
        .order('climbed_at', ascending: false);

    return (response as List).map((row) {
      if (row is Map) {
        return LogEntry.fromJson(Map<String, dynamic>.from(row));
      }
      throw Exception('Row is not a Map: $row');
    }).toList();
  }

  /// Add a new log entry
  Future<LogEntry> addLog(LogEntry log, String userId) async {
    final Map<String, dynamic> data = log.toJson();
    data['user_id'] = userId;
    
    final response = await _client
        .from(_logsTable)
        .insert(data)
        .select('*, climbing_routes(name, grade)')
        .single();
        
    return LogEntry.fromJson(response);
  }

  /// Delete a log entry
  Future<void> deleteLog(String logId) async {
    await _client.from(_logsTable).delete().eq('id', logId);
  }
}
