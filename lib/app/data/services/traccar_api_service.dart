import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/traccar_models.dart';
import '../../modules/reports/reports_controller.dart' show StopReport;
import '../../modules/maintenance/maintenance_controller.dart'
    show MaintenanceItem;

class TraccarApiService extends GetxService {
  static const String baseUrl = 'http://46.250.229.199:9082';
  static const String wsUrl = 'ws://46.250.229.199:9082';

  String? _sessionCookie;
  TraccarUser? _currentUser;
  WebSocketChannel? _webSocketChannel;

  final devices = <TraccarDevice>[].obs;
  final positions = <int, TraccarPosition>{}.obs;
  final geofences = <TraccarGeofence>[].obs;
  final events = <TraccarEvent>[].obs;

  final isConnected = false.obs;
  final isWebSocketConnected = false.obs;

  TraccarUser? get currentUser => _currentUser;
  String? get sessionCookie => _sessionCookie;

  // ==================== AUTH ====================

  Future<TraccarApiResponse<TraccarUser>> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/session'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body:
            'email=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
      );

      if (response.statusCode == 200) {
        final cookie = response.headers['set-cookie'];
        if (cookie != null) {
          _sessionCookie = cookie.split(';').first;
          await _saveSession(_sessionCookie!, email);
        }

        _currentUser = TraccarUser.fromJson(json.decode(response.body));
        isConnected.value = true;

        return TraccarApiResponse(success: true, data: _currentUser);
      } else {
        final error = response.statusCode == 401
            ? 'Email atau password salah'
            : 'Login gagal: ${response.statusCode}';
        return TraccarApiResponse(success: false, error: error);
      }
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Koneksi gagal: $e');
    }
  }

  Future<bool> checkSession() async {
    final prefs = await SharedPreferences.getInstance();
    _sessionCookie = prefs.getString('traccar_session');

    if (_sessionCookie == null) return false;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/session'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        _currentUser = TraccarUser.fromJson(json.decode(response.body));
        isConnected.value = true;
        return true;
      }
    } catch (e) {
      debugPrint('Session check failed: $e');
    }

    await _clearSession();
    return false;
  }

  Future<void> logout() async {
    try {
      await http.delete(
        Uri.parse('$baseUrl/api/session'),
        headers: _getHeaders(),
      );
    } catch (e) {
      debugPrint('Logout error: $e');
    }

    disconnectWebSocket();
    await _clearSession();
    _currentUser = null;
    isConnected.value = false;
    devices.clear();
    positions.clear();
  }

  /// Daftar akun baru (memerlukan opsi "registration" aktif di server Traccar).
  Future<TraccarApiResponse<bool>> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );
      if (response.statusCode == 200) {
        return TraccarApiResponse(success: true, data: true);
      }
      final body = response.body.toLowerCase();
      if (body.contains('duplicate') || body.contains('unique')) {
        return TraccarApiResponse(success: false, error: 'Email sudah terdaftar.');
      }
      if (response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403) {
        return TraccarApiResponse(
          success: false,
          error: 'Pendaftaran mandiri belum dibuka. Hubungi tim Topan untuk dibuatkan akun.',
        );
      }
      return TraccarApiResponse(
        success: false,
        error: 'Pendaftaran gagal (${response.statusCode}).',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Koneksi gagal: $e');
    }
  }

  /// Ganti kata sandi akun yang sedang masuk.
  /// Kata sandi lama diverifikasi dulu dengan login ulang.
  Future<TraccarApiResponse<bool>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _currentUser?.email;
    if (email == null) {
      return TraccarApiResponse(success: false, error: 'Sesi berakhir, silakan masuk ulang.');
    }
    try {
      final verify = await login(email, currentPassword);
      if (!verify.success) {
        return TraccarApiResponse(success: false, error: 'Kata sandi lama salah.');
      }
      final session = await http.get(
        Uri.parse('$baseUrl/api/session'),
        headers: _getHeaders(),
      );
      if (session.statusCode != 200) {
        return TraccarApiResponse(success: false, error: 'Gagal memuat data akun.');
      }
      final user = json.decode(session.body) as Map<String, dynamic>;
      user['password'] = newPassword;
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/${user['id']}'),
        headers: _getHeaders(),
        body: json.encode(user),
      );
      if (response.statusCode == 200) {
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengganti kata sandi (${response.statusCode}).',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Koneksi gagal: $e');
    }
  }

  // ==================== DEVICES ====================

  Future<TraccarApiResponse<List<TraccarDevice>>> getDevices() async {
    try {
      debugPrint('Getting devices from: $baseUrl/api/devices');
      final response = await http.get(
        Uri.parse('$baseUrl/api/devices'),
        headers: _getHeaders(),
      );

      debugPrint('Devices response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final deviceList = data.map((d) => TraccarDevice.fromJson(d)).toList();
        devices.value = deviceList;
        debugPrint('Loaded ${deviceList.length} devices');
        return TraccarApiResponse(success: true, data: deviceList);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil data device: ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      debugPrint('Error getting devices: $e');
      debugPrint('Stack trace: $stackTrace');
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== POSITIONS ====================

  Future<TraccarApiResponse<List<TraccarPosition>>> getPositions() async {
    try {
      debugPrint('Getting positions from: $baseUrl/api/positions');
      final response = await http.get(
        Uri.parse('$baseUrl/api/positions'),
        headers: _getHeaders(),
      );

      debugPrint('Positions response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final positionList = data
            .map((p) => TraccarPosition.fromJson(p))
            .toList();

        for (var pos in positionList) {
          positions[pos.deviceId] = pos;
        }

        debugPrint('Loaded ${positionList.length} positions');
        return TraccarApiResponse(success: true, data: positionList);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil posisi: ${response.statusCode}',
      );
    } catch (e, stackTrace) {
      debugPrint('Error getting positions: $e');
      debugPrint('Stack trace: $stackTrace');
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<List<TraccarPosition>>> getPositionHistory({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/positions?deviceId=$deviceId&from=$fromStr&to=$toStr',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final positionList = data
            .map((p) => TraccarPosition.fromJson(p))
            .toList();
        return TraccarApiResponse(success: true, data: positionList);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil riwayat posisi',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== GEOFENCES ====================

  Future<TraccarApiResponse<List<TraccarGeofence>>> getGeofences() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/geofences'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final geofenceList = data
            .map((g) => TraccarGeofence.fromJson(g))
            .toList();
        geofences.value = geofenceList;
        return TraccarApiResponse(success: true, data: geofenceList);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil geofence',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<TraccarGeofence>> createGeofence(
    TraccarGeofence geofence,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/geofences'),
        headers: _getHeaders(),
        body: json.encode(geofence.toJson()),
      );

      if (response.statusCode == 200) {
        final newGeofence = TraccarGeofence.fromJson(
          json.decode(response.body),
        );
        geofences.add(newGeofence);
        return TraccarApiResponse(success: true, data: newGeofence);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal membuat geofence',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<bool>> deleteGeofence(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/geofences/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        geofences.removeWhere((g) => g.id == id);
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menghapus geofence',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== GEOFENCE-DEVICE PERMISSIONS ====================

  Future<TraccarApiResponse<bool>> linkGeofenceToDevice(
    int geofenceId,
    int deviceId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/permissions'),
        headers: _getHeaders(),
        body: json.encode({'deviceId': deviceId, 'geofenceId': geofenceId}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menghubungkan geofence',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<bool>> unlinkGeofenceFromDevice(
    int geofenceId,
    int deviceId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/permissions'),
        headers: _getHeaders(),
        body: json.encode({'deviceId': deviceId, 'geofenceId': geofenceId}),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menghapus hubungan geofence',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<List<int>>> getDeviceGeofences(int deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/geofences?deviceId=$deviceId'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final ids = data.map((g) => g['id'] as int).toList();
        return TraccarApiResponse(success: true, data: ids);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil geofence device',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== DRIVERS ====================

  Future<TraccarApiResponse<List<TraccarDriver>>> getDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/drivers'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final drivers = data.map((d) => TraccarDriver.fromJson(d)).toList();
        return TraccarApiResponse(success: true, data: drivers);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil data pengemudi',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<TraccarDriver>> createDriver(
    TraccarDriver driver,
  ) async {
    try {
      debugPrint('Creating driver: ${driver.toJson()}');
      final response = await http.post(
        Uri.parse('$baseUrl/api/drivers'),
        headers: _getHeaders(),
        body: json.encode(driver.toJson()),
      );

      debugPrint(
        'Create driver response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final newDriver = TraccarDriver.fromJson(json.decode(response.body));
        return TraccarApiResponse(success: true, data: newDriver);
      }

      // Parse error message from response
      String errorMsg = 'Gagal menambahkan pengemudi';
      try {
        final errorBody = json.decode(response.body);
        if (errorBody['message'] != null) {
          errorMsg = errorBody['message'];
        }
      } catch (_) {}

      return TraccarApiResponse(
        success: false,
        error: '$errorMsg (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('Create driver error: $e');
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<bool>> deleteDriver(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/drivers/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menghapus pengemudi',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<TraccarDriver>> updateDriver(
    TraccarDriver driver,
  ) async {
    try {
      debugPrint('Updating driver: ${driver.toJson()}');
      final response = await http.put(
        Uri.parse('$baseUrl/api/drivers/${driver.id}'),
        headers: _getHeaders(),
        body: json.encode(driver.toJson()),
      );

      debugPrint(
        'Update driver response: ${response.statusCode} - ${response.body}',
      );

      if (response.statusCode == 200) {
        final updated = TraccarDriver.fromJson(json.decode(response.body));
        return TraccarApiResponse(success: true, data: updated);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengupdate pengemudi (${response.statusCode})',
      );
    } catch (e) {
      debugPrint('Update driver error: $e');
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== MAINTENANCE ====================

  Future<TraccarApiResponse<List<MaintenanceItem>>> getMaintenance() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/maintenance'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final items = data.map((m) => MaintenanceItem.fromJson(m)).toList();
        return TraccarApiResponse(success: true, data: items);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil data maintenance',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<MaintenanceItem>> createMaintenance(
    MaintenanceItem item,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/maintenance'),
        headers: _getHeaders(),
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 200) {
        final newItem = MaintenanceItem.fromJson(json.decode(response.body));
        return TraccarApiResponse(success: true, data: newItem);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menambahkan maintenance',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<MaintenanceItem>> updateMaintenance(
    MaintenanceItem item,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/maintenance/${item.id}'),
        headers: _getHeaders(),
        body: json.encode(item.toJson()),
      );

      if (response.statusCode == 200) {
        final updatedItem = MaintenanceItem.fromJson(
          json.decode(response.body),
        );
        return TraccarApiResponse(success: true, data: updatedItem);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengupdate maintenance',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<bool>> deleteMaintenance(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/maintenance/$id'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 204) {
        return TraccarApiResponse(success: true, data: true);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal menghapus maintenance',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== COMMANDS ====================

  Future<TraccarApiResponse<TraccarCommandDelivery>> sendCommand({
    required int deviceId,
    required String type,
    Map<String, dynamic>? attributes,
  }) async {
    try {
      final command = {
        'deviceId': deviceId,
        'type': type,
        if (attributes != null) 'attributes': attributes,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/commands/send'),
        headers: _getHeaders(),
        body: json.encode(command),
      );

      return switch (response.statusCode) {
        200 => TraccarApiResponse(
          success: true,
          data: TraccarCommandDelivery.sent,
        ),
        202 => TraccarApiResponse(
          success: true,
          data: TraccarCommandDelivery.queued,
        ),
        400 => TraccarApiResponse(
          success: false,
          error: 'Server menolak perintah. Periksa dukungan GPS dan izin akun.',
        ),
        401 || 403 => TraccarApiResponse(
          success: false,
          error: 'Sesi atau izin akun tidak mengizinkan perintah ini.',
        ),
        _ => TraccarApiResponse(
          success: false,
          error: 'Gagal mengirim perintah (HTTP ${response.statusCode}).',
        ),
      };
    } catch (e) {
      return TraccarApiResponse(
        success: false,
        error: 'Koneksi ke server gagal.',
      );
    }
  }

  // ==================== REPORTS ====================

  Future<TraccarApiResponse<List<TraccarTrip>>> getTrips({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/reports/trips?deviceId=$deviceId&from=$fromStr&to=$toStr',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final trips = data.map((t) => TraccarTrip.fromJson(t)).toList();
        return TraccarApiResponse(success: true, data: trips);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil riwayat perjalanan',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  Future<TraccarApiResponse<List<StopReport>>> getStops({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/reports/stops?deviceId=$deviceId&from=$fromStr&to=$toStr',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final stops = data.map((s) => StopReport.fromJson(s)).toList();
        return TraccarApiResponse(success: true, data: stops);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil data berhenti',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== EVENTS ====================

  Future<TraccarApiResponse<List<TraccarEvent>>> getEvents({
    required int deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    try {
      final fromStr = from.toUtc().toIso8601String();
      final toStr = to.toUtc().toIso8601String();

      final response = await http.get(
        Uri.parse(
          '$baseUrl/api/reports/events?deviceId=$deviceId&from=$fromStr&to=$toStr',
        ),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final eventList = data.map((e) => TraccarEvent.fromJson(e)).toList();
        return TraccarApiResponse(success: true, data: eventList);
      }
      return TraccarApiResponse(
        success: false,
        error: 'Gagal mengambil events',
      );
    } catch (e) {
      return TraccarApiResponse(success: false, error: 'Error: $e');
    }
  }

  // ==================== WEBSOCKET ====================

  void connectWebSocket() {
    // Skip WebSocket for now - use polling instead
    // Traccar WebSocket requires cookie authentication which is complex
    debugPrint('WebSocket: Using polling instead of WebSocket');
    isWebSocketConnected.value = false;
    _startPolling();
  }

  Timer? _pollingTimer;

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (isConnected.value) {
        try {
          await getPositions();
        } catch (e) {
          debugPrint('Polling error: $e');
        }
      }
    });
    debugPrint('Started position polling (every 15 seconds)');
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void _handleWebSocketMessage(dynamic message) {
    try {
      final data = json.decode(message);

      if (data['devices'] != null) {
        final List<dynamic> deviceData = data['devices'];
        for (var d in deviceData) {
          final device = TraccarDevice.fromJson(d);
          final index = devices.indexWhere((dev) => dev.id == device.id);
          if (index >= 0) {
            devices[index] = device;
          } else {
            devices.add(device);
          }
        }
      }

      if (data['positions'] != null) {
        final List<dynamic> posData = data['positions'];
        for (var p in posData) {
          final position = TraccarPosition.fromJson(p);
          positions[position.deviceId] = position;
        }
      }

      if (data['events'] != null) {
        final List<dynamic> eventData = data['events'];
        for (var e in eventData) {
          events.add(TraccarEvent.fromJson(e));
        }
      }
    } catch (e) {
      debugPrint('WebSocket message parse error: $e');
    }
  }

  void disconnectWebSocket() {
    _stopPolling();
    try {
      _webSocketChannel?.sink.close();
    } catch (e) {
      debugPrint('Error closing WebSocket: $e');
    }
    _webSocketChannel = null;
    isWebSocketConnected.value = false;
  }

  // ==================== HELPERS ====================

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_sessionCookie != null) 'Cookie': _sessionCookie!,
    };
  }

  Future<void> _saveSession(String cookie, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('traccar_session', cookie);
    await prefs.setString('traccar_email', email);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('traccar_session');
    await prefs.remove('traccar_email');
    _sessionCookie = null;
  }
}

class TraccarApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  TraccarApiResponse({required this.success, this.data, this.error});
}
