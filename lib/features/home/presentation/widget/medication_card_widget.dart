// lib/features/home/presentation/widgets/home_medication_card.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_image_widget.dart';

/// Status enum for medication card
enum MedicationStatus {
  taken,
  due,
  passed,
  upcoming;

  bool get isTaken => this == MedicationStatus.taken;
  bool get isDue => this == MedicationStatus.due;
  bool get isPassed => this == MedicationStatus.passed;
  bool get isUpcoming => this == MedicationStatus.upcoming;
}

/// Extension for medication status styling
extension MedicationStatusExtension on MedicationStatus {
  Color get color {
    return switch (this) {
      MedicationStatus.taken => const Color(0xFF4CAF50),
      MedicationStatus.due => const Color(0xFFFF9800),
      MedicationStatus.passed => const Color(0xFFEF5350),
      MedicationStatus.upcoming => const Color(0xFF64B5F6),
    };
  }

  Color get backgroundColor {
    return switch (this) {
      MedicationStatus.taken => const Color(0xFFF1F8F4),
      MedicationStatus.due => const Color(0xFFFFF8E1),
      MedicationStatus.passed => const Color(0xFFFFEBEE),
      MedicationStatus.upcoming => Colors.white,
    };
  }

  String get label {
    return switch (this) {
      MedicationStatus.taken => 'تم',
      MedicationStatus.due => 'الآن',
      MedicationStatus.passed => 'فات',
      MedicationStatus.upcoming => 'قريباً',
    };
  }

  IconData get icon {
    return switch (this) {
      MedicationStatus.taken => Icons.check_circle,
      MedicationStatus.due => Icons.notifications_active,
      MedicationStatus.passed => Icons.cancel,
      MedicationStatus.upcoming => Icons.schedule,
    };
  }
}

/// Home Medication Card Widget
class HomeMedicationCard extends StatelessWidget {
  final MedicationModel medication;
  final String time;
  final bool isTaken;
  final bool isDue;
  final bool isPassed;
  final VoidCallback onTake;

  const HomeMedicationCard({
    Key? key,
    required this.medication,
    required this.time,
    required this.isTaken,
    required this.isDue,
    required this.isPassed,
    required this.onTake,
  }) : super(key: key);

  MedicationStatus get _status {
    if (isTaken) return MedicationStatus.taken;
    if (isDue) return MedicationStatus.due;
    if (isPassed) return MedicationStatus.passed;
    return MedicationStatus.upcoming;
  }

  bool get _isInteractive => !isTaken && !isPassed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final status = _status;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: status.isDue ? status.color : status.color.withOpacity(0.2),
          width: status.isDue ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isInteractive ? onTake : null,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(14.r),
            child: Row(
              children: [
                _MedicationImage(
                  medication: medication,
                  status: status,
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: _MedicationInfo(
                    medication: medication,
                    time: time,
                    status: status,
                  ),
                ),
                SizedBox(width: 10.w),
                _MedicationAction(
                  status: status,
                  isInteractive: _isInteractive,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Medication Image with Status Badge
class _MedicationImage extends StatelessWidget {
  final MedicationModel medication;
  final MedicationStatus status;

  const _MedicationImage({
    required this.medication,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: status.color.withOpacity(0.3),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: MedicationImageWidget(
              imageUrl: medication.imageUrl,
              statusColor: status.color,
              size: 56,
              borderRadius: 12,
            ),
          ),
        ),
        if (status.isTaken || status.isPassed)
          Positioned(
            top: -2,
            right: -2,
            child: _StatusBadge(status: status),
          ),
      ],
    );
  }
}

/// Status Badge for Medication Image
class _StatusBadge extends StatelessWidget {
  final MedicationStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.r),
      decoration: BoxDecoration(
        color: status.color,
        shape: BoxShape.circle,
        border: Border.all(
          color: status.backgroundColor,
          width: 2,
        ),
      ),
      child: Icon(
        status.isTaken ? Icons.check : Icons.close,
        color: Colors.white,
        size: 12.r,
      ),
    );
  }
}

/// Medication Information Section
class _MedicationInfo extends StatelessWidget {
  final MedicationModel medication;
  final String time;
  final MedicationStatus status;

  const _MedicationInfo({
    required this.medication,
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          medication.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 6.h),
        _DosageInfo(dosage: medication.dosage),
        SizedBox(height: 4.h),
        _TimeInfo(time: time, status: status),
      ],
    );
  }
}

/// Dosage Information
class _DosageInfo extends StatelessWidget {
  final String dosage;

  const _DosageInfo({required this.dosage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          Icons.medication_liquid,
          size: 14.r,
          color: theme.hintColor,
        ),
        SizedBox(width: 4.w),
        Expanded(
          child: Text(
            dosage,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.hintColor,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Time Information with Status Badge
class _TimeInfo extends StatelessWidget {
  final String time;
  final MedicationStatus status;

  const _TimeInfo({
    required this.time,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _TimeChip(time: time, color: status.color),
        if (status.isDue) ...[
          SizedBox(width: 6.w),
          _DueNowChip(),
        ],
      ],
    );
  }
}

/// Time Chip
class _TimeChip extends StatelessWidget {
  final String time;
  final Color color;

  const _TimeChip({
    required this.time,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time, size: 12.r, color: color),
          SizedBox(width: 4.w),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Due Now Chip
class _DueNowChip extends StatelessWidget {
  const _DueNowChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.notifications_active,
            size: 11.r,
            color: Colors.white,
          ),
          SizedBox(width: 3.w),
          Text(
            'الآن',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

/// Medication Action Button/Status
class _MedicationAction extends StatelessWidget {
  final MedicationStatus status;
  final bool isInteractive;

  const _MedicationAction({
    required this.status,
    required this.isInteractive,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isTaken || status.isPassed) {
      return _StatusIndicator(status: status);
    }

    return _ConfirmButton(
      isEnabled: isInteractive,
      color: status.color,
    );
  }
}

/// Status Indicator (Taken/Passed)
class _StatusIndicator extends StatelessWidget {
  final MedicationStatus status;

  const _StatusIndicator({required this.status});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(8.r),
          decoration: BoxDecoration(
            color: status.color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            status.icon,
            color: status.color,
            size: 24.r,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 10.sp,
            color: status.color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Confirm Button
class _ConfirmButton extends StatelessWidget {
  final bool isEnabled;
  final Color color;

  const _ConfirmButton({
    required this.isEnabled,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isEnabled ? color : Colors.grey[300],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white,
            size: 22.r,
          ),
          SizedBox(height: 3.h),
          Text(
            'تأكيد',
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}