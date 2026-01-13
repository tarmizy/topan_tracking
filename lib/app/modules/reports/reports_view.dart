import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/traccar_models.dart';
import 'reports_controller.dart';

class ReportsView extends GetView<ReportsController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Laporan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => controller.selectDateRange(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildReportTabs(),
          Expanded(child: _buildReportContent()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: const Color(0xFF1A1A1A),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<TraccarDevice>(
                    value: controller.selectedDevice.value,
                    hint: const Text(
                      'Pilih Kendaraan',
                      style: TextStyle(color: Colors.grey),
                    ),
                    dropdownColor: const Color(0xFF1A1A1A),
                    isExpanded: true,
                    items: controller.devices.map((device) {
                      return DropdownMenuItem(
                        value: device,
                        child: Text(
                          device.name,
                          style: const TextStyle(color: Colors.white),
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
          ),
          const SizedBox(width: 8),
          Obx(
            () => GestureDetector(
              onTap: () => controller.selectDateRange(Get.context!),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.date_range,
                      color: Color(0xFF00D4FF),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${controller.formatDate(controller.startDate.value ?? DateTime.now())} - ${controller.formatDate(controller.endDate.value ?? DateTime.now())}',
                      style: const TextStyle(color: Colors.white, fontSize: 11),
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

  Widget _buildReportTabs() {
    return Container(
      height: 50,
      color: const Color(0xFF1A1A1A),
      child: Obx(
        () => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          children: [
            _buildTab('Ringkasan', ReportType.summary, Icons.dashboard),
            _buildTab('Perjalanan', ReportType.trips, Icons.route),
            _buildTab('Berhenti', ReportType.stops, Icons.local_parking),
            _buildTab('Event', ReportType.events, Icons.notifications),
            _buildTab('BBM', ReportType.fuel, Icons.local_gas_station),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, ReportType type, IconData icon) {
    final isSelected = controller.selectedReportType.value == type;
    return GestureDetector(
      onTap: () => controller.selectReportType(type),
      child: Container(
        margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00D4FF) : const Color(0xFF0A0A0A),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.black : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportContent() {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xFF00D4FF)),
        );
      }

      if (controller.selectedDevice.value == null) {
        return const Center(
          child: Text(
            'Pilih kendaraan untuk melihat laporan',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      switch (controller.selectedReportType.value) {
        case ReportType.summary:
          return _buildSummaryReport();
        case ReportType.trips:
          return _buildTripsReport();
        case ReportType.stops:
          return _buildStopsReport();
        case ReportType.events:
          return _buildEventsReport();
        case ReportType.fuel:
          return _buildFuelReport();
      }
    });
  }

  Widget _buildSummaryReport() {
    return Obx(() {
      final summary = controller.summaryData.value;
      if (summary == null) {
        return const Center(
          child: Text('Tidak ada data', style: TextStyle(color: Colors.grey)),
        );
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Stats cards
            Row(
              children: [
                _buildStatCard(
                  'Total Perjalanan',
                  '${summary.totalTrips}',
                  Icons.route,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Total Jarak',
                  '${summary.totalDistanceKm.toStringAsFixed(1)} km',
                  Icons.straighten,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Kec. Maks',
                  '${summary.maxSpeedKmh.toStringAsFixed(0)} km/h',
                  Icons.speed,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Kec. Rata²',
                  '${summary.avgSpeedKmh.toStringAsFixed(0)} km/h',
                  Icons.av_timer,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatCard(
                  'Total Waktu',
                  controller.formatDuration(summary.totalDurationMinutes),
                  Icons.timer,
                  Colors.teal,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Est. BBM',
                  '${summary.totalFuelLiters.toStringAsFixed(1)} L',
                  Icons.local_gas_station,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Daily chart placeholder
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perjalanan per Hari',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: summary.tripsByDay.entries.map((e) {
                        final maxTrips = summary.tripsByDay.values.reduce(
                          (a, b) => a > b ? a : b,
                        );
                        final height = maxTrips > 0
                            ? (e.value / maxTrips * 80)
                            : 0.0;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${e.value}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00D4FF),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  e.key,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 8,
                                  ),
                                ),
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
          ],
        ),
      );
    });
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsReport() {
    return Obx(() {
      if (controller.trips.isEmpty) {
        return const Center(
          child: Text(
            'Tidak ada perjalanan',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.trips.length,
        itemBuilder: (context, index) {
          final trip = controller.trips[index];
          return _buildTripCard(trip);
        },
      );
    });
  }

  Widget _buildTripCard(TraccarTrip trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.play_circle, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.startAddress ?? 'Lokasi awal',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                controller.formatDateTime(trip.startTime),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 9),
            padding: const EdgeInsets.only(left: 10),
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(color: Color(0xFF00D4FF), width: 2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  _buildTripStat(
                    Icons.straighten,
                    '${trip.distanceKm.toStringAsFixed(1)} km',
                  ),
                  _buildTripStat(Icons.timer, '${trip.durationMinutes} min'),
                  _buildTripStat(
                    Icons.speed,
                    '${trip.avgSpeedKmh.toStringAsFixed(0)} km/h',
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.stop_circle, color: Colors.red, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  trip.endAddress ?? 'Lokasi akhir',
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                controller.formatDateTime(trip.endTime),
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripStat(IconData icon, String value) {
    return Expanded(
      child: Row(
        children: [
          Icon(icon, color: Colors.grey, size: 14),
          const SizedBox(width: 4),
          Text(value, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStopsReport() {
    return Obx(() {
      if (controller.stops.isEmpty) {
        return const Center(
          child: Text(
            'Tidak ada data berhenti',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.stops.length,
        itemBuilder: (context, index) {
          final stop = controller.stops[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: stop.engineOff
                        ? Colors.red.withValues(alpha: 0.2)
                        : Colors.orange.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stop.engineOff ? Icons.power_off : Icons.local_parking,
                    color: stop.engineOff ? Colors.red : Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.address ??
                            '${stop.latitude.toStringAsFixed(4)}, ${stop.longitude.toStringAsFixed(4)}',
                        style: const TextStyle(color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${controller.formatDateTime(stop.startTime)} - ${controller.formatDateTime(stop.endTime)}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00D4FF).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    controller.formatDuration(stop.durationMinutes),
                    style: const TextStyle(
                      color: Color(0xFF00D4FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildEventsReport() {
    return Obx(() {
      if (controller.events.isEmpty) {
        return const Center(
          child: Text('Tidak ada event', style: TextStyle(color: Colors.grey)),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: controller.events.length,
        itemBuilder: (context, index) {
          final event = controller.events[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Text(event.eventIcon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.eventTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        controller.formatDateTime(event.eventTime),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildFuelReport() {
    return Obx(() {
      if (controller.trips.isEmpty) {
        return const Center(
          child: Text(
            'Tidak ada data BBM',
            style: TextStyle(color: Colors.grey),
          ),
        );
      }

      double totalFuel = 0;
      double totalDistance = 0;
      for (var trip in controller.trips) {
        totalFuel += trip.spentFuel;
        totalDistance += trip.distanceKm;
      }

      final efficiency = totalDistance > 0
          ? totalDistance / (totalFuel > 0 ? totalFuel : 1)
          : 0;

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                _buildStatCard(
                  'Total BBM',
                  '${totalFuel.toStringAsFixed(1)} L',
                  Icons.local_gas_station,
                  Colors.red,
                ),
                const SizedBox(width: 12),
                _buildStatCard(
                  'Efisiensi',
                  '${efficiency.toStringAsFixed(1)} km/L',
                  Icons.eco,
                  Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konsumsi per Perjalanan',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...controller.trips
                      .take(10)
                      .map(
                        (trip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  controller.formatDateTime(trip.startTime),
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              Text(
                                '${trip.distanceKm.toStringAsFixed(1)} km',
                                style: const TextStyle(color: Colors.white),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                '${trip.spentFuel.toStringAsFixed(1)} L',
                                style: const TextStyle(
                                  color: Color(0xFF00D4FF),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}
