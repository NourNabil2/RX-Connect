
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/theme/colors.dart';

import 'Loading_widget.dart';


class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool active;
  //final Color backgroundColor;
  final Color? textColor;
// final EdgeInsets padding;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;
  final double? horizontalPadding;
  final double? verticalPadding;

  const AppButton({
    Key? key,
    required this.text,
    this.active = true,
    required this.onPressed,
    this.isLoading = false,
    //this.backgroundColor,
    this.textColor,
   // this.padding = const EdgeInsets.symmetric(horizontal:  horizontalPadding??80, vertical: 15),
    this.borderRadius = 8.0,
    this.textStyle,
    this.leadingIcon, this.horizontalPadding=0, this.verticalPadding=15,

  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 80,
        vertical: verticalPadding ?? 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44.h,
        child: ElevatedButton(
          onPressed: isLoading || !active? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: active ? ColorsManager.primaryColor : ColorsManager.defaultTextSecondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),

          ),
          child: isLoading
              ? const LoadingSpinner(size: 25,)
              :  Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                text,
                style: textStyle ??
                    TextStyle(
                      color: textColor ??
                          (Theme.of(context).brightness == Brightness.dark
                              ? Colors.black
                              : Colors.white),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              if (leadingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    leadingIcon,
                    size: 20,
                    color: textColor ?? Colors.white,
                  ),
                ),

            ],
          ),
        ),
      ),
    );
  }
}


class AppOutlinedButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool active;
  final Color? disabledColor;
  final double borderRadius;
  final TextStyle? textStyle;
  final IconData? leadingIcon;
  final double? horizontalPadding;
  final double? verticalPadding;
  final double borderWidth;

  const AppOutlinedButton({
    Key? key,
    required this.text,
    this.active = true,
    required this.onPressed,
    this.isLoading = false,
    this.disabledColor,
    this.borderRadius = 8.0,
    this.textStyle,
    this.leadingIcon,
    this.horizontalPadding = 0,
    this.verticalPadding = 15,
    this.borderWidth = 1.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding ?? 80,
        vertical: verticalPadding ?? 15,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 44.h,
        child: OutlinedButton(
          onPressed: isLoading || !active ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(
              color: active
                  ? (Theme.of(context).brightness == Brightness.dark )
                  ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
              width: borderWidth,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            foregroundColor: active ? (Theme.of(context).brightness == Brightness.dark )
                ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
          child: isLoading
              ? LoadingSpinner(size: 25)
              : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    leadingIcon,
                    size: 20,
                    color: active ? Theme.of(context).disabledColor : (Theme.of(context).brightness == Brightness.dark )
                        ? ColorsManager.secondaryColor : ColorsManager.primaryColor,
                  ),
                ),
              Text(
                text,
                style: textStyle ??
                    TextStyle(
                      color:  active
                          ? (Theme.of(context).brightness == Brightness.dark )
                          ? ColorsManager.secondaryColor : ColorsManager.primaryColor : Theme.of(context).disabledColor ,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class SecondryAppButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const SecondryAppButton({
    Key? key,
    required this.text,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor, // Button color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8), // Rounded corners
          ),
          padding: EdgeInsets.symmetric(horizontal: 80, vertical: 8),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium));
  }
}
