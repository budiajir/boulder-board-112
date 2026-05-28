import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/hold_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/board_config.dart';
import '../../discovery/data/models/climbing_route_model.dart';

/// CustomPainter that renders the climbing board grid.
/// This is the core rendering engine of the app.
class ClimbingBoardPainter extends CustomPainter {
  ClimbingBoardPainter({
    required this.boardConfig,
    this.activeRoute,
    this.selectedHolds = const {},
    this.highlightedHoldId,
    this.glowPhase = 0.0,
  });

  final BoardConfig boardConfig;
  final ClimbingRouteModel? activeRoute;
  final Map<int, HoldType> selectedHolds; // For editor mode
  final int? highlightedHoldId;
  final double glowPhase; // 0.0–1.0 for glow animation

  static const double labelWidth = 28.0;
  static const double labelHeight = 24.0;

  @override
  void paint(Canvas canvas, Size size) {
    final usableWidth = size.width - labelWidth;
    final usableHeight = size.height - labelHeight;

    final cellWidth = usableWidth / boardConfig.columns;
    final cellHeight = usableHeight / boardConfig.rows;
    final holdRadius = min(cellWidth, cellHeight) * 0.32;

    _drawGridLines(canvas, size, cellWidth, cellHeight);
    _drawLabels(canvas, size, cellWidth, cellHeight);
    _drawHolds(canvas, cellWidth, cellHeight, holdRadius);
  }

  void _drawGridLines(
      Canvas canvas, Size size, double cellW, double cellH) {
    final paint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    final gridHeight = size.height - labelHeight;

    // Vertical lines
    for (int col = 0; col <= boardConfig.columns; col++) {
      final x = col * cellW + labelWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, gridHeight), paint);
    }

    // Horizontal lines
    for (int row = 0; row <= boardConfig.rows; row++) {
      final y = row * cellH;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), paint);
    }
  }

  void _drawLabels(
      Canvas canvas, Size size, double cellW, double cellH) {
    final textStyle = TextStyle(
      color: AppColors.textTertiary.withValues(alpha: 0.7),
      fontSize: min(cellW, cellH) * 0.28,
      fontWeight: FontWeight.w600,
    );

    final gridHeight = size.height - labelHeight;

    // Column labels (A, B, C...) at the bottom
    for (int col = 0; col < boardConfig.columns; col++) {
      final label = String.fromCharCode(65 + col);
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          col * cellW + labelWidth + (cellW - textPainter.width) / 2,
          gridHeight + (labelHeight - textPainter.height) / 2,
        ),
      );
    }

    // Row labels (1, 2, 3... 18) on the left margin
    for (int row = 0; row < boardConfig.rows; row++) {
      final label = '${row + 1}';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle,
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(
          (labelWidth - textPainter.width) / 2,
          (boardConfig.rows - 1 - row) * cellH + (cellH - textPainter.height) / 2,
        ),
      );
    }
  }

  void _drawHolds(
      Canvas canvas, double cellW, double cellH, double radius) {
    // Build lookup for active route holds
    final Map<int, HoldType> activeHoldMap = {};
    if (activeRoute != null) {
      for (final hold in activeRoute!.holds) {
        // Find the matching hold type string from enum
        final type = HoldType.values.firstWhere(
          (t) => t.name == hold.holdType,
          orElse: () => HoldType.hand,
        );
        // Calculate holdId based on x, y and boardConfig logic
        // Assuming id = row * columns + col
        final holdId = hold.ledIndex ?? (hold.y * boardConfig.columns + hold.x);
        activeHoldMap[holdId] = type;
      }
    }

    // Merge with selected holds (editor mode takes priority)
    final Map<int, HoldType> mergedHolds = {
      ...activeHoldMap,
      ...selectedHolds,
    };

    for (final hold in boardConfig.holds) {
      final cx = hold.col * cellW + labelWidth + cellW / 2;
      // Invert Y so row 0 (bottom of board) is at the bottom
      final cy = (boardConfig.rows - 1 - hold.row) * cellH + cellH / 2;
      final center = Offset(cx, cy);

      final holdType = mergedHolds[hold.id];
      final isActive = holdType != null;
      final isHighlighted = hold.id == highlightedHoldId;

      if (isActive) {
        _drawActiveHold(canvas, center, radius, holdType, isHighlighted);
      } else {
        _drawInactiveHold(canvas, center, radius);
      }
    }
  }

  void _drawActiveHold(
    Canvas canvas,
    Offset center,
    double radius,
    HoldType type,
    bool isHighlighted,
  ) {
    final color = type.color;
    final glowRadius = radius * (1.0 + glowPhase * 0.3);

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2 + glowPhase * 0.15)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.8);
    canvas.drawCircle(center, glowRadius * 1.3, glowPaint);

    // Main circle
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Foot holds draw as rings (unfilled), others as filled
    if (type == HoldType.foot) {
      mainPaint.style = PaintingStyle.stroke;
      mainPaint.strokeWidth = radius * 0.25;
      canvas.drawCircle(center, radius * 0.85, mainPaint);
    } else if (type == HoldType.finish) {
      // Finish: double circle
      canvas.drawCircle(center, radius, mainPaint);
      final innerPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.55, innerPaint);
      final innerRing = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius * 0.4, innerRing);
    } else if (type == HoldType.start) {
      // Start: filled with a subtle "play" indicator
      canvas.drawCircle(center, radius, mainPaint);
      // Small inner arrow
      final arrowPaint = Paint()
        ..color = AppColors.surface
        ..style = PaintingStyle.fill;
      final path = Path();
      path.moveTo(center.dx - radius * 0.2, center.dy - radius * 0.3);
      path.lineTo(center.dx + radius * 0.35, center.dy);
      path.lineTo(center.dx - radius * 0.2, center.dy + radius * 0.3);
      path.close();
      canvas.drawPath(path, arrowPaint);
    } else {
      // Hand hold: simple filled circle
      canvas.drawCircle(center, radius, mainPaint);
    }

    // Highlight ring (when tapped)
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 4, highlightPaint);
    }
  }

  void _drawInactiveHold(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = AppColors.holdInactive.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, paint);
  }

  @override
  bool shouldRepaint(covariant ClimbingBoardPainter oldDelegate) {
    return oldDelegate.activeRoute != activeRoute ||
        oldDelegate.selectedHolds != selectedHolds ||
        oldDelegate.highlightedHoldId != highlightedHoldId ||
        oldDelegate.glowPhase != glowPhase;
  }
}
