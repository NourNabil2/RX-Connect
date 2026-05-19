import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/widgets/empty_state_widget.dart';
import '../widget/home_app_bar_widget.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kTeal = Color(0xFF0F6E56);

class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) return;
    final userId = auth.currentUser!.id;
    Provider.of<MedicationProvider>(context, listen: false).loadMedications(userId);
    Provider.of<AdherenceProvider>(context, listen: false).loadTodaysAdherence(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: _kTeal,
        child: Consumer2<AuthProvider, MedicationProvider>(
          builder: (context, auth, medication, _) {
            final todaysMedications = medication.getTodaysMedications();

            return CustomScrollView(
              slivers: [
                const HomeAppBarWidget(),
                _buildSectionHeader(todaysMedications),
                _buildMedicationsList(todaysMedications),
                const SliverToBoxAdapter(child: SizedBox(height: 110)),
              ],
            );
          },
        ),
      ),
    );
  }

  // ─── Section header with date + count ───
  Widget _buildSectionHeader(List<MedicationModel> medications) {
    final now = DateTime.now();
    final weekdays = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    final months = ['يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'];
    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 50.h, 20.w, 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'أدوية اليوم',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A2E),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '$dayName، ${now.day} $monthName',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (medications.isNotEmpty)
              _DoseCountBadge(total: medications.fold(0, (sum, m) => sum + m.times.length)),
          ],
        ),
      ),
    );
  }

  // ─── Medications list ───
  Widget _buildMedicationsList(List<MedicationModel> medications) {
    if (medications.isEmpty) {
      return SliverToBoxAdapter(
        child: EmptyStateWidget(
          icon: Icons.medication_outlined,
          title: 'لا توجد أدوية لليوم',
          subtitle: 'ابدأ بإضافة أدويتك للحصول على تذكيرات',
        ),
      );
    }

    final totalCards = medications.map((m) => m.times.length).reduce((a, b) => a + b);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final data = _getMedicationAtIndex(medications, index);
          return Consumer<AdherenceProvider>(
            builder: (context, adherence, _) {
              final medication = data['medication'] as MedicationModel;
              final time = data['time'] as String;
              return HomeMedicationCard(
                medication: medication,
                time: time,
                isTaken: adherence.isMedicationTaken(medication.id, time),
                isDue: adherence.isMedicationDueNow(time),
                isPassed: adherence.hasMedicationTimePassed(time),
                onTake: () => _markAsTaken(medication, time),
              );
            },
          );
        },
        childCount: totalCards,
      ),
    );
  }

  Map<String, dynamic> _getMedicationAtIndex(List<MedicationModel> medications, int index) {
    int cumulative = 0;
    for (final medication in medications) {
      final timesCount = medication.times.length;
      if (index < cumulative + timesCount) {
        return {'medication': medication, 'time': medication.times[index - cumulative]};
      }
      cumulative += timesCount;
    }
    return {'medication': medications.first, 'time': medications.first.times.first};
  }

  Future<void> _markAsTaken(MedicationModel medication, String time) async {
    final adherence = Provider.of<AdherenceProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) return;

    final success = await adherence.markMedicationAsTaken(
      userId: auth.currentUser!.id,
      medicationId: medication.id,
      medicationName: medication.name,
      time: time,
    );

    if (!mounted) return;
    if (success) {
      CustomSnackBar.show(context, message: 'تم تسجيل جرعة ${medication.name} ✅', type: SnackBarType.success);
    } else {
      CustomSnackBar.show(context, message: 'فشل في التسجيل', type: SnackBarType.error);
    }
  }
}

// ─── Dose count badge ───
class _DoseCountBadge extends StatelessWidget {
  final int total;
  const _DoseCountBadge({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: _kTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: _kTeal.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.medication_rounded, size: 14.r, color: _kTeal),
          SizedBox(width: 5.w),
          Text(
            '$total جرعة',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: _kTeal),
          ),
        ],
      ),
    );
  }
}