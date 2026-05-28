import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../presentation/providers/ble_notifier.dart';

/// BLE setup screen for scanning and connecting to climbing boards.
class BleSetupScreen extends ConsumerWidget {
  const BleSetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Consumer(
                    builder: (context, ref, _) {
                      final bleState = ref.watch(bleProvider);
                      final bleNotifier = ref.read(bleProvider.notifier);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero icon + title
                          Center(
                            child: Column(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.accentPrimary
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: const Icon(
                                    Icons.bluetooth_searching,
                                    size: 36,
                                    color: AppColors.accentPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Connect Your Board',
                                  style: AppTypography.headline,
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Scan button / status
                          if (!bleState.isScanning &&
                              bleState.discoveredDevices.isEmpty)
                            Center(
                              child: SizedBox(
                                width: 200,
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    final error = await bleNotifier.startScan();
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: AppColors.accentRed,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.search, size: 20),
                                  label: Text('Scan for Boards',
                                      style: AppTypography.button),
                                ),
                              ),
                            )
                          else if (bleState.isScanning)
                            Row(
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accentPrimary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text('Scanning for boards...',
                                    style: AppTypography.body),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${bleState.discoveredDevices.length} boards found',
                                  style: AppTypography.body,
                                ),
                                TextButton.icon(
                                  onPressed: () async {
                                    final error = await bleNotifier.startScan();
                                    if (error != null && context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(error),
                                          backgroundColor: AppColors.accentRed,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.refresh, size: 16),
                                  label: const Text('Rescan'),
                                ),
                              ],
                            ),

                          const SizedBox(height: 16),

                          // Device list
                          Expanded(
                            child: ListView.builder(
                              itemCount: bleState.discoveredDevices.length,
                              itemBuilder: (context, index) {
                                final device =
                                    bleState.discoveredDevices[index];
                                final isCurrentlyConnected =
                                    bleState.isConnected &&
                                        bleState.connectedDeviceName ==
                                            device.name;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: isCurrentlyConnected
                                        ? AppColors.accentGreen
                                            .withValues(alpha: 0.1)
                                        : AppColors.surfaceVariant,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isCurrentlyConnected
                                          ? AppColors.accentGreen
                                          : AppColors.border,
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: _signalIcon(device.signalBars),
                                    title: Text(device.name,
                                        style: AppTypography.body.copyWith(
                                            fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      isCurrentlyConnected
                                          ? 'Connected ✓'
                                          : 'Signal: ${device.rssi} dBm',
                                      style: AppTypography.label.copyWith(
                                        color: isCurrentlyConnected
                                            ? AppColors.accentGreen
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    trailing: isCurrentlyConnected
                                        ? TextButton(
                                            onPressed: () =>
                                                bleNotifier.disconnect(),
                                            child: Text('Disconnect',
                                                style: AppTypography.label
                                                    .copyWith(
                                                        color: AppColors
                                                            .accentRed)),
                                          )
                                        : bleState.connectionState ==
                                                BleConnectionState.connecting
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : TextButton(
                                                onPressed: () async {
                                                  HapticFeedback.selectionClick();
                                                  await bleNotifier
                                                      .connectToDevice(device);
                                                },
                                                child: Text('Connect',
                                                    style: AppTypography.label
                                                        .copyWith(
                                                            color: AppColors
                                                                .accentPrimary)),
                                              ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Board layout selector
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.grid_view,
                                    size: 20, color: AppColors.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Board Layout',
                                          style: AppTypography.body),
                                      Text('Standard 11×18',
                                          style: AppTypography.label),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.keyboard_arrow_down,
                                    color: AppColors.textSecondary),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                          // Skip button
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(
                                'Skip for Now',
                                style: AppTypography.body.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _signalIcon(int bars) {
    final color = bars >= 2
        ? AppColors.accentGreen
        : bars >= 1
            ? AppColors.accentYellow
            : AppColors.accentRed;
    return Icon(
      bars >= 2
          ? Icons.signal_wifi_4_bar
          : bars >= 1
              ? Icons.network_wifi_2_bar
              : Icons.signal_wifi_0_bar,
      color: color,
      size: 22,
    );
  }
}
