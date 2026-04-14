import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CustomAdminInput extends StatelessWidget {
  final String label;
  final String? hintText;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final Color? fillColor;
  final bool hasBorder;

  const CustomAdminInput({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.onChanged,
    this.helperText,
    this.fillColor,
    this.hasBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontSize: 13, // Giữ kích thước nhỏ gọn cho nhãn input
            color: AppColors.textHeading,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          style: Theme.of(context).textTheme.bodyMedium,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textMuted,
            ),
            helperText: helperText,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 18, color: AppColors.textMuted) : null,
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: fillColor ?? AppColors.surfaceVariant.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasBorder ? const BorderSide(color: AppColors.border) : BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: hasBorder ? const BorderSide(color: AppColors.border) : BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
          ),
        ),
      ],
    );
  }
}
