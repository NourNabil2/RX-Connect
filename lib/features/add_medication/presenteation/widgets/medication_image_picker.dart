// lib/features/add_medication/widgets/add_medication_widgets.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/chat_screen.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/doctors_directory_screen.dart';
import 'package:pharmacist_assistant/core/models/medication/medication_model.dart';
import 'package:pharmacist_assistant/core/utils/extension.dart'; // Contains .hhmm() extension
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';

// Assuming DrugInteractionModel is defined in medication_model.dart or a related file
// Since you provided the definition for DrugInteractionModel, we use it directly here.
// We also need the definition of DrugInteractionModel for the Interaction Dialog.
// For the purpose of making this file compile, we must assume the DrugInteractionModel
// is available. I will paste the provided DrugInteractionModel definition here ONLY
// if it is absolutely necessary for compilation, otherwise, I will rely on the existing import.
// Given the ambiguity, I'll rely on the existing import and assume the class name change.

// NOTE: We MUST define the DrugInteractionModel or assume it's imported.
// Since the InteractionWarningCard uses DrugInteractionModel, we MUST use it
// for the InteractionDialog as well.

/// Image Picker Widget
class MedicationImagePicker extends StatelessWidget {
  final File? selectedImage;
  final String? networkImageUrl;
  final VoidCallback onTap;

  const MedicationImagePicker({
    Key? key,
    required this.selectedImage,
    this.networkImageUrl,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 120.r,
          height: 120.r,
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: theme.dividerColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: selectedImage != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: Image.file(selectedImage!, fit: BoxFit.cover),
          )
              : networkImageUrl != null && networkImageUrl!.isNotEmpty
              ? ClipRRect(
            borderRadius: BorderRadius.circular(16.r),
            child: CachedNetworkImage(
              imageUrl: networkImageUrl!,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => _buildPlaceholder(theme),
            ),
          )
              : _buildPlaceholder(theme),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
                size: 40.r,
                color: theme.hintColor,
              ),
              SizedBox(height: 8.h),
              Text(
                'إضافة صورة',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
    );
  }
}

