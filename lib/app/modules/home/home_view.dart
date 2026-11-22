import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/traccar_models.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/services/vehicle_service.dart';
import '../playback/playback_view.dart';
import '../playback/playback_controller.dart';
import 'home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Obx(
          () => IndexedStack(
            index: controller.selectedIndex.value,
            children: [
              const _BerandaTab(),
              _PlaybackTab(),
              const _PerintahTab(),
              _NotifikasiTab(),
              const _AkunTab(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          backgroundColor: AppColors.surface,
          indicatorColor: Colors.transparent,
          selectedIndex: controller.selectedIndex.value,
          onDestinationSelected: controller.changeTab,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: Icon(
                Icons.home_outlined,
                color: controller.selectedIndex.value == 0
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              selectedIcon: const Icon(Icons.home, color: AppColors.primary),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.play_circle_outline,
                color: controller.selectedIndex.value == 1
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.play_circle,
                color: AppColors.primary,
              ),
              label: 'Playback',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.grid_view_outlined,
                color: controller.selectedIndex.value == 2
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              selectedIcon: const Icon(
                Icons.grid_view,
                color: AppColors.primary,
              ),
              label: 'Perintah',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: controller.unreadCount > 0,
                label: Text(
                  '${controller.unreadCount}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: Icon(
                  Icons.notifications_outlined,
                  color: controller.selectedIndex.value == 3
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
              selectedIcon: Badge(
                isLabelVisible: controller.unreadCount > 0,
                label: Text(
                  '${controller.unreadCount}',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(
                  Icons.notifications,
                  color: AppColors.primary,
                ),
              ),
              label: 'Notifikasi',
            ),
            NavigationDestination(
              icon: Icon(
                Icons.person_outline,
                color: controller.selectedIndex.value == 4
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              selectedIcon: const Icon(Icons.person, color: AppColors.primary),
              label: 'Akun',
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== NOTIFIKASI TAB ====================
class _NotifikasiTab extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifikasi',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (controller.unreadCount > 0)
                    TextButton(
                      onPressed: () {
                        // Mark all as read
                        for (var notif in controller.notifications) {
                          notif.isRead = true;
                        }
                        controller.notifications.refresh();
                      },
                      child: const Text(
                        'Tandai Semua Dibaca',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Obx(
                () => controller.notifications.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Belum ada notifikasi',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.notifications.length,
                        itemBuilder: (context, index) {
                          final notif = controller.notifications[index];
                          return _NotificationItem(notification: notif);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final NotificationItem notification;
  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.surface
            : AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: notification.isRead
            ? null
            : Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getNotificationColor(
                notification.type,
              ).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getNotificationIcon(notification.type),
              color: _getNotificationColor(notification.type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notification.title,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: notification.isRead
                        ? FontWeight.normal
                        : FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notification.message,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(notification.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'geofence_enter':
        return Icons.login;
      case 'geofence_exit':
        return Icons.logout;
      case 'speed':
        return Icons.speed;
      case 'engine':
        return Icons.power;
      case 'sos':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'geofence_enter':
        return AppColors.success;
      case 'geofence_exit':
        return AppColors.danger;
      case 'speed':
        return AppColors.warning;
      case 'engine':
        return Colors.blue;
      case 'sos':
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  String _formatTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    return '${time.day}/${time.month}/${time.year}';
  }
}

// ==================== PLAYBACK TAB ====================
class _PlaybackTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Initialize PlaybackController if not exists
    if (!Get.isRegistered<PlaybackController>()) {
      Get.put(PlaybackController());
    }
    return const PlaybackView();
  }
}

// ==================== BERANDA TAB WITH MULTIPLE MAP PROVIDERS ====================
class _BerandaTab extends GetView<HomeController> {
  const _BerandaTab();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Widget based on selected provider
        Obx(() => _buildMap()),
        // Loading indicator
        Obx(
          () => controller.isLoading.value
              ? Container(
                  color: AppColors.shadow,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : const SizedBox(),
        ),
        // Top Bar with vehicle selector
        Positioned(top: 16, left: 16, right: 16, child: _VehicleSelector()),
        // Map Controls
        Positioned(
          right: 16,
          top: 100,
          child: Column(
            children: [
              _MapControlButton(
                icon: Icons.layers,
                onTap: controller.showMapProviderSelector,
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.refresh,
                onTap: controller.refreshData,
              ),
              const SizedBox(height: 8),
              _MapControlButton(
                icon: Icons.my_location,
                onTap: controller.centerOnVehicle,
              ),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.add, onTap: controller.zoomIn),
              const SizedBox(height: 8),
              _MapControlButton(icon: Icons.remove, onTap: controller.zoomOut),
            ],
          ),
        ),

        // Bottom Vehicle Info Card
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Obx(
            () => _VehicleInfoCard(
              device: controller.selectedDevice.value,
              position: controller.selectedPosition,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    final device = controller.selectedDevice.value;
    final position = device != null ? controller.positions[device.id] : null;
    final lat = position?.latitude ?? -6.2088;
    final lng = position?.longitude ?? 106.8456;

    // All map providers use flutter_map with LocationIQ as default
    return FlutterMap(
      mapController: controller.osmMapController,
      options: MapOptions(
        initialCenter: latlong.LatLng(lat, lng),
        initialZoom: 15,
      ),
      children: [
        TileLayer(
          urlTemplate: controller.currentTileUrl,
          userAgentPackageName: 'com.topan.topanTracking',
        ),
        // Vehicle markers
        MarkerLayer(
          markers: controller.devices
              .map((d) {
                final pos = controller.positions[d.id];
                if (pos == null) return null;
                return Marker(
                  point: latlong.LatLng(pos.latitude, pos.longitude),
                  width: 50,
                  height: 50,
                  child: _VehicleMarker(
                    device: d,
                    position: pos,
                    isSelected: controller.selectedDevice.value?.id == d.id,
                  ),
                );
              })
              .whereType<Marker>()
              .toList(),
        ),
        // Circle for selected vehicle
        if (position != null)
          CircleLayer(
            circles: [
              CircleMarker(
                point: latlong.LatLng(position.latitude, position.longitude),
                radius: 50,
                color: AppColors.primary.withValues(alpha: 0.1),
                borderColor: AppColors.primary.withValues(alpha: 0.5),
                borderStrokeWidth: 2,
              ),
            ],
          ),
      ],
    );
  }
}

class _VehicleMarker extends StatelessWidget {
  final TraccarDevice device;
  final TraccarPosition position;
  final bool isSelected;
  const _VehicleMarker({
    required this.device,
    required this.position,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final markerColor = isSelected
        ? AppColors.primary
        : (device.isOnline ? AppColors.success : AppColors.danger);

    return GestureDetector(
      onTap: () => Get.find<HomeController>().showVehicleOptions(device),
      child: SizedBox(
        width: 50,
        height: 50,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: markerColor,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  _getDeviceIcon(device.category),
                  color: AppColors.onPrimary,
                  size: 16,
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: markerColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'motorcycle':
      case 'motor':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      case 'bus':
        return Icons.directions_bus;
      case 'boat':
        return Icons.directions_boat;
      default:
        return Icons.directions_car;
    }
  }
}

class _MapControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _MapControlButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
    );
  }
}

class _VehicleSelector extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () => _showVehicleList(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDeviceIcon(controller.selectedDevice.value?.category),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      controller.selectedDevice.value?.name ??
                          'Pilih Kendaraan',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      controller.selectedDevice.value?.uniqueId ?? '-',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'motorcycle':
      case 'motor':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }

  void _showVehicleList(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pilih Kendaraan',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Obx(
                () => controller.devices.isEmpty
                    ? const Center(
                        child: Text(
                          'Tidak ada kendaraan',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: controller.devices.length,
                        itemBuilder: (context, index) {
                          final device = controller.devices[index];
                          return _VehicleListItem(device: device);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleListItem extends GetView<HomeController> {
  final TraccarDevice device;
  const _VehicleListItem({required this.device});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GestureDetector(
        onTap: () {
          controller.selectDevice(device);
          Get.back();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: controller.selectedDevice.value?.id == device.id
                ? AppColors.primary.withValues(alpha: 0.2)
                : AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: controller.selectedDevice.value?.id == device.id
                  ? AppColors.primary
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _getDeviceIcon(device.category),
                color: device.isOnline
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      device.uniqueId,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: device.isOnline
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.danger.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  device.statusText,
                  style: TextStyle(
                    color: device.isOnline ? AppColors.success : AppColors.danger,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String? category) {
    switch (category?.toLowerCase()) {
      case 'motorcycle':
      case 'motor':
        return Icons.two_wheeler;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.directions_car;
    }
  }
}

class _VehicleInfoCard extends StatelessWidget {
  final TraccarDevice? device;
  final TraccarPosition? position;
  const _VehicleInfoCard({this.device, this.position});

  @override
  Widget build(BuildContext context) {
    if (device == null) return const SizedBox();

    final speed = position?.speedKmh ?? 0;
    final battery = position?.batteryLevel;
    final ignition = position?.ignitionStatus;
    final ignitionColor = switch (ignition) {
      true => AppColors.success,
      false => AppColors.danger,
      null => AppColors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device!.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
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
                            color: device!.isOnline ? AppColors.success : AppColors.danger,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device!.statusText,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: ignitionColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(switch (ignition) {
                  true => Icons.power,
                  false => Icons.power_off,
                  null => Icons.help_outline,
                }, color: ignitionColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _InfoItem(
                icon: Icons.speed,
                value: speed.toStringAsFixed(0),
                unit: 'km/jam',
              ),
              const SizedBox(width: 24),
              if (battery != null)
                _InfoItem(
                  icon: Icons.battery_charging_full,
                  value: '$battery',
                  unit: '%',
                  valueColor: battery > 60
                      ? AppColors.success
                      : battery > 30
                      ? AppColors.warning
                      : AppColors.danger,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final Color? valueColor;
  const _InfoItem({
    required this.icon,
    required this.value,
    required this.unit,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          unit,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

// ==================== PERINTAH TAB ====================
class _PerintahTab extends GetView<HomeController> {
  const _PerintahTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pusat Kendali',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Obx(
            () => Text(
              controller.selectedDevice.value?.name ?? 'Pilih kendaraan',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          // Engine Control Card with Switch
          _EngineControlCard(),
          const SizedBox(height: 16),
          // Request Position Card
          Obx(() {
            final isRequesting = controller.isPositionRequestLoading.value;
            return _CommandCard(
              icon: Icons.gps_fixed,
              title: 'Permintaan Posisi',
              subtitle: isRequesting
                  ? 'Menghubungi server…'
                  : 'Minta posisi terbaru dari perangkat GPS',
              color: AppColors.primary,
              onTap: isRequesting ? null : controller.requestPosition,
              fullWidth: true,
            );
          }),
          const SizedBox(height: 24),
          // Command History
          _CommandHistorySection(),
        ],
      ),
    );
  }
}

class _EngineControlCard extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final ignition = controller.ignitionStatus;
      final isSending = controller.isCommandLoading.value;
      final (status, color, icon) = switch (ignition) {
        true => ('Kontak aktif', AppColors.success, Icons.power),
        false => ('Kontak mati', AppColors.danger, Icons.power_off),
        null => (
          'Status kontak belum tersedia',
          AppColors.textSecondary,
          Icons.help_outline,
        ),
      };
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.3),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kontrol Mesin',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (isSending)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Tooltip(
                message: ignition == true
                    ? 'Kirim perintah putus akses mesin'
                    : 'Kirim perintah pulihkan akses mesin',
                child: Switch(
                  value: ignition == true,
                  onChanged: ignition == null ? null : controller.toggleEngine,
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _CommandCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback? onTap;
  final bool fullWidth;

  const _CommandCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: fullWidth
            ? Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: color, size: 16),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
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
    );
  }
}

class _CommandHistorySection extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Riwayat Perintah',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Obx(
          () => controller.commandHistory.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      'Belum ada riwayat perintah',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              : Column(
                  children: controller.commandHistory
                      .take(5)
                      .map((cmd) => _CommandHistoryItemWidget(command: cmd))
                      .toList(),
                ),
        ),
      ],
    );
  }
}

class _CommandHistoryItemWidget extends GetView<HomeController> {
  final CommandHistoryItem command;
  const _CommandHistoryItemWidget({required this.command});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: command.isSuccess
                  ? AppColors.success.withValues(alpha: 0.2)
                  : AppColors.danger.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              command.isSuccess ? Icons.check : Icons.close,
              color: command.isSuccess ? AppColors.success : AppColors.danger,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  command.command,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '${command.status} · ${controller.formatDateTime(command.timestamp)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                if (command.errorMessage case final error?)
                  Text(
                    error,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== AKUN TAB ====================
class _AkunTab extends GetView<HomeController> {
  const _AkunTab();

  @override
  Widget build(BuildContext context) {
    final traccarApi = Get.find<TraccarApiService>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 20),
          // Profile Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.2),
                  AppColors.secondary.withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.surface,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  traccarApi.currentUser?.name ?? 'Pengguna',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  traccarApi.currentUser?.email ?? '',
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 16),
                // Stats Row
                Obx(
                  () => Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatItem(
                        value: '${controller.devices.length}',
                        label: 'Kendaraan',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      _StatItem(
                        value: '${controller.tripHistory.length}',
                        label: 'Perjalanan',
                      ),
                      Container(
                        width: 1,
                        height: 30,
                        color: AppColors.textSecondary.withValues(alpha: 0.3),
                      ),
                      _StatItem(
                        value: '${controller.commandHistory.length}',
                        label: 'Perintah',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Menu Items
          _MenuItem(
            icon: Icons.assessment_outlined,
            title: 'Laporan',
            subtitle: 'Laporan perjalanan & statistik',
            onTap: () => Get.toNamed('/reports'),
          ),
          _MenuItem(
            icon: Icons.people_outline,
            title: 'Pengemudi',
            subtitle: 'Kelola data pengemudi',
            onTap: () => Get.toNamed('/drivers'),
          ),
          _MenuItem(
            icon: Icons.build_circle_outlined,
            title: 'Pengingat Servis',
            subtitle: 'Jadwal maintenance kendaraan',
            onTap: () => Get.toNamed('/maintenance'),
          ),
          _MenuItem(
            icon: Icons.fence_outlined,
            title: 'Zona Aman',
            subtitle: 'Kelola geofence kendaraan',
            onTap: () => Get.toNamed('/geofence'),
          ),
          _MenuItem(
            icon: Icons.security_outlined,
            title: 'Keamanan',
            subtitle: 'Ubah password & PIN',
            onTap: () => _showSecuritySheet(context),
          ),
          _MenuItem(
            icon: Icons.help_outline,
            title: 'Bantuan',
            subtitle: 'FAQ & Hubungi kami',
            onTap: () => _showHelpSheet(context),
          ),
          _MenuItem(
            icon: Icons.info_outline,
            title: 'Tentang Aplikasi',
            subtitle: 'Versi 1.0.0',
            onTap: () => _showAboutSheet(context),
          ),
          const SizedBox(height: 16),
          // Logout Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: controller.logout,
              icon: const Icon(Icons.logout, color: AppColors.danger),
              label: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.danger),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showSecuritySheet(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final isLoading = false.obs;
    final obscureCurrent = true.obs;
    final obscureNew = true.obs;
    final obscureConfirm = true.obs;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.security, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Ubah Password',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Current Password
              Obx(
                () => TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent.value,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password Saat Ini',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          obscureCurrent.value = !obscureCurrent.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // New Password
              Obx(
                () => TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew.value,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () => obscureNew.value = !obscureNew.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Confirm Password
              Obx(
                () => TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm.value,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password Baru',
                    labelStyle: const TextStyle(color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm.value
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          obscureConfirm.value = !obscureConfirm.value,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Save Button
              Obx(
                () => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () async {
                            if (newPasswordController.text !=
                                confirmPasswordController.text) {
                              Get.snackbar(
                                'Error',
                                'Password baru tidak cocok',
                                backgroundColor: AppColors.danger,
                                colorText: AppColors.onPrimary,
                              );
                              return;
                            }
                            if (newPasswordController.text.length < 6) {
                              Get.snackbar(
                                'Error',
                                'Password minimal 6 karakter',
                                backgroundColor: AppColors.danger,
                                colorText: AppColors.onPrimary,
                              );
                              return;
                            }
                            isLoading.value = true;
                            final result = await Get.find<TraccarApiService>()
                                .changePassword(
                                  currentPassword:
                                      currentPasswordController.text,
                                  newPassword: newPasswordController.text,
                                );
                            isLoading.value = false;
                            if (!result.success) {
                              Get.snackbar(
                                'Gagal',
                                result.error ?? 'Gagal mengganti password',
                                backgroundColor: AppColors.danger,
                                colorText: AppColors.onPrimary,
                              );
                              return;
                            }
                            Get.back();
                            Get.snackbar(
                              'Berhasil',
                              'Password berhasil diubah',
                              backgroundColor: AppColors.success,
                              colorText: AppColors.onPrimary,
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Text(
                            'Simpan Password',
                            style: TextStyle(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showHelpSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.help_outline,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Bantuan',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // FAQ Section
              const Text(
                'FAQ',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _FaqItem(
                question: 'Bagaimana cara melacak kendaraan?',
                answer:
                    'Pilih kendaraan dari daftar di halaman Beranda, lalu posisi kendaraan akan ditampilkan di peta secara real-time.',
              ),
              _FaqItem(
                question: 'Bagaimana cara mematikan mesin dari jarak jauh?',
                answer:
                    'Buka menu Perintah, lalu gunakan switch untuk mematikan atau menyalakan mesin kendaraan.',
              ),
              _FaqItem(
                question: 'Bagaimana cara melihat riwayat perjalanan?',
                answer:
                    'Gunakan fitur Playback di navigasi bawah untuk melihat rute perjalanan kendaraan.',
              ),
              _FaqItem(
                question: 'Bagaimana cara mengatur zona aman?',
                answer:
                    'Buka menu Akun → Zona Aman, lalu atur radius dan pilih kendaraan yang ingin dipantau.',
              ),
              const SizedBox(height: 24),
              // Contact Section
              const Text(
                'Hubungi Kami',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _ContactItem(
                icon: Icons.email_outlined,
                title: 'Email',
                value: 'tarmizy.harsha@gmail.com',
                onTap: () async {
                  final url = Uri.parse('mailto:tarmizy.harsha@gmail.com');
                  await launchUrl(url);
                },
              ),
              _ContactItem(
                icon: Icons.phone_outlined,
                title: 'Telepon',
                value: '+62 823-1225-5030',
                onTap: () async {
                  final url = Uri.parse('tel:+6282312255030');
                  await launchUrl(url);
                },
              ),
              _ContactItem(
                icon: Icons.chat_outlined,
                title: 'WhatsApp',
                value: '+62 823-1225-5030',
                onTap: () async {
                  final url = Uri.parse('https://wa.me/6282312255030');
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _showAboutSheet(BuildContext context) {
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
            // App Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.3),
                    AppColors.secondary.withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Topan Tracking',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Versi 1.0.0',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Topan Tracking adalah aplikasi pelacakan kendaraan real-time yang membantu Anda memantau armada kendaraan dengan mudah dan efisien.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Features
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FeatureItem(icon: Icons.gps_fixed, label: 'Real-time'),
                _FeatureItem(icon: Icons.security, label: 'Aman'),
                _FeatureItem(icon: Icons.speed, label: 'Cepat'),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              '© 2024 Topan Tracking. All rights reserved.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  const _FaqItem({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,
        title: Text(
          question,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;
  const _ContactItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
