import 'package:flutter/material.dart';

/// Widget لعرض حالة فارغة (Empty State)
/// يمكن استخدامه في أي مكان في التطبيق
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double iconSize;
  final VoidCallback? onActionPressed;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.iconSize = 80,
    this.onActionPressed,
    this.actionLabel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          if (onActionPressed != null && actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onActionPressed,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}