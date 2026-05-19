import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_image_widget.dart';

// ─────────────────────────────────────────────
//  STATUS ENUM
// ─────────────────────────────────────────────
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

extension MedicationStatusStyle on MedicationStatus {
  // Card background
  Color get backgroundColor => switch (this) {
    MedicationStatus.taken => const Color(0xFFF0FAF5),
    MedicationStatus.due => const Color(0xFFFFFBF0),
    MedicationStatus.passed => const Color(0xFFFFF2F2),
    MedicationStatus.upcoming => Colors.white,
  };

  // Accent / border color
  Color get accentColor => switch (this) {
    MedicationStatus.taken => const Color(0xFF2E9E68),
    MedicationStatus.due => const Color(0xFFE8920A),
    MedicationStatus.passed => const Color(0xFFD94040),
    MedicationStatus.upcoming => const Color(0xFF5B9BD5),
  };

  // Soft tint for badges
  Color get tintColor => accentColor.withOpacity(0.12);

  String get label => switch (this) {
    MedicationStatus.taken => 'تم',
    MedicationStatus.due => 'حان الوقت',
    MedicationStatus.passed => 'فاتت',
    MedicationStatus.upcoming => 'قريباً',
  };

  IconData get icon => switch (this) {
    MedicationStatus.taken => Icons.check_circle_rounded,
    MedicationStatus.due => Icons.notifications_active_rounded,
    MedicationStatus.passed => Icons.cancel_rounded,
    MedicationStatus.upcoming => Icons.schedule_rounded,
  };
}

// ─────────────────────────────────────────────
//  MAIN CARD
// ─────────────────────────────────────────────
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
    final status = _status;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: status.backgroundColor,
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: status.isDue
                ? status.accentColor.withOpacity(0.6)
                : status.accentColor.withOpacity(0.15),
            width: status.isDue ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isInteractive ? onTake : null,
            borderRadius: BorderRadius.circular(18.r),
            splashColor: status.accentColor.withOpacity(0.08),
            child: Padding(
              padding: EdgeInsets.all(14.r),
              child: Row(
                children: [
                  _MedicationAvatar(medication: medication, status: status),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: _MedicationInfo(
                      medication: medication,
                      time: time,
                      status: status,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  _ActionArea(
                    status: status,
                    isInteractive: _isInteractive,
                    onTake: onTake,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Avatar with badge ───
class _MedicationAvatar extends StatelessWidget {
  final MedicationModel medication;
  final MedicationStatus status;

  const _MedicationAvatar({required this.medication, required this.status});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: status.tintColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: status.accentColor.withOpacity(0.25)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13.r),
            child: MedicationImageWidget(
              imageUrl: medication.imageUrl,
              statusColor: status.accentColor,
              size: 56,
              borderRadius: 13,
            ),
          ),
        ),
        // Badge overlay for taken / passed
        if (status.isTaken || status.isPassed)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 20.r,
              height: 20.r,
              decoration: BoxDecoration(
                color: status.accentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(
                status.isTaken ? Icons.check_rounded : Icons.close_rounded,
                color: Colors.white,
                size: 11.r,
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Info section ───
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          medication.name,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4.h),

        // Dosage row
        Row(
          children: [
            Icon(Icons.medication_liquid_outlined, size: 13.r, color: Colors.grey[500]),
            SizedBox(width: 4.w),
            Expanded(
              child: Text(
                medication.dosage,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // Time + Due badge
        Row(
          children: [
            _TimeChip(time: time, status: status),
            if (status.isDue) ...[
              SizedBox(width: 6.w),
              _PulsingDueBadge(),
            ],
          ],
        ),
      ],
    );
  }
}

// ─── Time chip ───
class _TimeChip extends StatelessWidget {
  final String time;
  final MedicationStatus status;

  const _TimeChip({required this.time, required this.status});

  @override
  Widget build(BuildContext context) {
    final hour = int.tryParse(time.split(':').first) ?? 0;
    final icon = hour < 12 ? Icons.wb_sunny_outlined : Icons.nightlight_round;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: status.tintColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.r, color: status.accentColor),
          SizedBox(width: 4.w),
          Text(
            time,
            style: TextStyle(
              fontSize: 12.sp,
              color: status.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Pulsing "due now" badge ───
class _PulsingDueBadge extends StatefulWidget {
  @override
  State<_PulsingDueBadge> createState() => _PulsingDueBadgeState();
}

class _PulsingDueBadgeState extends State<_PulsingDueBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
        decoration: BoxDecoration(
          color: const Color(0xFFE8920A),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_active_rounded, size: 11.r, color: Colors.white),
            SizedBox(width: 3.w),
            Text(
              'الآن',
              style: TextStyle(fontSize: 11.sp, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action area ───
class _ActionArea extends StatelessWidget {
  final MedicationStatus status;
  final bool isInteractive;
  final VoidCallback onTake;

  const _ActionArea({
    required this.status,
    required this.isInteractive,
    required this.onTake,
  });

  @override
  Widget build(BuildContext context) {
    if (status.isTaken || status.isPassed) {
      return _StatusIndicator(status: status);
    }
    return _ConfirmButton(
      isEnabled: isInteractive,
      color: status.accentColor,
      onTap: onTake,
    );
  }
}

// ─── Status indicator (taken/passed) ───
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
            color: status.tintColor,
            shape: BoxShape.circle,
          ),
          child: Icon(status.icon, color: status.accentColor, size: 22.r),
        ),
        SizedBox(height: 4.h),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 10.sp,
            color: status.accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Confirm button ───
class _ConfirmButton extends StatelessWidget {
  final bool isEnabled;
  final Color color;
  final VoidCallback onTap;

  const _ConfirmButton({
    required this.isEnabled,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isEnabled ? color : Colors.grey[200],
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_rounded,
              color: isEnabled ? Colors.white : Colors.grey[400],
              size: 22.r,
            ),
            SizedBox(height: 3.h),
            Text(
              'تأكيد',
              style: TextStyle(
                fontSize: 11.sp,
                color: isEnabled ? Colors.white : Colors.grey[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}