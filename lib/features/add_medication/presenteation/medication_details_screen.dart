// lib/features/medication_details/screens/medication_details_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_details_header.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';


class MedicationDetailsScreen extends StatefulWidget {
  final MedicationModel medication;

  const MedicationDetailsScreen({
    Key? key,
    required this.medication,
  }) : super(key: key);

  @override
  State<MedicationDetailsScreen> createState() => _MedicationDetailsScreenState();
}

class _MedicationDetailsScreenState extends State<MedicationDetailsScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _ingredientController;
  late TextEditingController _dosageController;
  late TextEditingController _notesController;

  // State
  late String _frequency;
  late List<TimeOfDay> _times;
  bool _isEditing = false;

  // Form
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeState();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.medication.name);
    _ingredientController = TextEditingController(
      text: widget.medication.activeIngredient ?? '',
    );
    _dosageController = TextEditingController(text: widget.medication.dosage);
    _notesController = TextEditingController(
      text: widget.medication.notes ?? '',
    );
  }

  void _initializeState() {
    _frequency = widget.medication.frequency;
    _times = widget.medication.times.map((timeString) {
      final parts = timeString.split(':');
      return TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ingredientController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== APP BAR ====================

  Widget _buildSliverAppBar() {
    final theme = Theme.of(context);

    return SliverAppBar(
      expandedHeight: 280.h,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (_isEditing)
          TextButton(
            onPressed: _cancelEdit,
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: MedicationDetailsHeader(
          name: widget.medication.name,
          imageUrl: widget.medication.imageUrl,
          frequency: widget.medication.frequency,
        ),
      ),
    );
  }

  // ==================== CONTENT ====================

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.all(20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing) ...[
            _buildEditMode(),
          ] else ...[
            _buildViewMode(),
          ],
        ],
      ),
    );
  }

  // ==================== VIEW MODE ====================

  Widget _buildViewMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Basic Info Section
        SectionHeader(title: 'المعلومات الأساسية', icon: Icons.info_outline),
        _buildBasicInfoCards(),
        SizedBox(height: 24.h),

        // Times Section
        SectionHeader(title: 'مواعيد الجرعات', icon: Icons.schedule),
        TimesDisplayGrid(times: _times),
        SizedBox(height: 24.h),

        // Notes Section
        if (widget.medication.notes?.isNotEmpty ?? false) ...[
          NotesCard(notes: widget.medication.notes),
        ],
      ],
    );
  }

  Widget _buildBasicInfoCards() {
    return Column(
      children: [
        InfoCard(
          label: 'الجرعة',
          value: widget.medication.dosage,
          icon: Icons.medication_liquid,
        ),
        SizedBox(height: 12.h),
        if (widget.medication.activeIngredient?.isNotEmpty ?? false)
          InfoCard(
            label: 'المادة الفعالة',
            value: widget.medication.activeIngredient!,
            icon: Icons.science_outlined,
            iconColor: Colors.purple,
          ),
      ],
    );
  }

  // ==================== EDIT MODE ====================

  Widget _buildEditMode() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name Field
        AppTextField(
          title: 'اسم الدواء',
          hintText: 'مثال: بانادول',
          controller: _nameController,
          enabled: true,
          validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        SizedBox(height: 16.h),

        // Ingredient Field
        AppTextField(
          title: 'المادة الفعالة',
          hintText: 'مثال: باراسيتامول',
          controller: _ingredientController,
          enabled: true,
        ),
        SizedBox(height: 16.h),

        // Dosage Field
        AppTextField(
          title: 'الجرعة',
          hintText: 'مثال: 500 mg',
          controller: _dosageController,
          enabled: true,
          validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
        ),
        SizedBox(height: 16.h),

        // Frequency Dropdown
        DropdownButtonFormField<String>(
          value: _frequency,
          decoration: InputDecoration(
            labelText: 'التكرار',
            prefixIcon: const Icon(Icons.repeat),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            filled: true,
            fillColor: theme.cardColor,
          ),
          items: const [
            DropdownMenuItem(value: 'daily', child: Text('يومياً')),
            DropdownMenuItem(value: 'alternate_days', child: Text('يوم بعد يوم')),
            DropdownMenuItem(value: 'weekly', child: Text('أسبوعياً')),
            DropdownMenuItem(value: 'as_needed', child: Text('عند الحاجة')),
          ],
          onChanged: (value) => setState(() => _frequency = value!),
        ),
        SizedBox(height: 24.h),

        // Times Section
        SectionHeader(title: 'مواعيد الجرعات', icon: Icons.schedule),
        ..._times.asMap().entries.map((entry) {
          return EditableTimeSlot(
            time: entry.value,
            index: entry.key,
            onTap: () => _selectTime(entry.key),
            onRemove: _times.length > 1 ? () => _removeTime(entry.key) : null,
          );
        }),
        AddTimeButtonSmall(onPressed: _addTime),
        SizedBox(height: 24.h),

        // Notes Field
        AppTextFieldFactory.textArea(
          title: 'ملاحظات',
          hintText: 'أي تعليمات إضافية...',
          controller: _notesController,
          maxLines: 4,
        ),
        SizedBox(height: 32.h),

        // Save Button
        Consumer<MedicationProvider>(
          builder: (context, provider, _) {
            return AppButton(
              text: 'حفظ التغييرات',
              onPressed: provider.isLoading ? null : _updateMedication,
              isLoading: provider.isLoading,
              active: true,
              horizontalPadding: 0,
            );
          },
        ),
      ],
    );
  }

  // ==================== ACTIONS ====================

  Future<void> _selectTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _times[index],
    );

    if (picked != null) {
      setState(() => _times[index] = picked);
    }
  }

  void _addTime() {
    setState(() => _times.add(TimeOfDay.now()));
  }

  void _removeTime(int index) {
    if (_times.length > 1) {
      setState(() => _times.removeAt(index));
    }
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _initializeControllers();
      _initializeState();
    });
  }

  Future<void> _updateMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final medicationProvider = context.read<MedicationProvider>();

    // Format times
    final timesString = _times
        .map((t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    // Create updated medication
    final updatedMedication = widget.medication.copyWith(
      name: _nameController.text,
      activeIngredient: _ingredientController.text.isEmpty
          ? null
          : _ingredientController.text,
      dosage: _dosageController.text,
      frequency: _frequency,
      times: timesString,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    // Update
    final success = await medicationProvider.updateMedication(updatedMedication);

    if (!mounted) return;

    if (success) {
      _showSuccessSnackBar();
      setState(() => _isEditing = false);
    } else {
      _showErrorSnackBar(
        medicationProvider.errorMessage ?? 'فشل في التحديث',
      );
    }
  }

  // ==================== SNACKBARS ====================

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: const BoxDecoration(
                color: Colors.white24,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 18.r,
              ),
            ),
            SizedBox(width: 12.w),
            const Text(
              'تم التحديث بنجاح',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.r),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
      ),
    );
  }
}