import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../data/models/traccar_models.dart';
import '../../data/services/vehicle_service.dart';
import '../../data/services/traccar_api_service.dart';

class GeofenceController extends GetxController {
  late final VehicleService _vehicleService;
  late final TraccarApiService _traccarApi;

  final radiusValue = 500.0.obs;
  final isEnterAlertEnabled = true.obs;
  final isExitAlertEnabled = true.obs;
  final isOutsideZone = false.obs;
  final zoneName = ''.obs;
  final isSaving = false.obs;

  // Device selection for geofence
  final selectedDeviceIds = <int>[].obs;
  final isAllDevices = true.obs;

  RxList<TraccarGeofence> get savedZones => _vehicleService.geofenceZones;
  RxList<TraccarDevice> get devices => _vehicleService.devices;

  // Map to track which devices are linked to which geofences
  final deviceGeofenceMap = <int, List<int>>{}.obs;

  // Get center from selected device position
  double get centerLat {
    final pos = _vehicleService.selectedPosition;
    return pos?.latitude ?? -6.2088;
  }

  double get centerLng {
    final pos = _vehicleService.selectedPosition;
    return pos?.longitude ?? 106.8456;
  }

  @override
  void onInit() {
    super.onInit();
    _vehicleService = Get.find<VehicleService>();
    _traccarApi = Get.find<TraccarApiService>();
    _loadDeviceGeofences();
  }

  Future<void> _loadDeviceGeofences() async {
    for (var device in devices) {
      final result = await _traccarApi.getDeviceGeofences(device.id);
      if (result.success && result.data != null) {
        deviceGeofenceMap[device.id] = result.data!;
      }
    }
  }

  void updateRadius(double value) {
    radiusValue.value = value;
  }

  void toggleEnterAlert(bool value) {
    isEnterAlertEnabled.value = value;
  }

  void toggleExitAlert(bool value) {
    isExitAlertEnabled.value = value;
  }

  void toggleAllDevices(bool value) {
    isAllDevices.value = value;
    if (value) {
      selectedDeviceIds.clear();
    }
  }

  void toggleDeviceSelection(int deviceId) {
    if (selectedDeviceIds.contains(deviceId)) {
      selectedDeviceIds.remove(deviceId);
    } else {
      selectedDeviceIds.add(deviceId);
    }
    isAllDevices.value = selectedDeviceIds.isEmpty;
  }

  bool isDeviceSelected(int deviceId) {
    return selectedDeviceIds.contains(deviceId);
  }

  List<TraccarDevice> getLinkedDevices(int geofenceId) {
    return devices.where((d) {
      final geofences = deviceGeofenceMap[d.id] ?? [];
      return geofences.contains(geofenceId);
    }).toList();
  }

  Future<void> saveGeofence() async {
    if (zoneName.value.isEmpty) {
      _showNameDialog();
      return;
    }

    isSaving.value = true;

    final success = await _vehicleService.createGeofence(
      name: zoneName.value,
      latitude: centerLat,
      longitude: centerLng,
      radiusMeters: radiusValue.value,
      description: 'Radius: $radiusText',
    );

    if (success) {
      // Link geofence to selected devices
      final newGeofence = savedZones.lastOrNull;
      if (newGeofence != null && newGeofence.id != null) {
        if (isAllDevices.value) {
          // Link to all devices
          for (var device in devices) {
            await _traccarApi.linkGeofenceToDevice(newGeofence.id!, device.id);
          }
        } else {
          // Link to selected devices only
          for (var deviceId in selectedDeviceIds) {
            await _traccarApi.linkGeofenceToDevice(newGeofence.id!, deviceId);
          }
        }
        await _loadDeviceGeofences();
      }

      Get.snackbar(
        'Berhasil',
        'Zona "${zoneName.value}" berhasil disimpan dengan radius $radiusText',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success.withValues(alpha: 0.9),
        colorText: AppColors.onPrimary,
        margin: const EdgeInsets.all(16),
      );

      // Reset
      zoneName.value = '';
      selectedDeviceIds.clear();
      isAllDevices.value = true;

      Get.back();
    } else {
      Get.snackbar(
        'Gagal',
        'Gagal menyimpan zona. Coba lagi.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger.withValues(alpha: 0.9),
        colorText: AppColors.onPrimary,
        margin: const EdgeInsets.all(16),
      );
    }

    isSaving.value = false;
  }

