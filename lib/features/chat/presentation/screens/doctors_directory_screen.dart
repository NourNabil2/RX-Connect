import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/chat/presentation/cubit/chat_provider.dart';
import 'package:pharmacist_assistant/features/chat/presentation/screens/chat_screen.dart';
import 'package:pharmacist_assistant/core/widgets/custom_snack_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart' as cloud_firestore;

// ─────────────────────────────────────────────
//  CONSTANTS
// ─────────────────────────────────────────────
const _kPrimaryTeal = Color(0xFF0F6E56);
const _kDarkTeal = Color(0xFF085041);
const _kLightTeal = Color(0xFFE8F5F0);
const _kSurfaceBg = Color(0xFFF5F6FA);

class DoctorsDirectoryScreen extends StatefulWidget {
  const DoctorsDirectoryScreen({Key? key}) : super(key: key);

  @override
  State<DoctorsDirectoryScreen> createState() => _DoctorsDirectoryScreenState();
}

class _DoctorsDirectoryScreenState extends State<DoctorsDirectoryScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Future<List<Map<String, dynamic>>> _doctorsFuture;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _doctorsFuture =
        Provider.of<ChatProvider>(context, listen: false).getAvailableDoctors();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filterDoctors(
      List<Map<String, dynamic>> doctors) {
    if (_searchQuery.isEmpty) return doctors;
    return doctors
        .where((d) => (d['name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // ─── Assign doctor flow ───
  Future<void> _onConnectPressed(Map<String, dynamic> doctor, String? currentStatus) async {
    if (currentStatus == 'pending') {
      CustomSnackBar.show(context, message: 'طلبك قيد الانتظار بالفعل ⏳', type: SnackBarType.info);
      return;
    } else if (currentStatus == 'accepted') {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final patientId = auth.currentUser?.id;
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chatId = chatProvider.getChatId(patientId!, doctor['id']);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: chatId,
            otherUserName: 'د. ${doctor['name']}',
            currentUserId: patientId,
            currentUserRole: 'patient',
          ),
        ),
      );
      return;
    }

    final doctorName = doctor['name'] ?? 'الطبيب';
    final doctorId = doctor['id'] as String;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => _ConfirmationDialog(doctorName: doctorName),
    );

    if (confirmed != true || !mounted) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final patientId = auth.currentUser?.id;

    if (patientId == null) {
      if (mounted) {
        CustomSnackBar.show(context,
            message: 'يرجى تسجيل الدخول أولاً', type: SnackBarType.error);
      }
      return;
    }

    // Show loading overlay
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black38,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: _kPrimaryTeal),
      ),
    );

    final success = await chatProvider.assignDoctor(patientId, doctorId);

    if (!mounted) return;
    Navigator.of(context).pop(); // close loading

    if (success) {
      CustomSnackBar.show(context,
          message: 'تم إرسال طلب الاستشارة، بانتظار موافقة الطبيب ⏳',
          type: SnackBarType.success);
    } else {
      CustomSnackBar.show(context,
          message: 'فشل إرسال الطلب، حاول مرة أخرى',
          type: SnackBarType.error);
    }
  }

  // ═══════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _kSurfaceBg,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(),
              _buildSearchBar(),
              _buildDoctorsList(),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Gradient App Bar ───
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 160.h,
      pinned: true,
      stretch: true,
      backgroundColor: _kDarkTeal,
      leading: IconButton(
        icon: Container(
          padding: EdgeInsets.all(6.r),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(Icons.arrow_forward_ios, size: 18.r, color: Colors.white),
        ),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: EdgeInsets.only(bottom: 14.h),
        title: Text(
          'دليل الأطباء',
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F6E56),
                Color(0xFF085041),
                Color(0xFF063A2F),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30.r,
                right: -20.r,
                child: Container(
                  width: 140.r,
                  height: 140.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),
              Positioned(
                bottom: 10.r,
                left: -40.r,
                child: Container(
                  width: 100.r,
                  height: 100.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.04),
                  ),
                ),
              ),
              Positioned(
                top: 20.r,
                left: 30.r,
                child: Container(
                  width: 60.r,
                  height: 60.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ),
              // Stethoscope icon
              Positioned(
                top: 50.h,
                left: 0,
                right: 0,
                child: Icon(
                  Icons.medical_services_rounded,
                  size: 44.r,
                  color: Colors.white.withOpacity(0.15),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Search Bar ───
  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 6.h),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            boxShadow: [
              BoxShadow(
                color: _kPrimaryTeal.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: TextStyle(fontSize: 15.sp, color: const Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: 'ابحث عن طبيب بالاسم...',
              hintStyle: TextStyle(
                color: Colors.grey[400],
                fontSize: 14.sp,
              ),
              prefixIcon: Padding(
                padding: EdgeInsets.all(12.r),
                child: Icon(Icons.search_rounded,
                    size: 22.r, color: _kPrimaryTeal),
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.close_rounded,
                          size: 20.r, color: Colors.grey[400]),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
      ),
    );
  }

  // ─── Doctors List ───
  Widget _buildDoctorsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _doctorsFuture,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 44.r,
                    height: 44.r,
                    child: const CircularProgressIndicator(
                      color: _kPrimaryTeal,
                      strokeWidth: 3.5,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'جارٍ تحميل الأطباء...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Error
        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.error_outline_rounded,
              message: 'حدث خطأ في تحميل البيانات',
              subtitle: 'يرجى المحاولة مرة أخرى',
            ),
          );
        }

        final allDoctors = snapshot.data ?? [];
        final filteredDoctors = _filterDoctors(allDoctors);

        // Empty state
        if (allDoctors.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.person_search_rounded,
              message: 'لا يوجد أطباء متاحين حالياً',
              subtitle: 'يرجى المحاولة لاحقاً',
            ),
          );
        }

        // No search results
        if (filteredDoctors.isEmpty) {
          return SliverFillRemaining(
            child: _buildEmptyState(
              icon: Icons.search_off_rounded,
              message: 'لا توجد نتائج',
              subtitle: 'جرّب البحث باسم مختلف',
            ),
          );
        }

        final patientId = Provider.of<AuthProvider>(context, listen: false).currentUser?.id ?? '';
        
        return StreamBuilder<cloud_firestore.QuerySnapshot>(
          stream: context.read<ChatProvider>().getMyDoctors(patientId),
          builder: (context, chatSnapshot) {
            final chats = chatSnapshot.data?.docs ?? [];
            final Map<String, String> doctorStatus = {};
            for (var doc in chats) {
               final data = doc.data() as Map<String, dynamic>;
               final dId = data['doctorId'] as String;
               final status = data['status'] as String? ?? 'accepted'; // old chats might not have status
               doctorStatus[dId] = status;
            }

            return SliverPadding(
              padding: EdgeInsets.fromLTRB(20.w, 14.h, 20.w, 100.h),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final doctor = filteredDoctors[index];
                    final status = doctorStatus[doctor['id']];
                    return _DoctorCard(
                      doctor: doctor,
                      index: index,
                      status: status,
                      onConnect: () => _onConnectPressed(doctor, status),
                    );
                  },
                  childCount: filteredDoctors.length,
                ),
              ),
            );
          }
        );
      },
    );
  }

  // ─── Empty / Error state ───
  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90.r,
              height: 90.r,
              decoration: BoxDecoration(
                color: _kLightTeal,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44.r, color: _kPrimaryTeal),
            ),
            SizedBox(height: 20.h),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  DOCTOR CARD
