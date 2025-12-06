import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


/// Delete Confirmation Dialog
class MedicationDeleteDialog extends StatelessWidget {
  final String medicationName;

  const MedicationDeleteDialog({
    Key? key,
    required this.medicationName,
  }) : super(key: key);

  static Future<bool> show(BuildContext context, String medicationName) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => MedicationDeleteDialog(medicationName: medicationName),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange,
              size: 48.r,
            ),
            SizedBox(height: 16.h),
            Text(
              'حذف "$medicationName"؟',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'سيتم حذف جميع السجلات المرتبطة',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            SizedBox(height: 20.h),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('إلغاء'),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('حذف'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}