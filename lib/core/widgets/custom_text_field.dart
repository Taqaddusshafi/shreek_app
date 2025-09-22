// In your custom_text_field.dart
import 'package:flutter/material.dart';
import 'package:shreek_app/core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool obscureText;
  final bool enabled;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final VoidCallback? onSuffixIconTap;
  final VoidCallback? onTap;
  final int? maxLines;
  final int? maxLength; // ✅ FIXED: Added maxLength parameter
  final TextStyle? style; // ✅ FIXED: Added style parameter

  const CustomTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType,
    this.validator,
    this.onSuffixIconTap,
    this.onTap,
    this.maxLines = 1,
    this.maxLength, // ✅ FIXED: Added to constructor
    this.style, // ✅ FIXED: Added to constructor
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: widget.obscureText,
      enabled: widget.enabled,
      keyboardType: widget.keyboardType,
      validator: widget.validator,
      onTap: widget.onTap,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength, // ✅ FIXED: Use maxLength
      style: widget.style, // ✅ FIXED: Use style
      decoration: InputDecoration(
        labelText: widget.labelText,
        hintText: widget.hintText,
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon)
            : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                onPressed: widget.onSuffixIconTap,
                icon: Icon(widget.suffixIcon),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primaryColor,
            width: 2,
          ),
        ),
      ),
    );
  }
}
