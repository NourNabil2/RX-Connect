import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/chat_screen.dart';

class DoctorDashboardScreen extends StatelessWidget {
  const DoctorDashboardScreen({Key? key}) : super(key: key);

  // ─── Premium dark teal gradient colors ───
  static const Color _darkTeal = Color(0xFF085041);
  static const Color _primaryTeal = Color(0xFF0F6E56);
  static const Color _lightTeal = Color(0xFF14896B);
  static const Color _accentTeal = Color(0xFF1BA882);

  // ─── Arabic relative‑time formatter ───
  static String _formatTimeArabic(dynamic timestamp) {
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

    if (diff.inSeconds < 60) {
      return 'الآن';
    } else if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      if (m == 1) return 'منذ دقيقة';
      if (m == 2) return 'منذ دقيقتين';
      if (m <= 10) return 'منذ $m دقائق';
      return 'منذ $m دقيقة';
    } else if (diff.inHours < 24) {
      final h = diff.inHours;
      if (h == 1) return 'منذ ساعة';
      if (h == 2) return 'منذ ساعتين';
      if (h <= 10) return 'منذ $h ساعات';
      return 'منذ $h ساعة';
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      final d = diff.inDays;
      if (d == 2) return 'منذ يومين';
      if (d <= 10) return 'منذ $d أيام';
      return 'منذ $d يوم';
    } else if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      if (w == 1) return 'منذ أسبوع';
      if (w == 2) return 'منذ أسبوعين';
      return 'منذ $w أسابيع';
    } else {
      final mon = (diff.inDays / 30).floor();
      if (mon == 1) return 'منذ شهر';
      if (mon == 2) return 'منذ شهرين';
      if (mon <= 10) return 'منذ $mon أشهر';
      return 'منذ $mon شهر';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;
    final doctorName = currentUser?.name ?? 'طبيب';
    final doctorId = currentUser?.id ?? '';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ══════════════════════════════════════
            //  SLIVER APP BAR — gradient header
            // ══════════════════════════════════════
            SliverAppBar(
              expandedHeight: 200.h,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: _darkTeal,
              automaticallyImplyLeading: false,
              actions: [
                // Logout button
                Padding(
                  padding: EdgeInsets.only(left: 8.w),
                  child: IconButton(
                    icon: Icon(
                      Icons.logout_rounded,
                      color: Colors.white.withOpacity(0.9),
                      size: 24.r,
                    ),
                    tooltip: 'تسجيل الخروج',
                    onPressed: () => _showLogoutDialog(context),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [_darkTeal, _primaryTeal, _lightTeal],
                      stops: [0.0, 0.5, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 16.h),
                          // Doctor avatar
                          Container(
                            width: 56.r,
                            height: 56.r,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.15),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 2,
                              ),
                            ),
                            child: Icon(
                              Icons.medical_services_rounded,
                              color: Colors.white,
                              size: 28.r,
                            ),
                          ),
                          SizedBox(height: 12.h),
                          // Greeting
                          Text(
                            'مرحباً د. $doctorName',
                            style: TextStyle(
                              fontSize: 22.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.3,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          // Specialization
                          Text(
                            'لوحة تحكم الطبيب',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ══════════════════════════════════════
            //  PENDING REQUESTS
            // ══════════════════════════════════════
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: context.read<ChatProvider>().getPendingRequests(doctorId),
                builder: (context, snapshot) {
                  final requests = snapshot.data?.docs ?? [];
                  if (requests.isEmpty) return const SizedBox.shrink();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 8.h),
                        child: Row(
                          children: [
                            Container(width: 4.w, height: 20.h, decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(2.r))),
                            SizedBox(width: 8.w),
                            Text('طلبات استشارة معلقة', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1A2B3C))),
                            SizedBox(width: 8.w),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                              decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(10.r)),
                              child: Text('${requests.length}', style: TextStyle(color: Colors.orange[800], fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                        itemCount: requests.length,
                        separatorBuilder: (_, __) => SizedBox(height: 12.h),
                        itemBuilder: (context, index) {
                          final data = requests[index].data() as Map<String, dynamic>;
                          final chatId = data['chatId'] as String;
                          final patientId = data['patientId'] as String;
                          final patientName = data['patientName'] as String;

                          return Container(
                            padding: EdgeInsets.all(16.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                              border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 24.r,
                                  backgroundColor: Colors.orange.withOpacity(0.1),
                                  child: Icon(Icons.person, color: Colors.orange, size: 28.r),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(patientName, style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
                                      Text('يطلب استشارة عبر الشات', style: TextStyle(fontSize: 13.sp, color: Colors.grey[600])),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => context.read<ChatProvider>().rejectRequest(chatId),
                                      icon: const Icon(Icons.close),
                                      color: Colors.red,
                                      style: IconButton.styleFrom(backgroundColor: Colors.red.withOpacity(0.1)),
                                    ),
                                    SizedBox(width: 8.w),
                                    IconButton(
                                      onPressed: () => context.read<ChatProvider>().acceptRequest(chatId, patientId, patientName, doctorId),
                                      icon: const Icon(Icons.check),
                                      color: Colors.green,
                                      style: IconButton.styleFrom(backgroundColor: Colors.green.withOpacity(0.1)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 16.h),
                    ],
                  );
                },
              ),
            ),

            // ══════════════════════════════════════
            //  STATS BAR + PATIENT LIST
            // ══════════════════════════════════════
            SliverToBoxAdapter(
              child: StreamBuilder<QuerySnapshot>(
                stream: context
                    .read<ChatProvider>()
                    .getMyPatients(doctorId),
                builder: (context, snapshot) {
                  final patients = snapshot.data?.docs ?? [];
                  final patientCount = patients.length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Stats bar ──
                      _buildStatsBar(patientCount),

                      // ── Section title ──
                      Padding(
                        padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 12.h),
                        child: Row(
                          children: [
                            Container(
                              width: 4.w,
                              height: 20.h,
                              decoration: BoxDecoration(
                                color: _primaryTeal,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              'المرضى المتصلين',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A2B3C),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Patient list or states ──
                      if (snapshot.connectionState == ConnectionState.waiting)
                        _buildLoadingState()
                      else if (snapshot.hasError)
                        _buildErrorState(snapshot.error.toString())
                      else if (patients.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.fromLTRB(
                              20.w, 0, 20.w, 100.h),
                          itemCount: patients.length,
                          separatorBuilder: (_, __) =>
                              SizedBox(height: 12.h),
                          itemBuilder: (context, index) {
                            final data = patients[index].data()
                                as Map<String, dynamic>;
                            return _buildPatientCard(
                              context: context,
                              data: data,
                              doctorId: doctorId,
                              doctorName: doctorName,
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  STATS BAR
  // ══════════════════════════════════════════════════
  Widget _buildStatsBar(int patientCount) {
    return Container(
      margin: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 16.h),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _primaryTeal.withOpacity(0.08),
            _accentTeal.withOpacity(0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _primaryTeal.withOpacity(0.12),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: _primaryTeal.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.people_alt_rounded,
              color: _primaryTeal,
              size: 24.r,
            ),
          ),
          SizedBox(width: 16.w),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'عدد المرضى',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  '$patientCount مريض',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w800,
                    color: _darkTeal,
                  ),
                ),
              ],
            ),
          ),
          // Decorative chevron
          Icon(
            Icons.trending_up_rounded,
            color: _accentTeal.withOpacity(0.5),
            size: 28.r,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  PATIENT CARD
  // ══════════════════════════════════════════════════
  Widget _buildPatientCard({
    required BuildContext context,
    required Map<String, dynamic> data,
    required String doctorId,
    required String doctorName,
  }) {
    final patientName = data['patientName'] as String? ?? 'مريض';
    final patientId = data['patientId'] as String? ?? '';
    final lastMessage = data['lastMessage'] as String? ?? '';
    final lastMessageTime = data['lastMessageTime'];
    final chatId = data['chatId'] as String? ?? '';
    final formattedTime = _formatTimeArabic(lastMessageTime);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16.r),
        onTap: () {
          if (chatId.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  chatId: chatId,
                  otherUserName: patientName,
                  currentUserId: doctorId,
                  currentUserRole: 'doctor',
                ),
              ),
            );
          }
        },
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F6E56).withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              // Patient avatar
              Container(
                width: 52.r,
                height: 52.r,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primaryTeal, _lightTeal],
                  ),
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Center(
                  child: Text(
                    patientName.isNotEmpty
                        ? patientName[0].toUpperCase()
                        : '؟',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 14.w),

              // Name + last message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1A2B3C),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (lastMessage.isNotEmpty) ...[
                      SizedBox(height: 4.h),
                      Text(
                        lastMessage,
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFF9CA3AF),
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Time + arrow
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (formattedTime.isNotEmpty)
                    Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFB0B8C1),
                      ),
                    ),
                  SizedBox(height: 6.h),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 14.r,
                    color: const Color(0xFFD1D5DB),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  STATE WIDGETS
  // ══════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h),
      child: Center(
        child: Column(
          children: [
            SizedBox(
              width: 40.r,
              height: 40.r,
              child: const CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryTeal),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'جاري تحميل المرضى...',
              style: TextStyle(
                fontSize: 14.sp,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 32.w),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 64.r,
              height: 64.r,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: const Color(0xFFDC2626),
                size: 32.r,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'حدث خطأ',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B3C),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 60.h, horizontal: 32.w),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 80.r,
              height: 80.r,
              decoration: BoxDecoration(
                color: _primaryTeal.withOpacity(0.08),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Icon(
                Icons.person_search_rounded,
                color: _primaryTeal.withOpacity(0.4),
                size: 40.r,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'لا يوجد مرضى متصلين',
              style: TextStyle(
                fontSize: 17.sp,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A2B3C),
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'سيظهر المرضى هنا عند اتصالهم بحسابك',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: const Color(0xFF9CA3AF),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════
  //  LOGOUT DIALOG
  // ══════════════════════════════════════════════════
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          title: Text(
            'تسجيل الخروج',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A2B3C),
            ),
          ),
          content: Text(
            'هل أنت متأكد من تسجيل الخروج؟',
            style: TextStyle(
              fontSize: 14.sp,
              color: const Color(0xFF6B7280),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'إلغاء',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.read<AuthProvider>().signOut();
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (route) => false,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
                elevation: 0,
              ),
              child: Text(
                'خروج',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
