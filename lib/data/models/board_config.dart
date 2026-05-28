/// Configuration for a climbing board layout.
/// Defines the grid dimensions and all possible hold positions.
class BoardConfig {
  const BoardConfig({
    required this.id,
    required this.name,
    required this.columns,
    required this.rows,
    required this.holds,
  });

  /// Unique identifier for this board layout.
  final String id;

  /// Display name (e.g. "Standard 11×18").
  final String name;

  /// Number of columns in the grid.
  final int columns;

  /// Number of rows in the grid.
  final int rows;

  /// All hold positions on this board.
  final List<HoldPosition> holds;

  /// Creates a default 11×18 board with holds at every position.
  factory BoardConfig.standard() {
    final holds = <HoldPosition>[];
    int idCounter = 0;
    for (int row = 0; row < 18; row++) {
      for (int col = 0; col < 11; col++) {
        holds.add(HoldPosition(
          id: idCounter++,
          col: col,
          row: row,
          label: '${String.fromCharCode(65 + col)}${row + 1}',
        ));
      }
    }
    return BoardConfig(
      id: 'standard_11x18',
      name: 'Standard 11×18',
      columns: 11,
      rows: 18,
      holds: holds,
    );
  }

  /// Find a hold by grid coordinate.
  HoldPosition? holdAt(int col, int row) {
    try {
      return holds.firstWhere((h) => h.col == col && h.row == row);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'columns': columns,
        'rows': rows,
        'holds': holds.map((h) => h.toJson()).toList(),
      };

  factory BoardConfig.fromJson(Map<String, dynamic> json) => BoardConfig(
        id: json['id'] as String,
        name: json['name'] as String,
        columns: json['columns'] as int,
        rows: json['rows'] as int,
        holds: (json['holds'] as List)
            .map((h) => HoldPosition.fromJson(h))
            .toList(),
      );
}

/// A single hold position on the physical board.
class HoldPosition {
  const HoldPosition({
    required this.id,
    required this.col,
    required this.row,
    required this.label,
  });

  /// Unique ID mapping to the physical LED.
  final int id;

  /// Column position (0-based).
  final int col;

  /// Row position (0-based, 0 = bottom).
  final int row;

  /// Human-readable label (e.g. "A1", "K18").
  final String label;

  Map<String, dynamic> toJson() => {
        'id': id,
        'col': col,
        'row': row,
        'label': label,
      };

  factory HoldPosition.fromJson(Map<String, dynamic> json) => HoldPosition(
        id: json['id'] as int,
        col: json['col'] as int,
        row: json['row'] as int,
        label: json['label'] as String,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HoldPosition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
