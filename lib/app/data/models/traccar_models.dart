import 'package:flutter/foundation.dart';
import '../../core/utils/rental.dart';

// Traccar User Model
class TraccarUser {
  final int id;
  final String name;
  final String email;
  final bool administrator;
  final String? phone;
  final bool disabled;
  final DateTime? expirationTime;
  final int deviceLimit;
  final int userLimit;
  final bool deviceReadonly;
  final bool readonly;
  final Map<String, dynamic>? attributes;

  TraccarUser({
    required this.id,
    required this.name,
    required this.email,
    this.administrator = false,
    this.phone,
    this.disabled = false,
    this.expirationTime,
    this.deviceLimit = -1,
    this.userLimit = 0,
    this.deviceReadonly = false,
    this.readonly = false,
    this.attributes,
  });

  factory TraccarUser.fromJson(Map<String, dynamic> json) {
    return TraccarUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      administrator: json['administrator'] ?? false,
      phone: json['phone'],
      disabled: json['disabled'] ?? false,
      expirationTime: json['expirationTime'] != null
          ? DateTime.tryParse(json['expirationTime'])
          : null,
      deviceLimit: json['deviceLimit'] ?? -1,
      userLimit: json['userLimit'] ?? 0,
      deviceReadonly: json['deviceReadonly'] ?? false,
      readonly: json['readonly'] ?? false,
      attributes: json['attributes'],
    );
  }
}

// Traccar Device Model
class TraccarDevice {
  final int id;
  final String name;
  final String uniqueId;
  final String status; // online, offline, unknown
  final bool disabled;
  final DateTime? lastUpdate;
  final int? positionId;
  final int? groupId;
  final String? phone;
  final String? model;
  final String? contact;
  final String? category;
  final Map<String, dynamic>? attributes;

  TraccarDevice({
    required this.id,
    required this.name,
    required this.uniqueId,
    this.status = 'unknown',
    this.disabled = false,
    this.lastUpdate,
    this.positionId,
    this.groupId,
    this.phone,
    this.model,
    this.contact,
    this.category,
    this.attributes,
  });

  factory TraccarDevice.fromJson(Map<String, dynamic> json) {
    return TraccarDevice(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      status: json['status'] ?? 'unknown',
      disabled: json['disabled'] ?? false,
      lastUpdate: json['lastUpdate'] != null
          ? DateTime.tryParse(json['lastUpdate'])
          : null,
      positionId: json['positionId'],
      groupId: json['groupId'],
      phone: json['phone'],
      model: json['model'],
      contact: json['contact'],
      category: json['category'],
      attributes: json['attributes'],
    );
  }

  bool get isOnline => status == 'online';

  String get statusText {
    switch (status) {
      case 'online':
        return 'Online';
      case 'offline':
        return 'Offline';
      default:
        return 'Tidak Diketahui';
    }
  }

  String get deviceType {
    if (category != null) return category!;
    final cat = attributes?['deviceType'] ?? attributes?['category'];
    if (cat != null) return cat;
    return 'Kendaraan';
  }
}

// Traccar Position Model
class TraccarPosition {
  final int id;
  final int deviceId;
  final String protocol;
  final DateTime deviceTime;
  final DateTime fixTime;
  final DateTime serverTime;
  final bool outdated;
  final bool valid;
  final double latitude;
  final double longitude;
  final double altitude;
  final double speed; // in knots
  final double course;
  final String? address;
  final double? accuracy;
  final Map<String, dynamic>? attributes;

  TraccarPosition({
    required this.id,
    required this.deviceId,
    required this.protocol,
    required this.deviceTime,
    required this.fixTime,
    required this.serverTime,
    this.outdated = false,
    this.valid = true,
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.speed = 0,
    this.course = 0,
    this.address,
    this.accuracy,
    this.attributes,
  });

