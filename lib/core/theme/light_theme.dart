
import 'package:flutter/material.dart';
import 'colors.dart';
import 'text_theme.dart';

class LightTheme {
  static final ThemeData theme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    // Primary Colors
    primaryColor: ColorsManager.primaryColor,
    primaryColorLight: ColorsManager.secondaryColor,
    primaryColorDark: ColorsManager.secondaryDarkColor,
    cardColor: ColorsManager.backgroundCard,
    // Background & Surface
    scaffoldBackgroundColor: ColorsManager.backgroundSurface,

    // Color Scheme
    colorScheme: ColorScheme.fromSeed(
      seedColor: ColorsManager.primaryColor,
      brightness: Brightness.light,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: ColorsManager.primaryColor,
      unselectedItemColor: ColorsManager.backgroundSurface,
      backgroundColor: ColorsManager.backgroundCard,
      elevation: 8,
      type: BottomNavigationBarType.fixed,
    ),

    // Bottom App Bar Theme
    bottomAppBarTheme: const BottomAppBarTheme(
      elevation: 0,
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
    ),

    // Text Theme
    textTheme: AppTextTheme.lightTextTheme,
  );
}

