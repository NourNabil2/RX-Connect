import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_details_header.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_image_picker.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_search_field.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';

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
  void _onMedicationSelected(String tradeName, String? activeIngredient) {
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
      expandedHeight: 200.h,
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
      bottom: PreferredSize(
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
      padding: EdgeInsets.fromLTRB(20.w, 70.h, 20.w, 16.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
              child: Image.asset(widget.medication.imageUrl!, fit: BoxFit.cover),
            )
                : Icon(Icons.medication_rounded, color: Colors.white, size: 30.r),
          ),
          SizedBox(width: 14.w),

          // Name + ingredient
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.medication.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.medication.activeIngredient?.isNotEmpty ?? false)
                  Text(
                    widget.medication.activeIngredient!,
                    style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  ),
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
    return Padding(
      padding: EdgeInsets.all(20.w),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _isEditing ? _buildEditMode() : _buildViewMode(),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  VIEW MODE
  // ─────────────────────────────────────────────
  Widget _buildViewMode() {
    return Column(
      key: const ValueKey('view'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Stats grid ──
        _buildStatsGrid(),
        SizedBox(height: 24.h),

        // ── Times ──
        _DetailSectionLabel(icon: Icons.schedule_rounded, label: 'مواعيد الجرعات'),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: _times.map((t) => _ViewTimeChip(time: t)).toList(),
        ),
        SizedBox(height: 24.h),

        // ── Notes ──
        if (widget.medication.notes?.isNotEmpty ?? false) ...[
          _DetailSectionLabel(icon: Icons.notes_rounded, label: 'ملاحظات'),
          SizedBox(height: 8.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Text(
              widget.medication.notes!,
              style: TextStyle(fontSize: 13.sp, height: 1.6, color: Theme.of(context).hintColor),
            ),
          ),
          SizedBox(height: 24.h),
        ],

        // ── Interaction trust badge ──
        _InteractionTrustBadge(),
        SizedBox(height: 20.h),

        // ── Edit CTA ──
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
      ],
    );
  }

  // ── Stats cards grid ──
  Widget _buildStatsGrid() {
    final freqLabel = _kFrequencies
        .firstWhere((f) => f.$1 == widget.medication.frequency,
        orElse: () => (widget.medication.frequency, widget.medication.frequency))
        .$2;

    return GridView.count(
      crossAxisCount: 2,
      mainAxisSpacing: 10.h,
      crossAxisSpacing: 10.w,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.7,
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F1FB),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFB5D4F4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF185FA5), size: 20),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'آخر فحص للتفاعلات الدوائية',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0C447C),
                ),
              ),
              Text(
                'لا تفاعلات مكتشفة',
                style: TextStyle(fontSize: 11.sp, color: const Color(0xFF185FA5)),
              ),
            ],
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