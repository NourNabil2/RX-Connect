import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/theme/colors.dart';
import '../utils/app_size.dart';



class AppTextField extends StatefulWidget {
  // Basic text field properties
  final String hintText;
  final String? labelText;
  final String? title;
  final TextEditingController? controller;
  final bool obscureText;
  final String? errorText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function()? onTap;
  final void Function(String)? onSubmitted;
  final VoidCallback? onEditingComplete;
  final bool hasError;
  final bool isDropMenu;

  // Input properties
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final bool readOnly;
  final bool enabled;
  final bool autofocus;
  final FocusNode? focusNode;
  final TextCapitalization textCapitalization;
  final TextAlign textAlign;

  // Visual customization
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? prefixText;
  final String? suffixText;
  final Color? fillColor;
  final Color? focusedFillColor; // Add focused fill color
  final Color? borderColor;
  final Color? focusedBorderColor;
  final Color? errorBorderColor;
  final Color? textColor;
  final Color? hintColor;
  final Color? focusedHintColor; // Add focused hint color
  final Color? labelColor;
  final Color? cursorColor;
  final double? borderRadius;
  final double? borderWidth;
  final EdgeInsetsGeometry? contentPadding;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;
  final TextStyle? labelStyle;
  final TextStyle? errorStyle;
  final TextStyle? titleStyle;
  final Color? titleColor;

  // Layout properties
  final double? height;
  final double? width;
  final bool isDense;
  final bool isCollapsed;
  final double titleSpacing;

