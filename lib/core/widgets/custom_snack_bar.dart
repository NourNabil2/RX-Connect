import 'dart:ui';

import 'package:flutter/material.dart';

enum SnackBarType { success, error, warning, info }

class CustomSnackBar {
  static void show(
      BuildContext context, {
        required String message,
        SnackBarType type = SnackBarType.success,
        Duration duration = const Duration(seconds: 4),
        String? actionLabel,
        VoidCallback? onActionPressed,
        bool showCloseButton = true,
      }) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackBarWidget(
        message: message,
        type: type,
        duration: duration,
        actionLabel: actionLabel,
        onActionPressed: onActionPressed,
        showCloseButton: showCloseButton,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }
}

class _CustomSnackBarWidget extends StatefulWidget {
  final String message;
  final SnackBarType type;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onActionPressed;
  final bool showCloseButton;
  final VoidCallback onDismiss;

  const _CustomSnackBarWidget({
    required this.message,
    required this.type,
    required this.duration,
    this.actionLabel,
    this.onActionPressed,
    required this.showCloseButton,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackBarWidget> createState() => _CustomSnackBarWidgetState();
}

class _CustomSnackBarWidgetState extends State<_CustomSnackBarWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _progressController;
  late AnimationController _pulseController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _progressAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    _progressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.linear,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _slideController.forward();
    _progressController.forward();
    _pulseController.repeat(reverse: true);

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _progressController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _slideController.reverse();
    widget.onDismiss();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF10B981).withOpacity(0.15);
      case SnackBarType.error:
        return const Color(0xFFEF4444).withOpacity(0.15);
      case SnackBarType.warning:
        return const Color(0xFFF59E0B).withOpacity(0.15);
      case SnackBarType.info:
        return const Color(0xFF3B82F6).withOpacity(0.15);
    }
  }

  Color _getAccentColor() {
    switch (widget.type) {
      case SnackBarType.success:
        return const Color(0xFF10B981);
      case SnackBarType.error:
        return const Color(0xFFEF4444);
      case SnackBarType.warning:
        return const Color(0xFFF59E0B);
      case SnackBarType.info:
        return const Color(0xFF3B82F6);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case SnackBarType.success:
        return Icons.check_circle_rounded;
      case SnackBarType.error:
        return Icons.error_rounded;
      case SnackBarType.warning:
        return Icons.warning_rounded;
      case SnackBarType.info:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: _getAccentColor().withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        _getBackgroundColor(),
                        _getBackgroundColor().withOpacity(0.8),
                      ],
                    ),
                    border: Border.all(
                      color: _getAccentColor().withOpacity(0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      // Animated background pattern
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: RadialGradient(
                                  center: Alignment.topRight,
                                  radius: _pulseAnimation.value,
                                  colors: [
                                    _getAccentColor().withOpacity(0.1),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Progress indicator
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedBuilder(
                          animation: _progressAnimation,
                          builder: (context, child) {
                            return LinearProgressIndicator(
                              value: _progressAnimation.value,
                              backgroundColor: Colors.transparent,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _getAccentColor().withOpacity(0.6),
                              ),
                              minHeight: 3,
                            );
                          },
                        ),
                      ),

                      // Main content
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            // Animated icon
                            AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _getAccentColor().withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getIcon(),
                                      color: _getAccentColor(),
                                      size: 24,
                                    ),
                                  ),
                                );
                              },
                            ),

                            const SizedBox(width: 16),

                            // Message
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  height: 1.4,
                                ),
                              ),
                            ),

                            // Action button
                            if (widget.actionLabel != null) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: widget.onActionPressed,
                                style: TextButton.styleFrom(
                                  backgroundColor: _getAccentColor().withOpacity(0.2),
                                  foregroundColor: _getAccentColor(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  widget.actionLabel!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],

                            // Close button
                            if (widget.showCloseButton) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: _dismiss,
                                icon: const Icon(Icons.close_rounded),
                                iconSize: 20,
                                color: Colors.white70,
                                splashRadius: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension for easy usage
extension CustomSnackBarExtension on BuildContext {
  void showCustomSnackBar({
    required String message,
    SnackBarType type = SnackBarType.success,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
    bool showCloseButton = true,
  }) {
    CustomSnackBar.show(
      this,
      message: message,
      type: type,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
      showCloseButton: showCloseButton,
    );
  }
}