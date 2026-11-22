import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import '../../data/models/traccar_models.dart';
import 'drivers_controller.dart';

class DriversView extends GetView<DriversController> {
  const DriversView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Pengemudi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadDrivers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showAddDriverDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: Column(
        children: [
          // Summary cards
          Obx(() {
            final activeDrivers = controller.drivers
                .where((d) => d.isActive)
                .length;
            final totalRental = controller.drivers
                .where((d) => d.isActive)
                .fold<double>(
                  0,
                  (sum, d) => sum + controller.calculateTotalRental(d),
                );

            return Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.people,
                      label: 'Total',
                      value: '${controller.drivers.length}',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.check_circle,
                      label: 'Aktif',
                      value: '$activeDrivers',
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryCard(
                      icon: Icons.attach_money,
                      label: 'Total Sewa',
                      value: 'Rp ${_formatNumber(totalRental)}',
                      color: AppColors.warning,
                      isSmallText: true,
                    ),
                  ),
                ],
              ),
            );
          }),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) => controller.searchQuery.value = value,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Cari pengemudi...',
                hintStyle: const TextStyle(color: AppColors.textSecondary),
                prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Driver list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final drivers = controller.filteredDrivers;

              if (drivers.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_off,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada pengemudi',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: controller.showAddDriverDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Pengemudi'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: drivers.length,
                itemBuilder: (context, index) {
                  return _DriverCard(driver: drivers[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}jt';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(0)}rb';
    }
    return number.toStringAsFixed(0);
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isSmallText;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.isSmallText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: isSmallText ? 12 : 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }
}

class _DriverCard extends GetView<DriversController> {
  final TraccarDriver driver;
  const _DriverCard({required this.driver});

  @override
  Widget build(BuildContext context) {
    final totalRental = controller.calculateTotalRental(driver);

    return GestureDetector(
      onTap: () => controller.showDriverDetail(driver),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: driver.isActive
              ? Border.all(color: AppColors.success.withValues(alpha: 0.5))
              : null,
        ),
        child: Row(
          children: [
            // Avatar with status indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: driver.isActive
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    driver.name.isNotEmpty ? driver.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: driver.isActive
                          ? AppColors.success
                          : AppColors.primary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (driver.isActive)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
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
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.directions_car,
                        size: 12,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          controller.getDeviceName(driver.deviceId),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (driver.isActive && totalRental > 0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Rp ${_formatNumber(totalRental)}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: driver.isOverdue
                        ? AppColors.danger.withValues(alpha: 0.15)
                        : driver.isActive
                        ? AppColors.success.withValues(alpha: 0.2)
                        : AppColors.textSecondary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    driver.isOverdue
                        ? 'Terlambat'
                        : driver.isActive
                        ? 'Aktif'
                        : 'Nonaktif',
                    style: TextStyle(
                      color: driver.isOverdue
                          ? AppColors.danger
                          : driver.isActive
                          ? AppColors.success
                          : AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${_formatNumber(driver.dailyRate)}/hari',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
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
}
