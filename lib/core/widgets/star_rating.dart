import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Interactive star rating widget.
/// Used in log entries and route detail.
class StarRating extends StatelessWidget {
  const StarRating({
    super.key,
    required this.rating,
    this.maxRating = 5,
    this.size = 20,
    this.onRatingChanged,
    this.color = AppColors.accentYellow,
    this.showValue = false,
  });

  final double rating;
  final int maxRating;
  final double size;
  final ValueChanged<double>? onRatingChanged;
  final Color color;
  final bool showValue;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(maxRating, (index) {
          final starValue = index + 1;
          final isFilled = starValue <= rating;
          final isHalf = starValue - 0.5 == rating;

          return GestureDetector(
            onTap: onRatingChanged != null
                ? () => onRatingChanged!(starValue.toDouble())
                : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 2),
              child: Icon(
                isHalf
                    ? Icons.star_half_rounded
                    : (isFilled
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded),
                color: isFilled || isHalf ? color : AppColors.textTertiary,
                size: size,
              ),
            ),
          );
        }),
        if (showValue) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size * 0.65,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
