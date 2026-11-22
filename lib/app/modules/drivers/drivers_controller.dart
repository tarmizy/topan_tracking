import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/models/traccar_models.dart';
import '../../core/utils/currency_formatter.dart';

class DriversController extends GetxController {
  final TraccarApiService _traccarApi = Get.find<TraccarApiService>();

  final drivers = <TraccarDriver>[].obs;
  final devices = <TraccarDevice>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;

  List<TraccarDriver> get filteredDrivers {
    if (searchQuery.value.isEmpty) return drivers;
    return drivers
        .where(
          (d) =>
              d.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
              d.uniqueId.toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
        )
        .toList();
  }

  // Calculate total rental for a driver
  double calculateTotalRental(TraccarDriver driver) {
    if (!driver.isActive || driver.rentalStartDate == null) return 0;
    final days = DateTime.now().difference(driver.rentalStartDate!).inDays + 1;
    return days * driver.dailyRate;
  }

  // Get device name by id
  String getDeviceName(int? deviceId) {
    if (deviceId == null) return 'Tidak ada';
    final device = devices.firstWhereOrNull((d) => d.id == deviceId);
    return device?.name ?? 'Device #$deviceId';
  }

  @override
  void onInit() {
    super.onInit();
    loadDrivers();
    loadDevices();
  }

  Future<void> loadDrivers() async {
    isLoading.value = true;
    final result = await _traccarApi.getDrivers();
    if (result.success && result.data != null) {
      drivers.value = result.data!;
    }
    isLoading.value = false;
  }

  Future<void> loadDevices() async {
    final result = await _traccarApi.getDevices();
    if (result.success && result.data != null) {
      devices.value = result.data!;
    }
  }

