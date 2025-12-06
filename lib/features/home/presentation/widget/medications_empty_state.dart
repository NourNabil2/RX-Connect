import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


/// Empty State Widget
class MedicationsEmptyState extends StatelessWidget {
  final VoidCallback onAddPressed;

  const MedicationsEmptyState({
    Key? key,
    required this.onAddPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120.r,
              height: 120.r,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_pharmacy_outlined,
                size: 60.r,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 32.h),
            Text(
              'مكتبتك فارغة',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              'ابدأ ببناء مكتبة أدويتك الخاصة\nوتتبع جميع أدويتك في مكان واحد',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
                height: 1.6,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add, size: 20),
              label: Text(
                'إضافة دواء جديد',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}