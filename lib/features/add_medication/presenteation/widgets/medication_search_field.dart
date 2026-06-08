import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/service/DrugInteractionService.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Professional AutoComplete medication search field
/// Connects directly to medical_reference.db
class MedicationSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String? initialValue;
  final Function(Map<String, dynamic> med)? onMedicationSelected;
  final String? Function(String?)? validator;
  final bool enabled;

  const MedicationSearchField({
    Key? key,
    required this.controller,
    this.initialValue,
    this.onMedicationSelected,
    this.validator,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<MedicationSearchField> createState() => _MedicationSearchFieldState();
}

class _MedicationSearchFieldState extends State<MedicationSearchField> {
  final DrugInteractionService _interactionService = DrugInteractionService();
  final LayerLink _layerLink = LayerLink();
  final FocusNode _focusNode = FocusNode();

  OverlayEntry? _overlayEntry;
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    if (widget.initialValue != null) {
      widget.controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        _removeOverlay();
        setState(() => _showSuggestions = false);
      });
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showOverlay() {
    _removeOverlay();
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4.h),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12.r),
            color: Theme.of(context).cardColor,
            child: Container(
              constraints: BoxConstraints(maxHeight: 280.h),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Theme.of(context).dividerColor.withOpacity(0.5),
                ),
              ),
              child: _isLoading
                  ? _buildLoadingIndicator()
                  : _suggestions.isEmpty
                  ? _buildEmptyState()
                  : _buildSuggestionsList(),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20.r,
            height: 20.r,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12.w),
          Text(
            'جاري البحث...',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_outlined,
            color: Theme.of(context).hintColor,
            size: 32.r,
          ),
          SizedBox(height: 8.h),
          Text(
            'لا توجد أدوية مطابقة',
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 13.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(height: 1, indent: 16.w, endIndent: 16.w),
      itemBuilder: (context, index) {
        final med = _suggestions[index];
        return _SuggestionTile(
          med: med,
          onTap: () => _onSuggestionSelected(med),
        );
      },
    );
  }

  void _onSuggestionSelected(Map<String, dynamic> med) {
    final brandName = med['brand_name'] as String;
    final activeIngredient = med['active_ingredient_name'] as String?;

    widget.controller.text = brandName;
    widget.controller.selection = TextSelection.collapsed(offset: brandName.length);

    if (widget.onMedicationSelected != null) {
      widget.onMedicationSelected!(med);
    }

    _removeOverlay();
    setState(() => _showSuggestions = false);
    _focusNode.unfocus();
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    if (value.trim().length < 2) {
      _removeOverlay();
      setState(() {
        _showSuggestions = false;
        _suggestions = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _showSuggestions = true;
    });

    _showOverlay();

    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      final results = await _interactionService.searchMedications(value.trim());

      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        _overlayEntry?.markNeedsBuild();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        validator: widget.validator,
        textDirection: TextDirection.rtl,
        style: theme.textTheme.bodyLarge,
        decoration: InputDecoration(
          labelText: 'اسم الدواء *',
          hintText: 'ابحث عن اسم الدواء التجاري...',
          hintStyle: TextStyle(color: theme.hintColor),
          prefixIcon: Icon(Icons.medication, color: theme.colorScheme.primary),
          suffixIcon: _isLoading
              ? Padding(
            padding: EdgeInsets.all(12.r),
            child: SizedBox(
              width: 16.r,
              height: 16.r,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : Icon(Icons.search, color: theme.hintColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: theme.dividerColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          ),
          filled: true,
          fillColor: theme.cardColor,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        ),
        onChanged: _onSearchChanged,
      ),
    );
  }
}

// ==================== Suggestion Tile ====================

class _SuggestionTile extends StatelessWidget {
  final Map<String, dynamic> med;
  final VoidCallback onTap;

  const _SuggestionTile({
    required this.med,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final brandName = med['brand_name'] as String;
    final activeIngredient = med['active_ingredient_name'] as String?;
    final photoUrl = med['photo_url'] as String?;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(color: theme.dividerColor),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoUrl != null && photoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => Icon(
                        Icons.medication_outlined,
                        size: 20.r,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.medication_outlined,
                      size: 20.r,
                      color: theme.colorScheme.primary,
                    ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    brandName,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (activeIngredient != null) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'المادة الفعالة: $activeIngredient',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}