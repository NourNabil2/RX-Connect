// lib/core/widgets/add_medication_widgets.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/utils/extension.dart';


/// ----------  Interaction Alert Card ----------
Widget buildInteractionCard(DrugInteractionModel interaction) {
  final isMajor = interaction.severity == 'major';
  final color = isMajor ? Colors.red : Colors.orange;

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    padding: EdgeInsets.all(12.r),
    decoration: BoxDecoration(
      color: isMajor ? Colors.red[50] : Colors.orange[50],
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(color: color, width: 1.2),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(isMajor ? Icons.dangerous : Icons.warning, color: color, size: 20.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                '${interaction.drug1} ↔ ${interaction.drug2}',
                style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 14.sp),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Text(interaction.description, style: TextStyle(fontSize: 13.sp)),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8.r)),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16),
              SizedBox(width: 8.w),
              Expanded(child: Text(interaction.recommendation, style: TextStyle(fontSize: 12.sp))),
            ],
          ),
        ),
      ],
    ),
  );
}
