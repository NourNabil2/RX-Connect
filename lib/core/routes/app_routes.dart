import 'package:flutter/material.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/screens/login_screen.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/screens/sign_up_screen.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/medication_details_screen.dart';
import 'package:pharmacist_assistant/features/dashboard/presentation/doctor_dashboard.dart';

// Screens
import '../../features/add_medication/presenteation/add_medication_screen.dart';
import '../../features/dashboard/presentation/dashboard.dart';

class AppRoutes {
  // Auth Routes
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role-selection';
  static const String login = '/login';
  static const String register = '/register';

  // Patient Routes
  static const String patientHome = '/patient/home';
  static const String addMedication = '/patient/add-medication';
  static const String medicationsList = '/patient/medications';
  static const String medicationDetails = '/patient/medication-details';
  static const String reminders = '/patient/reminders';
  static const String chat = '/patient/chat';
  static const String profile = '/patient/profile';
  static const String settings = '/patient/settings';

  // Doctor Routes
  static const String doctorHome = '/doctor/home';
  static const String patientsList = '/doctor/patients';
  static const String patientDetails = '/doctor/patient-details';

  // Named Routes Map
  static Map<String, WidgetBuilder> get routes => {
    // onboarding: (context) => const OnboardingScreen(),
    // roleSelection: (context) => const RoleSelectionScreen(),
    login: (context) => const LoginScreen(),


    // Patient
    patientHome: (context) => const PatientHomeScreen(),
    addMedication: (context) => const AddMedicationScreen(),
    register: (context) => const SignUpScreen(),

    // Doctor
    doctorHome: (context) => const DoctorDashboardScreen(),
    medicationDetails: (context) {
      final args = ModalRoute.of(context)!.settings.arguments;
      if (args is MedicationModel) {
        return MedicationDetailsScreen(medication: args);
      }
      return const Scaffold(
        body: Center(child: Text('خطأ: بيانات الدواء غير متوفرة')),
      );
    },
    // reminders: (context) => const RemindersScreen(),
    // chat: (context) => const ChatScreen(),
    // profile: (context) => const ProfileScreen(),
    // settings: (context) => const SettingsScreen(),
    //
    // // Doctor
    // doctorHome: (context) => const DoctorHomeScreen(),
    // patientsList: (context) => const PatientsListScreen(),
  };

  // Generate Route with Arguments
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {

      // case medicationDetails:
      //   final medicationId = settings.arguments as String;
      //   return MaterialPageRoute(
      //     builder: (_) => MedicationDetailsScreen(medicationId: medicationId),
      //   );
      //
      // case patientDetails:
      //   final patientId = settings.arguments as String;
      //   return MaterialPageRoute(
      //     builder: (_) => PatientDetailsScreen(patientId: patientId),
      //   );

      default:
        return null;
    }
  }

  // Navigation Helpers
  static void toLogin(BuildContext context) {
    Navigator.pushReplacementNamed(context, login);
  }

  static void toPatientHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      patientHome,
          (route) => false,
    );
  }

  static void toDoctorHome(BuildContext context) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      doctorHome,
          (route) => false,
    );
  }

  static void toAddMedication(BuildContext context) {
    Navigator.pushNamed(context, addMedication);
  }

  static void toMedicationDetails(BuildContext context, MedicationModel medication) {
    Navigator.pushNamed(context, medicationDetails, arguments: medication);
  }

  static void toPatientDetails(BuildContext context, String patientId) {
    Navigator.pushNamed(context, patientDetails, arguments: patientId);
  }
}