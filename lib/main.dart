import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pharmacist_assistant/core/routes/app_routes.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/screens/login_screen.dart';
import 'package:pharmacist_assistant/features/dashboard/presentation/dashboard.dart';
import 'package:pharmacist_assistant/features/dashboard/presentation/doctor_dashboard.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:pharmacist_assistant/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'features/alarm/screen/medication_alarm_screen.dart';
import 'features/alarm/service/medication_alarm_service.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'firebase_options.dart';

// Global navigator key for alarm navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase ONLY
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Alarm Service (lightweight)
  await Alarm.init();

  runApp(const VirtualPharmacistApp());
}

class VirtualPharmacistApp extends StatefulWidget {
  const VirtualPharmacistApp({Key? key}) : super(key: key);

  @override
  State<VirtualPharmacistApp> createState() => _VirtualPharmacistAppState();
}

class _VirtualPharmacistAppState extends State<VirtualPharmacistApp> with WidgetsBindingObserver {
  final _alarmService = MedicationAlarmService();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenToAlarms();

    // ⬅️ تأخير العمليات الثقيلة بعد بناء الـ UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeHeavyOperations();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _initialized) {
      _rescheduleAlarmsOnStartup();
    }
  }

  /// تهيئة العمليات الثقيلة بعد بناء الواجهة
  Future<void> _initializeHeavyOperations() async {
    if (_initialized) return;

    try {
      // طلب الأذونات
      await MedicationAlarmService.requestPermissions();

      // إعادة جدولة التنبيهات
      await _rescheduleAlarmsOnStartup();

      _initialized = true;
      debugPrint('✅ Heavy operations initialized');
    } catch (e) {
      debugPrint('⚠️ Failed to initialize: $e');
    }
  }

  /// Listen for alarm triggers
  void _listenToAlarms() {
    Alarm.ringStream.stream.listen((alarmSettings) {
      debugPrint('🔔 Alarm ringing: ${alarmSettings.id}');

      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MedicationAlarmScreen(
            alarmSettings: alarmSettings,
          ),
          fullscreenDialog: true,
        ),
      );
    });
  }

  /// إعادة جدولة التنبيهات
  Future<void> _rescheduleAlarmsOnStartup() async {
    try {
      await _alarmService.rescheduleRecurringAlarms();
      debugPrint('✅ Alarms rescheduled');
    } catch (e) {
      debugPrint('⚠️ Failed to reschedule: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => MedicationProvider()),
            ChangeNotifierProvider(create: (_) => AdherenceProvider()),
            ChangeNotifierProvider(create: (_) => ChatProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
          ],
          child: MaterialApp(
          title: 'Virtual Pharmacist',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          navigatorKey: navigatorKey,

          // استخدام الشاشات بتاعتك من AppRoutes
          home: Consumer<AuthProvider>(
            builder: (context, authProvider, _) {
              if (authProvider.status == AuthStatus.loading) {
                return const SplashScreen();
              }
              else if (authProvider.status == AuthStatus.authenticated) {
                // توجيه اليوزر حسب نوعه (مريض ولا دكتور)
                if (authProvider.isPatient) {
                  return const PatientHomeScreen();
                } else if (authProvider.isDoctor) {
                  return const DoctorDashboardScreen();
                } else {
                  return const PatientHomeScreen();
                }
              }
              else {
                return const LoginScreen();
              }
            },
          ),

          routes: AppRoutes.routes,
          onGenerateRoute: AppRoutes.onGenerateRoute,
        ),
        );
      },
    );
  }
}