/// Image Source Bottom Sheet
class ImageSourceBottomSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;
  final bool hasImage;

  const ImageSourceBottomSheet({
    Key? key,
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
    this.hasImage = false,
  }) : super(key: key);

  static void show(
      BuildContext context, {
        required VoidCallback onCamera,
        required VoidCallback onGallery,
        VoidCallback? onRemove,
        bool hasImage = false,
      }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => ImageSourceBottomSheet(
        onCamera: onCamera,
        onGallery: onGallery,
        onRemove: onRemove,
        hasImage: hasImage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      padding: EdgeInsets.all(20.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 20.h),

          // Title
          Text(
            'اختر صورة الدواء',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20.h),

          // Options
          Row(
            children: [
              Expanded(
                child: _ImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'الكاميرا',
                  color: const Color(0xFF1E88E5),
                  onTap: onCamera,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _ImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'المعرض',
                  color: const Color(0xFF00ACC1),
                  onTap: onGallery,
                ),
              ),
            ],
          ),

          // Remove button
          if (hasImage && onRemove != null) ...[
            SizedBox(height: 12.h),
            TextButton.icon(
              onPressed: onRemove,
              icon: const Icon(Icons.delete, color: Colors.red),
              label: Text(
                'إزالة الصورة',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Image Source Option
class _ImageSourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ImageSourceOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20.h),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32.r, color: color),
            SizedBox(height: 8.h),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time Slot Row
class TimeSlotRow extends StatelessWidget {
  final TimeOfDay time;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onRemove;
  final bool canRemove;

  const TimeSlotRow({
    Key? key,
    required this.time,
    required this.index,
    required this.onTap,
    required this.onRemove,
    required this.canRemove,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12.r),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  filled: true,
                  fillColor: theme.cardColor,
                ),
                child: Text(
                  DateTime(2025, 1, 1, time.hour, time.minute).hhmm(),
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

/// Interaction Warning Card
class InteractionWarningCard extends StatelessWidget {
  // Uses DrugInteractionModel as defined in the provided code block
  final DrugInteractionModel interaction;

  const InteractionWarningCard({
    Key? key,
    required this.interaction,
  }) : super(key: key);

  Color get _severityColor {
    return switch (interaction.severity.toLowerCase()) {
      'major' || 'high' => Colors.red,
      'moderate' || 'medium' => Colors.orange,
      'minor' || 'low' => Colors.yellow[700]!,
      _ => Colors.grey,
    };
  }

  IconData get _severityIcon {
    return switch (interaction.severity.toLowerCase()) {
      'major' || 'high' => Icons.dangerous,
      'moderate' || 'medium' => Icons.warning_amber,
      'minor' || 'low' => Icons.info,
      _ => Icons.help_outline,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: _severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _severityColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(_severityIcon, color: _severityColor, size: 20.r),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  // Assumes interaction has a property called interactingMedication
                  // Since the provided DrugInteractionModel doesn't have it,
                  // I will assume it's derived or a property of a wrapper model.
                  // For now, I'll use drug2 from DrugInteractionModel as a placeholder
                  'تفاعل مع: ${interaction.drug2}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _severityColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),

          // Description
          Text(
            interaction.description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Interaction Dialog - Pre-save Warning
class InteractionDialog extends StatelessWidget {
  final List<DrugInteractionModel> interactions;
  final VoidCallback? onAddAnyway;
  final String medicationName;

  const InteractionDialog({
    Key? key,
    required this.interactions,
    this.onAddAnyway,
    required this.medicationName,
  }) : super(key: key);

  static Future<bool> show(
      BuildContext context, {
        required List<DrugInteractionModel> interactions,
        required String medicationName,
        VoidCallback? onAddAnyway,
      }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => InteractionDialog(
        interactions: interactions,
        medicationName: medicationName,
        onAddAnyway: onAddAnyway,
      ),
    );
    return result ?? false;
  }

  bool get _hasMajorInteraction {
    return interactions.any(
          (i) => i.severity.toLowerCase() == 'major' || i.severity.toLowerCase() == 'severe',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      icon: Container(
        width: 80.r,
        height: 80.r,
        decoration: BoxDecoration(
          color: _hasMajorInteraction
              ? Colors.red.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _hasMajorInteraction ? Icons.dangerous_rounded : Icons.warning_amber_rounded,
          color: _hasMajorInteraction ? Colors.red : Colors.orange,
          size: 40.r,
        ),
      ),
      title: Text(
        _hasMajorInteraction ? '⛔ تفاعل دوائي خطير!' : '⚠️ تحذير: تفاعل دوائي',
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_hasMajorInteraction) ...[
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red, size: 20.r),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          'هذا التفاعل خطير ويُنصح بعدم إضافة هذا الدواء.',
                          style: TextStyle(
                            color: Colors.red[800],
                            fontWeight: FontWeight.bold,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12.h),
              ],
              ...interactions.map(
                    (interaction) => InteractionWarningCard(interaction: interaction),
              ),
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'يُنصح بشدة باستشارة الطبيب أو الصيدلي قبل المتابعة.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.blue[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        // Contact Doctor Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _contactDoctor(context),
            icon: const Icon(Icons.medical_services_outlined),
            label: const Text('استشارة الطبيب عبر الشات', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F6E56),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context, false),
            icon: const Icon(Icons.cancel_outlined),
            label: const Text('إلغاء الإضافة'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 12.h),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            ),
          ),
        ),
        if (!_hasMajorInteraction && onAddAnyway != null) ...[
          SizedBox(height: 8.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.warning_amber),
              label: const Text('إضافة رغم التحذير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12.h),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _contactDoctor(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    // Fetch the patient's doctors
    final doctorsQuery = await chatProvider.getMyDoctors(currentUser.id).first;
    final doctors = doctorsQuery.docs;

    if (!context.mounted) return;

    if (doctors.isEmpty) {
      // No doctors, ask to search for one
      showDialog(
        context: context,
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
            title: const Text('لا يوجد أطباء'),
            content: const Text('ليس لديك أي محادثات مع أطباء حالياً، هل تود البحث عن طبيب لاستشارته؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context, false); // Close InteractionDialog
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const DoctorsDirectoryScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F6E56)),
                child: const Text('البحث عن طبيب', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    } else if (doctors.length == 1) {
      // Only 1 doctor, send and navigate
      final docData = doctors.first.data() as Map<String, dynamic>;
      _sendAlertAndNavigate(context, docData, currentUser, chatProvider);
    } else {
      // Multiple doctors, show a bottom sheet to select
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        builder: (ctx) => Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'اختر الطبيب للاستشارة',
                  style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.h),
                ...doctors.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFF0F6E56).withOpacity(0.1),
                      child: const Icon(Icons.medical_services_rounded, color: Color(0xFF0F6E56)),
                    ),
                    title: Text('د. ${data['doctorName']}'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _sendAlertAndNavigate(context, data, currentUser, chatProvider);
                    },
                  );
                }).toList(),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _sendAlertAndNavigate(
      BuildContext context,
      Map<String, dynamic> docData,
      UserModel currentUser,
      ChatProvider chatProvider) async {
    
    final doctorId = docData['doctorId'] as String;
    final doctorName = docData['doctorName'] as String;
    final chatId = docData['chatId'] as String;

    final interactionsMap = interactions.map((i) => i.toJson()).toList();

    await chatProvider.sendConflictAlert(
      patientId: currentUser.id,
      patientName: currentUser.name,
      doctorId: doctorId,
      medicationName: medicationName,
      interactions: interactionsMap,
    );

    if (!context.mounted) return;
    
    // Close the dialog and open the chat
    Navigator.pop(context, false);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          chatId: chatId,
          otherUserName: 'د. $doctorName',
          currentUserId: currentUser.id,
          currentUserRole: 'patient',
        ),
      ),
    );
  }
}

/// Add Time Button
class AddTimeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AddTimeButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(
        Icons.add_circle_outline,
        color: theme.colorScheme.primary,
      ),
      label: Text(
        'إضافة وقت آخر',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}