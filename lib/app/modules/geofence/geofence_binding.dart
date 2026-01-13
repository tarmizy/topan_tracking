import 'package:get/get.dart';
import 'geofence_controller.dart';

class GeofenceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GeofenceController>(() => GeofenceController());
  }
}
