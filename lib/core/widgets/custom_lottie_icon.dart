import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class CustomLottieIcon extends StatefulWidget {
  final String assetPath;
  final double width;
  final double height;
  final BoxFit fit;
  final VoidCallback? onTap;
  final bool repeat;
  final Color? color;

  const CustomLottieIcon({
    Key? key,
    required this.assetPath,
    this.width = 90,
    this.height = 90,
    this.fit = BoxFit.contain,
    this.onTap,
    this.repeat = true,
    this.color,
  }) : super(key: key);

  @override
  CustomLottieIconState createState() => CustomLottieIconState();
}

class CustomLottieIconState extends State<CustomLottieIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  bool get isNetwork => widget.assetPath.startsWith('http');

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void handleTap() {
    if (widget.onTap != null) widget.onTap!();

    controller
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    final lottieWidget = isNetwork
        ? Lottie.network(
      widget.assetPath,
      controller: controller,
      onLoaded: (composition) {
        controller.duration = composition.duration;
      },
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      repeat: widget.repeat,
    )
        : Lottie.asset(
      widget.assetPath,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      delegates: LottieDelegates(
        values: [
          ValueDelegate.color(
            const ['**'], // wildcard to apply to all color keys
            value: widget.color, // your desired color
          ),
        ],
      ),
      repeat: widget.repeat,
    );

    return GestureDetector(
     // onTap: ()=>_handleTap(),
      child: lottieWidget,
    );
  }
}