  const AppTextField({
    Key? key,
    required this.hintText,
    this.labelText,
    this.title, // Add title parameter
    this.controller,
    this.obscureText = false,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.hasError = false,

    // Input properties
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.maxLines = 1,
    this.minLines,
    this.maxLength,
    this.readOnly = false,
    this.enabled = true,
    this.isDropMenu = false,
    this.autofocus = false,
    this.focusNode,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,

    // Visual customization
    this.prefixIcon,
    this.suffixIcon,
    this.prefixText,
    this.suffixText,
    this.fillColor,
    this.focusedFillColor,
    this.borderColor,
    this.focusedBorderColor,
    this.errorBorderColor,
    this.textColor,
    this.hintColor,
    this.focusedHintColor,
    this.labelColor,
    this.cursorColor,
    this.borderRadius,
    this.borderWidth,
    this.contentPadding,
    this.textStyle,
    this.hintStyle,
    this.labelStyle,
    this.errorStyle,
    this.titleStyle,
    this.titleColor,

    // Layout properties
    this.height,
    this.width,
    this.isDense = false,
    this.isCollapsed = false,
    this.titleSpacing = 9,
  }) : super(key: key);

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_onFocusChange);

    // Set initial focus state
    _isFocused = _focusNode.hasFocus || widget.autofocus;
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    } else {
      _focusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  Widget? _buildSuffixIcon() {
    // If there's an error, show X icon (highest priority)
    if (widget.hasError || widget.errorText != null) {
      return InkWell(
        onTap: () {
          widget.controller?.clear();
          if (widget.onChanged != null) {
            widget.onChanged!('');
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Icon(
            Icons.close,
            size: 20,
            color: widget.errorBorderColor ?? ColorsManager.errorFill,
          ),
        ),
      );
    }

    // Check if this is a password field and show visibility toggle
    if (widget.keyboardType == TextInputType.visiblePassword) {
      return IconButton(
        icon: Icon(
          _isPasswordVisible
              ? Icons.visibility_off_outlined
              : Icons.visibility_outlined,
          color: Colors.grey[600],
          size: 20,
        ),
        onPressed: _togglePasswordVisibility,
        splashRadius: 20,
      );
    }

    // Only return suffix icon if there's no suffix text
    // This allows suffix text to be shown when there's no suffix icon
    if (widget.suffixText != null && widget.suffixText!.isNotEmpty) {
      return null; // Return null so suffixText can be displayed
    }

    // Otherwise, return the provided suffix icon
    return widget.suffixIcon;
  }

  Widget _buildTitle() {
    if (widget.title == null) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(bottom: widget.titleSpacing),
      child: Text(
        widget.title!,
        style: widget.titleStyle ??
            Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final defaultFillColor = widget.fillColor ?? Theme.of(context).scaffoldBackgroundColor;
    final defaultFocusedFillColor = widget.focusedFillColor ?? const Color(0x4CDBDADA);
    final defaultBorderColor = widget.borderColor ?? const Color(0xff8692A6);
    final defaultFocusedBorderColor = widget.focusedBorderColor ?? ColorsManager.primaryColor;
    final defaultErrorBorderColor = widget.errorBorderColor ?? ColorsManager.errorFill;
    final defaultTextColor = widget.textColor ??( isDarkMode ?Colors.white: Colors.black);
    final defaultHintColor = widget.hintColor ?? Colors.grey;
    final defaultFocusedHintColor = widget.focusedHintColor ?? Colors.grey;
    final defaultCursorColor = widget.cursorColor ?? ColorsManager.primaryColor;
    final defaultBorderRadius = widget.borderRadius ?? SizeApp.radiusSmall;
    final defaultBorderWidth = widget.borderWidth ?? 0.42;
    final defaultContentPadding = widget.contentPadding ?? const EdgeInsets.symmetric(
      vertical: 12,
      horizontal: 16,
    );

    // Choose fill color based on focus state
    final currentFillColor = _isFocused ? defaultFocusedFillColor : defaultFillColor;

    // Choose hint color based on focus state
    final currentHintColor = _isFocused ? defaultFocusedHintColor : defaultHintColor;

    Widget textField = TextFormField(
      controller: widget.controller,
      obscureText: widget.keyboardType == TextInputType.visiblePassword
          ? !_isPasswordVisible  // Use toggle state for password fields
          : widget.obscureText,  // Use original value for non-password fields
      cursorColor: defaultCursorColor,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      maxLength: widget.maxLength,
      readOnly: widget.readOnly,
      enabled: widget.enabled,
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      textCapitalization: widget.textCapitalization,
      textAlign: widget.textAlign,
      onTap: widget.onTap,

      onFieldSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      decoration: InputDecoration(
        labelText: widget.labelText,
        labelStyle: widget.labelStyle ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: widget.labelColor,
            ),
        hintText: widget.hintText,
        hintStyle: widget.hintStyle ??
            Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontSize: 13.33.sp,
              color: currentHintColor,
            ),
        prefixIcon: widget.prefixIcon,
        suffixIcon: _buildSuffixIcon(), // This will now handle password visibility
        prefixText: widget.prefixText,
        suffixText: widget.suffixText,
        filled: true,
        fillColor: currentFillColor,
        isDense: widget.isDense,
        isCollapsed: widget.isCollapsed,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: widget.hasError ? defaultErrorBorderColor : defaultBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: widget.hasError ? defaultErrorBorderColor : defaultFocusedBorderColor,
            width: 1,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultErrorBorderColor,
            width: defaultBorderWidth,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: defaultErrorBorderColor,
            width: 2,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(defaultBorderRadius),
          borderSide: BorderSide(
            color: widget.isDropMenu ? defaultBorderColor : Colors.grey.withOpacity(0.3),
            width: defaultBorderWidth,
          ),
        ),
        errorText: widget.errorText,
        errorStyle: widget.errorStyle ?? TextStyle(
            color: defaultErrorBorderColor
        ),
        contentPadding: defaultContentPadding,
        counterText: widget.maxLength != null ? null : "",
      ),
      style: widget.textStyle ?? TextStyle(
        color: defaultTextColor,
        fontSize: 16,
      ),
      validator: widget.validator,
      onChanged: widget.onChanged,
    );


    // Wrap with SizedBox if height or width is specified
    if (widget.height != null || widget.width != null) {
      textField = SizedBox(
        height: widget.height,
        width: widget.width,
        child: textField,
      );
    }

    // Wrap the entire widget with Column to include title
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildTitle(),
        textField,
      ],
    );
  }
}

// Factory constructors for common use cases
extension AppTextFieldFactory on AppTextField {
  // Email input field
  static AppTextField email({
    Key? key,
    String hintText = 'Enter your email',
    String? title,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool hasError = false,
    bool readOnly = false,
    Widget? prefixIcon,
    Color? focusedFillColor,
    Color? focusedHintColor,
    TextStyle? titleStyle,
    Color? titleColor,
    Color? fillColor,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText,
      title: title,
      fillColor: fillColor,
      readOnly: readOnly,
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      textCapitalization: TextCapitalization.none,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      hasError: hasError,
      focusedFillColor: focusedFillColor,
      focusedHintColor: focusedHintColor,
      titleStyle: titleStyle,
      titleColor: titleColor,
    );
  }

