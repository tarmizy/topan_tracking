import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import '../../core/utils/map_provider.dart';
import '../../data/models/traccar_models.dart';
import '../../data/services/vehicle_service.dart';
import '../../data/services/traccar_api_service.dart';
import '../../routes/app_pages.dart';

class HomeController extends GetxController {
  late final VehicleService _vehicleService;
  late final TraccarApiService _traccarApi;
  MapController? osmMapController;

  final selectedIndex = 0.obs;
  final isLoading = false.obs;
  final isMapLoaded = true.obs;
  final selectedMapProvider = MapProvider.locationIQ.obs;

  // Traccar data
  RxList<TraccarDevice> get devices => _vehicleService.devices;
  Rxn<TraccarDevice> get selectedDevice => _vehicleService.selectedDevice;
  RxList<TraccarTrip> get tripHistory => _vehicleService.tripHistory;
  RxList<CommandHistoryItem> get commandHistory =>
      _vehicleService.commandHistory;
  RxList<NotificationItem> get notifications => _vehicleService.notifications;
  int get unreadCount => _vehicleService.unreadNotificationCount;

  TraccarPosition? get selectedPosition => _vehicleService.selectedPosition;
  Map<int, TraccarPosition> get positions => _vehicleService.positions;

  bool? get ignitionStatus => selectedPosition?.ignitionStatus;
  final speedLimit = 90.obs;
  final isCommandLoading = false.obs;
  final isPositionRequestLoading = false.obs;

  // Date filter for trip history
  final Rxn<DateTime> filterStartDate = Rxn<DateTime>();
  final Rxn<DateTime> filterEndDate = Rxn<DateTime>();

  List<TraccarTrip> get filteredTripHistory {
    if (filterStartDate.value == null && filterEndDate.value == null) {
      return tripHistory;
    }
    return tripHistory.where((trip) {
      if (filterStartDate.value != null &&
          trip.startTime.isBefore(filterStartDate.value!)) {
        return false;
      }
      if (filterEndDate.value != null &&
          trip.startTime.isAfter(
            filterEndDate.value!.add(const Duration(days: 1)),
          )) {
        return false;
      }
      return true;
    }).toList();
  }

  void setDateFilter(DateTime? start, DateTime? end) {
    filterStartDate.value = start;
    filterEndDate.value = end;
    // Reload trip history with new filter
    if (start != null || end != null) {
      _vehicleService.loadTripHistory(from: start, to: end);
    }
  }

  void clearDateFilter() {
    filterStartDate.value = null;
    filterEndDate.value = null;
    _vehicleService.loadTripHistory();
  }

  String get currentTileUrl => selectedMapProvider.value.tileUrl;

