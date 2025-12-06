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

/// الشاشة الرئيسية - تعرض أدوية اليوم
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({Key? key}) : super(key: key);

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  /// تحميل البيانات الأساسية
  void _loadData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    if (auth.currentUser == null) return;

    final userId = auth.currentUser!.id;

    // تحميل الأدوية
    Provider.of<MedicationProvider>(context, listen: false)
        .loadMedications(userId);

    // تحميل بيانات الالتزام
    Provider.of<AdherenceProvider>(context, listen: false)
        .loadTodaysAdherence(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        color: const Color(0xFF1E88E5),
        child: Consumer2<AuthProvider, MedicationProvider>(
          builder: (context, auth, medication, _) {
            final todaysMedications = medication.getTodaysMedications();

            return CustomScrollView(
              slivers: [
                // === الـ AppBar المخصص ===
                const HomeAppBarWidget(),

                // === عنوان "أدوية اليوم" ===
                _buildSectionTitle(),

                // === قائمة الأدوية ===
                _buildMedicationsList(todaysMedications),

                // === مساحة إضافية في النهاية ===
                const SliverToBoxAdapter(
                  child: SizedBox(height: 100),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// عنوان القسم
  Widget _buildSectionTitle() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 50.h, 16.w, 8.h),
        child: Text(
          'أدوية اليوم',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  /// قائمة الأدوية أو Empty State
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

    // حساب عدد الكاردات الكلي (كل دواء × عدد مرات الجرعة)
    final totalCards = medications
        .map((med) => med.times.length)
        .reduce((a, b) => a + b);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          // إيجاد الدواء والوقت المناسب بناءً على الـ index
          final medicationData = _getMedicationAtIndex(medications, index);

          return Consumer<AdherenceProvider>(
            builder: (context, adherence, _) {
              final medication = medicationData['medication'] as MedicationModel;
              final time = medicationData['time'] as String;

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

  /// الحصول على الدواء والوقت بناءً على الـ index
  Map<String, dynamic> _getMedicationAtIndex(
      List<MedicationModel> medications,
      int index,
      ) {
    int cumulative = 0;

    for (final medication in medications) {
      final timesCount = medication.times.length;

      if (index < cumulative + timesCount) {
        final timeIndex = index - cumulative;
        return {
          'medication': medication,
          'time': medication.times[timeIndex],
        };
      }

      cumulative += timesCount;
    }

    // Fallback (shouldn't happen)
    return {
      'medication': medications.first,
      'time': medications.first.times.first,
    };
  }

  /// تسجيل أخذ الجرعة
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
      CustomSnackBar.show(context, message: 'تم تسجيل الجرعة بنجاح',type: SnackBarType.success );
    } else {
      CustomSnackBar.show(context, message: 'فشل في التسجيل',type: SnackBarType.error );
    }
  }


}