  factory TraccarPosition.fromJson(Map<String, dynamic> json) {
    final latitude = json['latitude'];
    final longitude = json['longitude'];
    final deviceTime =
        DateTime.tryParse(json['deviceTime'] ?? '') ?? DateTime.now();
    return TraccarPosition(
      id: json['id'] ?? 0,
      deviceId: json['deviceId'] ?? 0,
      protocol: json['protocol'] ?? '',
      deviceTime: deviceTime,
      fixTime: DateTime.tryParse(json['fixTime'] ?? '') ?? deviceTime,
      serverTime: DateTime.tryParse(json['serverTime'] ?? '') ?? DateTime.now(),
      outdated: json['outdated'] ?? false,
      valid:
          (json['valid'] ?? true) == true &&
          latitude is num &&
          longitude is num,
      latitude: latitude is num ? latitude.toDouble() : 0,
      longitude: longitude is num ? longitude.toDouble() : 0,
      altitude: (json['altitude'] ?? 0).toDouble(),
      speed: (json['speed'] ?? 0).toDouble(),
      course: (json['course'] ?? 0).toDouble(),
      address: json['address'],
      accuracy: json['accuracy']?.toDouble(),
      attributes: json['attributes'],
    );
  }

  // Convert speed from knots to km/h
  double get speedKmh => speed * 1.852;

  // Get battery level from attributes
  int? get batteryLevel {
    final battery = attributes?['batteryLevel'] ?? attributes?['battery'];
    if (battery != null) return (battery as num).toInt();
    return null;
  }

  bool? get ignitionStatus {
    final value = attributes?['ignition'];
    return value is bool ? value : null;
  }

  bool get ignition => ignitionStatus ?? false;

  // Get total distance in km
  double? get totalDistance {
    final dist = attributes?['totalDistance'];
    if (dist != null) return (dist as num).toDouble() / 1000;
    return null;
  }
}

// Traccar Geofence Model
class TraccarGeofence {
  final int? id;
  final String name;
  final String? description;
  final String area; // CIRCLE (lat lon, radius) or POLYGON
  final int? calendarId;
  final Map<String, dynamic>? attributes;

  TraccarGeofence({
    this.id,
    required this.name,
    this.description,
    required this.area,
    this.calendarId,
    this.attributes,
  });

  factory TraccarGeofence.fromJson(Map<String, dynamic> json) {
    return TraccarGeofence(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      area: json['area'] ?? '',
      calendarId: json['calendarId'],
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      'area': area,
      if (calendarId != null) 'calendarId': calendarId,
      if (attributes != null) 'attributes': attributes,
    };
  }

  // Parse circle geofence: CIRCLE (lat lon, radius)
  static TraccarGeofence createCircle({
    required String name,
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String? description,
  }) {
    return TraccarGeofence(
      name: name,
      description: description,
      area: 'CIRCLE ($latitude $longitude, $radiusMeters)',
    );
  }

  // Get center and radius for circle geofence
  ({double lat, double lon, double radius})? get circleData {
    if (!area.startsWith('CIRCLE')) return null;
    try {
      final match = RegExp(
        r'CIRCLE \(([^ ]+) ([^,]+), ([^)]+)\)',
      ).firstMatch(area);
      if (match != null) {
        return (
          lat: double.parse(match.group(1)!),
          lon: double.parse(match.group(2)!),
          radius: double.parse(match.group(3)!),
        );
      }
    } catch (_) {
      // Ignore parsing errors
    }
    return null;
  }
}

// Traccar Event Model
class TraccarEvent {
  final int id;
  final String type;
  final DateTime eventTime;
  final int deviceId;
  final int? positionId;
  final int? geofenceId;
  final int? maintenanceId;
  final Map<String, dynamic>? attributes;

  TraccarEvent({
    required this.id,
    required this.type,
    required this.eventTime,
    required this.deviceId,
    this.positionId,
    this.geofenceId,
    this.maintenanceId,
    this.attributes,
  });

