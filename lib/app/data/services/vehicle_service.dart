import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/traccar_models.dart';
import 'traccar_api_service.dart';

class VehicleService extends GetxService {
  late final TraccarApiService _traccarApi;

  final devices = <TraccarDevice>[].obs;
  final selectedDevice = Rxn<TraccarDevice>();
  final tripHistory = <TraccarTrip>[].obs;
  final commandHistory = <CommandHistoryItem>[].obs;
  final notifications = <NotificationItem>[].obs;
  final geofenceZones = <TraccarGeofence>[].obs;

  final isLoading = false.obs;
  final errorMessage = ''.obs;

  TraccarPosition? get selectedPosition {
    if (selectedDevice.value == null) return null;
    return _traccarApi.positions[selectedDevice.value!.id];
  }

  Map<int, TraccarPosition> get positions => _traccarApi.positions;

  @override
  void onInit() {
    super.onInit();
    _traccarApi = Get.find<TraccarApiService>();

    // Segarkan notifikasi setiap 60 detik selama aplikasi terbuka.
    _eventsTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (_traccarApi.isConnected.value && selectedDevice.value != null) {
        loadEvents();
      }
    });

    // Listen to device updates from WebSocket
    ever(_traccarApi.devices, (devices) {
      this.devices.value = devices;
      // Update selected device if it was updated
      if (selectedDevice.value != null) {
        final updated = devices.firstWhereOrNull(
          (d) => d.id == selectedDevice.value!.id,
        );
        if (updated != null) {
          selectedDevice.value = updated;
        }
      }
    });
  }

  Future<void> loadInitialData() async {
    isLoading.value = true;
    errorMessage.value = '';

    try {
      debugPrint('=== Loading initial data ===');

      // Load devices
      debugPrint('Loading devices...');
      final devicesResult = await _traccarApi.getDevices();
      if (devicesResult.success && devicesResult.data != null) {
        devices.value = devicesResult.data!;
        debugPrint('Devices loaded: ${devices.length}');
        if (devices.isNotEmpty && selectedDevice.value == null) {
          selectedDevice.value = devices.first;
          debugPrint('Selected device: ${selectedDevice.value?.name}');
        }
      } else {
        debugPrint('Failed to load devices: ${devicesResult.error}');
        errorMessage.value = devicesResult.error ?? 'Gagal memuat devices';
      }

      // Load positions
      debugPrint('Loading positions...');
      final posResult = await _traccarApi.getPositions();
      debugPrint('Positions loaded: ${posResult.success}');

      // Load geofences
      debugPrint('Loading geofences...');
      final geofencesResult = await _traccarApi.getGeofences();
      if (geofencesResult.success && geofencesResult.data != null) {
        geofenceZones.value = geofencesResult.data!;
        debugPrint('Geofences loaded: ${geofenceZones.length}');
      }

      // Connect WebSocket for live updates (with error handling)
      debugPrint('Connecting WebSocket...');
      try {
        _traccarApi.connectWebSocket();
      } catch (e) {
        // WebSocket connection failure is not critical
        debugPrint('WebSocket connection failed (non-critical): $e');
      }

      // Load trip history for selected device
      if (selectedDevice.value != null) {
        debugPrint('Loading trip history...');
        try {
          await loadTripHistory();
        } catch (e) {
          debugPrint('Trip history load failed (non-critical): $e');
        }

        debugPrint('Loading events...');
        try {
          await loadEvents();
        } catch (e) {
          debugPrint('Events load failed (non-critical): $e');
        }
      }

      debugPrint('=== Initial data load complete ===');
    } catch (e, stackTrace) {
      debugPrint('Error in loadInitialData: $e');
      debugPrint('Stack trace: $stackTrace');
      errorMessage.value = 'Gagal memuat data: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await _traccarApi.getDevices();
    await _traccarApi.getPositions();
    await _traccarApi.getGeofences();
  }

  void selectDevice(TraccarDevice device) {
    selectedDevice.value = device;
    loadTripHistory();
    loadEvents();
  }

  Future<void> loadTripHistory({DateTime? from, DateTime? to}) async {
    if (selectedDevice.value == null) {
      debugPrint('loadTripHistory: No device selected');
      return;
    }

    try {
      final fromDate = from ?? DateTime.now().subtract(const Duration(days: 7));
      final toDate = to ?? DateTime.now();

      debugPrint('Loading trip history for device ${selectedDevice.value!.id}');
      final result = await _traccarApi.getTrips(
        deviceId: selectedDevice.value!.id,
        from: fromDate,
        to: toDate,
      );

      if (result.success && result.data != null) {
        tripHistory.value = result.data!;
        debugPrint('Trip history loaded: ${tripHistory.length} trips');
      } else {
        debugPrint('Trip history failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('Error loading trip history: $e');
    }
  }

  Future<void> loadEvents({DateTime? from, DateTime? to}) async {
    if (selectedDevice.value == null) {
      debugPrint('loadEvents: No device selected');
      return;
    }

    try {
      final fromDate = from ?? DateTime.now().subtract(const Duration(days: 7));
      final toDate = to ?? DateTime.now();

      debugPrint('Loading events for device ${selectedDevice.value!.id}');
      final result = await _traccarApi.getEvents(
        deviceId: selectedDevice.value!.id,
        from: fromDate,
        to: toDate,
      );

      if (result.success && result.data != null) {
        notifications.value = result.data!
            .map(
              (e) => NotificationItem(
                id: e.id.toString(),
                title: e.eventTitle,
                message: _eventMessage(e),
                type: _getEventType(e.type),
                timestamp: e.eventTime,
              ),
            )
            .toList();
        debugPrint('Events loaded: ${notifications.length} events');
      } else {
        debugPrint('Events failed: ${result.error}');
      }
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  /// Keterangan notifikasi: nama kendaraan + detail yang relevan.
  String _eventMessage(TraccarEvent e) {
    final device = _traccarApi.devices.firstWhereOrNull((d) => d.id == e.deviceId);
    final name = device?.name ?? selectedDevice.value?.name ?? 'Kendaraan';
    final speed = e.attributes?['speed'];
    if (speed is num) {
      return '$name · ${(speed * 1.852).round()} km/jam';
    }
    final geofenceId = e.geofenceId;
    if (geofenceId != null) {
      final zone = _traccarApi.geofences.firstWhereOrNull((g) => g.id == geofenceId);
      if (zone != null) return '$name · ${zone.name}';
    }
    return name;
  }

  String _getEventType(String eventType) {
    switch (eventType) {
      case 'deviceOverspeed':
      case 'alarm':
        return 'alert';
      case 'geofenceExit':
      case 'geofenceEnter':
        return 'warning';
      default:
        return 'info';
    }
  }

  // ==================== COMMANDS ====================

  Future<bool> sendCommand(
    String commandType, {
    Map<String, dynamic>? attributes,
  }) async {
    final result = await _sendCommand(commandType, attributes: attributes);
    return result.data == TraccarCommandDelivery.sent;
  }

  Future<TraccarApiResponse<TraccarCommandDelivery>> _sendCommand(
    String commandType, {
    Map<String, dynamic>? attributes,
  }) async {
    final device = selectedDevice.value;
    if (device == null) {
      return TraccarApiResponse(
        success: false,
        error: 'Pilih kendaraan dahulu.',
      );
    }

    final result = await _traccarApi.sendCommand(
      deviceId: device.id,
      type: commandType,
      attributes: attributes,
    );

    // Add to command history
    commandHistory.insert(
      0,
      CommandHistoryItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        command: _getCommandName(commandType),
        status: switch (result.data) {
          TraccarCommandDelivery.sent => 'Terkirim',
          TraccarCommandDelivery.queued => 'Dalam antrean',
          null => 'Gagal',
        },
        timestamp: DateTime.now(),
        isSuccess: result.success,
        errorMessage: result.error,
      ),
    );

    return result;
  }

  String _getCommandName(String type) {
    switch (type) {
      case TraccarCommandTypes.engineStop:
        return 'Matikan Mesin';
      case TraccarCommandTypes.engineResume:
        return 'Pulihkan Mesin';
      case TraccarCommandTypes.positionSingle:
        return 'Permintaan Posisi';
      case TraccarCommandTypes.rebootDevice:
        return 'Restart Device';
      default:
        return type;
    }
  }

  Future<bool> killEngine() async {
    return sendCommand(TraccarCommandTypes.engineStop);
  }

  Future<bool> restoreEngine() async {
    return sendCommand(TraccarCommandTypes.engineResume);
  }

  Future<TraccarApiResponse<TraccarCommandDelivery>> requestPosition() {
    return _sendCommand(TraccarCommandTypes.positionSingle);
  }

  // ==================== GEOFENCE ====================

  Future<bool> createGeofence({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? description,
  }) async {
    final geofence = TraccarGeofence.createCircle(
      name: name,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      description: description,
    );

    final result = await _traccarApi.createGeofence(geofence);

    if (result.success) {
      await _traccarApi.getGeofences();
      geofenceZones.value = _traccarApi.geofences;
    }

    return result.success;
  }

  Future<bool> deleteGeofence(int id) async {
    final result = await _traccarApi.deleteGeofence(id);

    if (result.success) {
      geofenceZones.removeWhere((g) => g.id == id);
    }

    return result.success;
  }

  // ==================== NOTIFICATIONS ====================

  void markNotificationAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = notifications[index];
      notifications[index] = NotificationItem(
        id: notification.id,
        title: notification.title,
        message: notification.message,
        type: notification.type,
        timestamp: notification.timestamp,
        isRead: true,
      );
    }
  }

  int get unreadNotificationCount =>
      notifications.where((n) => !n.isRead).length;

  // ==================== CLEANUP ====================

  Timer? _eventsTimer;

  @override
  void onClose() {
    _eventsTimer?.cancel();
    super.onClose();
  }

  void disconnect() {
    _traccarApi.disconnectWebSocket();
  }
}

// Local models for UI
class CommandHistoryItem {
  final String id;
  final String command;
  final String status;
  final DateTime timestamp;
  final bool isSuccess;
  final String? errorMessage;

  CommandHistoryItem({
    required this.id,
    required this.command,
    required this.status,
    required this.timestamp,
    required this.isSuccess,
    this.errorMessage,
  });
}

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime timestamp;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
  });
}
