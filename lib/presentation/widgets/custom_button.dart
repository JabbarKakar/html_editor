
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double textSize;
  final bool isLoading;
  final double borderWidth;
  final bool hasShadow;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.color = Colors.blue,
    this.textColor = Colors.white,
    this.borderColor = Colors.transparent,
    this.borderRadius = 14.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
    this.textSize = 16.0,
    this.isLoading = false,
    this.borderWidth = 2.0,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPressed, // Disable onPressed if loading
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: hasShadow
              ? [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              offset: Offset(0, 4),
              blurRadius: 6.0,
            ),
          ]
              : [], // No shadow if hasShadow is false
          border: Border.all(
            color: borderColor, // Border color
            width: borderWidth, // Border width
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator()
            : Text(
          text,
          style: TextStyle(
            color: textColor,
            fontFamily: 'Inter',
            fontSize: textSize,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