// ═══════════════════════════════════════════════
class _DoctorCard extends StatefulWidget {
  final Map<String, dynamic> doctor;
  final int index;
  final String? status;
  final VoidCallback onConnect;

  const _DoctorCard({
    required this.doctor,
    required this.index,
    this.status,
    required this.onConnect,
  });

  @override
  State<_DoctorCard> createState() => _DoctorCardState();
}

class _DoctorCardState extends State<_DoctorCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400 + (widget.index * 80)),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.doctor['name'] ?? 'طبيب';
    final specialization =
        widget.doctor['specialization'] ?? 'طبيب عام';
    final hospital = widget.doctor['hospital'];

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          child: AnimatedScale(
            scale: _isPressed ? 0.97 : 1.0,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            child: Container(
              margin: EdgeInsets.only(bottom: 14.h),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18.r),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimaryTeal.withOpacity(_isPressed ? 0.15 : 0.07),
                    blurRadius: _isPressed ? 24 : 16,
                    offset: Offset(0, _isPressed ? 8 : 4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  children: [
                    // Avatar
                    _buildAvatar(name),
                    SizedBox(width: 14.w),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'د. $name',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A1A2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            children: [
                              Icon(Icons.medical_information_outlined,
                                  size: 14.r, color: _kPrimaryTeal),
                              SizedBox(width: 4.w),
                              Flexible(
                                child: Text(
                                  specialization,
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    color: _kPrimaryTeal,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          if (hospital != null &&
                              hospital.toString().isNotEmpty) ...[
                            SizedBox(height: 3.h),
                            Row(
                              children: [
                                Icon(Icons.local_hospital_outlined,
                                    size: 13.r, color: Colors.grey[400]),
                                SizedBox(width: 4.w),
                                Flexible(
                                  child: Text(
                                    hospital.toString(),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[500],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),

                    // Connect button
                    _buildConnectButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String name) {
    return Container(
      width: 56.r,
      height: 56.r,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F6E56),
            Color(0xFF085041),
          ],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: _kPrimaryTeal.withOpacity(0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.person_rounded, size: 28.r, color: Colors.white),
          Positioned(
            bottom: 4.r,
            right: 4.r,
            child: Container(
              padding: EdgeInsets.all(2.r),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Icon(
                Icons.verified_rounded,
                size: 12.r,
                color: _kPrimaryTeal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton() {
    final bool isPending = widget.status == 'pending';
    final bool isAccepted = widget.status == 'accepted';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: widget.onConnect,
        borderRadius: BorderRadius.circular(12.r),
        splashColor: _kPrimaryTeal.withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isPending 
                  ? [Colors.orange[400]!, Colors.orange[600]!]
                  : [_kPrimaryTeal, _kDarkTeal],
            ),
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: isPending ? Colors.orange.withOpacity(0.3) : _kPrimaryTeal.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isPending ? Icons.access_time_rounded : (isAccepted ? Icons.chat_rounded : Icons.person_add_alt_1_rounded),
                size: 15.r, color: Colors.white
              ),
              SizedBox(width: 6.w),
              Text(
                isPending ? 'قيد الانتظار' : (isAccepted ? 'مراسلة' : 'تواصل الآن'),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  CONFIRMATION DIALOG
// ═══════════════════════════════════════════════
class _ConfirmationDialog extends StatelessWidget {
  final String doctorName;
  const _ConfirmationDialog({required this.doctorName});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 30.w),
        child: Container(
          padding: EdgeInsets.all(24.r),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: _kPrimaryTeal.withOpacity(0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 70.r,
                height: 70.r,
                decoration: BoxDecoration(
                  color: _kLightTeal,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_add_rounded,
                  size: 34.r,
                  color: _kPrimaryTeal,
                ),
              ),
              SizedBox(height: 20.h),

              // Title
              Text(
                'تأكيد الارتباط',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
              SizedBox(height: 10.h),

              // Message
              Text(
                'هل تريد الارتباط بالدكتور $doctorName؟',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15.sp,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              SizedBox(height: 28.h),

              // Buttons
              Row(
                children: [
                  // Cancel
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        side: BorderSide(
                          color: Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Confirm
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimaryTeal,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 13.h),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'تأكيد',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