  void _showNameDialog() {
    final textController = TextEditingController();
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Nama Zona', style: TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: textController,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Contoh: Rumah, Kantor',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                zoneName.value = textController.text;
                Get.back();
                saveGeofence();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void showZoneDetail(TraccarGeofence zone) {
    final linkedDevices = getLinkedDevices(zone.id!);

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
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.fence,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        zone.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (zone.description != null)
                        Text(
                          zone.description!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Kendaraan Terhubung:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (linkedDevices.isEmpty)
              const Text(
                'Tidak ada kendaraan terhubung',
                style: TextStyle(color: Colors.white70),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: linkedDevices.map((device) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: device.isOnline ? AppColors.success : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          device.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      deleteZone(zone.id!);
                    },
                    icon: const Icon(Icons.delete, color: AppColors.danger),
                    label: const Text(
                      'Hapus',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.danger),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showEditDevicesDialog(zone);
                    },
                    icon: const Icon(Icons.edit, color: AppColors.onPrimary),
                    label: const Text(
                      'Edit Kendaraan',
                      style: TextStyle(color: AppColors.onPrimary),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDevicesDialog(TraccarGeofence zone) {
    final currentLinked = getLinkedDevices(zone.id!).map((d) => d.id).toList();
    final tempSelected = <int>[...currentLinked].obs;

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Kendaraan untuk ${zone.name}',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Obx(
            () => ListView.builder(
              shrinkWrap: true,
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final device = devices[index];
                final isSelected = tempSelected.contains(device.id);
                return CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    if (value == true) {
                      tempSelected.add(device.id);
                    } else {
                      tempSelected.remove(device.id);
                    }
                  },
                  title: Text(
                    device.name,
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  subtitle: Text(
                    device.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: device.isOnline ? AppColors.success : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  activeColor: AppColors.primary,
                  checkColor: AppColors.onPrimary,
                );
              },
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _updateGeofenceDevices(
                zone.id!,
                currentLinked,
                tempSelected,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
            ),
            child: const Text('Simpan', style: TextStyle(color: AppColors.onPrimary)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateGeofenceDevices(
    int geofenceId,
    List<int> oldDevices,
    List<int> newDevices,
  ) async {
    isSaving.value = true;

    // Remove unlinked devices
    for (var deviceId in oldDevices) {
      if (!newDevices.contains(deviceId)) {
        await _traccarApi.unlinkGeofenceFromDevice(geofenceId, deviceId);
      }
    }

    // Add new linked devices
    for (var deviceId in newDevices) {
      if (!oldDevices.contains(deviceId)) {
        await _traccarApi.linkGeofenceToDevice(geofenceId, deviceId);
      }
    }

    await _loadDeviceGeofences();
    isSaving.value = false;

    Get.snackbar(
      'Berhasil',
      'Kendaraan berhasil diperbarui',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.9),
      colorText: AppColors.onPrimary,
    );
  }

  void deleteZone(int id) {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Zona', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Apakah Anda yakin ingin menghapus zona ini?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final success = await _vehicleService.deleteGeofence(id);
              Get.back();
              if (success) {
                await _loadDeviceGeofences();
                Get.snackbar(
                  'Berhasil',
                  'Zona berhasil dihapus',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.success.withValues(alpha: 0.9),
                  colorText: AppColors.onPrimary,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }

  String get radiusText {
    if (radiusValue.value >= 1000) {
      final km = radiusValue.value / 1000;
      if (km >= 10) return '${km.toInt()} KM';
      return '${km.toStringAsFixed(1)} KM';
    }
    return '${radiusValue.value.toInt()} M';
  }
}
