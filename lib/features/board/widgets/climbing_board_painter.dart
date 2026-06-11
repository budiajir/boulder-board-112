import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/hold_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/board_config.dart';
import '../../discovery/data/models/climbing_route_model.dart';

/// CustomPainter that renders a highly realistic 3D climbing board.
/// Features a wooden plywood grain background, metallic screw marks,
/// realistic 3D metallic T-Nut bolt holes, textured colored resin holds,
/// and neon-like glowing radial LED rings.
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

    _drawWoodPanelBackground(canvas, size);
    _drawGridLines(canvas, size, cellWidth, cellHeight);
    _drawLabels(canvas, size, cellWidth, cellHeight);
    _drawHolds(canvas, cellWidth, cellHeight, holdRadius);
  }

  void _drawWoodPanelBackground(Canvas canvas, Size size) {
    final usableWidth = size.width - labelWidth;
    final usableHeight = size.height - labelHeight;
    final rect = Rect.fromLTWH(labelWidth, 0, usableWidth, usableHeight);

    // 1. Draw solid dark background for the margin gutters first
    final gutterPaint = Paint()..color = AppColors.surface;
    canvas.drawRect(Rect.fromLTWH(0, 0, labelWidth, size.height), gutterPaint);
    canvas.drawRect(Rect.fromLTWH(labelWidth, usableHeight, usableWidth, labelHeight), gutterPaint);

    // 2. Base wood gradient (natural varnished birch plywood tone)
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFEEDBB2), // Warm light maple/birch
          Color(0xFFD8B986), // Warm medium wood tone
          Color(0xFFC4A470), // Slightly darker grain tone
        ],
      ).createShader(rect);
    canvas.drawRect(rect, basePaint);

    // 3. Draw horizontal plywood sheet seams (3 panels stacked horizontally)
    final seamPaint = Paint()
      ..color = const Color(0xFF6E5331).withValues(alpha: 0.4)
      ..strokeWidth = 1.8;
    
    // Divide the board into 3 horizontal panels (representing the 3 plywood sheets)
    final panelHeight = usableHeight / 3;
    canvas.drawLine(Offset(labelWidth, panelHeight), Offset(size.width, panelHeight), seamPaint);
    canvas.drawLine(Offset(labelWidth, panelHeight * 2), Offset(size.width, panelHeight * 2), seamPaint);

    // 4. Subtle natural wood grain lines (curved waves per panel sheet)
    final grainPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = const Color(0xFF8B6C3F).withValues(alpha: 0.08)
      ..strokeWidth = 1.2;

    final rand = Random(42); // Seeded random for consistent grain pattern
    for (int i = 0; i < 9; i++) {
      final path = Path();
      // Draw grains horizontally across the panels
      final startY = rand.nextDouble() * usableHeight;
      path.moveTo(labelWidth, startY);
      path.cubicTo(
        labelWidth + usableWidth * 0.25,
        startY + (rand.nextDouble() - 0.5) * 50,
        labelWidth + usableWidth * 0.75,
        startY + (rand.nextDouble() - 0.5) * 50,
        labelWidth + usableWidth,
        rand.nextDouble() * usableHeight,
      );
      canvas.drawPath(path, grainPaint);
    }

    // 5. Panel screw marks (small metal screw holes along the top, bottom, and seams)
    final screwPaint = Paint()
      ..color = const Color(0xFF5A4428).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    
    // Screws are fastened along the horizontal borders of each sheet
    final panelEdgesY = [4.0, panelHeight, panelHeight * 2, usableHeight - 4.0];
    for (final y in panelEdgesY) {
      for (double x = labelWidth + 20; x < size.width; x += usableWidth / 8) {
        // Offset screws slightly to look organic/hand-installed
        final screwY = y + (y == 4.0 ? 4 : (y == usableHeight - 4.0 ? -4 : (rand.nextBool() ? 5 : -5)));
        final screwX = x + (rand.nextDouble() - 0.5) * 10;
        canvas.drawCircle(Offset(screwX, screwY), 2.0, screwPaint);
      }
    }

    // 6. Draw clean border edge shadow on the wood panels
    final edgeShadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(rect, edgeShadowPaint);
  }

  void _drawGridLines(
      Canvas canvas, Size size, double cellW, double cellH) {
    // Laser-engraved style lines (thin, dark brown, low opacity)
    final paint = Paint()
      ..color = const Color(0xFF5A4428).withValues(alpha: 0.15)
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
      color: AppColors.textSecondary.withValues(alpha: 0.8),
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
        final type = HoldType.values.firstWhere(
          (t) => t.name == hold.holdType,
          orElse: () => HoldType.hand,
        );
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
    final glowRadius = radius * (1.0 + glowPhase * 0.2);

    // 1. Drop shadow of the physical climbing hold on the wooden board
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.35);
    canvas.drawCircle(center + const Offset(2.0, 3.0), radius * 0.85, shadowPaint);

    // 2. Realistic glowing LED light ring around/behind the hold (like a Kilter board)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.7 + glowPhase * 0.2), // Bright core
          color.withValues(alpha: 0.3 * (1.0 - glowPhase * 0.2)),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.5));
    canvas.drawCircle(center, radius * 1.5, glowPaint);

    // Physical neon-like bright border ring
    final ledRingPaint = Paint()
      ..color = color.withValues(alpha: 0.95)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.16;
    canvas.drawCircle(center, radius * 1.05, ledRingPaint);

    // 3. The climbing hold body itself (3D shaded colored resin look)
    final holdRect = Rect.fromCircle(center: center, radius: radius * 0.85);
    final holdShader = RadialGradient(
      center: const Alignment(-0.35, -0.35),
      colors: [
        Colors.white.withValues(alpha: 0.35), // Shiny highlight
        color,                               // Main color
        _darkenColor(color, 0.4),            // Shaded edge
      ],
      stops: const [0.0, 0.5, 1.0],
    ).createShader(holdRect);

    final holdPaint = Paint()
      ..shader = holdShader
      ..style = PaintingStyle.fill;

    // Render holds with distinct premium shapes per type
    if (type == HoldType.foot) {
      // Small round foothold button
      final footRect = Rect.fromCircle(center: center, radius: radius * 0.55);
      final footShader = RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [
          Colors.white.withValues(alpha: 0.35),
          color,
          _darkenColor(color, 0.45),
        ],
      ).createShader(footRect);
      final footPaint = Paint()..shader = footShader;
      canvas.drawCircle(center, radius * 0.55, footPaint);
    } else if (type == HoldType.finish) {
      // Octagonal Finish Hold
      final path = Path();
      final r = radius * 0.85;
      for (int i = 0; i < 8; i++) {
        final angle = i * pi / 4 + pi / 8;
        final x = center.dx + r * cos(angle);
        final y = center.dy + r * sin(angle);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, holdPaint);
    } else if (type == HoldType.start) {
      // Triangular Start Hold
      final path = Path();
      final r = radius * 0.9;
      path.moveTo(center.dx, center.dy - r);
      path.lineTo(center.dx + r * 0.86, center.dy + r * 0.5);
      path.lineTo(center.dx - r * 0.86, center.dy + r * 0.5);
      path.close();
      canvas.drawPath(path, holdPaint);
    } else {
      // Organic Asymmetric Hexagonal Hand Hold
      final path = Path();
      final r = radius * 0.82;
      final vertexOffsets = [
        Offset(0, -r),
        Offset(r * 0.75, -r * 0.35),
        Offset(r * 0.85, r * 0.45),
        Offset(0, r * 0.75),
        Offset(-r * 0.8, r * 0.55),
        Offset(-r * 0.65, -r * 0.45),
      ];
      for (int i = 0; i < vertexOffsets.length; i++) {
        final pt = center + vertexOffsets[i];
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, holdPaint);
    }

    // 4. Central Allen Bolt (Screw in the center of the hold)
    final boltHolePaint = Paint()
      ..color = const Color(0xFF2C3E50)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.22, boltHolePaint);

    final boltScrewPaint = Paint()
      ..color = const Color(0xFF7F8C8D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.14, boltScrewPaint);
    
    final boltInnerHolePaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.08, boltInnerHolePaint);

    // Highlight ring (when tapped in editor)
    if (isHighlighted) {
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawCircle(center, radius * 1.2, highlightPaint);
    }
  }

  void _drawInactiveHold(Canvas canvas, Offset center, double radius) {
    // Realistic metal T-Nut hole in the wooden panel
    final outerRingPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8C9899), // Shiny metal edge
          const Color(0xFF3B484A), // Dark oxidized metal cavity
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.45));
    canvas.drawCircle(center, radius * 0.42, outerRingPaint);

    // Inner bolt thread hole
    final innerHolePaint = Paint()
      ..color = const Color(0xFF1A1F21)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.2, innerHolePaint);

    // metallic specular highlight arc on the top-left
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.33),
      -pi * 0.75, // top-left arc
      pi * 0.5,
      false,
      highlightPaint,
    );
  }

  Color _darkenColor(Color color, double factor) {
    assert(factor >= 0 && factor <= 1);
    return Color.fromARGB(
      color.alpha,
      (color.red * (1.0 - factor)).round(),
      (color.green * (1.0 - factor)).round(),
      (color.blue * (1.0 - factor)).round(),
    );
  }

  @override
  bool shouldRepaint(covariant ClimbingBoardPainter oldDelegate) {
    return oldDelegate.activeRoute != activeRoute ||
        oldDelegate.selectedHolds != selectedHolds ||
        oldDelegate.highlightedHoldId != highlightedHoldId ||
        oldDelegate.glowPhase != glowPhase;
  }
}
