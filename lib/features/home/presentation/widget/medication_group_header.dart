import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/utils/extension.dart';

/// Medication Group Header
class MedicationGroupHeader extends StatelessWidget {
  final String frequency;
  final int count;

  const MedicationGroupHeader({
    Key? key,
    required this.frequency,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (groupIcon, groupColor, groupLabel) = frequency.getGroupStyle();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(groupIcon, color: groupColor, size: 18.r),
          ),
          SizedBox(width: 10.w),
          Text(
            groupLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8.w),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: groupColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: groupColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
