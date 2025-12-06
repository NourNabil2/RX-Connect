import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';


class CustomLoadingDialog extends StatefulWidget {
  final String loadingText;

  const CustomLoadingDialog({super.key, this.loadingText = 'Loading...'});

  @override
  State<CustomLoadingDialog> createState() => _CustomLoadingDialogState();
}

class _CustomLoadingDialogState extends State<CustomLoadingDialog> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true); // for a pulsating effect

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: isDarkMode
          ? Lottie.asset(
        'assets/lottie/loading white.json',
        repeat: true,
      )
          : Lottie.asset(
        'assets/lottie/loading emtlak.json',
        repeat: true,
      ),
    );
  }

}

/*
Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _scaleAnimation,
              child: SvgPicture.asset(
                AssetsManager.logo,
                width: 64,
                height: 64,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.loadingText,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
 */