import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CustomAdminToolbar extends StatelessWidget {
  final Widget? searchField;
  final List<Widget>? centerFilters;
  final List<Widget>? trailingActions;
  final double height;
  final EdgeInsets padding;

  const CustomAdminToolbar({
    super.key,
    this.searchField,
    this.centerFilters,
    this.trailingActions,
    this.height = 72,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (searchField != null) 
            Expanded(flex: 3, child: searchField!),
          
          if (centerFilters != null && centerFilters!.isNotEmpty) ...[
            const SizedBox(width: 16),
            ...centerFilters!.map((w) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(width: 200, child: w),
            )),
          ],

          if (trailingActions != null && trailingActions!.isNotEmpty) ...[
            const Spacer(),
            ...trailingActions!.map((w) => Padding(
              padding: const EdgeInsets.only(left: 12),
              child: w,
            )),
          ],
        ],
      ),
    );
  }
}
