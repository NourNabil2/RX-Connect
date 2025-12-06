// lib/features/auth/presentation/screens/signup_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/routes/app_routes.dart';
import 'package:pharmacist_assistant/core/theme/colors.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';

import '../../../../core/widgets/custom_snack_bar.dart';


class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // إنشاء حساب في Firebase Auth
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final user = userCredential.user;
      if (user == null) return;

      // إنشاء نموذج المستخدم
      final newUser = UserModel(
        id: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: null,
        role: 'patient', // يمكن تغييره لاحقًا
        dateOfBirth: null,
        chronicConditions: null,
        connectedDoctorId: null,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // حفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(newUser.toJson());

      if (!mounted) return;

      // الانتقال للصفحة الرئيسية
      Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
    } on FirebaseAuthException catch (e) {
      String message = 'حدث خطأ أثناء إنشاء الحساب';
      if (e.code == 'weak-password') {
        message = 'كلمة المرور ضعيفة جدًا';
      } else if (e.code == 'email-already-in-use') {
        message = 'البريد الإلكتروني مستخدم بالفعل';
      } else if (e.code == 'invalid-email') {
        message = 'البريد الإلكتروني غير صالح';
      }

      if (!mounted) return;
      CustomSnackBar.show(context, message: message);
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(context, message: 'try again, please.',type: SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                    'إنشاء حساب جديد',
                    style: TextStyle(
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E88E5),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'سجل بياناتك لتبدأ',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 48.h),

                  // Name Field
                  AppTextField(
                    title: 'الاسم الكامل',
                    hintText: 'أدخل اسمك الكامل',
                    controller: _nameController,
                    prefixIcon: Icon(Icons.person_outline, size: 20.r),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'الرجاء إدخال الاسم';
                      }
                      if (value.trim().length < 3) {
                        return 'الاسم قصير جدًا';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16.h),

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
                  SizedBox(height: 16.h),

                  // Confirm Password
                  AppTextFieldFactory.password(
                    title: 'تأكيد كلمة المرور',
                    hintText: 'أعد إدخال كلمة المرور',
                    controller: _confirmPasswordController,
                    prefixIcon: Icon(Icons.lock_outline, size: 20.r),
                    validator: (value) {
                      if (value != _passwordController.text) {
                        return 'كلمة المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 32.h),

                  // Sign Up Button
                  AppButton(
                    text: 'إنشاء الحساب',
                    onPressed: _signUp,
                    isLoading: _isLoading,
                    active: true,
                    horizontalPadding: 0,
                  ),
                  SizedBox(height: 24.h),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'لديك حساب بالفعل؟ ',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, AppRoutes.login);
                        },
                        child: Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: ColorsManager.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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