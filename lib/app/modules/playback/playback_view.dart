import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFF0A0A0A),
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
      color: const Color(0xFF0A0A0A),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Playback Rute',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Obx(
                () => PopupMenuButton<MapProvider>(
                  tooltip: 'Pilih Peta',
                  icon: const Icon(Icons.layers, color: Colors.white),
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
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<TraccarDevice>(
                  value: controller.selectedDevice.value,
                  hint: const Row(
                    children: [
                      Icon(Icons.directions_car, color: Colors.grey, size: 20),
                      SizedBox(width: 12),
                      Text(
                        'Pilih Kendaraan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  dropdownColor: const Color(0xFF1A1A1A),
                  isExpanded: true,
                  icon: const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFF00D4FF),
                  ),
                  items: controller.devices.map((device) {
                    return DropdownMenuItem(
                      value: device,
                      child: Row(
                        children: [
                          Icon(
                            Icons.directions_car,
                            color: device.isOnline ? Colors.green : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              device.name,
                              style: const TextStyle(color: Colors.white),
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
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.calendar_month,
                        color: Color(0xFF00D4FF),
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
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.startDate.value != null &&
                                    controller.endDate.value != null
                                ? '${_formatDate(controller.startDate.value!)} - ${_formatDate(controller.endDate.value!)}'
                                : 'Pilih tanggal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
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
                          color: Colors.black,
                        ),
                      )
                    : const Icon(Icons.search, color: Colors.black),
                label: Text(
                  controller.isLoading.value ? 'Memuat...' : 'Muat Rute',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  disabledBackgroundColor: Colors.grey.shade800,
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
          color: const Color(0xFF1A1A1A),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 64, color: Colors.grey.shade700),
                const SizedBox(height: 16),
                Text(
                  controller.routeMessage.value ??
                      'Pilih kendaraan dan tanggal\nkemudian tekan "Muat Rute"',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey, fontSize: 14),
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
                  color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                  strokeWidth: 4,
                ),
                // Traveled portion
                if (controller.currentIndex.value > 0)
                  Polyline(
                    points: controller.routePoints.sublist(
                      0,
                      controller.currentIndex.value + 1,
                    ),
                    color: const Color(0xFF00D4FF),
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
                  color: const Color(0x3300D4FF),
                  borderColor: const Color(0x6600D4FF),
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
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
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
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.stop,
                      color: Colors.white,
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
            color: const Color(0xFF00D4FF),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00D4FF).withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.navigation, color: Colors.white, size: 20),
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
        color: const Color(0xFF1A1A1A),
        child: Column(
          children: [
            // Current position info
            if (controller.currentPosition.value != null)
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.access_time,
                        color: Color(0xFF00D4FF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      controller.formatTime(
                        controller.currentPosition.value!.fixTime.toLocal(),
                      ),
                      style: const TextStyle(
                        color: Colors.white,
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
                        color: Colors.orange.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.speed,
                            color: Colors.orange,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${controller.currentPosition.value!.speedKmh.toStringAsFixed(0)} km/h',
                            style: const TextStyle(
                              color: Colors.orange,
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
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
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
          color: const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF00D4FF), size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 10),
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
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress slider
              SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: const Color(0xFF00D4FF),
                  inactiveTrackColor: Colors.grey.shade800,
                  thumbColor: const Color(0xFF00D4FF),
                  overlayColor: const Color(0xFF00D4FF).withValues(alpha: 0.2),
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
                    color: const Color(0xFF1A1A1A),
                    onSelected: controller.setPlaybackSpeed,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 0.5,
                        child: Text(
                          '0.5x',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 1.0,
                        child: Text(
                          '1x',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 2.0,
                        child: Text(
                          '2x',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 5.0,
                        child: Text(
                          '5x',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 10.0,
                        child: Text(
                          '10x',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0A0A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${controller.playbackSpeed.value}x',
                        style: const TextStyle(
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Stop button
                  IconButton(
                    onPressed: controller.stopPlayback,
                    icon: const Icon(Icons.stop, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
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
                      color: Colors.black,
                      size: 32,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4FF),
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
                    icon: const Icon(Icons.fit_screen, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFF0A0A0A),
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
