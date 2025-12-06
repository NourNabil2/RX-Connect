import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'colors.dart';


class AppTextTheme {
  static const String fontFamily = 'Poppins';

  /// Light Theme TextStyles
  static final TextTheme lightTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48.sp,
      fontWeight: FontWeight.bold,
      fontFamily: fontFamily,
      color: ColorsManager.defaultText,
    ),
    headlineLarge: TextStyle(
      fontSize: 32.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultText,
    ),
    titleLarge: TextStyle(
      fontSize: 20.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultText,
    ),
    titleMedium:  TextStyle(
      fontSize: 20.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: ColorsManager.defaultTextSecondary,
    ),
    titleSmall: TextStyle(
      fontSize: 13.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      color: ColorsManager.defaultText,
    ),
    bodyLarge: TextStyle(
      fontSize: 18.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.normal,
      color: ColorsManager.defaultTextSecondary,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.normal,
      overflow: TextOverflow.ellipsis,
      color: ColorsManager.defaultTextSecondary,
    ),
    bodySmall: TextStyle(
      fontSize: 14.sp,
      fontFamily: fontFamily,
      color: ColorsManager.defaultTextSecondary,
    ),
    labelLarge: TextStyle(
      fontSize: 16.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: ColorsManager.primaryColor,
    ),
    labelMedium: TextStyle(
      fontSize: 14.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      color: ColorsManager.miscellaneous,
    ),
    labelSmall: TextStyle(
    fontSize: 10.sp,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w400,
    color: ColorsManager.defaultTextSecondary,
  ),
    displaySmall: TextStyle(
      fontSize: 10.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w300,
      color: ColorsManager.defaultTextSecondary,
    ),
  );

  /// Dark Theme TextStyles
  static final TextTheme darkTextTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: 48.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    headlineLarge: TextStyle(
      fontSize: 32.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    titleLarge: TextStyle(
      fontSize: 20.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      color: ColorsManager.defaultSurface,
    ),
    titleMedium:  TextStyle(
      fontSize: 20.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    bodyLarge: TextStyle(
      fontSize: 18.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.normal,
      color: Colors.white70,
    ),
    bodyMedium: TextStyle(
      fontSize: 16.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.normal,
      color: Colors.white,
    ),
    bodySmall: TextStyle(
      fontSize: 14.sp,
      fontFamily: fontFamily,
      color: Colors.grey[400],
    ),
    labelLarge: TextStyle(
      fontSize: 16.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    labelMedium: TextStyle(
      fontSize: 14.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w500,
      color: Colors.white70,
    ),
    labelSmall: TextStyle(
      fontSize: 10.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      color: Colors.grey[200],
    ),
    displaySmall: TextStyle(
      fontSize: 10.sp,
      fontFamily: fontFamily,
      fontWeight: FontWeight.w400,
      color: ColorsManager.defaultTextSecondaryDark,
    ),
  );

  /// Optional semantic roles for custom cases
  static final TextStyle infoTextLight = TextStyle(
    color: ColorsManager.infoText,
    fontFamily: fontFamily,
    fontWeight: FontWeight.w500,
  );

  static final TextStyle successTextLight = TextStyle(
    color: ColorsManager.successText,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle warningTextLight = TextStyle(
    color: ColorsManager.warningText,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle errorTextLight = TextStyle(
    color: ColorsManager.errorText,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle infoTextDark = TextStyle(
    color: Colors.lightBlueAccent,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle successTextDark = TextStyle(
    color: Colors.greenAccent,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle warningTextDark = TextStyle(
    color: Colors.orangeAccent,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static final TextStyle errorTextDark = TextStyle(
    color: Colors.redAccent,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );
}
