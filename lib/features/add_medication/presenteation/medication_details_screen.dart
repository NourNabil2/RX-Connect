import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_image_picker.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_search_field.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kTeal = Color(0xFF0F6E56);
const _kTealLight = Color(0xFFE1F5EE);
const _kTealMid = Color(0xFF5DCAA5);
const _kTealDark = Color(0xFF085041);

const _kFrequencies = [
  ('daily', 'يومياً'),
  ('alternate_days', 'يوم بعد يوم'),
  ('weekly', 'أسبوعياً'),
  ('as_needed', 'عند الحاجة'),
];

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class MedicationDetailsScreen extends StatefulWidget {
  final MedicationModel medication;

  const MedicationDetailsScreen({Key? key, required this.medication}) : super(key: key);

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _ingredientController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  // State
  late String _frequency;
  late List<TimeOfDay> _times;
  bool _isEditing = false;
  bool _isSaving = false;
  late TabController _tabController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _initializeControllers();
    _initializeState();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.medication.name);
    _ingredientController =
        TextEditingController(text: widget.medication.activeIngredient ?? '');
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _notesController = TextEditingController(text: widget.medication.notes ?? '');
  }

  void _initializeState() {
    _frequency = widget.medication.frequency;
    _times = widget.medication.times.map((t) {
      final parts = t.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _ingredientController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Medication selected in edit mode ───
  void _onMedicationSelected(Map<String, dynamic> med) {
    final tradeName = med['brand_name'] as String;
    final activeIngredient = med['active_ingredient_name'] as String?;

    setState(() {
      _nameController.text = tradeName;
      if (activeIngredient != null && activeIngredient.isNotEmpty) {
        _ingredientController.text = activeIngredient;
      }
    });
    CustomSnackBar.show(
      context,
      message: 'تم تغيير الدواء إلى: $tradeName',
      type: SnackBarType.info,
    );
  }

  // ─── Pre-save interaction check ───
  Future<bool> _validateAndConfirmUpdate() async {
    if (!_formKey.currentState!.validate()) return false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _InteractionCheckDialog(),
    );

    final medicationProvider = context.read<MedicationProvider>();
    final interactions = await medicationProvider.checkInteractions(
      _nameController.text,
      _ingredientController.text.isNotEmpty ? _ingredientController.text : null,
    );

    if (mounted) Navigator.pop(context);
    if (!mounted) return false;

    if (interactions.isEmpty) return true;

    final hasMajor = interactions
        .any((i) => i.severity.toLowerCase() == 'major' || i.severity.toLowerCase() == 'severe');

    final shouldProceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => InteractionDialog(
        interactions: interactions,
        medicationName: widget.medication.name,
        onAddAnyway: hasMajor ? null : () => Navigator.pop(ctx, true),
      ),
    ) ??
        false;

    return shouldProceed;
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  SLIVER APP BAR
  // ─────────────────────────────────────────────
  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: _isEditing ? 150.h : 200.h,
      backgroundColor: _kTealDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'تعديل',
            onPressed: () => setState(() => _isEditing = true),
          )
        else
          TextButton.icon(
            onPressed: _cancelEdit,
            icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
            label: Text(
              'إلغاء',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeroHeader(),
      ),
      bottom: _isEditing
          ? null
          : PreferredSize(
              preferredSize: const Size.fromHeight(kToolbarHeight),
              child: _buildTabBar(),
            ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF085041), Color(0xFF0F6E56)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.fromLTRB(20.w, 80.h, 20.w, 20.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Drug icon
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: widget.medication.imageUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(14.r),
              child: widget.medication.imageUrl!.startsWith('http')
                  ? Image.network(widget.medication.imageUrl!, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.medication_rounded, color: Colors.white, size: 30.r))
                  : Image.file(File(widget.medication.imageUrl!), fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.medication_rounded, color: Colors.white, size: 30.r)),
            )
                : Icon(Icons.medication_rounded, color: Colors.white, size: 30.r),
          ),
          SizedBox(width: 14.w),

          // Name + ingredient
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  widget.medication.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.medication.activeIngredient?.isNotEmpty ?? false) ...[
                  SizedBox(height: 4.h),
                  Text(
                    widget.medication.activeIngredient!,
                    style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  ),
                ],
              ],
            ),
          ),

          // Active badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6.r,
                  height: 6.r,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5DCAA5),
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 5.w),
                Text(
                  'فعّال',
                  style: TextStyle(color: Colors.white, fontSize: 11.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: _kTealDark,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 2.5,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white54,
        labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 13.sp),
        tabs: const [
          Tab(text: 'المعلومات'),
          Tab(text: 'الجدول'),
          Tab(text: 'التقارير'),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  BODY
  // ─────────────────────────────────────────────
  Widget _buildBody() {
    if (_isEditing) {
      return Padding(
        padding: EdgeInsets.all(20.w),
        child: _buildEditMode(),
      );
    }

    return Padding(
      padding: EdgeInsets.all(20.w),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.05),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildTabContent(_tabController.index),
      ),
    );
  }

  Widget _buildTabContent(int index) {
    switch (index) {
      case 0:
        return _buildInfoTab();
      case 1:
        return _buildScheduleTab();
      case 2:
        return _buildReportsTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoTab() {
    return Column(
      key: const ValueKey('info_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildStatsGrid(),
        SizedBox(height: 24.h),

        _DetailSectionLabel(icon: Icons.schedule_rounded, label: 'مواعيد الجرعات'),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 10.w,
          runSpacing: 10.h,
          children: _times.map((t) => _ViewTimeChip(time: t)).toList(),
        ),
        SizedBox(height: 24.h),

        _buildNotesCard(),
        SizedBox(height: 24.h),

        _InteractionTrustBadge(
          onRecheck: () async {
            setState(() => _isSaving = true);
            final success = await _validateAndConfirmUpdate();
            setState(() => _isSaving = false);
            if (success) {
              CustomSnackBar.show(context, message: 'الدواء آمن ولا توجد تعارضات', type: SnackBarType.success);
            }
          },
        ),
        SizedBox(height: 24.h),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => setState(() => _isEditing = true),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('تعديل البيانات'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kTeal,
              side: const BorderSide(color: _kTeal),
              padding: EdgeInsets.symmetric(vertical: 13.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildNotesCard() {
    final notes = widget.medication.notes;
    if (notes == null || notes.isEmpty) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).hintColor, size: 20.r),
            SizedBox(width: 12.w),
            Text(
              'لا توجد ملاحظات إضافية لهذا الدواء',
              style: TextStyle(
                fontSize: 13.sp,
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.note_alt_outlined, color: Colors.amber[850], size: 20.r),
              SizedBox(width: 8.w),
              Text(
                'ملاحظات الاستخدام والتعليمات',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber[900],
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            notes,
            style: TextStyle(
              fontSize: 13.sp,
              height: 1.6,
              color: Colors.amber[950],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTab() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    final adherenceProvider = context.read<AdherenceProvider>();

    return Column(
      key: const ValueKey('schedule_tab'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _DetailSectionLabel(icon: Icons.hourglass_empty_rounded, label: 'الخط الزمني لجرعات اليوم'),
        SizedBox(height: 16.h),

        _buildTimelineView(),
        SizedBox(height: 32.h),

        _DetailSectionLabel(icon: Icons.history_rounded, label: 'سجل النشاط الأخير (آخر 7 أيام)'),
        SizedBox(height: 16.h),

        FutureBuilder<List<Map<String, dynamic>>>(
          future: adherenceProvider.getMedicationLogs(userId, widget.medication.id),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(color: _kTeal),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(20.r),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.history_toggle_off_rounded, color: Theme.of(context).hintColor, size: 36.r),
                    SizedBox(height: 10.h),
                    Text(
                      'لا توجد سجلات التزام سابقة لهذا الدواء بعد.',
                      style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            final logs = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: logs.length > 5 ? 5 : logs.length,
              separatorBuilder: (_, __) => SizedBox(height: 12.h),
              itemBuilder: (context, idx) {
                final log = logs[idx];
                final status = log['status'] as String;
                final scheduledTimeStr = log['scheduledTime'] as String;
                final schedTime = DateTime.parse(scheduledTimeStr);

                final isTaken = status == 'taken';
                final statusLabel = isTaken ? 'تم أخذها' : 'مُفوّتة';
                final statusColor = isTaken ? const Color(0xFF10B981) : const Color(0xFFEF4444);

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isTaken ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: statusColor,
                          size: 20.r,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'جرعة يوم ${schedTime.day}/${schedTime.month}/${schedTime.year}',
                              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              'الموعد المجدول: ${schedTime.hour.toString().padLeft(2, '0')}:${schedTime.minute.toString().padLeft(2, '0')}',
                              style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(color: statusColor, fontSize: 11.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        SizedBox(height: 24.h),
      ],
    );
  }

  Widget _buildTimelineView() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _times.length,
      itemBuilder: (context, index) {
        final time = _times[index];
        final label = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
        final isMorning = time.hour < 12;

        return IntrinsicHeight(
          child: Row(
            children: [
              SizedBox(
                width: 70.w,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: _kTealDark,
                      ),
                    ),
                    Text(
                      isMorning ? 'صباحاً' : 'مساءً',
                      style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.w),

              Column(
                children: [
                  Container(
                    width: 14.r,
                    height: 14.r,
                    decoration: BoxDecoration(
                      color: _kTeal,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2.5),
                      boxShadow: [
                        BoxShadow(
                          color: _kTeal.withOpacity(0.3),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  if (index < _times.length - 1)
                    Expanded(
                      child: Container(
                        width: 2.w,
                        color: _kTeal.withOpacity(0.3),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 16.w),

              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: index < _times.length - 1 ? 16.h : 0),
                  child: Container(
                    padding: EdgeInsets.all(14.r),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(14.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isMorning ? Icons.wb_sunny_outlined : Icons.nightlight_round_outlined,
                          color: Colors.orange[400],
                          size: 20.r,
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'الجرعة ${index + 1}',
                                style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                'تناول الجرعة المحددة: ${widget.medication.dosage}',
                                style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReportsTab() {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id ?? '';
    final adherenceProvider = context.read<AdherenceProvider>();

    return FutureBuilder<double>(
      future: adherenceProvider.calculateMedicationAdherenceRate(userId, widget.medication.id),
      builder: (context, snapshot) {
        final rate = snapshot.data ?? 0.0;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Column(
          key: const ValueKey('reports_tab'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DetailSectionLabel(icon: Icons.analytics_outlined, label: 'تحليل الالتزام بالدواء'),
            SizedBox(height: 16.h),

            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.r),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F6E56), Color(0xFF085041)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F6E56).withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 110.r,
                        height: 110.r,
                        child: CircularProgressIndicator(
                          value: isLoading ? 0.0 : rate / 100.0,
                          strokeWidth: 9.r,
                          backgroundColor: Colors.white24,
                          color: const Color(0xFF5DCAA5),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isLoading ? '...' : '${rate.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'معدل الالتزام',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 10.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    _getAdherenceFeedback(rate),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    'تم احتساب النسبة بناءً على الجرعات المتوقعة والمسجلة آخر 7 أيام.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 24.h),

            _buildCommitmentStars(rate),
            SizedBox(height: 24.h),

            _DetailSectionLabel(icon: Icons.calendar_view_week_rounded, label: 'تتبع الالتزام الأسبوعي'),
            SizedBox(height: 12.h),
            _buildWeeklyAdherenceGrid(userId),
            SizedBox(height: 24.h),
          ],
        );
      },
    );
  }

  String _getAdherenceFeedback(double rate) {
    if (rate >= 90) return 'عمل ممتاز! ملتزم بالكامل بالجرعات 🔥';
    if (rate >= 80) return 'جيد جداً! التزام رائع بالدواء 👍';
    if (rate >= 60) return 'مستوى التزام مقبول، حاول الحفاظ على المواعيد ⏰';
    return 'معدل التزام منخفض، يرجى الحرص على تناول الدواء ⚠️';
  }

  Widget _buildCommitmentStars(double rate) {
    int starsCount = 0;
    if (rate >= 95) starsCount = 5;
    else if (rate >= 80) starsCount = 4;
    else if (rate >= 60) starsCount = 3;
    else if (rate >= 40) starsCount = 2;
    else if (rate > 0) starsCount = 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Text(
            'تقييم الالتزام المعنوي',
            style: TextStyle(fontSize: 12.sp, color: Theme.of(context).hintColor, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final isLit = index < starsCount;
              return Icon(
                isLit ? Icons.star_rounded : Icons.star_border_rounded,
                color: isLit ? Colors.amber[500] : Colors.grey[300],
                size: 28.r,
              );
            }),
          ),
          SizedBox(height: 6.h),
          Text(
            starsCount == 5 ? 'مثالي 👑' : (starsCount == 4 ? 'رائع ⭐' : 'تحتاج للمزيد من التركيز 🎯'),
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAdherenceGrid(String userId) {
    final adherenceProvider = context.read<AdherenceProvider>();
    final daysOfWeek = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];
    final now = DateTime.now();

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: adherenceProvider.getMedicationLogs(userId, widget.medication.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _kTeal));
        }

        final logs = snapshot.data ?? [];
        final takenDates = logs
            .where((l) => l['status'] == 'taken')
            .map((l) => DateTime.parse(l['scheduledTime'] as String))
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();

        final missedDates = logs
            .where((l) => l['status'] == 'missed')
            .map((l) => DateTime.parse(l['scheduledTime'] as String))
            .map((d) => DateTime(d.year, d.month, d.day))
            .toSet();

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (index) {
              final dayDate = now.subtract(Duration(days: 6 - index));
              final checkDate = DateTime(dayDate.year, dayDate.month, dayDate.day);
              final isTaken = takenDates.contains(checkDate);
              final isMissed = missedDates.contains(checkDate);

              final dayIndex = (checkDate.weekday % 7);
              final dayName = daysOfWeek[dayIndex == 0 ? 1 : (dayIndex == 6 ? 0 : dayIndex + 1)];

              Color color = Colors.grey[200]!;
              Color textColor = Colors.grey[600]!;
              IconData? icon;

              if (isTaken) {
                color = const Color(0xFF10B981);
                textColor = Colors.white;
                icon = Icons.check_rounded;
              } else if (isMissed) {
                color = const Color(0xFFEF4444);
                textColor = Colors.white;
                icon = Icons.close_rounded;
              }

              return Column(
                children: [
                  Text(
                    '${checkDate.day}/${checkDate.month}',
                    style: TextStyle(fontSize: 9.sp, color: Theme.of(context).hintColor),
                  ),
                  SizedBox(height: 6.h),
                  Container(
                    width: 32.r,
                    height: 32.r,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: isTaken || isMissed
                          ? [
                              BoxShadow(
                                color: color.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              )
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: icon != null
                        ? Icon(icon, size: 14.r, color: Colors.white)
                        : Text(
                            dayName,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              );
            }),
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid() {
    final freqLabel = _kFrequencies
        .firstWhere((f) => f.$1 == widget.medication.frequency,
            orElse: () => (widget.medication.frequency, widget.medication.frequency))
        .$2;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.5,
      children: [
        _StatCard(icon: Icons.medication_liquid_outlined, label: 'الجرعة', value: widget.medication.dosage),
        _StatCard(icon: Icons.repeat_rounded, label: 'التكرار', value: freqLabel),
        _StatCard(
          icon: Icons.calendar_today_outlined,
          label: 'تاريخ البداية',
          value:
              '${widget.medication.startDate.day}/${widget.medication.startDate.month}/${widget.medication.startDate.year}',
        ),
        _StatCard(
          icon: Icons.science_outlined,
          label: 'المادة الفعالة',
          value: widget.medication.activeIngredient ?? '—',
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  EDIT MODE
  // ─────────────────────────────────────────────
  Widget _buildEditMode() {
    return Column(
      key: const ValueKey('edit'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Info banner
        _EditInfoBanner(),
        SizedBox(height: 16.h),

        // Drug search
        _DetailSectionLabel(icon: Icons.search_rounded, label: 'اسم الدواء'),
        SizedBox(height: 8.h),
        MedicationSearchField(
          controller: _nameController,
          onMedicationSelected: _onMedicationSelected,
          validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        SizedBox(height: 14.h),

        // Ingredient
        AppTextField(
          title: 'المادة الفعالة',
          hintText: 'مثال: باراسيتامول',
          controller: _ingredientController,
          prefixIcon: const Icon(Icons.science_outlined),
          enabled: true,
        ),
        SizedBox(height: 14.h),

        // Dosage
        AppTextField(
          title: 'الجرعة',
          hintText: 'مثال: 500 مج',
          controller: _dosageController,
          prefixIcon: const Icon(Icons.medication_liquid_outlined),
          enabled: true,
          validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        SizedBox(height: 18.h),

        // Frequency chips
        _DetailSectionLabel(icon: Icons.repeat_rounded, label: 'التكرار'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _kFrequencies.map((f) {
            final isSelected = f.$1 == _frequency;
            return GestureDetector(
              onTap: () => setState(() => _frequency = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: isSelected ? _kTeal : Colors.transparent,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(color: isSelected ? _kTeal : Colors.grey.shade300),
                ),
                child: Text(
                  f.$2,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? Colors.white : Theme.of(context).hintColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 18.h),

        // Times
        _DetailSectionLabel(icon: Icons.schedule_rounded, label: 'مواعيد الجرعات'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            ..._times.asMap().entries.map((e) => _EditableTimeChip(
              time: e.value,
              canRemove: _times.length > 1,
              onTap: () => _selectTime(e.key),
              onRemove: () => _removeTime(e.key),
            )),
            _AddTimeChipSmall(onTap: _addTime),
          ],
        ),
        SizedBox(height: 18.h),

        // Notes
        AppTextFieldFactory.textArea(
          title: 'ملاحظات',
          hintText: 'أي تعليمات إضافية...',
          controller: _notesController,
          maxLines: 4,
        ),
        SizedBox(height: 28.h),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _cancelEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).hintColor,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: const Text('إلغاء'),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: AppButton(
                text: 'حفظ التغييرات',
                onPressed: _isSaving ? null : _updateMedication,
                isLoading: _isSaving,
                active: true,
                horizontalPadding: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  ACTIONS
  // ─────────────────────────────────────────────
  Future<void> _selectTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => Theme(
        data: Theme.of(context)
            .copyWith(colorScheme: const ColorScheme.light(primary: _kTeal)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  void _addTime() => setState(() => _times.add(TimeOfDay.now()));
  void _removeTime(int index) {
    if (_times.length > 1) setState(() => _times.removeAt(index));
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeControllers();
      _initializeState();
    });
  }

  Future<void> _updateMedication() async {
    final shouldUpdate = await _validateAndConfirmUpdate();
    if (!shouldUpdate) return;

    setState(() => _isSaving = true);

    final medicationProvider = context.read<MedicationProvider>();

    final timesString = _times
        .map((t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    final updatedMedication = widget.medication.copyWith(
      name: _nameController.text,
      activeIngredient:
      _ingredientController.text.isEmpty ? null : _ingredientController.text,
      dosage: _dosageController.text,
      frequency: _frequency,
      times: timesString,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    final success = await medicationProvider.updateMedication(updatedMedication);

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      CustomSnackBar.show(context, message: 'تم التحديث بنجاح ✅', type: SnackBarType.success);
      setState(() => _isEditing = false);
    } else {
      CustomSnackBar.show(
        context,
        message: medicationProvider.errorMessage ?? 'فشل في التحديث',
        type: SnackBarType.error,
      );
    }
  }
}

// ═══════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════

class _DetailSectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _DetailSectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16.r, color: _kTeal),
        SizedBox(width: 6.w),
        Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: _kTeal,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Stat card ───
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 14.r, color: _kTeal),
              SizedBox(width: 5.w),
              Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: Theme.of(context).hintColor),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── View-mode time chip ───
class _ViewTimeChip extends StatelessWidget {
  final TimeOfDay time;
  const _ViewTimeChip({required this.time});

  @override
  Widget build(BuildContext context) {
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: _kTealLight,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _kTealMid.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            time.hour < 12 ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            size: 15.r,
            color: _kTeal,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
                fontSize: 13.sp, fontWeight: FontWeight.w600, color: _kTeal),
          ),
        ],
      ),
    );
  }
}

// ─── Editable time chip ───
class _EditableTimeChip extends StatelessWidget {
  final TimeOfDay time;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  const _EditableTimeChip(
      {required this.time,
        required this.canRemove,
        required this.onTap,
        this.onRemove});

  @override
  Widget build(BuildContext context) {
    final label =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: _kTealLight,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: _kTealMid.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              time.hour < 12 ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              size: 15.r,
              color: _kTeal,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                  fontSize: 13.sp, fontWeight: FontWeight.w600, color: _kTeal),
            ),
            if (canRemove && onRemove != null) ...[
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded,
                    size: 14.r, color: _kTeal.withOpacity(0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add time chip (small) ───
class _AddTimeChipSmall extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTimeChipSmall({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15.r, color: Theme.of(context).hintColor),
            SizedBox(width: 4.w),
            Text('إضافة',
                style: TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor)),
          ],
        ),
      ),
    );
  }
}

// ─── Interaction trust badge ───
class _InteractionTrustBadge extends StatelessWidget {
  final VoidCallback onRecheck;

  const _InteractionTrustBadge({Key? key, required this.onRecheck}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE0F2FE), Color(0xFFF0F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44.r,
                height: 44.r,
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
              Icon(Icons.verified_user_rounded, color: const Color(0xFF0284C7), size: 24.r),
            ],
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'فحص التفاعلات والتعارضات',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0369A1),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'تم التحقق وتأكيد سلامة تناول الدواء.',
                  style: TextStyle(fontSize: 11.sp, color: const Color(0xFF0284C7)),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          ElevatedButton(
            onPressed: onRecheck,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0284C7),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
            child: Text(
              'إعادة فحص',
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Edit info banner ───
class _EditInfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: const Color(0xFFB5D4F4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF185FA5)),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'تعديل اسم الدواء سيُعيد فحص التفاعلات الدوائية تلقائياً.',
              style: TextStyle(fontSize: 12.sp, color: const Color(0xFF0C447C)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  INTERACTION CHECK DIALOG (loading)
// ─────────────────────────────────────────────
class _InteractionCheckDialog extends StatelessWidget {
  const _InteractionCheckDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: EdgeInsets.all(28.r),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 48.r,
              height: 48.r,
              child: const CircularProgressIndicator(strokeWidth: 3, color: _kTeal),
            ),
            SizedBox(height: 20.h),
            Text(
              'جاري فحص التفاعلات الدوائية...',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            Text(
              'نتحقق من التعارض قبل الحفظ',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}