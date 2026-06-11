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

  Gradient get _gradient {
    final num = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num == 0) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEC4899), Color(0xFFBE185D)], // Pink / Rose
      );
    }
    if (num <= 2) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF9FAFB), Color(0xFFE5E7EB)], // Cool White / Pearl
      );
    }
    if (num <= 4) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFBBF24), Color(0xFFD97706)], // Warm Gold / Amber
      );
    }
    if (num <= 6) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF60A5FA), Color(0xFF2563EB)], // Vibrant Blue
      );
    }
    if (num <= 8) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF34D399), Color(0xFF059669)], // Emerald Green
      );
    }
    if (num <= 10) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEF4444), Color(0xFFB91C1C)], // Crimson Red
      );
    }
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF374151), Color(0xFF111827)], // Dark Onyx
    );
  }

  Color get _textColor {
    final num = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num >= 1 && num <= 4) return Colors.black87; // Dark text for light backgrounds
    return Colors.white;
  }

  Color get _borderColor {
    final num = int.tryParse(grade.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    if (num >= 1 && num <= 4) return Colors.black12;
    return Colors.white10;
  }

  @override
  Widget build(BuildContext context) {
    final double fontSize;
    final EdgeInsets padding;

    switch (size) {
      case GradeBadgeSize.small:
        fontSize = 11;
        padding = const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5);
        break;
      case GradeBadgeSize.medium:
        fontSize = 15;
        padding = const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5);
        break;
      case GradeBadgeSize.large:
        fontSize = 19;
        padding = const EdgeInsets.symmetric(horizontal: 15, vertical: 6.5);
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        grade,
        style: AppTypography.gradeBadge.copyWith(
          fontSize: fontSize,
          color: _textColor,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

enum GradeBadgeSize { small, medium, large }
