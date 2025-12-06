import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';

/// Widget لعرض صورة الدواء
/// يدعم الصور من الإنترنت والملفات المحلية
class MedicationImageWidget extends StatelessWidget {
  final String? imageUrl;
  final Color statusColor;
  final double size;
  final double borderRadius;

  const MedicationImageWidget({
    Key? key,
    required this.imageUrl,
    required this.statusColor,
    this.size = 50,
    this.borderRadius = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // لو مفيش صورة، نرجع الأيقونة الافتراضية
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildFallbackIcon();
    }

    // لو الصورة من النت
    if (imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: CachedNetworkImage(
          imageUrl: imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _buildLoadingPlaceholder(),
          errorWidget: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }

    // لو الصورة من الجهاز
    final file = File(imageUrl!);
    if (file.existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(),
        ),
      );
    }

    // لو الملف مش موجود، نرجع الأيقونة الافتراضية
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Icon(
        Icons.medication,
        color: statusColor,
        size: size * 0.5,
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}