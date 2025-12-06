import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// (افترض أن هذه الملفات موجودة لديك)
import 'package:pharmacist_assistant/core/theme/text_theme.dart';
import 'package:pharmacist_assistant/core/utils/assets.dart';
import 'package:pharmacist_assistant/core/widgets/CustomIcon.dart';
import 'package:pharmacist_assistant/features/home/presentation/screen/home_screen.dart';
import 'package:pharmacist_assistant/features/home/presentation/screen/medication_tap_screen.dart';

class PatientHomeScreen extends StatefulWidget {
  const PatientHomeScreen({Key? key}) : super(key: key);

  @override
  State<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends State<PatientHomeScreen> {
  int _currentIndex = 0;
  bool _isNavBarVisible = true;
  double _lastScrollPosition = 0;

  // ===== قائمة الصفحات (مُعدلة) =====
  // ملاحظة: تأكد من أن الصفحات TabScreen() لا تحتوي على Scaffold/AppBar
  // إذا كنت تريد أن يظهر AppBar الخاص بهم فوق الـ Bottom Nav Bar العائم.
  final List<Widget> _screens = [
    const HomeTabScreen(),
    const MedicationsTabScreen(),
    const RemindersTabScreen(),
    const ChatTabScreen(),
    const ProfileTabScreen(),
  ];

  final List<String> _icons = [
    Assets.homeIcon,
    Assets.pillsIcon,
    Assets.chatsIcon,
    Assets.settingIcon,
  ];

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis == Axis.vertical) {
      if (notification is ScrollUpdateNotification) {
        final currentPosition = notification.metrics.pixels;

        // Check if scrolled more than 50 pixels to avoid small movements
        if ((currentPosition - _lastScrollPosition).abs() > 5) {
          if (currentPosition > _lastScrollPosition && currentPosition > 100) {
            // Scrolling down - hide navbar
            if (_isNavBarVisible) {
              setState(() => _isNavBarVisible = false);
            }
          } else if (currentPosition < _lastScrollPosition) {
            // Scrolling up - show navbar
            // Added check to only show if scroll position is above the bottom of the screen
            if (!_isNavBarVisible && currentPosition < notification.metrics.maxScrollExtent - 100) {
              setState(() => _isNavBarVisible = true);
            }
          }
          _lastScrollPosition = currentPosition;
        }
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // اللون الأساسي النشط (Primary Color)
    final Color activeColor = theme.primaryColor;
    // اللون الأساسي غير النشط (Unselected Color)
    final Color inactiveColor = theme.colorScheme.onSurfaceVariant;

    // لون خلفية الـ Frosted Glass
    final Color glassColor = isDark ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.3);
    // لون إطار الـ Frosted Glass
    final Color borderColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1);


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // تأكد من أن الـ body يمتد أسفل الشريط العائم
      extendBody: true,
      body: Stack(
        children: [
          // المحتوى الرئيسي
          NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: IndexedStack(
              index: _currentIndex,
              children: _screens,
            ),
          ),

          // شريط التنقل السفلي العائم (Floating Bottom Nav Bar)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            // يجب أن يكون الـ 16.h هو نفس المسافة التي تريدها من الأسفل
            bottom: _isNavBarVisible ? 16.h : -100.h,
            left: 12.w,
            right: 12.w,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  height: 70.h, // تم تعديل الارتفاع ليكون أكثر دقة
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  decoration: BoxDecoration(
                    color: glassColor,
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_icons.length, (index) {
                      bool isSelected = _currentIndex == index;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _currentIndex = index),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeInOut,
                                  // استخدام لون Theme.primaryColor
                                  padding: EdgeInsets.all(isSelected ? 8.r : 0),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? activeColor.withOpacity(0.15)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: CustomIcon(
                                   assetPath: _icons[index],
                                    size: 26.r,
                                    color: isSelected ? activeColor : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------

// ===== الصفحات الوهمية المُعدلة لتطبيق الثيم على AppBar =====

class RemindersTabScreen extends StatelessWidget {
  const RemindersTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('التنبيهات', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: const Center(child: Text('Reminders Screen')),
    );
  }
}

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('المساعد', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: const Center(child: Text('Chat Screen')),
    );
  }
}

class ProfileTabScreen extends StatelessWidget {
  const ProfileTabScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('الملف الشخصي', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
      ),
      body: const Center(child: Text('Profile Screen')),
    );
  }
}