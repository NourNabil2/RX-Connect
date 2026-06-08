import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_image_picker.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_search_field.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kTeal = Color(0xFF0F6E56);
const _kTealLight = Color(0xFFE1F5EE);
const _kTealMid = Color(0xFF5DCAA5);

const _kFrequencies = [
  ('daily', 'يومياً'),
  ('alternate_days', 'يوم بعد يوم'),
  ('weekly', 'أسبوعياً'),
  ('as_needed', 'عند الحاجة'),
];

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  String _frequency = 'daily';
  List<TimeOfDay> _times = [TimeOfDay.now()];
  File? _selectedImage;
  String? _selectedPhotoUrl;
  bool _isSaving = false;

  List<DrugInteractionModel> _currentInteractions = [];
  bool _isCheckingInteractions = false;

  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // ─── Medication selected from search ───
  void _onMedicationSelected(Map<String, dynamic> med) async {
    debugPrint('=== Selected Medication Data ===');
    debugPrint(med.toString());
    debugPrint('================================');
    
    final tradeName = med['brand_name'] as String;
    final activeIngredient = med['active_ingredient_name'] as String?;
    final photoUrl = med['photo_url'] as String?;

    setState(() {
      _nameController.text = tradeName;
      if (activeIngredient != null && activeIngredient.isNotEmpty) {
        _ingredientController.text = activeIngredient;
      }
      _selectedPhotoUrl = photoUrl;
      _isCheckingInteractions = true;
      _currentInteractions.clear();
    });

    final provider = context.read<MedicationProvider>();
    final interactions = await provider.checkInteractions(tradeName, activeIngredient);

    if (mounted) {
      setState(() {
        _currentInteractions = interactions;
        _isCheckingInteractions = false;
      });

      if (interactions.isEmpty) {
        CustomSnackBar.show(
          context,
          message: 'لا يوجد تعارض دوائي ✅',
          type: SnackBarType.success,
        );
      }
    }
  }

  // ─── Save ───
  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();

    final timesString = _times
        .map((t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    final success = await medicationProvider.addMedication(
      userId: authProvider.currentUser!.id,
      name: _nameController.text,
      activeIngredient:
      _ingredientController.text.isNotEmpty ? _ingredientController.text : null,
      dosage: _dosageController.text,
      frequency: _frequency,
      times: timesString,
      imageUrl: _selectedImage?.path ?? _selectedPhotoUrl,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      CustomSnackBar.show(context, message: 'تم إضافة الدواء بنجاح ✅', type: SnackBarType.success);
      Navigator.pop(context, true);
    } else {
      CustomSnackBar.show(
        context,
        message: medicationProvider.errorMessage ?? 'فشل في الحفظ',
        type: SnackBarType.error,
      );
    }
  }

  void _showImagePickerOptions() {
    ImageSourceBottomSheet.show(
      context,
      onCamera: () {
        Navigator.pop(context);
        _pickImage(ImageSource.camera);
      },
      onGallery: () {
        Navigator.pop(context);
        _pickImage(ImageSource.gallery);
      },
      onRemove: (_selectedImage != null || _selectedPhotoUrl != null)
          ? () {
        Navigator.pop(context);
        setState(() {
          _selectedImage = null;
          _selectedPhotoUrl = null;
        });
      }
          : null,
      hasImage: _selectedImage != null || _selectedPhotoUrl != null,
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (image != null) setState(() => _selectedImage = File(image.path));
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(context, message: 'فشل اختيار الصورة', type: SnackBarType.error);
    }
  }

  Future<void> _selectTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
      builder: (context, child) => _themedTimePicker(context, child),
    );
    if (picked != null) setState(() => _times[index] = picked);
  }

  void _addTime() => setState(() => _times.add(TimeOfDay.now()));
  void _removeTime(int index) {
    if (_times.length > 1) setState(() => _times.removeAt(index));
  }

  Widget _themedTimePicker(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(primary: _kTeal),
      ),
      child: child!,
    );
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final hasMajor = _currentInteractions
        .any((i) => i.severity.toLowerCase() == 'major' || i.severity.toLowerCase() == 'severe');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 40.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Image picker ──
                    MedicationImagePicker(
                      selectedImage: _selectedImage,
                      networkImageUrl: _selectedPhotoUrl,
                      onTap: _showImagePickerOptions,
                    ),
                    SizedBox(height: 24.h),

                    // ── Drug search ──
                    _SectionLabel(icon: Icons.search_rounded, label: 'البحث عن الدواء'),
                    SizedBox(height: 8.h),
                    MedicationSearchField(
                      controller: _nameController,
                      onMedicationSelected: _onMedicationSelected,
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                    ),

                    // ── Interaction status ──
                    _buildInteractionStatus(hasMajor),

                    SizedBox(height: 20.h),

                    // ── Active ingredient ──
                    AppTextField(
                      title: 'المادة الفعالة',
                      controller: _ingredientController,
                      prefixIcon: const Icon(Icons.science_outlined),
                      hintText: 'مثال: Amoxicillin',
                    ),
                    SizedBox(height: 14.h),

                    // ── Dosage ──
                    AppTextField(
                      title: 'الجرعة *',
                      controller: _dosageController,
                      prefixIcon: const Icon(Icons.medication_liquid_outlined),
                      validator: (v) => v?.isEmpty ?? true ? 'مطلوب' : null,
                      hintText: 'مثال: 500 مج',
                    ),
                    SizedBox(height: 20.h),

                    // ── Frequency chips ──
                    _SectionLabel(icon: Icons.repeat_rounded, label: 'التكرار'),
                    SizedBox(height: 10.h),
                    _FrequencyChips(
                      selected: _frequency,
                      onChanged: (v) => setState(() => _frequency = v),
                    ),
                    SizedBox(height: 20.h),

                    // ── Times ──
                    _SectionLabel(icon: Icons.schedule_rounded, label: 'مواعيد الجرعات'),
                    SizedBox(height: 10.h),
                    _buildTimesRow(),
                    SizedBox(height: 20.h),

                    // ── Notes ──
                    AppTextFieldFactory.textArea(
                      title: 'ملاحظات',
                      controller: _notesController,
                      maxLines: 3,
                    ),
                    SizedBox(height: 28.h),

                    // ── Save button ──
                    _buildSaveButton(hasMajor),
                    SizedBox(height: 10.h),

                    if (!hasMajor && !_isCheckingInteractions)
                      Center(
                        child: Text(
                          'سيتم جدولة التذكيرات تلقائياً بعد الحفظ 🔔',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Theme.of(context).hintColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  APP BAR
  // ─────────────────────────────────────────────
  Widget _buildAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 130.h,
      backgroundColor: _kTeal,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: EdgeInsets.only(right: 20.w, bottom: 16.h),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'إضافة دواء جديد',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'اختر الدواء وتحقق من التفاعلات',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11.sp,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0F6E56), Color(0xFF1D9E75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  INTERACTION STATUS
  // ─────────────────────────────────────────────
  Widget _buildInteractionStatus(bool hasMajor) {
    if (_isCheckingInteractions) {
      return _InteractionCheckingBanner();
    }
    if (_currentInteractions.isEmpty && _nameController.text.isEmpty) {
      return const SizedBox.shrink();
    }
    if (_currentInteractions.isEmpty) {
      return _InteractionClearBanner();
    }
    return Column(
      children: _currentInteractions
          .map((i) => _InteractionCard(interaction: i))
          .toList(),
    );
  }

  // ─────────────────────────────────────────────
  //  TIMES ROW
  // ─────────────────────────────────────────────
  Widget _buildTimesRow() {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: [
        ..._times.asMap().entries.map((e) => _TimeChip(
          time: e.value,
          canRemove: _times.length > 1,
          onTap: () => _selectTime(e.key),
          onRemove: () => _removeTime(e.key),
        )),
        _AddTimeChip(onTap: _addTime),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  SAVE BUTTON
  // ─────────────────────────────────────────────
  Widget _buildSaveButton(bool hasMajor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: AppButton(
        text: hasMajor ? '⛔ لا يمكن الإضافة — تفاعل خطير' : 'حفظ الدواء',
        onPressed: (_isSaving || hasMajor) ? null : _saveMedication,
        isLoading: _isSaving,
        active: !hasMajor,
        horizontalPadding: 0,
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═══════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

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

// ─── Frequency chips ───
class _FrequencyChips extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FrequencyChips({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      children: _kFrequencies.map((f) {
        final isSelected = f.$1 == selected;
        return GestureDetector(
          onTap: () => onChanged(f.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: isSelected ? _kTeal : Colors.transparent,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: isSelected ? _kTeal : Colors.grey.shade300,
              ),
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
    );
  }
}

// ─── Time chip ───
class _TimeChip extends StatelessWidget {
  final TimeOfDay time;
  final bool canRemove;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _TimeChip({
    required this.time,
    required this.canRemove,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final label = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    final isAm = time.hour < 12;

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
              isAm ? Icons.wb_sunny_outlined : Icons.nightlight_round,
              size: 15.r,
              color: _kTeal,
            ),
            SizedBox(width: 6.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: _kTeal,
              ),
            ),
            if (canRemove) ...[
              SizedBox(width: 8.w),
              GestureDetector(
                onTap: onRemove,
                child: Icon(Icons.close_rounded, size: 14.r, color: _kTeal.withOpacity(0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Add time chip ───
class _AddTimeChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddTimeChip({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: Colors.grey.shade300,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15.r, color: Theme.of(context).hintColor),
            SizedBox(width: 4.w),
            Text(
              'موعد جديد',
              style: TextStyle(fontSize: 13.sp, color: Theme.of(context).hintColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Interaction: checking ───
class _InteractionCheckingBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 16.r,
            height: 16.r,
            child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
          ),
          SizedBox(width: 10.w),
          Text(
            'جاري فحص التفاعلات الدوائية...',
            style: TextStyle(fontSize: 13.sp, color: Colors.blue.shade700),
          ),
        ],
      ),
    );
  }
}

// ─── Interaction: clear ───
class _InteractionClearBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3DE),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFC0DD97)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF3B6D11), size: 18),
          SizedBox(width: 10.w),
          Text(
            'لا توجد تفاعلات دوائية',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF27500A),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Interaction: warning card ───
class _InteractionCard extends StatelessWidget {
  final DrugInteractionModel interaction;
  const _InteractionCard({required this.interaction});

  @override
  Widget build(BuildContext context) {
    final isMajor = interaction.severity.toLowerCase() == 'major' ||
        interaction.severity.toLowerCase() == 'severe';

    final bgColor = isMajor ? const Color(0xFFFCEBEB) : const Color(0xFFFAEEDA);
    final borderColor = isMajor ? const Color(0xFFF7C1C1) : const Color(0xFFFAC775);
    final iconColor = isMajor ? const Color(0xFFA32D2D) : const Color(0xFF854F0B);
    final titleColor = isMajor ? const Color(0xFF791F1F) : const Color(0xFF633806);
    final severityText = isMajor ? 'خطير' : 'متوسط';

    return Container(
      margin: EdgeInsets.only(top: 10.h),
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Icon(
                isMajor ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
                color: iconColor,
                size: 20.r,
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  '${interaction.drug1} ↔ ${interaction.drug2}',
                  maxLines: 3,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: titleColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: borderColor,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  severityText,
                  maxLines: 3,
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: titleColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Description
          Text(
            interaction.description,
            maxLines: 3,
            style: TextStyle(fontSize: 12.sp, color: titleColor.withOpacity(0.8), height: 1.5),
          ),
          SizedBox(height: 10.h),

          // Recommendation
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 15.r, color: iconColor),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    interaction.recommendation,
                    maxLines: 3,
                    style: TextStyle(fontSize: 11.sp, color: titleColor, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}