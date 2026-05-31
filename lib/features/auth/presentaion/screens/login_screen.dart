import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/routes/app_routes.dart';
import 'package:pharmacist_assistant/core/theme/colors.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'patient';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Check user role to route correctly
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        final actualRole = userDoc.data()?['role'] ?? 'patient';
        if (!mounted) return;
        
        if (actualRole != _selectedRole) {
          await FirebaseAuth.instance.signOut();
          String error = _selectedRole == 'doctor' ? 'هذا الحساب ليس مسجلاً كطبيب' : 'هذا الحساب ليس مسجلاً كمريض';
          CustomSnackBar.show(context, message: error, type: SnackBarType.error);
          setState(() => _isLoading = false);
          return;
        }

        if (actualRole == 'doctor') {
          Navigator.pushReplacementNamed(context, AppRoutes.doctorHome);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
      }
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ في تسجيل الدخول';
      if (e.code == 'user-not-found') {
        message = 'البريد الإلكتروني غير مسجل';
      } else if (e.code == 'wrong-password') {
        message = 'كلمة المرور غير صحيحة';
      }

      if (!mounted) return;
      CustomSnackBar.show(context, message: message);

    } finally {
    if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  SizedBox(height: 40.h),

                  // Logo
                  Icon(
                    Icons.medical_services_rounded,
                    size: 80.r,
                    color: ColorsManager.primaryColor,
                  ),
                  SizedBox(height: 24.h),

                  // Title
                  Text(
                    'مرحباً بك',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'سجل دخولك للمتابعة',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 32.h),

                  // ─── Role Selection ───
                  Row(
                    children: [
                      Expanded(
                        child: _RoleSelectionCard(
                          icon: Icons.person_rounded,
                          label: 'مريض',
                          subtitle: 'دخول المريض',
                          isSelected: _selectedRole == 'patient',
                          onTap: () => setState(() => _selectedRole = 'patient'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _RoleSelectionCard(
                          icon: Icons.medical_services_rounded,
                          label: 'طبيب',
                          subtitle: 'دخول الطبيب',
                          isSelected: _selectedRole == 'doctor',
                          onTap: () => setState(() => _selectedRole = 'doctor'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),

                  // Email Field
                  AppTextFieldFactory.email(
                    title: 'البريد الإلكتروني',
                    hintText: 'أدخل بريدك الإلكتروني',
                    controller: _emailController,
                    prefixIcon: Icon(Icons.email_outlined, size: 20.r),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال البريد الإلكتروني';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'البريد الإلكتروني غير صالح';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

                  // Password Field
                  AppTextFieldFactory.password(
                    title: 'كلمة المرور',
                    hintText: 'أدخل كلمة المرور',
                    controller: _passwordController,
                    prefixIcon: Icon(Icons.lock_outline, size: 20.r),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'الرجاء إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24.h),

                  // Login Button
                  AppButton(
                    text: 'تسجيل الدخول',
                    onPressed: _login,
                    isLoading: _isLoading,
                    active: true,
                    horizontalPadding: 0,
                  ),
                  SizedBox(height: 24.h),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        child: Text(
                          'أو',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  SizedBox(height: 24.h),

                  // Register Button
                  AppOutlinedButton(
                    text: 'إنشاء حساب جديد',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.register);
                    },
                    active: true,
                    horizontalPadding: 0,
                  ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSelectionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleSelectionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorsManager.primaryColor.withOpacity(0.08)
              : Colors.grey[50],
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isSelected
                ? ColorsManager.primaryColor
                : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorsManager.primaryColor.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 28.r,
              color: isSelected
                  ? ColorsManager.primaryColor
                  : Colors.grey[500],
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? ColorsManager.primaryColor
                    : Colors.grey[700],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10.sp,
                color: isSelected
                    ? ColorsManager.primaryColor.withOpacity(0.7)
                    : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }
}