  void showAddDriverDialog() {
    final nameController = TextEditingController();
    final uniqueIdController = TextEditingController();
    final phoneController = TextEditingController();
    final dailyRateController = TextEditingController();

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Tambah Pengemudi',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTextField(nameController, 'Nama Pengemudi', Icons.person),
              const SizedBox(height: 12),
              _buildTextField(uniqueIdController, 'No. KTP / SIM', Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(phoneController, 'No. Telepon', Icons.phone),
              const SizedBox(height: 12),
              _buildCurrencyField(
                dailyRateController,
                'Biaya Sewa/Hari (Rp)',
                Icons.attach_money,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty ||
                  uniqueIdController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'Nama dan No. KTP/SIM harus diisi',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: AppColors.danger,
                  colorText: AppColors.onPrimary,
                );
                return;
              }
              Get.back();
              await addDriver(
                name: nameController.text,
                uniqueId: uniqueIdController.text,
                phone: phoneController.text.isEmpty
                    ? null
                    : phoneController.text,
                dailyRate: parseFormattedNumber(dailyRateController.text),
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

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildCurrencyField(
    TextEditingController controller,
    String label,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [ThousandsSeparatorFormatter()],
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        prefixText: 'Rp ',
        prefixStyle: const TextStyle(color: AppColors.textPrimary),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Future<void> addDriver({
    required String name,
    required String uniqueId,
    String? phone,
    double dailyRate = 0,
  }) async {
    isLoading.value = true;
    final result = await _traccarApi.createDriver(
      TraccarDriver.create(
        name: name,
        uniqueId: uniqueId,
        phone: phone,
        dailyRate: dailyRate,
      ),
    );

    if (result.success) {
      await loadDrivers();
      Get.snackbar(
        'Berhasil',
        'Pengemudi berhasil ditambahkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
    } else {
      Get.snackbar(
        'Gagal',
        result.error ?? 'Gagal menambahkan pengemudi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.onPrimary,
      );
    }
    isLoading.value = false;
  }

  Future<void> toggleDriverStatus(TraccarDriver driver) async {
    isLoading.value = true;

    final newAttributes = Map<String, dynamic>.from(driver.attributes ?? {});
    final newIsActive = !driver.isActive;
    newAttributes['isActive'] = newIsActive;

    if (newIsActive) {
      newAttributes['rentalStartDate'] = DateTime.now().toIso8601String();
    } else {
      newAttributes.remove('rentalStartDate');
    }

    final updatedDriver = driver.copyWith(attributes: newAttributes);
    final result = await _traccarApi.updateDriver(updatedDriver);

    if (result.success) {
      await loadDrivers();
      Get.snackbar(
        'Berhasil',
        newIsActive ? 'Pengemudi diaktifkan' : 'Pengemudi dinonaktifkan',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
    } else {
      Get.snackbar(
        'Gagal',
        result.error ?? 'Gagal mengupdate status',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.onPrimary,
      );
    }
    isLoading.value = false;
  }

  // Check if device is already assigned to an active driver
  bool isDeviceAvailable(int deviceId, {int? excludeDriverId}) {
    for (final driver in drivers) {
      if (driver.id == excludeDriverId) continue;
      if (driver.deviceId == deviceId && driver.isActive) {
        return false; // Device is already assigned to another active driver
      }
    }
    return true;
  }

  // Get driver who is using a device
  TraccarDriver? getDriverByDevice(int deviceId) {
    return drivers.firstWhereOrNull(
      (d) => d.deviceId == deviceId && d.isActive,
    );
  }

  Future<void> assignToDevice(TraccarDriver driver, int? deviceId) async {
    // Check if device is available
    if (deviceId != null &&
        !isDeviceAvailable(deviceId, excludeDriverId: driver.id)) {
      final existingDriver = getDriverByDevice(deviceId);
      Get.snackbar(
        'Gagal',
        'Kendaraan sudah digunakan oleh ${existingDriver?.name ?? "pengemudi lain"} yang sedang aktif',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.onPrimary,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    isLoading.value = true;

    // Use withDeviceId helper to update attributes
    final updatedDriver = driver.withDeviceId(deviceId);
    final result = await _traccarApi.updateDriver(updatedDriver);

    if (result.success) {
      await loadDrivers();
      Get.snackbar(
        'Berhasil',
        deviceId != null
            ? 'Pengemudi berhasil di-assign'
            : 'Pengemudi di-unassign',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.success,
        colorText: AppColors.onPrimary,
      );
    } else {
      Get.snackbar(
        'Gagal',
        result.error ?? 'Gagal assign pengemudi',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.danger,
        colorText: AppColors.onPrimary,
      );
    }
    isLoading.value = false;
  }

  void showAssignDialog(TraccarDriver driver) {
    final selectedDevice = Rxn<TraccarDevice>();
    if (driver.deviceId != null) {
      selectedDevice.value = devices.firstWhereOrNull(
        (d) => d.id == driver.deviceId,
      );
    }

    Get.dialog(
      AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Assign ke Kendaraan',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pengemudi: ${driver.name}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TraccarDevice?>(
                    value: selectedDevice.value,
                    hint: const Text(
                      'Pilih Kendaraan',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    dropdownColor: AppColors.surface,
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<TraccarDevice?>(
                        value: null,
                        child: Text(
                          'Tidak ada',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                      ...devices.map((d) {
                        final isAvailable = isDeviceAvailable(
                          d.id,
                          excludeDriverId: driver.id,
                        );
                        final usingDriver = getDriverByDevice(d.id);
                        return DropdownMenuItem(
                          value: d,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  d.name,
                                  style: TextStyle(
                                    color: isAvailable
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              if (!isAvailable && usingDriver != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    usingDriver.name,
                                    style: const TextStyle(
                                      color: AppColors.warning,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (v) => selectedDevice.value = v,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kendaraan yang sudah digunakan pengemudi aktif tidak dapat dipilih',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              Get.back();
              assignToDevice(driver, selectedDevice.value?.id);
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

  Future<void> deleteDriver(int id) async {
    final confirm = await Get.dialog<bool>(
      AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Hapus Pengemudi',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: const Text(
          'Yakin ingin menghapus pengemudi ini?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Get.back(result: true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus', style: TextStyle(color: AppColors.textPrimary)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      isLoading.value = true;
      final result = await _traccarApi.deleteDriver(id);
      if (result.success) {
        drivers.removeWhere((d) => d.id == id);
        Get.snackbar(
          'Berhasil',
          'Pengemudi berhasil dihapus',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: AppColors.success,
          colorText: AppColors.onPrimary,
        );
      }
      isLoading.value = false;
    }
  }

  void showDriverDetail(TraccarDriver driver) {
    final totalRental = calculateTotalRental(driver);
    final rentalDays = driver.rentalStartDate != null
        ? DateTime.now().difference(driver.rentalStartDate!).inDays + 1
        : 0;

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
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: driver.isActive
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.primary.withValues(alpha: 0.2),
                    child: Icon(
                      Icons.person,
                      size: 30,
                      color: driver.isActive
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: driver.isActive
                                ? AppColors.success.withValues(alpha: 0.2)
                                : AppColors.textSecondary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            driver.isActive ? 'AKTIF' : 'NONAKTIF',
                            style: TextStyle(
                              color: driver.isActive
                                  ? AppColors.success
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Toggle switch
                  Switch(
                    value: driver.isActive,
                    onChanged: (_) {
                      Get.back();
                      toggleDriverStatus(driver);
                    },
                    activeTrackColor: AppColors.success.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Info rows
              _buildDetailRow(Icons.badge, 'No. KTP/SIM', driver.uniqueId),
              if (driver.phone != null)
                _buildDetailRow(Icons.phone, 'Telepon', driver.phone!),
              _buildDetailRow(
                Icons.directions_car,
                'Kendaraan',
                getDeviceName(driver.deviceId),
              ),
              _buildDetailRow(
                Icons.attach_money,
                'Biaya/Hari',
                'Rp ${_formatNumber(driver.dailyRate)}',
              ),

              if (driver.isActive && driver.rentalStartDate != null) ...[
                const Divider(color: AppColors.textSecondary, height: 32),
                const Text(
                  'LAPORAN SEWA',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Mulai Sewa',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            _formatDate(driver.rentalStartDate!),
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Durasi',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          Text(
                            '$rentalDays hari',
                            style: const TextStyle(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.textSecondary, height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Biaya',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Rp ${_formatNumber(totalRental)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        showAssignDialog(driver);
                      },
                      icon: const Icon(
                        Icons.directions_car,
                        color: AppColors.primary,
                      ),
                      label: const Text(
                        'Assign',
                        style: TextStyle(color: AppColors.primary),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        deleteDriver(driver.id!);
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
                ],
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppColors.textPrimary),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    return number
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
