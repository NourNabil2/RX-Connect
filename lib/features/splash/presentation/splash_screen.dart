import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/routes/app_routes.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart'
as app_auth;

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();

    // Wait for animation then check auth
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Wait for animation to complete
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // Listen to AuthProvider status
    _checkAuthStatus();
  }

  void _checkAuthStatus() {
    final authProvider = Provider.of<app_auth.AuthProvider>(
      context,
      listen: false,
    );

    print('🔍 Checking auth status...');
    print('   Status: ${authProvider.status}');
    print('   Is Authenticated: ${authProvider.isAuthenticated}');
    print('   Current User: ${authProvider.currentUser?.name ?? "null"}');

    // If already authenticated, navigate immediately
    if (authProvider.isAuthenticated && authProvider.currentUser != null) {
      _navigateBasedOnRole(authProvider);
      return;
    }

    // Otherwise, listen for auth changes
    // Add a timeout in case auth never resolves
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted || _hasNavigated) return;

      final provider = Provider.of<app_auth.AuthProvider>(
        context,
        listen: false,
      );

      if (provider.isAuthenticated && provider.currentUser != null) {
        _navigateBasedOnRole(provider);
      } else {
        _navigateToLogin();
      }
    });
  }

  void _navigateBasedOnRole(app_auth.AuthProvider authProvider) {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    print('✅ User authenticated: ${authProvider.currentUser!.name}');
    print('   Role: ${authProvider.currentUser!.role}');

    if (authProvider.isPatient) {
      print('➡️ Navigating to Patient Home');
      AppRoutes.toPatientHome(context);
    } else if (authProvider.isDoctor) {
      print('➡️ Navigating to Doctor Home');
      AppRoutes.toDoctorHome(context);
    } else {
      print('⚠️ Unknown role, navigating to Login');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;

    print('➡️ Navigating to Login');
    AppRoutes.toLogin(context);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<app_auth.AuthProvider>(
      builder: (context, authProvider, _) {
        // Listen to auth changes and navigate accordingly
        if (!_hasNavigated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (authProvider.status == app_auth.AuthStatus.authenticated &&
                authProvider.currentUser != null) {
              _navigateBasedOnRole(authProvider);
            } else if (authProvider.status ==
                app_auth.AuthStatus.unauthenticated) {
              _navigateToLogin();
            }
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF1E88E5),
          body: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  Container(
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
                  const SizedBox(height: 20),

                  // Debug status (remove in production)
                  if (authProvider.status == app_auth.AuthStatus.loading)
                    const Text(
                      'جاري التحميل...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}