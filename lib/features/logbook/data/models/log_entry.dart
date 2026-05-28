/// A log entry recording a climbing attempt or send (Supabase mapped).
class LogEntry {
  const LogEntry({
    required this.id,
    required this.routeId,
    this.routeName = 'Unknown Route',
    this.routeGrade = 'V?',
    required this.date,
    this.isSent = false,
    this.attempts = 1,
    this.rating = 0.0,
    this.notes = '',
  });

  final String id;
  final String routeId;
  final String routeName;
  final String routeGrade;
  final DateTime date;
  final bool isSent;
  final int attempts;
  final double rating; // 0.0-5.0 star rating
  final String notes;

  LogEntry copyWith({
    String? id,
    String? routeId,
    String? routeName,
    String? routeGrade,
    DateTime? date,
    bool? isSent,
    int? attempts,
    double? rating,
    String? notes,
  }) {
    return LogEntry(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      routeName: routeName ?? this.routeName,
      routeGrade: routeGrade ?? this.routeGrade,
      date: date ?? this.date,
      isSent: isSent ?? this.isSent,
      attempts: attempts ?? this.attempts,
      rating: rating ?? this.rating,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'route_id': routeId,
        'is_sent': isSent,
        'attempts': attempts,
        'rating': rating,
        'notes': notes,
      };

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    // In Supabase we join climbing_routes to get name and grade
    final route = json['climbing_routes'] as Map<String, dynamic>?;
    
    return LogEntry(
      id: json['id'] as String,
      routeId: json['route_id'] as String,
      routeName: route?['name'] as String? ?? 'Unknown Route',
      routeGrade: route?['grade'] as String? ?? 'V?',
      date: DateTime.parse(json['climbed_at'] as String? ?? json['created_at'] as String),
      isSent: json['is_sent'] as bool? ?? false,
      attempts: json['attempts'] as int? ?? 1,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
    );
  }
}
