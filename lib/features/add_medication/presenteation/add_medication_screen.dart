// lib/features/add_medication/screens/add_medication_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pharmacist_assistant/core/widgets/app_buton.dart';
import 'package:pharmacist_assistant/core/widgets/app_text_feild.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/cubit/medication_status.dart';
import 'package:pharmacist_assistant/features/add_medication/presenteation/widgets/medication_image_picker.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:provider/provider.dart';


class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({Key? key}) : super(key: key);

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  // Form
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _ingredientController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  // State
  String _frequency = 'daily';
  List<TimeOfDay> _times = [TimeOfDay.now()];
  bool _isCheckingInteractions = false;
  File? _selectedImage;

  // Image Picker
  final _imagePicker = ImagePicker();

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
      appBar: _buildAppBar(theme),
      body: Consumer<MedicationProvider>(
        builder: (context, medicationProvider, _) {
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePicker(),
                  SizedBox(height: 24.h),
                  _buildNameField(),
                  SizedBox(height: 16.h),
                  _buildIngredientField(),
                  SizedBox(height: 16.h),
                  _buildDosageField(),
                  SizedBox(height: 16.h),
                  _buildFrequencyDropdown(theme),
                  SizedBox(height: 20.h),
                  _buildTimesSection(theme),
                  SizedBox(height: 16.h),
                  _buildNotesField(),
                  SizedBox(height: 32.h),
                  _buildSaveButton(medicationProvider),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== APP BAR ====================

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('إضافة دواء جديد'),
      backgroundColor: theme.colorScheme.primary,
      elevation: 0,
    );
  }

  // ==================== IMAGE PICKER ====================

  Widget _buildImagePicker() {
    return MedicationImagePicker(
      selectedImage: _selectedImage,
      onTap: _showImagePickerOptions,
    );
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
      onRemove: _selectedImage != null
          ? () {
        Navigator.pop(context);
        setState(() => _selectedImage = null);
      }
          : null,
      hasImage: _selectedImage != null,
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

      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.show(
        context,
        message: 'فشل اختيار الصورة',
        type: SnackBarType.error,
      );
    }
  }

  // ==================== FORM FIELDS ====================

  Widget _buildNameField() {
    return AppTextField(
      title: 'اسم الدواء *',
      hintText: 'مثال: بانادول',
      controller: _nameController,
      prefixIcon: const Icon(Icons.medication),
      validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
      onChanged: (_) => _checkInteractions(),
    );
  }

  Widget _buildIngredientField() {
    return AppTextField(
      title: 'المادة الفعالة',
      hintText: 'مثال: باراسيتامول',
      controller: _ingredientController,
      prefixIcon: const Icon(Icons.science_outlined),
      onChanged: (_) => _checkInteractions(),
    );
  }

  Widget _buildDosageField() {
    return AppTextField(
      title: 'الجرعة *',
      hintText: 'مثال: 500 mg',
      controller: _dosageController,
      prefixIcon: const Icon(Icons.medical_information),
      validator: (value) => value?.isEmpty ?? true ? 'مطلوب' : null,
    );
  }

  Widget _buildFrequencyDropdown(ThemeData theme) {
    return DropdownButtonFormField<String>(
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
    );
  }

  Widget _buildNotesField() {
    return AppTextFieldFactory.textArea(
      title: 'ملاحظات',
      hintText: 'أي تعليمات إضافية...',
      controller: _notesController,
      maxLines: 3,
    );
  }

  // ==================== TIMES SECTION ====================

  Widget _buildTimesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'مواعيد الجرعات',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 12.h),
        ..._times.asMap().entries.map(
              (entry) => TimeSlotRow(
            time: entry.value,
            index: entry.key,
            onTap: () => _selectTime(entry.key),
            onRemove: () => _removeTime(entry.key),
            canRemove: _times.length > 1,
          ),
        ),
        AddTimeButton(onPressed: _addTime),
      ],
    );
  }

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

  // ==================== INTERACTION CHECK ====================

  Future<void> _checkInteractions() async {
    if (_nameController.text.isEmpty) return;

    setState(() => _isCheckingInteractions = true);

    final medicationProvider = context.read<MedicationProvider>();

    await medicationProvider.checkInteractions(
      _nameController.text,
      _ingredientController.text.isNotEmpty ? _ingredientController.text : null,
    );

    setState(() => _isCheckingInteractions = false);

    if (!mounted) return;

    if (medicationProvider.hasInteractions) {
      _showInteractionDialog(medicationProvider);
    }
  }

  void _showInteractionDialog(MedicationProvider provider) {
    InteractionDialog.show(
      context,
      interactions: provider.detectedInteractions,
      onAddAnyway: provider.detectedInteractions.any(
            (i) => i.severity.toLowerCase() == 'major',
      )
          ? null
          : _saveMedication,
    );
  }

  // ==================== SAVE MEDICATION ====================

  Widget _buildSaveButton(MedicationProvider provider) {
    final isLoading = provider.isLoading || _isCheckingInteractions;

    return AppButton(
      text: 'حفظ الدواء',
      onPressed: isLoading ? null : _saveMedication,
      isLoading: isLoading,
      active: true,
      horizontalPadding: 0,
    );
  }

  Future<void> _saveMedication() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final medicationProvider = context.read<MedicationProvider>();

    if (authProvider.currentUser == null) {
      CustomSnackBar.show(
        context,
        message: 'خطأ: المستخدم غير مسجل',
        type: SnackBarType.error,
      );
      return;
    }

    // Format times
    final timesString = _times
        .map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}')
        .toList();

    // Get image URL
    final imageUrl = _selectedImage?.path;

    // Save medication
    final success = await medicationProvider.addMedication(
      userId: authProvider.currentUser!.id,
      name: _nameController.text,
      activeIngredient: _ingredientController.text.isNotEmpty ? _ingredientController.text : null,
      dosage: _dosageController.text,
      frequency: _frequency,
      times: timesString,
      imageUrl: imageUrl,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    if (!mounted) return;

    if (success) {
      CustomSnackBar.show(
        context,
        message: 'تم إضافة الدواء بنجاح ✅',
        type: SnackBarType.success,
      );
      Navigator.pop(context, true);
    } else {
      CustomSnackBar.show(
        context,
        message: medicationProvider.errorMessage ?? 'فشل في الحفظ',
        type: SnackBarType.error,
      );
    }
  }
}