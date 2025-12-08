import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart' as app_auth;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // ⬅️ Navigation واحد فقط بعد بناء الـ frame الأول
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _navigateAfterDelay();
    });
  }

  Future<void> _navigateAfterDelay() async {
    // انتظار قصير للـ smooth animation (500ms كافي)
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted || _hasNavigated) return;

    _checkAndNavigate();
  }

  void _checkAndNavigate() {
    if (_hasNavigated) return;

    final authProvider = context.read<app_auth.AuthProvider>();

    debugPrint('🔍 Auth Check:');
    debugPrint('   Status: ${authProvider.status}');
    debugPrint('   Authenticated: ${authProvider.isAuthenticated}');
    debugPrint('   User: ${authProvider.currentUser?.name}');

    _hasNavigated = true;

    // Navigate based on auth status
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      _navigateToHome(authProvider);
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome(app_auth.AuthProvider authProvider) {
    final user = authProvider.currentUser!;

    debugPrint('✅ Navigating to ${user.role} home');

    if (authProvider.isPatient) {
      AppRoutes.toPatientHome(context);
    } else if (authProvider.isDoctor) {
      AppRoutes.toDoctorHome(context);
    } else {
      debugPrint('⚠️ Unknown role: ${user.role}');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    debugPrint('➡️ Navigating to Login');
    AppRoutes.toLogin(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E88E5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo with simple fade-in
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.medical_services_rounded,
                  size: 70,
                  color: Color(0xFF1E88E5),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // App Name
            const Text(
              'Virtual Pharmacist',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),

            // Tagline
            const Text(
              'صيدليك الشخصي في جيبك',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 50),

            // Loading Indicator
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}