  @override
  void onInit() {
    super.onInit();
    _vehicleService = Get.find<VehicleService>();
    _traccarApi = Get.find<TraccarApiService>();
    osmMapController = MapController();

    // Load initial data with delay to ensure everything is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      _loadData();
    });

    // Listen to device selection changes
    ever(selectedDevice, (device) {
      if (device != null) {
        try {
          centerOnVehicle();
        } catch (e) {
          debugPrint('Error updating device selection: $e');
        }
      }
    });
  }

  Future<void> _loadData() async {
    try {
      debugPrint('HomeController: Starting _loadData');
      isLoading.value = true;
      await _vehicleService.loadInitialData();
      debugPrint('HomeController: loadInitialData complete');
      // Posisi baru tersedia setelah data dimuat: arahkan peta ke kendaraan.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          centerOnVehicle();
        } catch (e) {
          debugPrint('centerOnVehicle after load failed: $e');
        }
      });
    } catch (e, stackTrace) {
      debugPrint('HomeController Error loading data: $e');
      debugPrint('Stack trace: $stackTrace');
      Get.snackbar(
        'Error',
        'Gagal memuat data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: AppColors.onPrimary,
      );
    } finally {
      isLoading.value = false;
      debugPrint('HomeController: _loadData finished');
    }
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    await _vehicleService.refreshData();
    isLoading.value = false;
  }

  void changeMapProvider(MapProvider provider) {
    selectedMapProvider.value = provider;
    Get.back();
  }

  void showMapProviderSelector() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Peta',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...MapProvider.values.map(
              (provider) => _buildMapProviderOption(provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapProviderOption(MapProvider provider) {
    return Obx(
      () => GestureDetector(
        onTap: () => changeMapProvider(provider),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selectedMapProvider.value == provider
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selectedMapProvider.value == provider
                  ? AppColors.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getMapIcon(provider),
                color: selectedMapProvider.value == provider
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getMapDescription(provider),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (selectedMapProvider.value == provider)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMapIcon(MapProvider provider) {
    switch (provider) {
      case MapProvider.locationIQ:
        return Icons.map;
      case MapProvider.openStreetMap:
        return Icons.public;
      case MapProvider.cartoDark:
        return Icons.dark_mode;
      case MapProvider.cartoLight:
        return Icons.light_mode;
    }
  }

  String _getMapDescription(MapProvider provider) {
    switch (provider) {
      case MapProvider.locationIQ:
        return 'Peta default dengan detail lengkap';
      case MapProvider.openStreetMap:
        return 'Peta gratis dan open source';
      case MapProvider.cartoDark:
        return 'Tema gelap, cocok untuk malam';
      case MapProvider.cartoLight:
        return 'Tema terang, detail jelas';
    }
  }

  void centerOnVehicle() {
    if (selectedDevice.value == null) return;

    final position = positions[selectedDevice.value!.id];
    if (position == null) return;

    final lat = position.latitude;
    final lng = position.longitude;

    if (osmMapController != null) {
      osmMapController!.move(latlong.LatLng(lat, lng), 16);
    }
  }

  void zoomIn() {
    if (osmMapController != null) {
      final currentZoom = osmMapController!.camera.zoom;
      osmMapController!.move(osmMapController!.camera.center, currentZoom + 1);
    }
  }

  void zoomOut() {
    if (osmMapController != null) {
      final currentZoom = osmMapController!.camera.zoom;
      osmMapController!.move(osmMapController!.camera.center, currentZoom - 1);
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void selectDevice(TraccarDevice device) {
    _vehicleService.selectDevice(device);
  }

  /// Navigate to vehicle location using Google Maps app
  Future<void> navigateToVehicle(TraccarDevice device) async {
    final position = positions[device.id];
    if (position == null) {
      _showErrorSnackbar('Posisi kendaraan tidak tersedia');
      return;
    }

    final lat = position.latitude;
    final lng = position.longitude;

    debugPrint('Navigating to: $lat, $lng');

    // Google Maps app URL scheme untuk iOS
    final googleMapsAppUrl = Uri.parse(
      'comgooglemaps://?daddr=$lat,$lng&directionsmode=driving',
    );

    // Apple Maps URL sebagai fallback
    final appleMapsUrl = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');

    // Google Maps web sebagai fallback terakhir
    final webUrl = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );

    try {
      // Coba buka Google Maps app dulu
      if (await canLaunchUrl(googleMapsAppUrl)) {
        debugPrint('Opening Google Maps app');
        await launchUrl(googleMapsAppUrl);
        return;
      }

      // Fallback ke Apple Maps
      if (await canLaunchUrl(appleMapsUrl)) {
        debugPrint('Opening Apple Maps');
        await launchUrl(appleMapsUrl);
        return;
      }

      // Fallback ke browser
      debugPrint('Opening web browser');
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Error launching maps: $e');
      _showErrorSnackbar('Tidak dapat membuka peta');
    }
  }

  /// Show options when tapping on vehicle marker
  void showVehicleOptions(TraccarDevice device) {
    final position = positions[device.id];

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Vehicle info header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: device.isOnline
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.danger.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.directions_car,
                    color: device.isOnline ? AppColors.success : AppColors.danger,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: device.isOnline
                                  ? AppColors.success
                                  : AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            device.statusText,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                          if (position != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.speed, color: AppColors.textSecondary, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${position.speedKmh.toStringAsFixed(0)} km/h',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.navigation,
                    label: 'Navigasi',
                    color: AppColors.primary,
                    onTap: () {
                      Get.back();
                      navigateToVehicle(device);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.my_location,
                    label: 'Fokus',
                    color: AppColors.warning,
                    onTap: () {
                      Get.back();
                      selectDevice(device);
                      centerOnVehicle();
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.route,
                    label: 'Playback',
                    color: Colors.purple,
                    onTap: () {
                      Get.back();
                      selectDevice(device);
                      selectedIndex.value = 1; // Go to Playback tab
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> killEngine() async {
    isCommandLoading.value = true;
    final success = await _vehicleService.killEngine();

    if (success) {
      _showSuccessSnackbar('Perintah matikan mesin terkirim');
    } else {
      _showErrorSnackbar('Gagal mengirim perintah');
    }
    isCommandLoading.value = false;
  }

  Future<void> restoreEngine() async {
    isCommandLoading.value = true;
    final success = await _vehicleService.restoreEngine();

    if (success) {
      _showSuccessSnackbar('Perintah pulihkan mesin terkirim');
    } else {
      _showErrorSnackbar('Gagal mengirim perintah');
    }
    isCommandLoading.value = false;
  }

  Future<void> toggleEngine(bool turnOn) async {
    isCommandLoading.value = true;

    bool success;
    if (turnOn) {
      success = await _vehicleService.restoreEngine();
    } else {
      success = await _vehicleService.killEngine();
    }

    if (success) {
      _showSuccessSnackbar(
        turnOn ? 'Perintah pemulihan terkirim' : 'Perintah pemutusan terkirim',
      );
    } else {
      _showErrorSnackbar('Gagal mengirim perintah');
    }
    isCommandLoading.value = false;
  }

  Future<void> setSpeedLimit(int limit) async {
    isCommandLoading.value = true;
    // Note: Speed limit command depends on device support
    final success = await _vehicleService.sendCommand(
      'custom',
      attributes: {'data': 'setspeed$limit'},
    );

    if (success) {
      speedLimit.value = limit;
      _showSuccessSnackbar('Batas kecepatan diatur ke $limit KM/H');
    } else {
      _showErrorSnackbar('Gagal mengatur batas kecepatan');
    }
    isCommandLoading.value = false;
  }

  Future<void> requestPosition() async {
    if (isPositionRequestLoading.value) return;

    isPositionRequestLoading.value = true;
    try {
      final result = await _vehicleService.requestPosition();
      if (isClosed) return;

      switch (result.data) {
        case TraccarCommandDelivery.sent:
          _showSuccessSnackbar(
            'Permintaan terkirim. Menunggu posisi dari GPS.',
          );
          Future.delayed(const Duration(seconds: 3), () {
            if (!isClosed) _traccarApi.getPositions();
          });
        case TraccarCommandDelivery.queued:
          _showSuccessSnackbar('Permintaan masuk antrean server.');
        case null:
          _showErrorSnackbar(result.error ?? 'Gagal mengirim permintaan.');
      }
    } finally {
      if (!isClosed) isPositionRequestLoading.value = false;
    }
  }

  void openSOS() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 12),
            Text('Konfirmasi SOS', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin mengirim sinyal darurat?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              _sendSOS();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text(
              'Kirim SOS',
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendSOS() async {
    isLoading.value = true;
    // Send SOS command to device
    await _vehicleService.sendCommand('custom', attributes: {'data': 'SOS'});
    isLoading.value = false;
    _showSuccessSnackbar('Sinyal SOS terkirim');
  }

  void openTripDetail(TraccarTrip trip) {
    Get.snackbar(
      'Detail Perjalanan',
      '${trip.startAddress ?? "Lokasi awal"} → ${trip.endAddress ?? "Lokasi akhir"}\n'
          'Jarak: ${trip.distanceKm.toStringAsFixed(1)} km\n'
          'Durasi: ${trip.durationMinutes} menit',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 4),
    );
  }

  void logout() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Apakah Anda yakin ingin keluar?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _traccarApi.logout();
              Get.offAllNamed(Routes.login);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Keluar', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    Get.snackbar(
      'Berhasil',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.9),
      colorText: AppColors.onPrimary,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  void _showErrorSnackbar(String message) {
    Get.snackbar(
      'Gagal',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.danger.withValues(alpha: 0.9),
      colorText: AppColors.onPrimary,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  String formatDateTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  String formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _vehicleService.disconnect();
    super.onClose();
  }
}
