import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pharmacist_assistant/core/widgets/Loading_widget.dart';
import 'package:pharmacist_assistant/features/auth/presentaion/cubit/auth_status.dart';
import 'package:pharmacist_assistant/features/home/presentation/cubit/adherence_provider.dart';
import 'package:pharmacist_assistant/core/widgets/card_widgets.dart';
import 'package:provider/provider.dart';
import 'dart:io';

import 'package:shimmer/shimmer.dart';

/// Custom AppBar للصفحة الرئيسية
class HomeAppBarWidget extends StatelessWidget {
  const HomeAppBarWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Theme.of(context).primaryColor,
      expandedHeight: 240.h,
      collapsedHeight: 80.h,
      floating: false,
      pinned: true,
      stretch: true,
      automaticallyImplyLeading: false,
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final isExpanded = constraints.maxHeight > 180.h;

          return Stack(
            children: [
              // الخلفية
              _buildBackground(context),

              // الهيدر العلوي
              _buildTopBar(context, isExpanded, constraints),

              // كارت الالتزام
              if (isExpanded) _buildAdherenceCard(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBackground(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/appbar_bg.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Theme.of(context).primaryColor,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.3),
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(
      BuildContext context,
      bool isExpanded,
      BoxConstraints constraints,
      ) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;

              if (user == null) {
                return const SizedBox.shrink();
              }

              final photoUrl = user.profileImageUrl ?? 'assets/images/default_avatar.png';
              final name = user.name?.split(' ').first ?? 'مستخدم';
              return Row(
                children: [
                  // صورة المستخدم
                  _buildUserAvatar(photoUrl, isExpanded),

                  SizedBox(width: isExpanded ? 12.w : 8.w),

                  // الاسم
                  if (isExpanded || constraints.maxWidth > 100)
                    Expanded(
                      child: Text(
                        'مرحباً, $name',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isExpanded ? 18.sp : 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const Spacer(),

                  // جرس الإشعارات
                  _buildNotificationBell(isExpanded),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildUserAvatar(String? photoUrl, bool isExpanded) {
    return CircleAvatar(
      radius: isExpanded ? 22.r : 16.r,
      backgroundImage:  _getAvatarImage(photoUrl),
      child: photoUrl == null || photoUrl.isEmpty
          ? Icon(
        Icons.person,
        color: Colors.grey[400],
        size: isExpanded ? 24.r : 18.r,
      )
          : null,
    );
  }

  ImageProvider? _getAvatarImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    try {
      if (photoUrl.startsWith('http')) {
        return NetworkImage(photoUrl);
      }

      final file = File(photoUrl);
      if (file.existsSync()) {
        return FileImage(file);
      }
    } catch (e) {
      debugPrint('Error loading avatar: $e');
    }

    return null;
  }

  Widget _buildNotificationBell(bool isExpanded) {
    return Container(
      padding: EdgeInsets.all(isExpanded ? 10.r : 6.r),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Icon(
        Icons.notifications_outlined,
        color: Colors.white,
        size: isExpanded ? 26.r : 20.r,
      ),
    );
  }

  Widget _buildAdherenceCard(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Transform.translate(
        offset: Offset(0, 40.h),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              final user = auth.currentUser;

              if (user == null) {
                return const SizedBox.shrink();
              }

              return Consumer<AdherenceProvider>(
                builder: (context, adherence, _) {
                  return FutureBuilder<Map<String, dynamic>>(
                    future: _calculateAdherenceData(context, user.id),
                    builder: (context, snapshot) {

                      // --- CHANGED HERE ---
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return _buildAdherenceCardShimmer(context);
                      }
                      // --------------------

                      if (snapshot.hasError) {
                        debugPrint('Error calculating adherence: ${snapshot.error}');
                        return _buildErrorCard(); // Make sure you have an error card or SizedBox
                      }

                      final data = snapshot.data ?? {'rate': 0.0, 'streak': 0};

                      return buildAdherenceCard(
                        context,
                        percentage: data['rate'] as double,
                        streak: data['streak'] as int,
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAdherenceCardShimmer(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 1. Setup Shimmer Colors based on Theme
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    // 2. Return the Card Structure
    return Container(
      padding: EdgeInsets.all(14.r),
      decoration: BoxDecoration(
        color: theme.cardColor, // The physical card background
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // 3. Wrap internal content in Shimmer
      child: Shimmer.fromColors(
        baseColor: baseColor,
        highlightColor: highlightColor,
        child: Row(
          children: [
            // Circle Skeleton (Matches 60.r size)
            Container(
              width: 60.r,
              height: 60.r,
              decoration: const BoxDecoration(
                color: Colors.white, // Color needed for Shimmer mask
                shape: BoxShape.circle,
              ),
            ),

            SizedBox(width: 12.w),

            // Text Skeletons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Important for alignment
                children: [
                  // Title Line
                  Container(
                    width: 120.w,
                    height: 14.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  // Streak/Subtitle Line
                  Container(
                    width: 60.w,
                    height: 12.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, dynamic>> _calculateAdherenceData(
      BuildContext context,
      String userId,
      ) async {
    try {
      final adherence = Provider.of<AdherenceProvider>(context, listen: false);

      // حساب نسبة الالتزام لآخر 7 أيام
      final rate = await adherence.calculateAdherenceRate(userId, days: 7);

      // حساب الـ streak
      final streak = await adherence.calculateStreak(userId);

      return {
        'rate': rate,
        'streak': streak,
      };
    } catch (e) {
      debugPrint('Error in _calculateAdherenceData: $e');
      return {'rate': 0.0, 'streak': 0};
    }
  }

  Widget _buildErrorCard() {
    return Container(
      height: 120.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32.r),
            SizedBox(height: 8.h),
            Text(
              'تعذر تحميل البيانات',
              style: TextStyle(color: Colors.grey[600], fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}