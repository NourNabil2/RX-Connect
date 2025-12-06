import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../utils/app_size.dart';


class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final Color activeColor;
  final Color backgroundColor;
  final double size;
  final TextStyle? labelStyle;
  final bool isCheckboxLeft;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.activeColor = ColorsManager.secondaryColor,
    this.backgroundColor = Colors.transparent,
    this.size = 20.0,
    this.labelStyle,
    this.isCheckboxLeft = false,
  });

  void _toggleCheckbox() {
    onChanged(!value);
  }

  @override
  Widget build(BuildContext context) {
    final checkbox = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: value ? activeColor : backgroundColor,
        shape: BoxShape.circle,
        border: !value
            ? Border.all(
          color: Theme.of(context).primaryColorDark,
          width: 1,
        )
            : null,
      ),
      child: value
          ? Icon(
        Icons.check,
        size: size * 0.6,
        color: Colors.white,
      )
          : null,
    );

    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: labelStyle ?? Theme.of(context).textTheme.bodyMedium,
    );

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: SizeApp.padding,
        horizontal: SizeApp.padding * 2,
      ),
      child: InkWell(
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        onTap: _toggleCheckbox,
        borderRadius: BorderRadius.circular(size),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: isCheckboxLeft ? MainAxisAlignment.start : MainAxisAlignment.spaceBetween,
          children: isCheckboxLeft
              ? [checkbox, const SizedBox(width: 8), text]
              : [text, const SizedBox(width: 8), checkbox],
        ),
      ),
    );
  }
}

