import 'package:get/get.dart';
import 'playback_controller.dart';

class PlaybackBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PlaybackController>(() => PlaybackController());
  }
}
