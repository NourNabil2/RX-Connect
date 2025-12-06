// lib/features/medications/widgets/medication_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/utils/extension.dart';

/// Filter Chip Widget
class MedicationFilterChip extends StatelessWidget {
  final MedicationFilter filter;
  final bool isSelected;
  final VoidCallback onTap;

  const MedicationFilterChip({
    Key? key,
    required this.filter,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            filter.icon,
            size: 16.r,
            color: isSelected ? Colors.white : theme.hintColor,
          ),
          SizedBox(width: 6.w),
          Text(filter.label),
        ],
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      backgroundColor: theme.cardColor,
      selectedColor: primaryColor,
      labelStyle: TextStyle(
        fontSize: 13.sp,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(
          color: isSelected ? primaryColor : theme.dividerColor,
        ),
      ),
    );
  }
}







