import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:admin_daklak_web/features/order_management/widgets/orders_table_widget.dart';

const Color _bgGray = Color(0xFFF5F7FA);
const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);

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
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: _primaryGreen,
              onPrimary: Colors.white,
              onSurface: _textPrimary,
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
    String dateRangeLabel = 'Filter by DateRange';
    if (_selectedDateRange != null) {
      final s = _selectedDateRange!.start;
      final e = _selectedDateRange!.end;
      dateRangeLabel = '${s.day}/${s.month}/${s.year} - ${e.day}/${e.month}/${e.year}';
    }

    return Scaffold(
      backgroundColor: _bgGray,
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
                      icon: const Icon(Icons.arrow_back, color: _textPrimary),
                      onPressed: () => context.pop(),
                      tooltip: 'Back to Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Management',
                      style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitor all orders, view details, and export data to CSV.',
                      style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
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
                         label: Text('Clear Date', style: GoogleFonts.inter(color: Colors.red)),
                      ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: _pickDateRange,
                      icon: const Icon(Icons.date_range, color: _textPrimary, size: 20),
                      label: Text(dateRangeLabel, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textPrimary)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () => _tableKey.currentState?.exportToCSV(),
                      icon: const Icon(Icons.file_download, color: Colors.white, size: 20),
                      label: Text('Export CSV', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryGreen,
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
