import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../theme/colors.dart';
import '../utils/app_size.dart';

class FullScreenMediaViewer extends StatelessWidget {
  final String filePath;
  final Color? accentColor;

  const FullScreenMediaViewer({
    super.key,
    required this.filePath,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: Image.file(
                File(filePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.broken_image_rounded,
                          size: 64.sp,
                          color: Colors.white,
                        ),
                        SizedBox(height: SizeApp.s16),
                        Text(
                          'لا يمكن عرض الصورة',
                          style: TextStyle(
                            fontSize: 16.sp,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            right: 16,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Static method لسهولة الاستخدام
  static void show(
      BuildContext context, {
        required String filePath,
        required bool isVideo,
        Color? accentColor,
      }) {
    showDialog(
      context: context,
      barrierColor: Colors.black,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: FullScreenMediaViewer(
          filePath: filePath,
          accentColor: accentColor,
        ),
      ),
    );
  }
}