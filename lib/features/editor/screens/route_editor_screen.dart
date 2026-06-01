import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/hold_types.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/board_config.dart';
import '../../board/widgets/climbing_grid.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import '../../ble/screens/ble_setup_screen.dart';
import '../../discovery/presentation/providers/route_list_notifier.dart';
import '../presentation/providers/editor_notifier.dart';
import '../../../core/widgets/ble_status_indicator.dart';
import '../../profile/presentation/providers/drafts_notifier.dart';

/// Route editor screen for creating new climbing routes.
class RouteEditorScreen extends ConsumerWidget {
  const RouteEditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, ref),
              Expanded(child: _buildGrid(context, ref)),
              _buildHoldTypeSelector(context, ref),
              _buildHoldCounter(context, ref),
              _buildActions(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, WidgetRef ref) {
    final bleState = ref.watch(bleProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text('New Route', style: AppTypography.title),
          const Spacer(),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BleSetupScreen()),
              );
            },
            child: BleStatusIndicator(
              isConnected: bleState.isConnected,
              showLabel: true,
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: () {
              ref.read(editorProvider.notifier).clear();
            },
            child: Text('Clear', style: AppTypography.body.copyWith(
              color: AppColors.accentRed,
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: ClimbingGrid(
        boardConfig: BoardConfig.standard(),
        selectedHolds: editorState.selectedHolds,
        isEditable: true,
        isLocked: true,
        onHoldTapped: (holdId, col, row) {
          HapticFeedback.selectionClick();
          ref.read(editorProvider.notifier).toggleHold(holdId);
        },
      ),
    );
  }

  Widget _buildHoldTypeSelector(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Hold Mode', style: AppTypography.label),
          const SizedBox(height: 8),
          Row(
            children: HoldType.values.map((type) {
              final isActive = editorState.activeHoldType == type;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => ref.read(editorProvider.notifier).setActiveHoldType(type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isActive
                            ? type.color.withValues(alpha: 0.2)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive ? type.color : AppColors.border,
                          width: isActive ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: type == HoldType.foot
                                  ? Colors.transparent
                                  : type.color,
                              border: Border.all(color: type.color, width: 2),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            type.label,
                            style: AppTypography.label.copyWith(
                              color: isActive ? type.color : AppColors.textSecondary,
                              fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildHoldCounter(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Text('Holds: ', style: AppTypography.bodySmall),
          _countChip('🟢', editorState.startCount, AppColors.holdStart),
          const SizedBox(width: 8),
          _countChip('🔵', editorState.handCount, AppColors.holdHand),
          const SizedBox(width: 8),
          _countChip('🟠', editorState.footCount, AppColors.holdFoot),
          const SizedBox(width: 8),
          _countChip('🔴', editorState.finishCount, AppColors.holdFinish),
          const Spacer(),
          Text(
            'Total: ${editorState.totalHolds}',
            style: AppTypography.label.copyWith(color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _countChip(String emoji, int count, Color color) {
    return Text(
      '$emoji×$count',
      style: AppTypography.label.copyWith(fontSize: 13),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        children: [
          // Preview Light Up
          Expanded(
            child: SizedBox(
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentLime),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  final editorState = ref.read(editorProvider);
                  final bleState = ref.read(bleProvider);
                  
                  if (bleState.isConnected) {
                    if (editorState.totalHolds == 0) {
                      ref.read(bleProvider.notifier).sendPayload([0x02]); // Turn off
                      return;
                    }
                    
                    final List<int> payload = [0x01]; // Command: Turn ON
                    
                    // Add each selected hold to the payload using high-saturation pure colors
                    editorState.selectedHolds.forEach((holdId, type) {
                      payload.add(holdId);
                      switch (type) {
                        case HoldType.start:
                          payload.addAll([0, 255, 0]); // Pure Green
                          break;
                        case HoldType.finish:
                          payload.addAll([255, 0, 0]); // Pure Red
                          break;
                        case HoldType.foot:
                          payload.addAll([255, 255, 0]); // Pure Yellow
                          break;
                        case HoldType.hand:
                          payload.addAll([0, 0, 255]); // Pure Blue
                          break;
                      }
                    });
                    
                    ref.read(bleProvider.notifier).sendPayload(payload);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Not connected to BLE board'),
                        backgroundColor: AppColors.surfaceElevated,
                        action: SnackBarAction(
                          label: 'Connect',
                          textColor: AppColors.accentPrimary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BleSetupScreen()),
                            );
                          },
                        ),
                      ),
                    );
                  }
                  HapticFeedback.mediumImpact();
                },
                icon: const Icon(Icons.lightbulb_outline,
                    size: 18, color: AppColors.accentLime),
                label: Text('Preview',
                    style: AppTypography.button
                        .copyWith(color: AppColors.accentLime)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Save
          Expanded(
            child: SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                onPressed: () => _showSaveSheet(context, ref),
                icon: const Icon(Icons.save, size: 18),
                label: Text('Save', style: AppTypography.button),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveSheet(BuildContext context, WidgetRef ref) {
    final editorState = ref.read(editorProvider);
    final nameController = TextEditingController(text: editorState.routeName);
    final descController = TextEditingController(text: editorState.routeDescription);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, sheetRef, _) {
            final currentState = sheetRef.watch(editorProvider);
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 8, 24, MediaQuery.of(ctx).viewInsets.bottom + 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Save Route', style: AppTypography.headline),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
                      hintText: 'e.g. The Crux',
                    ),
                    onChanged: (v) => ref.read(editorProvider.notifier).setRouteName(v),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: currentState.routeGrade,
                          decoration: const InputDecoration(
                            labelText: 'Grade',
                          ),
                          items: List.generate(
                              18,
                              (i) => DropdownMenuItem(
                                    value: 'V$i',
                                    child: Text('V$i'),
                                  )),
                          onChanged: (v) {
                            if (v != null) ref.read(editorProvider.notifier).setRouteGrade(v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: currentState.routeAngle,
                          decoration: const InputDecoration(
                            labelText: 'Angle',
                          ),
                          items: [0, 15, 25, 30, 35, 40, 45, 50]
                              .map((a) => DropdownMenuItem(
                                    value: a,
                                    child: Text('$a°'),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) ref.read(editorProvider.notifier).setRouteAngle(v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    style: AppTypography.body,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional beta or notes...',
                    ),
                    maxLines: 2,
                    onChanged: (v) => ref.read(editorProvider.notifier).setRouteDescription(v),
                  ),
                  const SizedBox(height: 20),
                  // Publish
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        ref.read(editorProvider.notifier).setRouteName(nameController.text);
                        ref.read(editorProvider.notifier).setRouteDescription(descController.text);
                        
                        try {
                          await ref.read(editorProvider.notifier).saveRoute();
                          ref.read(editorProvider.notifier).clear();
                          ref.read(routeListProvider.notifier).refresh(); // Refresh discover list
                          Navigator.pop(ctx);
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('📤 Route published to Supabase!'),
                              backgroundColor: AppColors.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.toString()),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text('📤 Publish Route',
                          style: AppTypography.button),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Draft
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () async {
                        final editorState = ref.read(editorProvider);
                        ref.read(editorProvider.notifier).setRouteName(nameController.text);
                        ref.read(editorProvider.notifier).setRouteDescription(descController.text);
                        
                        try {
                          await ref.read(draftsProvider.notifier).saveDraft(
                            id: editorState.draftId,
                            name: nameController.text,
                            grade: editorState.routeGrade,
                            angle: editorState.routeAngle,
                            description: descController.text,
                            selectedHolds: editorState.selectedHolds,
                          );
                          ref.read(editorProvider.notifier).clear();
                          Navigator.pop(ctx); // Pop bottom sheet
                          Navigator.pop(context); // Exit editor screen
                          
                          HapticFeedback.heavyImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('💾 Saved as draft (Local only)'),
                              backgroundColor: AppColors.surfaceElevated,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Failed to save draft: $e'),
                              backgroundColor: AppColors.error,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      child: Text('💾 Save as Draft',
                          style: AppTypography.button),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
