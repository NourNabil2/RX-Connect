import 'package:flutter/material.dart';

import 'dart:io';

import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Widget لعرض صورة الدواء
/// يدعم الصور من الإنترنت والملفات المحلية

/// Medication Image Widget
class MedicationImageLibWidget extends StatelessWidget {
  final String? imageUrl;
  final Color color;
  final IconData fallbackIcon;
  final double size;
  final double borderRadius;

  const MedicationImageLibWidget({
    Key? key,
    required this.imageUrl,
    required this.color,
    required this.fallbackIcon,
    this.size = 56,
    this.borderRadius = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.r,
      height: size.r,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius.r),
      ),
      child: imageUrl != null && imageUrl!.isNotEmpty
          ? ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius.r),
        child: _buildImage(),
      )
          : Icon(fallbackIcon, color: color, size: (size * 0.5).r),
    );
  }

  Widget _buildImage() {
    if (imageUrl!.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, url, error) => Icon(
          fallbackIcon,
          color: Colors.grey[400],
        ),
      );
    }

    final file = File(imageUrl!);
    if (file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }

    return Icon(fallbackIcon, color: Colors.grey[400]);
  }
}