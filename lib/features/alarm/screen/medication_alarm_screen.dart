// lib/features/alarm/screens/medication_alarm_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:alarm/alarm.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/alarm/service/medication_alarm_service.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';
import 'package:provider/provider.dart';

class MedicationAlarmScreen extends StatefulWidget {
  final AlarmSettings alarmSettings;

  const MedicationAlarmScreen({
    Key? key,
    required this.alarmSettings,
  }) : super(key: key);

  @override
  State<MedicationAlarmScreen> createState() => _MedicationAlarmScreenState();
}

class _MedicationAlarmScreenState extends State<MedicationAlarmScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  final _alarmService = MedicationAlarmService();

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.primary,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
              ],
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 40.h),
              _buildTimeDisplay(),
              SizedBox(height: 60.h),
              _buildMedicationInfo(),
              const Spacer(),
              _buildActionButtons(),
              SizedBox(height: 40.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final now = DateTime.now();
    final timeString = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Column(
      children: [
        Text(
          'وقت الدواء',
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.white70,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          timeString,
          style: TextStyle(
            fontSize: 64.sp,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildMedicationInfo() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: child,
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 40.w),
        padding: EdgeInsets.all(32.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Medication Icon
            Container(
              width: 100.r,
              height: 100.r,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.medication_rounded,
                size: 60.r,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: 24.h),

            // Medication Name
            Text(
              widget.alarmSettings.notificationSettings.body,
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),

            // Message
            Text(
              'حان وقت تناول دوائك',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        children: [
          // Stop Alarm Button
          _buildButton(
            label: 'أخذت الدواء ✅',
            icon: Icons.check_circle,
            color: Colors.green,
            onPressed: _stopAlarmAndConfirm,
          ),
          SizedBox(height: 16.h),

          // Snooze Button
          _buildButton(
            label: 'تأجيل 5 دقائق',
            icon: Icons.snooze,
            color: Colors.orange,
            onPressed: _snoozeAlarm,
          ),
          SizedBox(height: 16.h),

          // Dismiss Button
          TextButton(
            onPressed: _dismissAlarm,
            child: Text(
              'تجاهل',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28.r),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 8,
          shadowColor: color.withOpacity(0.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
        ),
      ),
    );
  }

  void _stopAlarmAndConfirm() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (!mounted) return;

    try {
      // 1. استخراج اسم الدواء من نص الإشعار
      final body = widget.alarmSettings.notificationSettings.body;
      final medName = body.split(' - ').first;

      // 2. البحث عن الدواء في MedicationProvider
      final medProvider = context.read<MedicationProvider>();
      final medication = medProvider.medications.firstWhere(
            (m) => m.name == medName,
      );

      // 3. تسجيل الجرعة في AdherenceProvider (تم الأخذ)
      final authProvider = context.read<AuthProvider>();
      final adherenceProvider = context.read<AdherenceProvider>();

      if (authProvider.currentUser != null) {
        await adherenceProvider.logDose(
          userId: authProvider.currentUser!.id,
          medicationId: medication.id,
          medicationName: medication.name,
          status: 'taken', // ⬅️ حالة الجرعة: تم أخذها
          scheduledTime: widget.alarmSettings.dateTime,
          actualTime: DateTime.now(),
        );
      }

      CustomSnackBar.show(
        context,
        message: 'تم تسجيل الجرعة بنجاح ✅',
        type: SnackBarType.success,
      );
    } catch (e) {
      debugPrint('Error logging dose: $e');
    }

    Navigator.pop(context, true);
  }

  void _snoozeAlarm() async {
    await _alarmService.snoozeAlarm(widget.alarmSettings, minutes: 5);
    if (!mounted) return;

    CustomSnackBar.show(
      context,
      message: 'سيتم التذكير بعد 5 دقائق',
      type: SnackBarType.info,
    );

    Navigator.pop(context, false);
  }

  void _dismissAlarm() async {
    await Alarm.stop(widget.alarmSettings.id);
    if (!mounted) return;

    try {
      final body = widget.alarmSettings.notificationSettings.body;
      final medName = body.split(' - ').first;

      final medProvider = context.read<MedicationProvider>();
      final medication = medProvider.medications.firstWhere(
            (m) => m.name == medName,
      );

      final authProvider = context.read<AuthProvider>();
      final adherenceProvider = context.read<AdherenceProvider>();

      if (authProvider.currentUser != null) {
        // تسجيل الجرعة كـ Missed (تم تفويتها)
        await adherenceProvider.logDose(
          userId: authProvider.currentUser!.id,
          medicationId: medication.id,
          medicationName: medication.name,
          status: 'missed', // ⬅️ حالة الجرعة: تم تفويتها
          scheduledTime: widget.alarmSettings.dateTime,
        );
      }
    } catch (e) {
      debugPrint('Error logging missed dose: $e');
    }

    Navigator.pop(context, false);
  }
}

