import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/services/vehicle_service.dart';
import '../../data/models/traccar_models.dart';

class MaintenanceController extends GetxController {
  final TraccarApiService _traccarApi = Get.find<TraccarApiService>();
  final VehicleService _vehicleService = Get.find<VehicleService>();

  RxList<TraccarDevice> get devices => _vehicleService.devices;
  final maintenanceList = <MaintenanceItem>[].obs;
  final isLoading = false.obs;

  // Filter
  final selectedFilter = 'all'.obs; // all, upcoming, overdue, completed

  List<MaintenanceItem> get filteredMaintenance {
    switch (selectedFilter.value) {
      case 'upcoming':
        return maintenanceList
            .where((m) => m.status == MaintenanceStatus.upcoming)
            .toList();
      case 'overdue':
        return maintenanceList
            .where((m) => m.status == MaintenanceStatus.overdue)
            .toList();
      case 'completed':
        return maintenanceList
            .where((m) => m.status == MaintenanceStatus.completed)
            .toList();
      default:
        return maintenanceList;
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadMaintenance();
  }

  Future<void> loadMaintenance() async {
    isLoading.value = true;
    final result = await _traccarApi.getMaintenance();
    if (result.success && result.data != null) {
      maintenanceList.value = result.data!.map((m) {
        // Calculate status based on current values
        final device = devices.firstWhereOrNull((d) => d.id == m.deviceId);
        return m.copyWithStatus(device);
      }).toList();
    }
    isLoading.value = false;
  }

  void showAddMaintenanceDialog() {
    final nameController = TextEditingController();
    final startController = TextEditingController();
    final periodController = TextEditingController();
    final selectedDevice = Rxn<TraccarDevice>();
    final selectedType = 'distance'.obs; // distance or time

    Get.dialog(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Pengingat Servis',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Device selector
              const Text(
                'Kendaraan',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<TraccarDevice>(
                      value: selectedDevice.value,
                      hint: const Text(
                        'Pilih Kendaraan',
                        style: TextStyle(color: Colors.grey),
                      ),
                      dropdownColor: const Color(0xFF1A1A1A),
                      isExpanded: true,
                      items: devices.map((device) {
                        return DropdownMenuItem(
                          value: device,
                          child: Text(
                            device.name,
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                      onChanged: (device) => selectedDevice.value = device,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              _buildTextField(
                nameController,
                'Nama Servis',
                'Contoh: Ganti Oli, Servis Rutin',
              ),
              const SizedBox(height: 16),

              // Type selector
              const Text(
                'Tipe Pengingat',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _buildTypeButton(
                        'Jarak (KM)',
                        Icons.straighten,
                        selectedType.value == 'distance',
                        () => selectedType.value = 'distance',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildTypeButton(
                        'Waktu (Hari)',
                        Icons.calendar_today,
                        selectedType.value == 'time',
                        () => selectedType.value = 'time',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Start value
              Obx(
                () => _buildTextField(
                  startController,
                  selectedType.value == 'distance'
                      ? 'Mulai dari (KM)'
                      : 'Mulai dari (Hari)',
                  selectedType.value == 'distance'
                      ? 'Contoh: 50000'
                      : 'Contoh: 30',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(height: 12),

              // Period
              Obx(
                () => _buildTextField(
                  periodController,
                  selectedType.value == 'distance'
                      ? 'Interval (KM)'
                      : 'Interval (Hari)',
                  selectedType.value == 'distance'
                      ? 'Contoh: 5000'
                      : 'Contoh: 90',
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (selectedDevice.value == null || nameController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Lengkapi semua field',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              Get.back();
              await addMaintenance(
                deviceId: selectedDevice.value!.id,
                name: nameController.text,
                type: selectedType.value,
                start: double.tryParse(startController.text) ?? 0,
                period: double.tryParse(periodController.text) ?? 0,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D4FF),
            ),
            child: const Text('Simpan', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(color: Colors.grey),
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
        filled: true,
        fillColor: const Color(0xFF0A0A0A),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String label,
    IconData icon,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00D4FF).withValues(alpha: 0.2)
              : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00D4FF) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? const Color(0xFF00D4FF) : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF00D4FF) : Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addMaintenance({
    required int deviceId,
    required String name,
    required String type,
    required double start,
    required double period,
  }) async {
    isLoading.value = true;
    final result = await _traccarApi.createMaintenance(
      MaintenanceItem(
        name: name,
        type: type,
        start: start,
        period: period,
        deviceId: deviceId,
      ),
    );

    if (result.success) {
      await loadMaintenance();
      Get.snackbar(
        'Berhasil',
        'Pengingat servis berhasil ditambahkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      Get.snackbar(
        'Gagal',
        result.error ?? 'Gagal menambahkan pengingat',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }

  Future<void> deleteMaintenance(int id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Hapus Pengingat',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Yakin ingin menghapus pengingat ini?',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      isLoading.value = true;
      final result = await _traccarApi.deleteMaintenance(id);
      if (result.success) {
        maintenanceList.removeWhere((m) => m.id == id);
        Get.snackbar(
          'Berhasil',
          'Pengingat berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
      }
      isLoading.value = false;
    }
  }

  Future<void> markAsCompleted(MaintenanceItem item) async {
    // Update the maintenance start value to current + period
    isLoading.value = true;
    final newStart = item.start + item.period;
    final result = await _traccarApi.updateMaintenance(
      item.copyWith(start: newStart),
    );

    if (result.success) {
      await loadMaintenance();
      Get.snackbar(
        'Berhasil',
        'Servis ditandai selesai',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    }
    isLoading.value = false;
  }

  String getDeviceName(int? deviceId) {
    if (deviceId == null) return 'Semua Kendaraan';
    final device = devices.firstWhereOrNull((d) => d.id == deviceId);
    return device?.name ?? 'Unknown';
  }
}

enum MaintenanceStatus { upcoming, overdue, completed }

class MaintenanceItem {
  final int? id;
  final String name;
  final String type; // 'distance' or 'time'
  final double start;
  final double period;
  final int? deviceId;
  final MaintenanceStatus status;
  final Map<String, dynamic>? attributes;

  MaintenanceItem({
    this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.period,
    this.deviceId,
    this.status = MaintenanceStatus.upcoming,
    this.attributes,
  });

  factory MaintenanceItem.fromJson(Map<String, dynamic> json) {
    return MaintenanceItem(
      id: json['id'],
      name: json['name'] ?? '',
      type: json['type'] ?? 'distance',
      start: (json['start'] ?? 0).toDouble(),
      period: (json['period'] ?? 0).toDouble(),
      deviceId: json['deviceId'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'type': type,
      'start': start,
      'period': period,
      if (deviceId != null) 'deviceId': deviceId,
      if (attributes != null) 'attributes': attributes,
    };
  }

  MaintenanceItem copyWith({double? start, MaintenanceStatus? status}) {
    return MaintenanceItem(
      id: id,
      name: name,
      type: type,
      start: start ?? this.start,
      period: period,
      deviceId: deviceId,
      status: status ?? this.status,
      attributes: attributes,
    );
  }

  MaintenanceItem copyWithStatus(TraccarDevice? device) {
    // Calculate status based on device's current odometer or time
    MaintenanceStatus newStatus = MaintenanceStatus.upcoming;

    if (device != null) {
      if (type == 'distance') {
        final currentOdometer = device.attributes?['totalDistance'] ?? 0;
        final currentKm = (currentOdometer as num).toDouble() / 1000;
        if (currentKm >= start) {
          newStatus = MaintenanceStatus.overdue;
        } else if (currentKm >= start - (period * 0.1)) {
          newStatus = MaintenanceStatus.upcoming;
        }
      }
    }

    return copyWith(status: newStatus);
  }

  String get typeLabel => type == 'distance' ? 'KM' : 'Hari';
  String get startLabel => type == 'distance'
      ? '${start.toStringAsFixed(0)} KM'
      : '${start.toStringAsFixed(0)} Hari';
  String get periodLabel => type == 'distance'
      ? 'Setiap ${period.toStringAsFixed(0)} KM'
      : 'Setiap ${period.toStringAsFixed(0)} Hari';
}
