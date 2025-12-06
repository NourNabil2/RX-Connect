import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharmacist_assistant/core/routes/app_routes.dart';
import 'package:pharmacist_assistant/core/service/notification_helper.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';
import 'package:timezone/data/latest.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // ✅ تهيئة Timezone
  tz.initializeTimeZones();

  // ✅ تهيئة Notifications
  await NotificationService().initialize();

  // Initialize Local Notifications
  await NotificationService().initialize();

  runApp(const VirtualPharmacistApp());
}

class VirtualPharmacistApp extends StatelessWidget {
  const VirtualPharmacistApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844), // 👈 غيّر المقاس ده حسب تصميمك (فيجما مثلاً)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => MedicationProvider()),
            ChangeNotifierProvider(create: (_) => AdherenceProvider()),
            // ChangeNotifierProvider(create: (_) => AdherenceProvider()),
            // ChangeNotifierProvider(create: (_) => ChatProvider()),
          ],
          child: MaterialApp(
            title: 'Virtual Pharmacist',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            home: const SplashScreen(),
            routes: AppRoutes.routes,
            onGenerateRoute: AppRoutes.onGenerateRoute,
          ),
        );
      },
    );
  }
}
