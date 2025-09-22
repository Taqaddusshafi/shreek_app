import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import '../constants/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final IconData? icon;
  // ✅ REMOVED: The erroneous 'required style' parameter

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 50,
    this.icon,
    // ✅ FIXED: Removed the problematic 'required style' parameter
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primaryColor,
          foregroundColor: textColor ?? Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          // ✅ ENHANCED: Added more styling options
          shadowColor: Colors.transparent,
          disabledBackgroundColor: (backgroundColor ?? AppColors.primaryColor).withOpacity(0.6),
          disabledForegroundColor: (textColor ?? Colors.white).withOpacity(0.6),
        ),
        child: isLoading
            ? SpinKitThreeBounce(
                color: textColor ?? Colors.white,
                size: 20,
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20, // ✅ FIXED: Added explicit icon size
                    ),
                    const SizedBox(width: 8),
                  ],
                  Flexible( // ✅ ENHANCED: Added Flexible to prevent overflow
                    child: Text(
                      text,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor ?? Colors.white, // ✅ FIXED: Explicit color
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
