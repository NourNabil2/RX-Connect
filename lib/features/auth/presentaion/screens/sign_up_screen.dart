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
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();

  bool _isLoading = false;
  String _selectedRole = 'patient'; // 'patient' or 'doctor'

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
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
      final userData = UserModel(
        id: user.uid,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: null,
        role: _selectedRole,
        dateOfBirth: null,
        chronicConditions: null,
        connectedDoctorId: null,
        profileImageUrl: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ).toJson();

      // إضافة حقول الطبيب الإضافية
      if (_selectedRole == 'doctor') {
        userData['specialization'] = _specializationController.text.trim().isNotEmpty
            ? _specializationController.text.trim()
            : 'طبيب عام';
        userData['hospital'] = _hospitalController.text.trim().isNotEmpty
            ? _hospitalController.text.trim()
            : null;
      }

      // حفظ البيانات في Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set(userData);

      if (!mounted) return;

      // الانتقال للصفحة الرئيسية حسب الدور
      if (_selectedRole == 'doctor') {
        Navigator.pushReplacementNamed(context, AppRoutes.doctorHome);
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.patientHome);
      }
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
                  SizedBox(height: 32.h),

                  // ─── Role Selection ───
                  Text(
                    'نوع الحساب',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _RoleSelectionCard(
                          icon: Icons.person_rounded,
                          label: 'مريض',
                          subtitle: 'تتبع أدويتك',
                          isSelected: _selectedRole == 'patient',
                          onTap: () => setState(() => _selectedRole = 'patient'),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _RoleSelectionCard(
                          icon: Icons.medical_services_rounded,
                          label: 'طبيب',
                          subtitle: 'تابع مرضاك',
                          isSelected: _selectedRole == 'doctor',
                          onTap: () => setState(() => _selectedRole = 'doctor'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // ─── Doctor Extra Fields ───
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: _selectedRole == 'doctor'
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                    firstChild: Column(
                      children: [
                        AppTextField(
                          title: 'التخصص',
                          hintText: 'مثال: أخصائي باطنة',
                          controller: _specializationController,
                          prefixIcon: Icon(Icons.local_hospital_outlined, size: 20.r),
                          keyboardType: TextInputType.text,
                        ),
                        SizedBox(height: 16.h),
                        AppTextField(
                          title: 'المستشفى / العيادة',
                          hintText: 'مثال: مستشفى الملك فهد',
                          controller: _hospitalController,
                          prefixIcon: Icon(Icons.business_outlined, size: 20.r),
                          keyboardType: TextInputType.text,
                        ),
                        SizedBox(height: 16.h),
                      ],
                    ),
                    secondChild: const SizedBox.shrink(),
                  ),

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

// ─── Role Selection Card Widget ───
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