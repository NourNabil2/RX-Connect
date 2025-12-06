import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
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
                  SizedBox(height: 48.h),

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