  factory TraccarEvent.fromJson(Map<String, dynamic> json) {
    return TraccarEvent(
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      eventTime: DateTime.tryParse(json['eventTime'] ?? '') ?? DateTime.now(),
      deviceId: json['deviceId'] ?? 0,
      positionId: json['positionId'],
      geofenceId: json['geofenceId'],
      maintenanceId: json['maintenanceId'],
      attributes: json['attributes'],
    );
  }

  String get eventTitle {
    switch (type) {
      case 'deviceOnline':
        return 'Device Online';
      case 'deviceOffline':
        return 'Device Offline';
      case 'deviceMoving':
        return 'Kendaraan Bergerak';
      case 'deviceStopped':
        return 'Kendaraan Berhenti';
      case 'deviceOverspeed':
        return 'Kecepatan Berlebih';
      case 'geofenceEnter':
        return 'Masuk Zona Aman';
      case 'geofenceExit':
        return 'Keluar Zona Aman';
      case 'ignitionOn':
        return 'Mesin Menyala';
      case 'ignitionOff':
        return 'Mesin Mati';
      case 'alarm':
        return 'Alarm';
      default:
        return type;
    }
  }

  String get eventIcon {
    switch (type) {
      case 'deviceOnline':
        return '🟢';
      case 'deviceOffline':
        return '🔴';
      case 'deviceMoving':
        return '🚗';
      case 'deviceStopped':
        return '🅿️';
      case 'deviceOverspeed':
        return '⚠️';
      case 'geofenceEnter':
        return '📍';
      case 'geofenceExit':
        return '🚪';
      case 'ignitionOn':
        return '🔑';
      case 'ignitionOff':
        return '🔒';
      case 'alarm':
        return '🚨';
      default:
        return '📌';
    }
  }
}

// Traccar Trip Model (from reports)
class TraccarTrip {
  final int deviceId;
  final String deviceName;
  final double distance; // in meters
  final double averageSpeed; // in knots
  final double maxSpeed; // in knots
  final int duration; // in milliseconds
  final DateTime startTime;
  final DateTime endTime;
  final double startLat;
  final double startLon;
  final double endLat;
  final double endLon;
  final String? startAddress;
  final String? endAddress;
  final double spentFuel;
  final String? driverUniqueId;
  final String? driverName;

  TraccarTrip({
    required this.deviceId,
    required this.deviceName,
    required this.distance,
    required this.averageSpeed,
    required this.maxSpeed,
    required this.duration,
    required this.startTime,
    required this.endTime,
    required this.startLat,
    required this.startLon,
    required this.endLat,
    required this.endLon,
    this.startAddress,
    this.endAddress,
    this.spentFuel = 0,
    this.driverUniqueId,
    this.driverName,
  });

