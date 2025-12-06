// lib/core/utils/date_extensions.dart
import 'package:flutter/material.dart';

/// Arabic plural rules (simplified for UI)
String _arPlural(int n, String one, String two, String few, String many) {
  if (n == 1) return one;
  if (n == 2) return two;
  if (n >= 3 && n <= 10) return '$n $few';
  return '$n $many';
}

extension DateTimeX on DateTime {
  String timeAgo({String locale = 'ar', DateTime? now}) {
    final _now = now ?? DateTime.now();
    Duration diff = _now.difference(this);
    final isFuture = diff.isNegative;
    if (isFuture) diff = diff.abs();

    if (diff.inSeconds < 45) {
      return locale.startsWith('ar') ? 'الآن' : 'just now';
    }

    String arPhrase(int n, String one, String two, String few, String many) {
      final core = _arPlural(n, one, two, few, many);
      return isFuture ? 'بعد $core' : 'قبل $core';
    }

    if (diff.inMinutes < 1) {
      final s = diff.inSeconds;
      return locale.startsWith('ar')
          ? arPhrase(s, 'ثانية', 'ثانيتين', 'ثوانٍ', 'ثانية')
          : isFuture ? 'in ${s}s' : '${s}s ago';
    }

    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return locale.startsWith('ar')
          ? arPhrase(m, 'دقيقة', 'دقيقتين', 'دقائق', 'دقيقة')
          : isFuture ? 'in ${m}m' : '${m}m ago';
    }

    if (diff.inHours < 24) {
      final h = diff.inHours;
      return locale.startsWith('ar')
          ? arPhrase(h, 'ساعة', 'ساعتين', 'ساعات', 'ساعة')
          : isFuture ? 'in ${h}h' : '${h}h ago';
    }

    if (diff.inDays < 7) {
      final d = diff.inDays;
      return locale.startsWith('ar')
          ? arPhrase(d, 'يوم', 'يومين', 'أيام', 'يوم')
          : isFuture ? 'in ${d}d' : '${d}d ago';
    }

    if (diff.inDays < 30) {
      final w = (diff.inDays / 7).floor();
      return locale.startsWith('ar')
          ? arPhrase(w, 'أسبوع', 'أسبوعين', 'أسابيع', 'أسبوع')
          : isFuture ? 'in ${w}w' : '${w}w ago';
    }

    if (diff.inDays < 365) {
      final mo = (diff.inDays / 30).floor();
      return locale.startsWith('ar')
          ? arPhrase(mo, 'شهر', 'شهرين', 'أشهر', 'شهر')
          : isFuture ? 'in ${mo}mo' : '${mo}mo ago';
    }

    final y = (diff.inDays / 365).floor();
    return locale.startsWith('ar')
        ? arPhrase(y, 'سنة', 'سنتين', 'سنوات', 'سنة')
        : isFuture ? 'in ${y}y' : '${y}y ago';
  }

  String timeAgoCtx(BuildContext context, {DateTime? now}) {
    final locale = Localizations.localeOf(context).languageCode;
    return timeAgo(locale: locale, now: now);
  }

  String yMd([String sep = '-']) =>
      '${year.toString().padLeft(4, '0')}$sep${month.toString().padLeft(2, '0')}$sep${day.toString().padLeft(2, '0')}';

  String dMy([String sep = '/']) =>
      '${day.toString().padLeft(2, '0')}$sep${month.toString().padLeft(2, '0')}$sep${year.toString().padLeft(4, '0')}';

  String hhmm() => '${_two(hour)}:${_two(minute)}';

  DateTime get startOfDay => DateTime(year, month, day);
  DateTime get endOfDay => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
  bool get isToday => isSameDay(DateTime.now());
  bool get isYesterday => isSameDay(DateTime.now().subtract(const Duration(days: 1)));
  bool get isTomorrow => isSameDay(DateTime.now().add(const Duration(days: 1)));

  int daysSince([DateTime? from]) => (from ?? DateTime.now()).difference(this).inDays;
  int daysUntil([DateTime? to]) => difference(to ?? DateTime.now()).inDays;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// Extension for Medication Frequency Styling
extension MedicationFrequencyExtension on String {
  /// Get icon and color for frequency type
  (IconData, Color) getFrequencyStyle() {
    return switch (this) {
      'daily' => (Icons.medication, const Color(0xFF1E88E5)),
      'alternate_days' => (Icons.calendar_today, const Color(0xFFFF9800)),
      'weekly' => (Icons.event_repeat, const Color(0xFF4CAF50)),
      'as_needed' => (Icons.medication_liquid, const Color(0xFF9C27B0)),
      _ => (Icons.medication, const Color(0xFF607D8B)),
    };
  }

  /// Get group styling (icon, color, label)
  (IconData, Color, String) getGroupStyle() {
    return switch (this) {
      'daily' => (Icons.calendar_today, const Color(0xFF1E88E5), 'الأدوية اليومية'),
      'alternate_days' => (Icons.event_repeat, const Color(0xFFFF9800), 'أيام متبادلة'),
      'weekly' => (Icons.calendar_month, const Color(0xFF4CAF50), 'الأدوية الأسبوعية'),
      'as_needed' => (Icons.notifications_active, const Color(0xFF9C27B0), 'عند الحاجة'),
      _ => (Icons.medication, const Color(0xFF607D8B), 'أخرى'),
    };
  }

  /// Get localized frequency label
  String getFrequencyLabel() {
    return switch (this) {
      'daily' => 'يومي',
      'alternate_days' => 'أيام متبادلة',
      'weekly' => 'أسبوعي',
      'as_needed' => 'عند الحاجة',
      _ => 'غير محدد',
    };
  }
}

/// Medication Filter Types
enum MedicationFilter {
  all('all', 'الكل', Icons.grid_view_rounded),
  daily('daily', 'يومي', Icons.calendar_today),
  alternateDays('alternate_days', 'أيام متبادلة', Icons.event_repeat),
  weekly('weekly', 'أسبوعي', Icons.calendar_month),
  asNeeded('as_needed', 'عند الحاجة', Icons.notifications_active);

  final String value;
  final String label;
  final IconData icon;

  const MedicationFilter(this.value, this.label, this.icon);

  static MedicationFilter fromValue(String value) {
    return MedicationFilter.values.firstWhere(
          (e) => e.value == value,
      orElse: () => MedicationFilter.all,
    );
  }
}