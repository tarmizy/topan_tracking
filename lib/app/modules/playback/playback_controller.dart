import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/map_provider.dart';
import '../../data/models/traccar_models.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/services/vehicle_service.dart';

class PlaybackController extends GetxController {
  final TraccarApiService _traccarApi = Get.find<TraccarApiService>();
  final VehicleService _vehicleService = Get.find<VehicleService>();

  final mapController = MapController();
  final selectedMapProvider = MapProvider.openStreetMap.obs;

  // Selected device
  Rxn<TraccarDevice> get selectedDevice => _vehicleService.selectedDevice;
  RxList<TraccarDevice> get devices => _vehicleService.devices;

  // Date range
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();

  // Route data
  final routePositions = <TraccarPosition>[].obs;
  final routePoints = <LatLng>[].obs;

  // Playback state
  final isLoading = false.obs;
  final isPlaying = false.obs;
  final playbackSpeed = 1.0.obs;
  final currentIndex = 0.obs;
  final currentPosition = Rxn<TraccarPosition>();

  Timer? _playbackTimer;

  // Stats
  double get totalDistance {
    if (routePositions.isEmpty) return 0;
    double total = 0;
    for (int i = 1; i < routePositions.length; i++) {
      total += _calculateDistance(
        routePositions[i - 1].latitude,
        routePositions[i - 1].longitude,
        routePositions[i].latitude,
        routePositions[i].longitude,
      );
    }
    return total;
  }

  double get maxSpeed {
    if (routePositions.isEmpty) return 0;
    return routePositions
        .map((p) => p.speedKmh)
        .reduce((a, b) => a > b ? a : b);
  }

  double get avgSpeed {
    if (routePositions.isEmpty) return 0;
    final moving = routePositions.where((p) => p.speedKmh > 1).toList();
    if (moving.isEmpty) return 0;
    return moving.map((p) => p.speedKmh).reduce((a, b) => a + b) /
        moving.length;
  }

  Duration get totalDuration {
    if (routePositions.length < 2) return Duration.zero;
    return routePositions.last.deviceTime.difference(
      routePositions.first.deviceTime,
    );
  }

  Duration get movingDuration {
    if (routePositions.length < 2) return Duration.zero;
    Duration total = Duration.zero;
    for (int i = 1; i < routePositions.length; i++) {
      if (routePositions[i].speedKmh > 1) {
        total += routePositions[i].deviceTime.difference(
          routePositions[i - 1].deviceTime,
        );
      }
    }
    return total;
  }

  Duration get stoppedDuration => totalDuration - movingDuration;

  @override
  void onInit() {
    super.onInit();
    // Default to today
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, now.day, 0, 0, 0);
    endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  @override
  void onClose() {
    _playbackTimer?.cancel();
    super.onClose();
  }

  void selectDevice(TraccarDevice device) {
    _vehicleService.selectDevice(device);
    loadRoute();
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate.value ?? DateTime.now(),
        end: endDate.value ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D4FF),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      startDate.value = DateTime(
        picked.start.year,
        picked.start.month,
        picked.start.day,
        0,
        0,
        0,
      );
      endDate.value = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      loadRoute();
    }
  }

  Future<void> loadRoute() async {
    if (selectedDevice.value == null ||
        startDate.value == null ||
        endDate.value == null) {
      return;
    }

    isLoading.value = true;
    stopPlayback();
    routePositions.clear();
    routePoints.clear();
    currentIndex.value = 0;
    currentPosition.value = null;

    try {
      final result = await _traccarApi.getPositionHistory(
        deviceId: selectedDevice.value!.id,
        from: startDate.value!,
        to: endDate.value!,
      );

      if (result.success && result.data != null) {
        // Sort by time
        final positions = result.data!
          ..sort((a, b) => a.deviceTime.compareTo(b.deviceTime));
        routePositions.value = positions;
        routePoints.value = positions
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();

        if (routePoints.isNotEmpty) {
          currentPosition.value = routePositions.first;
          // Fit map to route
          _fitMapToRoute();
        }
      }
    } catch (e) {
      debugPrint('Error loading route: $e');
      Get.snackbar(
        'Error',
        'Gagal memuat rute: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red.withValues(alpha: 0.9),
        colorText: Colors.white,
      );
    }

    isLoading.value = false;
  }

  void _fitMapToRoute() {
    if (routePoints.isEmpty) return;

    try {
      final bounds = LatLngBounds.fromPoints(routePoints);
      mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } catch (e) {
      // Fallback to first point
      if (routePoints.isNotEmpty) {
        mapController.move(routePoints.first, 14);
      }
    }
  }

  void togglePlayback() {
    if (isPlaying.value) {
      pausePlayback();
    } else {
      startPlayback();
    }
  }

  void startPlayback() {
    if (routePositions.isEmpty) return;

    isPlaying.value = true;
    _playbackTimer?.cancel();

    final interval = (1000 / playbackSpeed.value).round();
    _playbackTimer = Timer.periodic(Duration(milliseconds: interval), (_) {
      if (currentIndex.value < routePositions.length - 1) {
        currentIndex.value++;
        currentPosition.value = routePositions[currentIndex.value];

        // Center map on current position
        final pos = routePoints[currentIndex.value];
        mapController.move(pos, mapController.camera.zoom);
      } else {
        // End of playback
        pausePlayback();
      }
    });
  }

  void pausePlayback() {
    isPlaying.value = false;
    _playbackTimer?.cancel();
  }

  void stopPlayback() {
    pausePlayback();
    currentIndex.value = 0;
    if (routePositions.isNotEmpty) {
      currentPosition.value = routePositions.first;
    }
  }

  void seekTo(double value) {
    final index = (value * (routePositions.length - 1)).round();
    currentIndex.value = index;
    if (index < routePositions.length) {
      currentPosition.value = routePositions[index];
      final pos = routePoints[index];
      mapController.move(pos, mapController.camera.zoom);
    }
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed.value = speed;
    if (isPlaying.value) {
      // Restart with new speed
      pausePlayback();
      startPlayback();
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const Distance distance = Distance();
    return distance.as(
      LengthUnit.Kilometer,
      LatLng(lat1, lon1),
      LatLng(lat2, lon2),
    );
  }

  String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}j ${minutes}m';
    }
    return '${minutes} menit';
  }

  String formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}
