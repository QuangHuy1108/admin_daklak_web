import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class CustomAdminTable extends StatelessWidget {
  final List<int> flex;
  final List<String> labels;
  final int itemCount;
  final List<Widget> Function(BuildContext, int) rowBuilder;
  final VoidCallback? onRowTap;
  final Function(int)? onRowTapWithIndex;
  final Widget? emptyWidget;

  const CustomAdminTable({
    super.key,
    required this.flex,
    required this.labels,
    required this.itemCount,
    required this.rowBuilder,
    this.onRowTap,
    this.onRowTapWithIndex,
    this.emptyWidget,
  }) : assert(flex.length == labels.length);

  @override
  Widget build(BuildContext context) {
    if (itemCount == 0) return emptyWidget ?? const _DefaultEmptyState();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final glassColor = isDark ? const Color(0xCC1E2538) : Colors.white.withValues(alpha: 0.75);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.6);

    return Column(
      children: [
        // Header Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: glassColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            children: List.generate(labels.length, (index) {
              return Expanded(
                flex: flex[index],
                child: Text(
                  labels[index].toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            }),
          ),
        ),
        // Data Rows
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: glassColor,
              border: Border(
                left: BorderSide(color: borderColor, width: 1.5),
                right: BorderSide(color: borderColor, width: 1.5),
                bottom: BorderSide(color: borderColor, width: 1.5),
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: ListView.separated(
              itemCount: itemCount,
              separatorBuilder: (context, index) => const Divider(height: 1, color: AppColors.background),
              itemBuilder: (context, index) {
                final cells = rowBuilder(context, index);
                
                return _AdminTableRow(
                  cells: cells,
                  flex: flex,
                  onTap: () {
                    if (onRowTapWithIndex != null) onRowTapWithIndex!(index);
                    if (onRowTap != null) onRowTap!();
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _AdminTableRow extends StatefulWidget {
  final List<Widget> cells;
  final List<int> flex;
  final VoidCallback onTap;

  const _AdminTableRow({
    required this.cells,
    required this.flex,
    required this.onTap,
  });

  @override
  State<_AdminTableRow> createState() => _AdminTableRowState();
}

class _AdminTableRowState extends State<_AdminTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: _isHovered ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
          child: Row(
            children: List.generate(widget.cells.length, (index) {
              return Expanded(
                flex: widget.flex[index],
                child: widget.cells[index],
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DefaultEmptyState extends StatelessWidget {
  const _DefaultEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('Không có dữ liệu hiển thị', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
