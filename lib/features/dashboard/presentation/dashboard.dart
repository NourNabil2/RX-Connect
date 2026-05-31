import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// (افترض أن هذه الملفات موجودة لديك)
import 'package:pharmacist_assistant/core/theme/text_theme.dart';
import 'package:pharmacist_assistant/core/utils/assets.dart';
import 'package:pharmacist_assistant/core/widgets/CustomIcon.dart';
import 'package:pharmacist_assistant/features/home/presentation/screen/home_screen.dart';
import 'package:pharmacist_assistant/features/home/presentation/screen/medication_tap_screen.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/chat_screen.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/doctors_directory_screen.dart';
import 'package:pharmacist_assistant/features/settings/settings_provider.dart';
import 'package:provider/provider.dart';

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

class ChatTabScreen extends StatelessWidget {
  const ChatTabScreen({Key? key}) : super(key: key);

  // ─── Formatter ───
  String _formatTimeArabic(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime dateTime;
    if (timestamp is Timestamp) {
      dateTime = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dateTime = timestamp;
    } else if (timestamp is String) {
      dateTime = DateTime.tryParse(timestamp) ?? DateTime.now();
    } else {
      return '';
    }

    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays == 1) return 'أمس';
    return 'منذ ${diff.inDays} يوم';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final chatProvider = context.read<ChatProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'أطبائي',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: chatProvider.getMyDoctors(currentUser.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: theme.primaryColor),
            );
          }

          if (snapshot.hasError) {
            return const Center(child: Text('حدث خطأ في جلب المحادثات'));
          }

          final allChats = snapshot.data?.docs ?? [];
          final chats = allChats.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status'] as String? ?? 'accepted';
            return status != 'rejected'; // hide rejected entirely or show them? Let's just hide rejected.
          }).toList();

          if (chats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64.r, color: Colors.grey[400]),
                  SizedBox(height: 16.h),
                  Text(
                    'لا يوجد لديك محادثات مع أطباء',
                    style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'اضغط على الزر أدناه للبحث عن طبيب',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[500]),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
            itemCount: chats.length,
            separatorBuilder: (_, __) => SizedBox(height: 12.h),
            itemBuilder: (context, index) {
              final data = chats[index].data() as Map<String, dynamic>;
              final doctorName = data['doctorName'] as String? ?? 'طبيب';
              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastMessageTime = data['lastMessageTime'];
              final chatId = data['chatId'] as String? ?? '';
              final status = data['status'] as String? ?? 'accepted';
              final isPending = status == 'pending';

              return InkWell(
                borderRadius: BorderRadius.circular(16.r),
                onTap: () {
                  if (isPending) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('الطلب قيد الانتظار، يرجى انتظار موافقة الطبيب'),
                        backgroundColor: Colors.orange[800],
                      )
                    );
                    return;
                  }
                  if (chatId.isNotEmpty) {
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
                },
                child: Container(
                  padding: EdgeInsets.all(16.r),
                  decoration: BoxDecoration(
                    color: isPending ? Colors.orange.withOpacity(0.05) : Colors.white,
                    border: isPending ? Border.all(color: Colors.orange.withOpacity(0.3)) : null,
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50.r,
                        height: 50.r,
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(Icons.medical_services_outlined, color: theme.primaryColor),
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'د. $doctorName',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1A2B3C),
                              ),
                            ),
                            if (lastMessage.isNotEmpty) ...[
                              SizedBox(height: 4.h),
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _formatTimeArabic(lastMessageTime),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.grey[400],
                            ),
                          ),
                          SizedBox(height: 8.h),
                          Icon(Icons.arrow_forward_ios, size: 14.r, color: Colors.grey[300]),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 85.h),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DoctorsDirectoryScreen()),
            );
          },
          backgroundColor: theme.primaryColor,
          icon: const Icon(Icons.person_search, color: Colors.white),
          label: const Text('البحث عن طبيب', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class ProfileTabScreen extends StatefulWidget {
  const ProfileTabScreen({Key? key}) : super(key: key);

  @override
  State<ProfileTabScreen> createState() => _ProfileTabScreenState();
}

class _ProfileTabScreenState extends State<ProfileTabScreen> {
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text('تسجيل الخروج',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A2B3C))),
          content: Text('هل أنت متأكد من تسجيل الخروج؟',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280))),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('إلغاء',
                  style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: const Color(0xFF6B7280))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().signOut();
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                elevation: 0,
              ),
              child: Text('خروج', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final currentUser = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text('الإعدادات',
            style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF085041),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: 100.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header Gradient ───
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 40.h),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF085041), Color(0xFF0F6E56)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64.r,
                    height: 64.r,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 2),
                    ),
                    child: Icon(Icons.person, color: Colors.white, size: 34.r),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.name ?? 'المستخدم',
                          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          currentUser?.email ?? '',
                          style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                        ),
                        SizedBox(height: 6.h),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(20.r),
                          ),
                          child: Text(
                            currentUser?.role == 'doctor' ? '🩺 طبيب' : '💊 مريض',
                            style: TextStyle(fontSize: 12.sp, color: Colors.white, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -20),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 40.h),
                    // ─── Alarm Settings Card ───
                    _sectionTitle('🔔 إعدادات التنبيهات'),
                    _buildAlarmCard(settings),

                    SizedBox(height: 20.h),

                    // ─── Other Settings ───
                    _sectionTitle('⚙️ عام'),
                    _buildSettingsCard([
                      _buildSettingTile(icon: Icons.person_outline, title: 'تعديل الملف الشخصي', onTap: () {}),
                      _buildSettingTile(icon: Icons.lock_outline, title: 'الخصوصية والأمان', onTap: () {}),
                      _buildSettingTile(icon: Icons.help_outline, title: 'المساعدة والدعم', onTap: () {}),
                    ]),

                    SizedBox(height: 28.h),

                    // ─── Logout ───
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showLogoutDialog(context),
                        icon: Icon(Icons.logout, color: Colors.white, size: 20.r),
                        label: Text('تسجيل الخروج',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          elevation: 0,
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

  Widget _sectionTitle(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h, top: 4.h),
      child: SizedBox(
        width: double.infinity,
        child: Text(
          text,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.grey[700]),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  Widget _buildAlarmCard(SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Toggle: Enable Alarms
          _buildSwitchRow(
            icon: Icons.alarm,
            iconColor: const Color(0xFF0F6E56),
            title: 'تفعيل التنبيهات',
            subtitle: 'تلقّ تنبيهاً عند وقت كل دواء',
            value: settings.isAlarmEnabled,
            onChanged: (v) => settings.setAlarmEnabled(v),
          ),

          Divider(height: 1, indent: 20.w, endIndent: 20.w),

          // Toggle: Vibration
          AnimatedOpacity(
            opacity: settings.isAlarmEnabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: _buildSwitchRow(
              icon: Icons.vibration,
              iconColor: Colors.indigo,
              title: 'الاهتزاز',
              subtitle: 'اهتزاز الجهاز مع التنبيه',
              value: settings.vibrate,
              onChanged: settings.isAlarmEnabled ? (v) => settings.setVibrate(v) : null,
            ),
          ),

          Divider(height: 1, indent: 20.w, endIndent: 20.w),

          // Slider: Volume
          AnimatedOpacity(
            opacity: settings.isAlarmEnabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Icon(Icons.volume_up, color: Colors.orange[700], size: 20.r),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('مستوى الصوت',
                                style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            Text('${(settings.volume * 100).round()}%',
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500])),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF0F6E56),
                      inactiveTrackColor: const Color(0xFF0F6E56).withOpacity(0.15),
                      thumbColor: const Color(0xFF085041),
                      overlayColor: const Color(0xFF085041).withOpacity(0.1),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: settings.volume,
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      onChanged: settings.isAlarmEnabled
                          ? (v) => settings.setVolume(v)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(height: 1, indent: 20.w, endIndent: 20.w),

          // Dropdown: Snooze Duration
          AnimatedOpacity(
            opacity: settings.isAlarmEnabled ? 1.0 : 0.4,
            duration: const Duration(milliseconds: 300),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.r),
                    decoration: BoxDecoration(
                      color: Colors.purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(Icons.snooze, color: Colors.purple[600], size: 20.r),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('مدة الغفوة (Snooze)',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('وقت التأجيل عند الضغط على غفوة',
                            style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  DropdownButton<int>(
                    value: settings.snoozeDuration,
                    underline: const SizedBox.shrink(),
                    borderRadius: BorderRadius.circular(12.r),
                    items: [5, 10, 15, 20, 30]
                        .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text('$m دقيقة',
                                  style: TextStyle(
                                      fontSize: 14.sp,
                                      color: const Color(0xFF085041),
                                      fontWeight: FontWeight.bold)),
                            ))
                        .toList(),
                    onChanged: settings.isAlarmEnabled
                        ? (v) => settings.setSnoozeDuration(v!)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: iconColor, size: 20.r),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(subtitle, style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0F6E56),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: List.generate(children.length, (i) => Column(
          children: [
            children[i],
            if (i < children.length - 1) Divider(height: 1, indent: 20.w, endIndent: 20.w),
          ],
        )),
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(8.r),
        decoration: BoxDecoration(
          color: const Color(0xFF0F6E56).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: const Color(0xFF0F6E56), size: 22.r),
      ),
      title: Text(title, style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16.r, color: Colors.grey[400]),
    );
  }
}