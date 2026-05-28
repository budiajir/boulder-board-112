import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  disconnecting,
}

class BleDevice {
  const BleDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.device,
  });

  final String id;
  final String name;
  final int rssi;
  final BluetoothDevice device;

  int get signalBars {
    if (rssi >= -50) return 3;
    if (rssi >= -65) return 2;
    if (rssi >= -80) return 1;
    return 0;
  }
}

class BleState {
  const BleState({
    this.connectionState = BleConnectionState.disconnected,
    this.connectedDeviceName,
    this.connectedDevice,
    this.discoveredDevices = const [],
    this.isScanning = false,
    this.characteristic,
  });

  final BleConnectionState connectionState;
  final String? connectedDeviceName;
  final BluetoothDevice? connectedDevice;
  final List<BleDevice> discoveredDevices;
  final bool isScanning;
  final BluetoothCharacteristic? characteristic;

  bool get isConnected => connectionState == BleConnectionState.connected;

  BleState copyWith({
    BleConnectionState? connectionState,
    String? connectedDeviceName,
    BluetoothDevice? connectedDevice,
    List<BleDevice>? discoveredDevices,
    bool? isScanning,
    BluetoothCharacteristic? characteristic,
  }) {
    return BleState(
      connectionState: connectionState ?? this.connectionState,
      connectedDeviceName: connectedDeviceName ?? this.connectedDeviceName,
      connectedDevice: connectedDevice ?? this.connectedDevice,
      discoveredDevices: discoveredDevices ?? this.discoveredDevices,
      isScanning: isScanning ?? this.isScanning,
      characteristic: characteristic ?? this.characteristic,
    );
  }
}

class BleNotifier extends Notifier<BleState> {
  static const String SERVICE_UUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  static const String CHARACTERISTIC_UUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;

  @override
  BleState build() {
    ref.onDispose(() {
      _scanSubscription?.cancel();
      _connectionSubscription?.cancel();
      state.connectedDevice?.disconnect();
    });
    return const BleState();
  }

  Future<bool> _requestPermissions() async {
    if (Platform.isIOS) {
      // iOS only requires Bluetooth permission. Location is not required for BLE.
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }

    if (Platform.isAndroid) {
      // Android requires different permissions depending on SDK.
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location,
      ].request();

      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? false;
      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? false;
      final locationGranted = statuses[Permission.location]?.isGranted ?? false;

      // On Android 12+ (API 31+), scan and connect are required.
      // On older versions, location is required.
      return (scanGranted && connectGranted) || locationGranted;
    }

    return true;
  }

  Future<String?> startScan() async {
    if (!await _requestPermissions()) {
      debugPrint("Bluetooth permissions denied");
      return "Bluetooth and Location permissions are required to scan.";
    }

    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      debugPrint("Bluetooth is off");
      return "Bluetooth is turned off. Please turn it on.";
    }

    state = state.copyWith(isScanning: true, discoveredDevices: []);

    _scanSubscription?.cancel();
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      final devices = results
          .where((r) => r.device.platformName.isNotEmpty)
          .map((r) => BleDevice(
                id: r.device.remoteId.toString(),
                name: r.device.platformName,
                rssi: r.rssi,
                device: r.device,
              ))
          .toList();
      state = state.copyWith(discoveredDevices: devices);
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    
    // Scan will stop automatically after 4 seconds
    FlutterBluePlus.isScanning.listen((scanning) {
      if (!scanning) {
        state = state.copyWith(isScanning: false);
      }
    });

    return null;
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    state = state.copyWith(isScanning: false);
  }

  Future<bool> connectToDevice(BleDevice device) async {
    stopScan();
    state = state.copyWith(connectionState: BleConnectionState.connecting);

    try {
      await device.device.connect(timeout: const Duration(seconds: 10));
      
      _connectionSubscription?.cancel();
      _connectionSubscription = device.device.connectionState.listen((connState) {
        if (connState == BluetoothConnectionState.disconnected) {
          state = BleState(
            connectionState: BleConnectionState.disconnected,
            discoveredDevices: state.discoveredDevices,
          );
        }
      });

      // Discover services
      List<BluetoothService> services = await device.device.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (var service in services) {
        if (service.uuid.toString() == SERVICE_UUID) {
          for (var char in service.characteristics) {
            if (char.uuid.toString() == CHARACTERISTIC_UUID) {
              targetChar = char;
              break;
            }
          }
        }
      }

      if (targetChar != null) {
        // Request higher MTU for sending full route payloads (up to 512)
        if (defaultTargetPlatform == TargetPlatform.android) {
          await device.device.requestMtu(512);
        }
        
        state = state.copyWith(
          connectionState: BleConnectionState.connected,
          connectedDeviceName: device.name,
          connectedDevice: device.device,
          characteristic: targetChar,
        );
        return true;
      } else {
        await device.device.disconnect();
        state = BleState(
          connectionState: BleConnectionState.disconnected,
          discoveredDevices: state.discoveredDevices,
        );
        debugPrint("Service/Characteristic not found");
        return false;
      }
    } catch (e) {
      debugPrint("Connection error: $e");
      state = BleState(
        connectionState: BleConnectionState.disconnected,
        discoveredDevices: state.discoveredDevices,
      );
      return false;
    }
  }

  Future<void> disconnect() async {
    state = state.copyWith(connectionState: BleConnectionState.disconnecting);
    await state.connectedDevice?.disconnect();
    // The state will be reset in the connectionState listener
  }

  Future<bool> sendPayload(List<int> payload) async {
    if (!state.isConnected || state.characteristic == null) return false;

    try {
      // Set withoutResponse to false so it uses standard WRITE instead of WRITE_NO_RESPONSE
      await state.characteristic!.write(payload, withoutResponse: false);
      debugPrint('[BLE] Sent ${payload.length} bytes to ${state.connectedDeviceName}');
      return true;
    } catch (e) {
      debugPrint('[BLE] Failed to send: $e');
      return false;
    }
  }
}

final bleProvider = NotifierProvider<BleNotifier, BleState>(BleNotifier.new);
