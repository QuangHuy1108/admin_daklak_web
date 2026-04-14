import 'package:flutter/material.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_daklak_web/features/order_management/widgets/orders_table_widget.dart';



class OrderListScreen extends StatefulWidget {
  const OrderListScreen({Key? key}) : super(key: key);

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  final GlobalKey<OrdersTableWidgetState> _tableKey = GlobalKey<OrdersTableWidgetState>();
  DateTimeRange? _selectedDateRange;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final newRange = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (newRange != null) {
      setState(() {
        _selectedDateRange = DateTimeRange(
          start: DateTime(newRange.start.year, newRange.start.month, newRange.start.day),
          end: DateTime(newRange.end.year, newRange.end.month, newRange.end.day, 23, 59, 59),
        );
      });
    }
  }

  void _clearDateRange() {
      setState(() {
         _selectedDateRange = null;
      });
  }

  @override
  Widget build(BuildContext context) {
    String dateRangeLabel = 'Lọc theo ngày';
    if (_selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      dateRangeLabel = '${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}';
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                      onPressed: () => context.pop(),
                      tooltip: 'Quay lại Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quản lý Đơn hàng',
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold, 
                            color: Theme.of(context).colorScheme.onSurface
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Theo dõi tất cả đơn hàng, xem chi tiết và xuất dữ liệu CSV.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (_selectedDateRange != null)
                      TextButton.icon(
                         onPressed: _clearDateRange,
                         icon: const Icon(Icons.clear, color: Colors.red, size: 18),
                         label: Text('Xóa ngày', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.red)),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: Icon(Icons.date_range, color: Theme.of(context).colorScheme.onSurface, size: 20),
                      label: Text(dateRangeLabel, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _tableKey.currentState?.exportToCSV(),
                      icon: const Icon(Icons.file_download, color: Colors.white, size: 20),
                      label: Text('Xuất CSV', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Standard Table Injection 
            OrdersTableWidget(
               key: _tableKey,
               dateRange: _selectedDateRange,
               isDashboard: false,
            ),
          ],
        ),
      ),
    );
  }
}
