import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Defines the functional type of a hold in a climbing route.
enum HoldType {
  start,
  hand,
  foot,
  finish;

  /// Display label for the hold type.
  String get label {
    switch (this) {
      case HoldType.start:
        return 'Start';
      case HoldType.hand:
        return 'Hand';
      case HoldType.foot:
        return 'Foot';
      case HoldType.finish:
        return 'Finish';
    }
  }

  /// Color associated with this hold type.
  Color get color {
    switch (this) {
      case HoldType.start:
        return AppColors.holdStart;
      case HoldType.hand:
        return AppColors.holdHand;
      case HoldType.foot:
        return AppColors.holdFoot;
      case HoldType.finish:
        return AppColors.holdFinish;
    }
  }

  /// Icon for the hold type (used in editor toolbar).
  IconData get icon {
    switch (this) {
      case HoldType.start:
        return Icons.play_circle_filled;
      case HoldType.hand:
        return Icons.circle;
      case HoldType.foot:
        return Icons.circle_outlined;
      case HoldType.finish:
        return Icons.stop_circle;
    }
  }

  /// Cycles to the next hold type. None → Hand → Start → Foot → Finish → None
  static HoldType? cycleNext(HoldType? current) {
    if (current == null) return HoldType.hand;
    switch (current) {
      case HoldType.hand:
        return HoldType.start;
      case HoldType.start:
        return HoldType.foot;
      case HoldType.foot:
        return HoldType.finish;
      case HoldType.finish:
        return null; // back to none
    }
  }
}
