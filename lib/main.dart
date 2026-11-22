import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app/core/theme/app_theme.dart';
import 'app/routes/app_pages.dart';
import 'app/data/services/traccar_api_service.dart';
import 'app/data/services/vehicle_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  Get.put(TraccarApiService(), permanent: true);
  Get.put(VehicleService(), permanent: true);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Topan Tracking',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
    );
  }
}
