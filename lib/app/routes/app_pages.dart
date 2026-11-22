import 'package:get/get.dart';
import '../modules/splash/splash_view.dart';
import '../modules/login/login_binding.dart';
import '../modules/login/login_view.dart';
import '../modules/register/register_binding.dart';
import '../modules/register/register_view.dart';
import '../modules/home/home_binding.dart';
import '../modules/home/home_view.dart';
import '../modules/geofence/geofence_binding.dart';
import '../modules/geofence/geofence_view.dart';
import '../modules/notifications/notifications_binding.dart';
import '../modules/notifications/notifications_view.dart';
import '../modules/playback/playback_binding.dart';
import '../modules/playback/playback_view.dart';
import '../modules/reports/reports_binding.dart';
import '../modules/reports/reports_view.dart';
import '../modules/drivers/drivers_binding.dart';
import '../modules/drivers/drivers_view.dart';
import '../modules/maintenance/maintenance_binding.dart';
import '../modules/maintenance/maintenance_view.dart';

part 'app_routes.dart';

class AppPages {
  static const initial = Routes.splash;

  static final routes = [
    GetPage(
      name: Routes.splash,
      page: () => const SplashView(),
    ),
    GetPage(
      name: Routes.login,
      page: () => const LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: Routes.register,
      page: () => const RegisterView(),
      binding: RegisterBinding(),
    ),
    GetPage(
      name: Routes.home,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.geofence,
      page: () => const GeofenceView(),
      binding: GeofenceBinding(),
    ),
    GetPage(
      name: Routes.notifications,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: Routes.playback,
      page: () => const PlaybackView(),
      binding: PlaybackBinding(),
    ),
    GetPage(
      name: Routes.reports,
      page: () => const ReportsView(),
      binding: ReportsBinding(),
    ),
    GetPage(
      name: Routes.drivers,
      page: () => const DriversView(),
      binding: DriversBinding(),
    ),
    GetPage(
      name: Routes.maintenance,
      page: () => const MaintenanceView(),
      binding: MaintenanceBinding(),
    ),
  ];
}
