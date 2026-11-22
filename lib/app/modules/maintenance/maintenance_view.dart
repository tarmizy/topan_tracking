import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'package:get/get.dart';
import 'maintenance_controller.dart';

class MaintenanceView extends GetView<MaintenanceController> {
  const MaintenanceView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Pengingat Servis'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadMaintenance,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: controller.showAddMaintenanceDialog,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: AppColors.onPrimary),
      ),
      body: Column(
        children: [
          // Filter tabs
          _buildFilterTabs(),

          // Maintenance list
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              final items = controller.filteredMaintenance;

              if (items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.build_circle_outlined,
                        size: 64,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Belum ada pengingat servis',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: controller.showAddMaintenanceDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Pengingat'),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  return _MaintenanceCard(item: items[index]);
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      color: AppColors.surface,
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _buildFilterTab('Semua', 'all'),
            _buildFilterTab('Akan Datang', 'upcoming'),
            _buildFilterTab('Terlambat', 'overdue'),
            _buildFilterTab('Selesai', 'completed'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterTab(String label, String value) {
    final isSelected = controller.selectedFilter.value == value;
    return GestureDetector(
      onTap: () => controller.selectedFilter.value = value,
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? AppColors.onPrimary : AppColors.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _MaintenanceCard extends GetView<MaintenanceController> {
  final MaintenanceItem item;
  const _MaintenanceCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final statusIcon = _getStatusIcon();
    final statusText = _getStatusText();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        controller.getDeviceName(item.deviceId),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDetailItem(Icons.flag, 'Mulai', item.startLabel),
                    const SizedBox(width: 16),
                    _buildDetailItem(
                      Icons.repeat,
                      'Interval',
                      item.periodLabel,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => controller.deleteMaintenance(item.id!),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Hapus'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.danger,
                          side: const BorderSide(color: AppColors.danger),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: item.status == MaintenanceStatus.overdue
                            ? () => controller.markAsCompleted(item)
                            : null,
                        icon: const Icon(
                          Icons.check,
                          size: 18,
                          color: AppColors.onPrimary,
                        ),
                        label: const Text(
                          'Selesai',
                          style: TextStyle(color: AppColors.onPrimary),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.border,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
              ),
              Text(
                value,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    switch (item.status) {
      case MaintenanceStatus.overdue:
        return AppColors.danger;
      case MaintenanceStatus.upcoming:
        return AppColors.warning;
      case MaintenanceStatus.completed:
        return AppColors.success;
    }
  }

  IconData _getStatusIcon() {
    switch (item.status) {
      case MaintenanceStatus.overdue:
        return Icons.warning;
      case MaintenanceStatus.upcoming:
        return Icons.schedule;
      case MaintenanceStatus.completed:
        return Icons.check_circle;
    }
  }

  String _getStatusText() {
    switch (item.status) {
      case MaintenanceStatus.overdue:
        return 'Terlambat';
      case MaintenanceStatus.upcoming:
        return 'Akan Datang';
      case MaintenanceStatus.completed:
        return 'Selesai';
    }
  }
}
