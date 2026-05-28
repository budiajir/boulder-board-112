import 'package:flutter/material.dart';
import '../theme/app_typography.dart';

/// A colored badge showing the V-scale grade (e.g. "V3", "V5").
class GradeBadge extends StatelessWidget {
  const GradeBadge({
    super.key,
    required this.grade,
    this.size = GradeBadgeSize.medium,
  });

  final String grade;
  final GradeBadgeSize size;

  Color get _backgroundColor {
    final num = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num == 0) return const Color(0xFFE91E63); // Pink
    if (num <= 2) return const Color(0xFFFFFFFF); // White
    if (num <= 4) return const Color(0xFFFFEB3B); // Yellow
    if (num <= 6) return const Color(0xFF2196F3); // Blue
    if (num <= 8) return const Color(0xFF4CAF50); // Green
    if (num <= 10) return const Color(0xFFF44336); // Red
    return const Color(0xFF212121); // Black
  }

  Color get _textColor {
    final num = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num >= 1 && num <= 4) return Colors.black87; // Black text for White and Yellow
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize;
    final EdgeInsets padding;

    switch (size) {
      case GradeBadgeSize.small:
        fontSize = 12;
        padding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2);
        break;
      case GradeBadgeSize.medium:
        fontSize = 16;
        padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4);
        break;
      case GradeBadgeSize.large:
        fontSize = 20;
        padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 6);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        grade,
        style: AppTypography.gradeBadge.copyWith(
          fontSize: fontSize,
          color: _textColor,
        ),
      ),
    );
  }
}

enum GradeBadgeSize { small, medium, large }
