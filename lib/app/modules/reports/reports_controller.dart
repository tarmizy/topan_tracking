import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../data/models/traccar_models.dart';
import '../../data/services/traccar_api_service.dart';
import '../../data/services/vehicle_service.dart';

enum ReportType { summary, trips, stops, events, fuel }

class ReportsController extends GetxController {
  final TraccarApiService _traccarApi = Get.find<TraccarApiService>();
  final VehicleService _vehicleService = Get.find<VehicleService>();

  Rxn<TraccarDevice> get selectedDevice => _vehicleService.selectedDevice;
  RxList<TraccarDevice> get devices => _vehicleService.devices;

  final selectedReportType = ReportType.summary.obs;
  final startDate = Rxn<DateTime>();
  final endDate = Rxn<DateTime>();
  final isLoading = false.obs;

  // Report data
  final trips = <TraccarTrip>[].obs;
  final events = <TraccarEvent>[].obs;
  final stops = <StopReport>[].obs;
  final summaryData = Rxn<SummaryReport>();

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    startDate.value = DateTime(now.year, now.month, now.day - 7);
    endDate.value = DateTime(now.year, now.month, now.day, 23, 59, 59);
  }

  void selectDevice(TraccarDevice device) {
    _vehicleService.selectDevice(device);
    loadReport();
  }

  void selectReportType(ReportType type) {
    selectedReportType.value = type;
    loadReport();
  }

  Future<void> selectDateRange(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start:
            startDate.value ?? DateTime.now().subtract(const Duration(days: 7)),
        end: endDate.value ?? DateTime.now(),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00D4FF),
              onPrimary: Colors.black,
              surface: Color(0xFF1A1A1A),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      startDate.value = picked.start;
      endDate.value = DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
      );
      loadReport();
    }
  }

  Future<void> loadReport() async {
    if (selectedDevice.value == null) return;

    isLoading.value = true;

    try {
      switch (selectedReportType.value) {
        case ReportType.summary:
          await _loadSummary();
          break;
        case ReportType.trips:
          await _loadTrips();
          break;
        case ReportType.stops:
          await _loadStops();
          break;
        case ReportType.events:
          await _loadEvents();
          break;
        case ReportType.fuel:
          await _loadFuel();
          break;
      }
    } catch (e) {
      debugPrint('Error loading report: $e');
    }

    isLoading.value = false;
  }

  Future<void> _loadSummary() async {
    final tripsResult = await _traccarApi.getTrips(
      deviceId: selectedDevice.value!.id,
      from: startDate.value!,
      to: endDate.value!,
    );

    if (tripsResult.success && tripsResult.data != null) {
      final tripList = tripsResult.data!;

      double totalDistance = 0;
      double maxSpeed = 0;
      int totalDuration = 0;
      double totalFuel = 0;

      for (var trip in tripList) {
        totalDistance += trip.distance;
        if (trip.maxSpeed > maxSpeed) maxSpeed = trip.maxSpeed;
        totalDuration += trip.duration;
        totalFuel += trip.spentFuel;
      }

      summaryData.value = SummaryReport(
        totalTrips: tripList.length,
        totalDistanceKm: totalDistance / 1000,
        maxSpeedKmh: maxSpeed * 1.852,
        avgSpeedKmh: tripList.isNotEmpty
            ? tripList.map((t) => t.averageSpeed).reduce((a, b) => a + b) /
                  tripList.length *
                  1.852
            : 0,
        totalDurationMinutes: totalDuration ~/ 60000,
        totalFuelLiters: totalFuel,
        tripsByDay: _groupTripsByDay(tripList),
      );
    }
  }

  Map<String, int> _groupTripsByDay(List<TraccarTrip> tripList) {
    final Map<String, int> result = {};
    for (var trip in tripList) {
      final key = '${trip.startTime.day}/${trip.startTime.month}';
      result[key] = (result[key] ?? 0) + 1;
    }
    return result;
  }

  Future<void> _loadTrips() async {
    final result = await _traccarApi.getTrips(
      deviceId: selectedDevice.value!.id,
      from: startDate.value!,
      to: endDate.value!,
    );

    if (result.success && result.data != null) {
      trips.value = result.data!;
    }
  }

  Future<void> _loadStops() async {
    // Get stops from Traccar API
    final result = await _traccarApi.getStops(
      deviceId: selectedDevice.value!.id,
      from: startDate.value!,
      to: endDate.value!,
    );

    if (result.success && result.data != null) {
      stops.value = result.data!;
    }
  }

  Future<void> _loadEvents() async {
    final result = await _traccarApi.getEvents(
      deviceId: selectedDevice.value!.id,
      from: startDate.value!,
      to: endDate.value!,
    );

    if (result.success && result.data != null) {
      events.value = result.data!;
    }
  }

  Future<void> _loadFuel() async {
    // Fuel report uses trips data
    await _loadTrips();
  }

  String formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  String formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (hours > 0) return '${hours}j ${mins}m';
    return '${mins}m';
  }
}

class SummaryReport {
  final int totalTrips;
  final double totalDistanceKm;
  final double maxSpeedKmh;
  final double avgSpeedKmh;
  final int totalDurationMinutes;
  final double totalFuelLiters;
  final Map<String, int> tripsByDay;

  SummaryReport({
    required this.totalTrips,
    required this.totalDistanceKm,
    required this.maxSpeedKmh,
    required this.avgSpeedKmh,
    required this.totalDurationMinutes,
    required this.totalFuelLiters,
    required this.tripsByDay,
  });
}

class StopReport {
  final DateTime startTime;
  final DateTime endTime;
  final double latitude;
  final double longitude;
  final String? address;
  final int durationMinutes;
  final bool engineOff;

  StopReport({
    required this.startTime,
    required this.endTime,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.durationMinutes,
    this.engineOff = false,
  });

  factory StopReport.fromJson(Map<String, dynamic> json) {
    final start = DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now();
    return StopReport(
      startTime: start,
      endTime: end,
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      address: json['address'],
      durationMinutes: json['duration'] != null
          ? (json['duration'] / 60000).round()
          : end.difference(start).inMinutes,
      engineOff: json['engineHours'] == 0,
    );
  }
}
