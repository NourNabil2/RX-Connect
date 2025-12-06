import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pharmacist_assistant/core/theme/text_theme.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';


Widget buildAdherenceCard(BuildContext context, {required double percentage, required int streak}) {
  final theme = Theme.of(context);

  return Container(
    padding: EdgeInsets.all(14.r),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(18.r),
      boxShadow: [
        BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4)
        ),
      ],
    ),
    child: IntrinsicHeight(
      child: Row(
        children: [
          // Circular Indicator
          SizedBox(
            width: 60.r,
            height: 60.r,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: percentage / 100,
                  strokeAlign: 4,
                  strokeWidth: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest, // Or generic grey
                  valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                ),
                FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    '${percentage.toInt()}%',
                    // Using labelLarge but overriding color to Primary
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 16.sp,
                      color: theme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: 12.w),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'نسبة الالتزام الأسبوعية',
                  style: theme.textTheme.titleSmall, // Mapped to 13.sp bold
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    // Semantic colors (like Orange for streaks) usually remain hardcoded
                    // or come from a specific semantic extension, but here we keep orange.
                    Icon(Icons.local_fire_department, color: Colors.orange, size: 14.r),
                    SizedBox(width: 4.w),
                    Text(
                      '$streak أيام',
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.sp),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
// lib/core/widgets/card_widgets.dart

Widget buildMedicationCard(
    BuildContext context, {
      required String name,
      required String dose,
      required String time,
      required bool taken,
      required bool isDueNow,
      required bool isTimePassed,
      required Color statusColor, // This color usually comes from logic, not theme
      String? imageUrl,
      VoidCallback? onTake,
    }) {
  final theme = Theme.of(context);

  return Consumer<AdherenceProvider>(
    builder: (context, adherence, _) {
      final isTakenNow = adherence.isMedicationTaken(name, time);
      final isDue = adherence.isMedicationDueNow(time);
      final isPassed = adherence.hasMedicationTimePassed(time);

      return Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16.r),
          // Using semantic warning color for border if due
          border: isDue ? Border.all(color: Colors.orange, width: 1.5) : null,
          boxShadow: [
            BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2)
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            if (imageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12.r),
                child: Image.network(imageUrl, width: 50.r, height: 50.r, fit: BoxFit.cover),
              )
            else
              Container(
                width: 50.r, height: 50.r,
                decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r)
                ),
                child: Icon(Icons.medication, color: statusColor, size: 28.r),
              ),

            SizedBox(width: 16.w),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      name,
                      style: theme.textTheme.titleMedium // 20.sp semi-bold
                  ),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Text(
                          '$dose • $time',
                          style: theme.textTheme.bodySmall // 14.sp grey
                      ),
                      if (isDue) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                          decoration: BoxDecoration(
                              color: Colors.orange[100],
                              borderRadius: BorderRadius.circular(8.r)
                          ),
                          child: Text(
                              'الآن',
                              style: theme.textTheme.displaySmall?.copyWith(
                                  fontSize: 10.sp,
                                  color: Colors.orange[800],
                                  fontWeight: FontWeight.bold
                              )
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Action Icons
            if (isTakenNow)
              Icon(Icons.check_circle, color: AppTextTheme.successTextLight.color, size: 28.r)
            else if (isPassed)
              Icon(Icons.close, color: theme.colorScheme.error, size: 28.r)
            else
              OutlinedButton(
                onPressed: onTake,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  side: BorderSide(color: statusColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text(
                    'تم الأخذ',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontSize: 13.sp,
                        color: statusColor
                    )
                ),
              ),
          ],
        ),
      );
    },
  );
}

/* ------------------- Medication List Card (Medications Screen) ------------------- */
Widget buildMedicationListCard(
    BuildContext context, {
      required String name,
      required String dosage,
      required String frequency,
      required List<String> times,
      required IconData icon,
      required Color color, // Semantic color for the specific pill
      String? imageUrl,
      VoidCallback? onTap,
    }) {
  final theme = Theme.of(context);

  return Container(
    margin: EdgeInsets.only(bottom: 12.h),
    decoration: BoxDecoration(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: theme.shadowColor.withOpacity(0.06),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Row(
            children: [
              // Medicine Image/Icon
              _buildMedicineImage(imageUrl, color, size: 60.r, iconSize: 32.r),
              SizedBox(width: 16.w),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 17.sp, // Slight override if needed, or stick to theme
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color ?? Colors.black
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            dosage,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 12.sp,
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Icon(Icons.repeat, size: 14.r, color: theme.textTheme.bodySmall?.color),
                        SizedBox(width: 4.w),
                        Text(
                          frequency,
                          style: theme.textTheme.bodySmall?.copyWith(fontSize: 13.sp),
                        ),
                      ],
                    ),
                    if (times.isNotEmpty) ...[
                      SizedBox(height: 8.h),
                      Wrap(
                        spacing: 6.w,
                        runSpacing: 6.h,
                        children: times.take(3).map((time) {
                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: theme.scaffoldBackgroundColor, // or specific grey
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, size: 12.r, color: theme.textTheme.bodySmall?.color),
                                SizedBox(width: 4.w),
                                Text(
                                  time,
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontSize: 11.sp,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16.r,
                color: theme.disabledColor,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/* ------------------- Quick Action Card ------------------- */
Widget buildQuickActionCard(
    BuildContext context, {
      required String title,
      required IconData icon,
      required Color color,
      VoidCallback? onTap,
    }) {
  final theme = Theme.of(context);

  return Expanded(
    child: Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 28.r, color: color),
                ),
                SizedBox(height: 12.h),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/* ------------------- Helper: Build Medicine Image ------------------- */
Widget _buildMedicineImage(
    String? imageUrl,
    Color fallbackColor, {
      double size = 56,
      double iconSize = 28,
    }) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: fallbackColor.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12.r),
      border: Border.all(
        color: fallbackColor.withOpacity(0.2),
        width: 1.5,
      ),
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(12.r),
      child: _buildImageWidget(imageUrl, fallbackColor, iconSize),
    ),
  );
}

Widget _buildImageWidget(String? imageUrl, Color fallbackColor, double iconSize) {
  // No image
  if (imageUrl == null || imageUrl.isEmpty) {
    return Icon(
      Icons.medication,
      color: fallbackColor,
      size: iconSize,
    );
  }

  // Local file
  if (imageUrl.startsWith('/') || imageUrl.startsWith('file://')) {
    final file = File(imageUrl.replaceFirst('file://', ''));
    if (file.existsSync()) {
      return Image.file(
        file,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.medication,
          color: fallbackColor,
          size: iconSize,
        ),
      );
    }
  }

  // Network image
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      placeholder: (_, __) => Center(
        child: SizedBox(
          width: iconSize * 0.6,
          height: iconSize * 0.6,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(fallbackColor),
          ),
        ),
      ),
      errorWidget: (_, __, ___) => Icon(
        Icons.medication,
        color: fallbackColor,
        size: iconSize,
      ),
    );
  }

  // Fallback
  return Icon(
    Icons.medication,
    color: fallbackColor,
    size: iconSize,
  );
}