  // Password input field
  static AppTextField password({
    Key? key,
    String hintText = 'Enter your password',
    String? title,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool hasError = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? focusedFillColor,
    Color? focusedHintColor,
    TextStyle? titleStyle,
    Color? titleColor,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText,
      title: title,
      controller: controller,
      obscureText: true,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      hasError: hasError,
      suffixIcon: suffixIcon, // Will be overridden by X icon if error
      focusedFillColor: focusedFillColor,
      focusedHintColor: focusedHintColor,
      titleStyle: titleStyle,
      titleColor: titleColor,
    );
  }

  // Multiline text area
  static AppTextField textArea({
    Key? key,
    String hintText = 'Enter text...',
    String? labelText,
    String? title,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool hasError = false,
    int maxLines = 4,
    int? maxLength,
    Color? focusedFillColor,
    Color? focusedHintColor,
    TextStyle? titleStyle,
    Color? titleColor,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText,
      labelText: labelText,
      title: title,
      controller: controller,
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      maxLines: maxLines,
      maxLength: maxLength,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      hasError: hasError,
      textAlign: TextAlign.start,
      focusedFillColor: focusedFillColor,
      focusedHintColor: focusedHintColor,
      titleStyle: titleStyle,
      titleColor: titleColor,
    );
  }

  // Number input field
  static AppTextField number({
    Key? key,
    String hintText = 'Enter number',
    String? labelText = 'Number',
    String? title,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool hasError = false,
    bool allowDecimal = false,
    Widget? prefixIcon,
    Color? focusedFillColor,
    Color? focusedHintColor,
    TextStyle? titleStyle,
    Color? titleColor,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText,
      labelText: labelText,
      title: title,
      controller: controller,
      keyboardType: allowDecimal ?
      const TextInputType.numberWithOptions(decimal: true) :
      TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: allowDecimal ?
      [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))] :
      [FilteringTextInputFormatter.digitsOnly],
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      hasError: hasError,
      prefixIcon: prefixIcon,
      focusedFillColor: focusedFillColor,
      focusedHintColor: focusedHintColor,
      titleStyle: titleStyle,
      titleColor: titleColor,
    );
  }

  // Add this to your existing AppTextField factory extension

// Search input field
  static AppTextField search({
    Key? key,
    String hintText = 'Search',
    String? title,
    TextEditingController? controller,
    String? errorText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    void Function()? onTap,
    void Function(String)? onSubmitted,
    bool hasError = false,
    bool readOnly = false,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? fillColor,
    Color? focusedFillColor,
    Color? focusedHintColor,
    TextStyle? titleStyle,
    Color? titleColor,
    double? borderRadius,
    EdgeInsetsGeometry? contentPadding,
    bool autofocus = false,
    FocusNode? focusNode,
  }) {
    return AppTextField(
      key: key,
      hintText: hintText,
      title: title,
      controller: controller,
      readOnly: readOnly,
      autofocus: autofocus,
      focusNode: focusNode,
      onTap: onTap,
      onSubmitted: onSubmitted,
      prefixIcon: prefixIcon ?? const Icon(
        Icons.search,
        color: Colors.grey,
        size: 20,
      ),
      suffixIcon: suffixIcon,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.none,
      errorText: errorText,
      validator: validator,
      onChanged: onChanged,
      hasError: hasError,

      // Search-specific styling
      fillColor: fillColor ?? Colors.grey[100],
      focusedFillColor: focusedFillColor ?? Colors.grey[100],
      focusedHintColor: focusedHintColor ?? Colors.grey[600],
      titleStyle: titleStyle,
      titleColor: titleColor,

      // No border styling
      borderColor: Colors.transparent,
      focusedBorderColor: Colors.transparent,
      errorBorderColor: Colors.transparent,
      borderWidth: 0,
      borderRadius: borderRadius ?? 12,

      // Content padding
      contentPadding: contentPadding ?? const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
    );
  }
}