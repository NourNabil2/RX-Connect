import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';


/// Statistics Card Widget
class MedicationStatCard extends StatelessWidget {
  final String label;
  final String count;
  final IconData icon;
  final Color color;

  const MedicationStatCard({
    Key? key,
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.r),
          ),
          SizedBox(height: 8.h),
          Text(
            count,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }
}