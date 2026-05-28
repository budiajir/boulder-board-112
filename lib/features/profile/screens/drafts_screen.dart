import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/ble_status_indicator.dart';
import '../../ble/presentation/providers/ble_notifier.dart';
import '../../editor/presentation/providers/editor_notifier.dart';
import '../../editor/screens/route_editor_screen.dart';
import '../../discovery/presentation/providers/route_list_notifier.dart';
import '../data/models/draft_route_model.dart';
import '../presentation/providers/drafts_notifier.dart';

/// Screen listing locally saved draft routes with editing and publishing tools.
class DraftsScreen extends ConsumerWidget {
  const DraftsScreen({super.key});

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(draftsProvider);
    final bleState = ref.watch(bleProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, bleState),
              Expanded(
                child: draftsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.accentPrimary),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error loading drafts: $err',
                      style: AppTypography.body,
                    ),
                  ),
                  data: (drafts) {
                    if (drafts.isEmpty) {
                      return _buildEmptyState(context);
                    }
                    return _buildDraftsList(context, ref, drafts, bleState);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, BleState bleState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          Text('My Drafts', style: AppTypography.title),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: BleStatusIndicator(
              isConnected: bleState.isConnected,
              showLabel: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceVariant,
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(
                Icons.drafts_outlined,
                size: 36,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No draft routes yet',
              style: AppTypography.headline.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a route in the editor and click "Save as Draft" to store it locally on your device.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const RouteEditorScreen()),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: Text('Create Route', style: AppTypography.button),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftsList(
      BuildContext context, WidgetRef ref, List<DraftRouteModel> drafts, BleState bleState) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: drafts.length,
      itemBuilder: (context, index) {
        final draft = drafts[index];
        return _buildDraftCard(context, ref, draft, bleState);
      },
    );
  }

  Widget _buildDraftCard(
      BuildContext context, WidgetRef ref, DraftRouteModel draft, BleState bleState) {
    final holdsCount = draft.holds.length;
    final dateStr = _formatDate(draft.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _previewDraftOnBoard(context, ref, draft, bleState);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Badges / Icons
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.architecture_outlined,
                      color: AppColors.accentPrimary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Text details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          draft.name,
                          style: AppTypography.body.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${draft.grade} • ${draft.angle}°',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$holdsCount holds',
                              style: AppTypography.label.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created $dateStr',
                          style: AppTypography.bodySmall.copyWith(
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // Actions Row
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Edit Draft
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 20, color: AppColors.accentPrimary),
                        tooltip: 'Edit Draft',
                        onPressed: () {
                          ref.read(editorProvider.notifier).loadDraft(draft);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const RouteEditorScreen()),
                          );
                        },
                      ),
                      // Publish Draft
                      IconButton(
                        icon: const Icon(Icons.publish_outlined, size: 20, color: AppColors.accentGreen),
                        tooltip: 'Publish to Gym',
                        onPressed: () {
                          _confirmPublish(context, ref, draft);
                        },
                      ),
                      // Delete Draft
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.accentRed),
                        tooltip: 'Delete Draft',
                        onPressed: () {
                          _confirmDelete(context, ref, draft);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _previewDraftOnBoard(
      BuildContext context, WidgetRef ref, DraftRouteModel draft, BleState bleState) {
    if (!bleState.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Not connected to BLE board. Tap top indicator to connect.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final List<int> payload = [0x01]; // Command: Turn ON
    for (final h in draft.holds) {
      final index = h.ledIndex ?? ((17 - h.y) * 11 + h.x);
      payload.add(index);
      
      switch (h.holdType) {
        case 'start':
          payload.addAll([0, 255, 0]); // Pure Green
          break;
        case 'finish':
          payload.addAll([255, 0, 0]); // Pure Red
          break;
        case 'foot':
          payload.addAll([255, 255, 0]); // Pure Yellow
          break;
        case 'hand':
        default:
          payload.addAll([0, 0, 255]); // Pure Blue
          break;
      }
    }

    ref.read(bleProvider.notifier).sendPayload(payload);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚡ Previewing draft "${draft.name}" on BLE board!'),
        backgroundColor: AppColors.accentLime.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, DraftRouteModel draft) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text('Delete Draft', style: AppTypography.headline.copyWith(fontSize: 18)),
          content: Text(
            'Are you sure you want to delete the draft "${draft.name}"? This action cannot be undone.',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(draftsProvider.notifier).deleteDraft(draft.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('🗑️ Draft "${draft.name}" deleted.'),
                      backgroundColor: AppColors.surfaceElevated,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text('Delete', style: AppTypography.body.copyWith(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmPublish(BuildContext context, WidgetRef ref, DraftRouteModel draft) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surfaceElevated,
          title: Text('Publish Route', style: AppTypography.headline.copyWith(fontSize: 18)),
          content: Text(
            'Publish "${draft.name}" to the public Gym Board? Once uploaded to Supabase, other climbers will be able to see and climb it!',
            style: AppTypography.body,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                
                // Show floating loading indicator
                final overlayState = Overlay.of(context);
                final overlayEntry = OverlayEntry(
                  builder: (context) => Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.accentPrimary),
                    ),
                  ),
                );
                overlayState.insert(overlayEntry);

                try {
                  // Set editor values and save to Supabase
                  ref.read(editorProvider.notifier).loadDraft(draft);
                  await ref.read(editorProvider.notifier).saveRoute();
                  
                  // On success, clear editor, delete the local draft, and refresh discover list
                  ref.read(editorProvider.notifier).clear();
                  await ref.read(draftsProvider.notifier).deleteDraft(draft.id!);
                  ref.read(routeListProvider.notifier).refresh();

                  overlayEntry.remove();
                  HapticFeedback.heavyImpact();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('📤 Route published and uploaded to Supabase!'),
                        backgroundColor: AppColors.accentGreen,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                } catch (e) {
                  overlayEntry.remove();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to publish: $e'),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
              child: Text('Publish', style: AppTypography.body.copyWith(color: AppColors.accentGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
