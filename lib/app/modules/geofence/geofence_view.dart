import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/gradient_button.dart';
import 'geofence_controller.dart';

class GeofenceView extends GetView<GeofenceController> {
  const GeofenceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textPrimary),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'Zona Aman',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list, color: AppColors.textPrimary),
            onPressed: () => _showSavedZones(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Real Map Area with Geofence Circle
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                // Real Map
                Obx(
                  () => FlutterMap(
                    options: MapOptions(
                      initialCenter: LatLng(
                        controller.centerLat,
                        controller.centerLng,
                      ),
                      initialZoom: 15,
                      onPositionChanged: (position, hasGesture) {
                        // Update center when map moves
                      },
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tiles.locationiq.com/v3/streets/r/{z}/{x}/{y}.png?key=pk.b5498eed1aef9d81027b4c3ff2032802',
                        userAgentPackageName: 'com.topan.tracking',
                      ),
                      // Geofence circle overlay
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(
                              controller.centerLat,
                              controller.centerLng,
                            ),
                            radius: controller.radiusValue.value,
                            useRadiusInMeter: true,
                            color: controller.isOutsideZone.value
                                ? AppColors.danger.withValues(alpha: 0.2)
                                : AppColors.primary.withValues(alpha: 0.2),
                            borderColor: controller.isOutsideZone.value
                                ? AppColors.danger
                                : AppColors.primary,
                            borderStrokeWidth: 3,
                          ),
                        ],
                      ),
                      // Center marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(
                              controller.centerLat,
                              controller.centerLng,
                            ),
                            width: 40,
                            height: 40,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: AppColors.onPrimary,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Radius badge
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Radius: ${controller.radiusText}',
                          style: const TextStyle(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom Controls
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Atur Jarak Radius',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 15),
                        ),
                        Obx(
                          () => Text(
                            controller.radiusText,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: AppColors.primary,
                          inactiveTrackColor: AppColors.surface,
                          thumbColor: AppColors.primary,
                          trackHeight: 6,
                        ),
                        child: Slider(
                          value: controller.radiusValue.value,
                          min: 100,
                          max: 500000,
                          onChanged: controller.updateRadius,
                        ),
                      ),
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '100m',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '250km',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '500km',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Device Selection
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'TERAPKAN KE KENDARAAN',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _DeviceSelector(),
                    const SizedBox(height: 20),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'NOTIFIKASI ALERT',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _AlertToggle(
                      icon: Icons.login,
                      iconColor: AppColors.success,
                      title: 'Masuk Area',
                      subtitle: 'Alert saat kendaraan masuk zona',
                      value: controller.isEnterAlertEnabled,
                      onChanged: controller.toggleEnterAlert,
                    ),
                    const SizedBox(height: 8),
                    _AlertToggle(
                      icon: Icons.logout,
                      iconColor: AppColors.danger,
                      title: 'Keluar Area',
                      subtitle: 'Alert saat kendaraan keluar zona',
                      value: controller.isExitAlertEnabled,
                      onChanged: controller.toggleExitAlert,
                    ),
                    const SizedBox(height: 20),
                    Obx(
                      () => GradientButton(
                        text: 'Simpan Zona Aman',
                        icon: Icons.check_circle_outline,
                        isLoading: controller.isSaving.value,
                        onPressed: controller.saveGeofence,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSavedZones() {
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
              'Zona Tersimpan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Obx(
              () => controller.savedZones.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          'Belum ada zona tersimpan',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  : Column(
                      children: controller.savedZones.map((zone) {
                        final circleData = zone.circleData;
                        final radius = circleData?.radius ?? 0;
                        final linkedDevices = zone.id != null
                            ? controller.getLinkedDevices(zone.id!)
                            : <dynamic>[];
                        return GestureDetector(
                          onTap: () {
                            Get.back();
                            if (zone.id != null)
                              controller.showZoneDetail(zone);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.share_location,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            zone.name,
                                            style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'Radius: ${radius >= 1000 ? "${(radius / 1000).toStringAsFixed(1)} km" : "${radius.toInt()} m"}',
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: AppColors.textSecondary,
                                    ),
                                  ],
                                ),
                                if (linkedDevices.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: linkedDevices.take(3).map((
                                      device,
                                    ) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          device.name,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                  if (linkedDevices.length > 3)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        '+${linkedDevices.length - 3} kendaraan lainnya',
                                        style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                ],
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}


class _AlertToggle extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final RxBool value;
  final ValueChanged<bool> onChanged;

  const _AlertToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Obx(
            () => Switch(
              value: value.value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceSelector extends GetView<GeofenceController> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All devices toggle
          Obx(
            () => GestureDetector(
              onTap: () => controller.toggleAllDevices(true),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: controller.isAllDevices.value
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          width: 2,
                        ),
                        color: controller.isAllDevices.value
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                      child: controller.isAllDevices.value
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: AppColors.onPrimary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Semua Kendaraan',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Divider(color: AppColors.textSecondary, height: 16),

          // Individual devices
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: controller.devices.map((device) {
                final isSelected = controller.isDeviceSelected(device.id);
                return GestureDetector(
                  onTap: () => controller.toggleDeviceSelection(device.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device.name,
                          style: TextStyle(
                            color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