  factory TraccarTrip.fromJson(Map<String, dynamic> json) {
    return TraccarTrip(
      deviceId: json['deviceId'] ?? 0,
      deviceName: json['deviceName'] ?? '',
      distance: (json['distance'] ?? 0).toDouble(),
      averageSpeed: (json['averageSpeed'] ?? 0).toDouble(),
      maxSpeed: (json['maxSpeed'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      startTime: DateTime.tryParse(json['startTime'] ?? '') ?? DateTime.now(),
      endTime: DateTime.tryParse(json['endTime'] ?? '') ?? DateTime.now(),
      startLat: (json['startLat'] ?? 0).toDouble(),
      startLon: (json['startLon'] ?? 0).toDouble(),
      endLat: (json['endLat'] ?? 0).toDouble(),
      endLon: (json['endLon'] ?? 0).toDouble(),
      startAddress: json['startAddress'],
      endAddress: json['endAddress'],
      spentFuel: (json['spentFuel'] ?? 0).toDouble(),
      driverUniqueId: json['driverUniqueId'],
      driverName: json['driverName'],
    );
  }

  // Distance in km
  double get distanceKm => distance / 1000;

  // Duration in minutes
  int get durationMinutes => (duration / 60000).round();

  // Average speed in km/h
  double get avgSpeedKmh => averageSpeed * 1.852;

  // Max speed in km/h
  double get maxSpeedKmh => maxSpeed * 1.852;
}

enum TraccarCommandDelivery { sent, queued }

// Command types for Traccar
class TraccarCommandTypes {
  static const String engineStop = 'engineStop';
  static const String engineResume = 'engineResume';
  static const String positionSingle = 'positionSingle';
  static const String positionPeriodic = 'positionPeriodic';
  static const String setTimezone = 'setTimezone';
  static const String rebootDevice = 'rebootDevice';
  static const String custom = 'custom';
}

// Traccar Driver Model
// Note: Traccar API only supports: id, uniqueId, attributes, name
// deviceId must be stored in attributes and linked via permissions API
class TraccarDriver {
  final int? id;
  final String name;
  final String uniqueId;
  final Map<String, dynamic>? attributes;

  TraccarDriver({
    this.id,
    required this.name,
    required this.uniqueId,
    this.attributes,
  });

  // Get phone from attributes
  String? get phone => attributes?['phone'];

  // Get deviceId from attributes (stored locally, not in Traccar)
  int? get deviceId {
    final id = attributes?['deviceId'];
    if (id == null) return null;
    return id is int ? id : int.tryParse(id.toString());
  }

  // Get rental info from attributes
  bool get isActive => attributes?['isActive'] ?? false;
  double get dailyRate => (attributes?['dailyRate'] ?? 0).toDouble();
  DateTime? get rentalStartDate {
    final dateStr = attributes?['rentalStartDate'];
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Batas akhir sewa yang disepakati (opsional).
  DateTime? get rentalEndDate {
    final dateStr = attributes?['rentalEndDate'];
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Perhitungan sewa berjalan; null bila tidak sedang menyewa.
  RentalCalc? get rental {
    final start = rentalStartDate;
    if (!isActive || start == null) return null;
    return RentalCalc(start: start, end: rentalEndDate, dailyRate: dailyRate);
  }

  bool get isOverdue => rental?.isOverdue ?? false;

  factory TraccarDriver.fromJson(Map<String, dynamic> json) {
    return TraccarDriver(
      id: json['id'],
      name: json['name'] ?? '',
      uniqueId: json['uniqueId'] ?? '',
      attributes: json['attributes'] != null
          ? Map<String, dynamic>.from(json['attributes'])
          : null,
    );
  }

  // toJson for Traccar API - only includes supported fields
  Map<String, dynamic> toJson() {
    final json = {
      if (id != null) 'id': id,
      'name': name,
      'uniqueId': uniqueId,
      'attributes': attributes ?? {},
    };
    debugPrint('TraccarDriver.toJson: $json');
    return json;
  }

  // Create driver with phone stored in attributes
  factory TraccarDriver.create({
    required String name,
    required String uniqueId,
    String? phone,
    double dailyRate = 0,
    int? deviceId,
  }) {
    return TraccarDriver(
      name: name,
      uniqueId: uniqueId,
      attributes: {
        if (phone != null) 'phone': phone,
        'dailyRate': dailyRate,
        'isActive': false,
        if (deviceId != null) 'deviceId': deviceId,
      },
    );
  }

  // Copy with new values
  TraccarDriver copyWith({
    int? id,
    String? name,
    String? uniqueId,
    Map<String, dynamic>? attributes,
  }) {
    return TraccarDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      uniqueId: uniqueId ?? this.uniqueId,
      attributes: attributes ?? this.attributes,
    );
  }

  // Helper to create updated attributes with deviceId
  TraccarDriver withDeviceId(int? newDeviceId) {
    final newAttrs = Map<String, dynamic>.from(attributes ?? {});
    if (newDeviceId != null) {
      newAttrs['deviceId'] = newDeviceId;
    } else {
      newAttrs.remove('deviceId');
    }
    return copyWith(attributes: newAttrs);
  }
}
