import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/utils/extension.dart';
import 'package:pharmacist_assistant/core/widgets/Loading_widget.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_delete_dialog.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_filter_chip.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_group_header.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_image_lib.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medication_stat_card.dart';
import 'package:pharmacist_assistant/features/home/presentation/widget/medications_empty_state.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/core/routes/app_routes.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';

import '../widget/medication_image_widget.dart';


class MedicationsTabScreen extends StatefulWidget {
  const MedicationsTabScreen({Key? key}) : super(key: key);

  @override
  State<MedicationsTabScreen> createState() => _MedicationsTabScreenState();
}

class _MedicationsTabScreenState extends State<MedicationsTabScreen> with AutomaticKeepAliveClientMixin {

  MedicationFilter _selectedFilter = MedicationFilter.all;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // ⬅️ Keep state alive

  @override
  void initState() {
    super.initState();
    // ⬅️ تحميل مرة واحدة فقط
    if (!_isInitialized) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMedications();
        _isInitialized = true;
      });
    }
  }

  void _loadMedications() {
    final auth = context.read<AuthProvider>();
    final medications = context.read<MedicationProvider>();

    if (auth.currentUser != null && medications.medications.isEmpty) {
      medications.loadMedications(auth.currentUser!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Consumer<MedicationProvider>(
        builder: (context, medProvider, _) {
          return CustomScrollView(
            slivers: [
              // 1. الأب بار دايماً موجود
              _buildSliverAppBar(medProvider.medications.length),

              // 2. حالة التحميل (Loading)
              if (medProvider.isLoading && medProvider.medications.isEmpty)
                _buildLoadingState()

              // 3. حالة عدم وجود أدوية (Empty State)
              else if (medProvider.medications.isEmpty)
                _buildEmptyState()

              // 4. حالة وجود أدوية (Data State)
              else ...[
                  _buildFilterChips(),
                  _buildStatisticsCards(medProvider.medications),
                  _buildMedicationsList(medProvider.medications),
                ],

              // مسافة تحتية
              SliverToBoxAdapter(child: SizedBox(height: 20.h)),
            ],
          );
        },
      ),
    );
  }

  // ==================== SLIVER APP BAR ====================

  Widget _buildSliverAppBar(int totalCount) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return SliverAppBar(
      expandedHeight: 140.h,
      floating: false,
      pinned: true,
      backgroundColor: theme.cardColor,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                theme.cardColor,
                primaryColor.withOpacity(0.05),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(
                          Icons.local_pharmacy_rounded,
                          color: primaryColor,
                          size: 24.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        '$totalCount دواء',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  _buildAddButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return IconButton(
      onPressed: () async {
        await Navigator.pushNamed(context, AppRoutes.addMedication);
        _loadMedications();
      },
      icon: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 20.r,
        ),
      ),
    );
  }

  // ==================== FILTER CHIPS ====================

  Widget _buildFilterChips() {
    return SliverToBoxAdapter(
      child: Container(
        height: 50.h,
        margin: EdgeInsets.symmetric(vertical: 12.h),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          itemCount: MedicationFilter.values.length,
          separatorBuilder: (_, __) => SizedBox(width: 10.w),
          itemBuilder: (context, index) {
            final filter = MedicationFilter.values[index];
            return MedicationFilterChip(
              filter: filter,
              isSelected: _selectedFilter == filter,
              onTap: () => setState(() => _selectedFilter = filter),
            );
          },
        ),
      ),
    );
  }

  // ==================== STATISTICS ====================

  Widget _buildStatisticsCards(List<MedicationModel> medications) {
    final dailyCount = medications.where((m) => m.frequency == 'daily').length;
    final weeklyCount = medications.where((m) => m.frequency == 'weekly').length;
    final asNeededCount = medications.where((m) => m.frequency == 'as_needed').length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        child: Row(
          children: [
            Expanded(
              child: MedicationStatCard(
                label: 'يومي',
                count: dailyCount.toString(),
                icon: Icons.calendar_today,
                color: const Color(0xFF1E88E5),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MedicationStatCard(
                label: 'أسبوعي',
                count: weeklyCount.toString(),
                icon: Icons.event_repeat,
                color: const Color(0xFF4CAF50),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: MedicationStatCard(
                label: 'عند الحاجة',
                count: asNeededCount.toString(),
                icon: Icons.medication_liquid,
                color: const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== MEDICATIONS LIST ====================

  Widget _buildMedicationsList(List<MedicationModel> medications) {
    final filteredMedications = _getFilteredMedications(medications);
    final groupedMedications = _groupMedicationsByFrequency(filteredMedications);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
            (context, index) {
          final entry = groupedMedications.entries.elementAt(index);
          return _buildMedicationGroup(entry.key, entry.value);
        },
        childCount: groupedMedications.length,
      ),
    );
  }

  List<MedicationModel> _getFilteredMedications(List<MedicationModel> medications) {
    if (_selectedFilter == MedicationFilter.all) {
      return medications;
    }
    return medications.where((m) => m.frequency == _selectedFilter.value).toList();
  }

  Map<String, List<MedicationModel>> _groupMedicationsByFrequency(
      List<MedicationModel> medications,
      ) {
    final grouped = <String, List<MedicationModel>>{};
    for (var med in medications) {
      grouped.putIfAbsent(med.frequency, () => []).add(med);
    }
    return grouped;
  }

  Widget _buildMedicationGroup(String frequency, List<MedicationModel> medications) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MedicationGroupHeader(
          frequency: frequency,
          count: medications.length,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Column(
            children: medications
                .map((med) => _buildMedicationCard(med))
                .toList(),
          ),
        ),
      ],
    );
  }

  // ==================== MEDICATION CARD ====================

  Widget _buildMedicationCard(MedicationModel medication) {
    final theme = Theme.of(context);
    final (icon, color) = medication.frequency.getFrequencyStyle();
    final timesText = medication.times.length > 1
        ? '${medication.times.length} مرات'
        : 'مرة واحدة';

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Dismissible(
        key: Key(medication.id),
        background: _buildDismissBackground(
          color: Colors.red[400]!,
          icon: Icons.delete_outline,
          alignment: Alignment.centerRight,
        ),
        secondaryBackground: _buildDismissBackground(
          color: theme.colorScheme.primary,
          icon: Icons.edit_outlined,
          alignment: Alignment.centerLeft,
        ),
        confirmDismiss: (direction) => _handleDismiss(direction, medication),
        child: _buildCardContent(medication, icon, color, timesText, theme),
      ),
    );
  }

  Widget _buildDismissBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12.r),
      ),
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Icon(icon, color: Colors.white, size: 24.r),
    );
  }

  Future<bool> _handleDismiss(
      DismissDirection direction,
      MedicationModel medication,
      ) async {
    if (direction == DismissDirection.endToStart) {
      // Edit
      AppRoutes.toMedicationDetails(context, medication);
      return false;
    } else {
      // Delete
      final shouldDelete = await MedicationDeleteDialog.show(context, medication.name);
      if (shouldDelete) {
        final success = await context.read<MedicationProvider>().deleteMedication(context, medication.id);
        if (success) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('تم حذف ${medication.name}')),
           );
           return true;
        } else {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('فشل الحذف')),
           );
           return false;
        }
      }
      return false;
    }
  }

  Widget _buildCardContent(
      MedicationModel medication,
      IconData icon,
      Color color,
      String timesText,
      ThemeData theme,
      ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => AppRoutes.toMedicationDetails(context, medication),
          borderRadius: BorderRadius.circular(12.r),
          child: Padding(
            padding: EdgeInsets.all(12.r),
            child: Row(
              children: [
                MedicationImageLibWidget(
                  imageUrl: medication.imageUrl,
                  color: color,
                  fallbackIcon: icon,
                  size: 56,
                  borderRadius: 10,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        medication.dosage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.hintColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.r),
                  ),
                  child: Text(
                    timesText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  Icons.chevron_right,
                  color: theme.dividerColor,
                  size: 20.r,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== STATES ====================

  Widget _buildLoadingState() {
    return const SliverFillRemaining(
      child: Center(
        child: LoadingSpinner(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: MedicationsEmptyState(
        onAddPressed: () async {
          await Navigator.pushNamed(context, AppRoutes.addMedication);
          _loadMedications();
        },
      ),
    );
  }

}