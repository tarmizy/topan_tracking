import 'package:get/get.dart';
import '../../data/services/vehicle_service.dart';

class NotificationsController extends GetxController {
  late final VehicleService _vehicleService;

  RxList<NotificationItem> get notifications => _vehicleService.notifications;

  @override
  void onInit() {
    super.onInit();
    _vehicleService = Get.find<VehicleService>();
  }

  void markAsRead(String id) {
    _vehicleService.markNotificationAsRead(id);
  }

  void markAllAsRead() {
    for (var notification in notifications) {
      _vehicleService.markNotificationAsRead(notification.id);
    }
  }

  String formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} menit lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
