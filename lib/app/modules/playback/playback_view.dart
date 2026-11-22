import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/utils/map_provider.dart';
import '../../data/models/traccar_models.dart';
import 'playback_controller.dart';

class PlaybackView extends GetView<PlaybackController> {
  const PlaybackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Header & Selector
          _buildHeader(context),

          // Map
          Expanded(child: _buildMap()),

          // Stats
          _buildStats(),

          // Playback controls
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Playback Rute',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Obx(
                () => PopupMenuButton<MapProvider>(
                  tooltip: 'Pilih Peta',
                  icon: const Icon(Icons.layers, color: AppColors.textPrimary),
                  initialValue: controller.selectedMapProvider.value,
                  onSelected: (provider) =>
                      controller.selectedMapProvider.value = provider,
                  itemBuilder: (context) => [
                    for (final provider in MapProvider.values)
                      PopupMenuItem(
                        value: provider,
                        child: Text(provider.label),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Device selector
          Obx(
            () => Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TraccarDevice>(
                  value: controller.selectedDevice.value,
                  hint: const Row(
                    children: [
                      Icon(Icons.directions_car, color: AppColors.textSecondary, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Pilih Kendaraan',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  dropdownColor: AppColors.surface,
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.primary,
                  ),
                  items: controller.devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: device.isOnline ? AppColors.success : AppColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device.name,
                              style: const TextStyle(color: AppColors.textPrimary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (device) {
                    if (device != null) controller.selectDevice(device);
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Date range selector
          Obx(
            () => GestureDetector(
              onTap: () => controller.selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Rentang Tanggal',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.startDate.value != null &&
                                    controller.endDate.value != null
                                ? '${_formatDate(controller.startDate.value!)} - ${_formatDate(controller.endDate.value!)}'
                                : 'Pilih tanggal',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Load button
          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    controller.selectedDevice.value != null &&
                        !controller.isLoading.value
                    ? controller.loadRoute
                    : null,
                icon: controller.isLoading.value
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.onPrimary,
                        ),
                      )
                    : const Icon(Icons.search, color: AppColors.onPrimary),
                label: Text(
                  controller.isLoading.value ? 'Memuat...' : 'Muat Rute',
                  style: const TextStyle(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.border,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Widget _buildMap() {
    return Obx(() {
      if (controller.routePositions.isEmpty && !controller.isLoading.value) {
        return Container(
          color: AppColors.surface,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: AppColors.textHint),
                const SizedBox(height: 16),
                Text(
                  controller.routeMessage.value ??
                      'Pilih kendaraan dan tanggal\nkemudian tekan "Muat Rute"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      }

      final mapProvider = controller.selectedMapProvider.value;
      final position = controller.currentPosition.value;
      final accuracy = position?.accuracy;
      return FlutterMap(
        mapController: controller.mapController,
        options: MapOptions(
          initialCenter: controller.routePoints.isNotEmpty
              ? controller.routePoints.first
              : const LatLng(-6.2088, 106.8456),
          initialZoom: 14,
        ),
        children: [
          TileLayer(
            key: ValueKey(mapProvider),
            urlTemplate: mapProvider.tileUrl,
            userAgentPackageName: 'com.topan.topan_tracking',
          ),

          // Route polyline
          if (controller.routePoints.isNotEmpty)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: controller.routePoints,
                  color: AppColors.primary.withValues(alpha: 0.5),
                  strokeWidth: 4,
                ),
                // Traveled portion
                if (controller.currentIndex.value > 0)
                  Polyline(
                    points: controller.routePoints.sublist(
                      0,
                      controller.currentIndex.value + 1,
                    ),
                    color: AppColors.primary,
                    strokeWidth: 5,
                  ),
              ],
            ),

          if (position != null &&
              accuracy != null &&
              accuracy.isFinite &&
              accuracy > 0)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: LatLng(position.latitude, position.longitude),
                  radius: accuracy,
                  useRadiusInMeter: true,
                  color: const Color(0x33C8952F),
                  borderColor: const Color(0x66C8952F),
                  borderStrokeWidth: 1,
                ),
              ],
            ),
          // Markers
          MarkerLayer(
            markers: [
              // Start marker
              if (controller.routePoints.isNotEmpty)
                Marker(
                  point: controller.routePoints.first,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textPrimary, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              // End marker
              if (controller.routePoints.length > 1)
                Marker(
                  point: controller.routePoints.last,
                  width: 40,
                  height: 40,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textPrimary, width: 2),
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                  ),
                ),
              // Current position marker
              if (position != null)
                Marker(
                  point: LatLng(position.latitude, position.longitude),
                  width: 50,
                  height: 50,
                  child: _buildVehicleMarker(),
                ),
            ],
          ),
          SimpleAttributionWidget(source: Text(mapProvider.attribution)),
        ],
      );
    });
  }

  Widget _buildVehicleMarker() {
    return Obx(() {
      final pos = controller.currentPosition.value;
      final rotation = pos != null ? pos.course * 3.14159 / 180 : 0.0;

      return Transform.rotate(
        angle: rotation,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.textPrimary, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: AppColors.textPrimary, size: 20),
        ),
      );
    });
  }

  Widget _buildStats() {
    return Obx(() {
      if (controller.routePositions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(12),
        color: AppColors.surface,
        child: Column(
          children: [
            // Current position info
            if (controller.currentPosition.value != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      controller.formatTime(
                        controller.currentPosition.value!.fixTime.toLocal(),
                      ),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            color: AppColors.warning,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${controller.currentPosition.value!.speedKmh.toStringAsFixed(0)} km/h',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${controller.currentIndex.value + 1} / ${controller.routePositions.length}',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),

            // Stats row
            Row(
              children: [
                _buildStatItem(
                  Icons.route,
                  '${controller.totalDistance.toStringAsFixed(1)} km',
                  'Jarak',
                ),
                _buildStatItem(
                  Icons.timer,
                  controller.formatDuration(controller.totalDuration),
                  'Durasi',
                ),
                _buildStatItem(
                  Icons.speed,
                  '${controller.avgSpeed.toStringAsFixed(0)} km/h',
                  'Rata²',
                ),
                _buildStatItem(
                  Icons.flash_on,
                  '${controller.maxSpeed.toStringAsFixed(0)} km/h',
                  'Maks',
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Obx(() {
      if (controller.routePositions.isEmpty) {
        return const SizedBox.shrink();
      }

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: AppColors.primary,
                  inactiveTrackColor: AppColors.border,
                  thumbColor: AppColors.primary,
                  overlayColor: AppColors.primary.withValues(alpha: 0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value:
                      controller.currentIndex.value /
                      (controller.routePositions.length - 1).clamp(
                        1,
                        double.infinity,
                      ),
                  onChanged: controller.seekTo,
                ),
              ),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Speed selector
                  PopupMenuButton<double>(
                    color: AppColors.surface,
                    onSelected: controller.setPlaybackSpeed,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0.5,
                        child: Text(
                          '0.5x',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1.0,
                        child: Text(
                          '1x',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 2.0,
                        child: Text(
                          '2x',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 5.0,
                        child: Text(
                          '5x',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 10.0,
                        child: Text(
                          '10x',
                          style: TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.playbackSpeed.value}x',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stop button
                  IconButton(
                    onPressed: controller.stopPlayback,
                    icon: const Icon(Icons.stop, color: AppColors.textPrimary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.background,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Play/Pause button
                  IconButton(
                    onPressed: controller.togglePlayback,
                    icon: Icon(
                      controller.isPlaying.value
                          ? Icons.pause
                          : Icons.play_arrow,
                      color: AppColors.onPrimary,
                      size: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Fit to route button
                  IconButton(
                    onPressed: () {
                      if (controller.routePoints.isNotEmpty) {
                        final bounds = LatLngBounds.fromPoints(
                          controller.routePoints,
                        );
                        controller.mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(50),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.fit_screen, color: AppColors.textPrimary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.background,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}
