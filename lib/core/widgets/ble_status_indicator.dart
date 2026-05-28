import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Small dot indicator showing BLE connection status.
class BleStatusIndicator extends StatefulWidget {
  const BleStatusIndicator({
    super.key,
    required this.isConnected,
    this.size = 10,
    this.showLabel = false,
  });

  final bool isConnected;
  final double size;
  final bool showLabel;

  @override
  State<BleStatusIndicator> createState() => _BleStatusIndicatorState();
}

class _BleStatusIndicatorState extends State<BleStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isConnected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BleStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isConnected && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isConnected) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color =
        widget.isConnected ? AppColors.accentGreen : AppColors.accentRed;
    final label = widget.isConnected ? 'Connected' : 'Disconnected';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: widget.isConnected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: widget.size * _pulseAnimation.value,
                          spreadRadius: widget.size * 0.2,
                        ),
                      ]
                    : null,
              ),
            );
          },
        ),
        if (widget.showLabel) ...[
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
