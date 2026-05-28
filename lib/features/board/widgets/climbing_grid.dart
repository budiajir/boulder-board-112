import 'package:flutter/material.dart';
import '../../../core/constants/hold_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/board_config.dart';
import '../../discovery/data/models/climbing_route_model.dart';
import 'climbing_board_painter.dart';

/// Interactive climbing board grid widget.
/// Supports zoom, pan, and tap-to-select holds.
class ClimbingGrid extends StatefulWidget {
  const ClimbingGrid({
    super.key,
    required this.boardConfig,
    this.activeRoute,
    this.selectedHolds = const {},
    this.isEditable = false,
    this.onHoldTapped,
    this.showLabels = true,
    this.isLocked = false,
  });

  /// The board layout configuration.
  final BoardConfig boardConfig;

  /// Currently displayed route (null = no route).
  final ClimbingRouteModel? activeRoute;

  /// Holds selected in editor mode.
  final Map<int, HoldType> selectedHolds;

  /// Whether holds can be tapped to select/deselect.
  final bool isEditable;

  /// Callback when a hold is tapped. Returns (holdId, col, row).
  final void Function(int holdId, int col, int row)? onHoldTapped;

  /// Whether to show column/row labels.
  final bool showLabels;

  /// Whether the grid is locked (no zoom/pan, full-bleed to fill container).
  final bool isLocked;

  @override
  State<ClimbingGrid> createState() => _ClimbingGridState();
}

class _ClimbingGridState extends State<ClimbingGrid>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  int? _highlightedHoldId;
  final TransformationController _transformController =
      TransformationController();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size gridSize) {
    final localPos = details.localPosition; // Already in child coordinates

    const double labelWidth = 28.0;
    const double labelHeight = 24.0;
    
    final usableWidth = gridSize.width - labelWidth;
    final usableHeight = gridSize.height - labelHeight;

    final cellWidth = usableWidth / widget.boardConfig.columns;
    final cellHeight = usableHeight / widget.boardConfig.rows;

    final adjustedX = localPos.dx - labelWidth;
    final col = (adjustedX / cellWidth).floor();
    final row =
        widget.boardConfig.rows - 1 - (localPos.dy / cellHeight).floor();

    if (col >= 0 &&
        col < widget.boardConfig.columns &&
        row >= 0 &&
        row < widget.boardConfig.rows) {
      final hold = widget.boardConfig.holdAt(col, row);
      if (hold != null) {
        setState(() => _highlightedHoldId = hold.id);
        widget.onHoldTapped?.call(hold.id, col, row);

        // Clear highlight after a short delay
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) setState(() => _highlightedHoldId = null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (widget.isLocked) {
              // Full-bleed static mode: stretch to fill container, no zooming/panning
              return Builder(
                builder: (innerContext) {
                  return GestureDetector(
                    onTapUp: (details) {
                      final size = innerContext.size;
                      if (size != null) {
                        _handleTap(details, size);
                      }
                    },
                    child: AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        // Use natural grid ratio to draw perfectly proportioned square cells
                        final gridAspectRatio = widget.boardConfig.columns / widget.boardConfig.rows;

                        return AspectRatio(
                          aspectRatio: gridAspectRatio,
                          child: CustomPaint(
                            painter: ClimbingBoardPainter(
                              boardConfig: widget.boardConfig,
                              activeRoute: widget.activeRoute,
                              selectedHolds: widget.selectedHolds,
                              highlightedHoldId: _highlightedHoldId,
                              glowPhase: _glowController.value,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            }

            // The physical board has a horizontal spacing of 20cm and vertical spacing of 10cm (2:1 ratio).
            // We scale the columns and rows accordingly to match the physical aspect ratio perfectly.
            final aspectRatio = (widget.boardConfig.columns * 20) / (widget.boardConfig.rows * 10);

            return InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 4.0,
              boundaryMargin: const EdgeInsets.all(40),
              child: Center(
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Builder(
                    builder: (innerContext) {
                      return GestureDetector(
                        onTapUp: (details) {
                          final size = innerContext.size;
                          if (size != null) {
                            _handleTap(details, size);
                          }
                        },
                        child: AnimatedBuilder(
                          animation: _glowController,
                          builder: (context, _) {
                            return CustomPaint(
                              // Size will be automatically constrained by AspectRatio
                              painter: ClimbingBoardPainter(
                                boardConfig: widget.boardConfig,
                                activeRoute: widget.activeRoute,
                                selectedHolds: widget.selectedHolds,
                                highlightedHoldId: _highlightedHoldId,
                                glowPhase: _glowController.value,
                              ),
                            );
                          },
                        ),
                      );
                    }
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
