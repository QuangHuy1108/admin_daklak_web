import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/finance_provider.dart';
import '../models/expense_model.dart';
import '../../logs/services/audit_service.dart';
import '../../logs/models/audit_log_model.dart';

const Color _bgGray = Color(0xFFF5F7FA);
const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _warningRed = Color(0xFFD32F2F);
const Color _infoBlue = Color(0xFF1976D2);

class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final financeProvider = context.watch<FinanceProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    if (financeProvider.isLoading) {
      return const Scaffold(
        backgroundColor: _bgGray,
        body: Center(child: CircularProgressIndicator(color: _primaryGreen)),
      );
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
                      tooltip: 'Quay lại',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sổ Cái Tài Chính & Đối Soát',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tổng quan về dòng tiền, chi phí vận hành và lợi nhuận thực tế.',
                          style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showAddExpenseDialog(context),
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: Text('Ghi nhận chi phí', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // KPI Row
            Row(
              children: [
                Expanded(child: _buildKPICard('Tổng Doanh Thu', financeProvider.totalGrossRevenue, _primaryGreen, Icons.account_balance_wallet, currencyFormat)),
                const SizedBox(width: 24),
                Expanded(child: _buildKPICard('Tổng Chi Phí Thực Tế', financeProvider.totalExpenses, _warningRed, Icons.payments, currencyFormat)),
                const SizedBox(width: 24),
                Expanded(child: _buildKPICard('Lợi Nhuận Ròng', financeProvider.netProfit, _infoBlue, Icons.trending_up, currencyFormat, isNet: true)),
              ],
            ),
            const SizedBox(height: 32),

            // Charts
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Phân Tích Dòng Tiền Thật', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 350,
                          child: _buildRevenueChart(financeProvider),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 32),
                Expanded(
                  flex: 1,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10)]),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Cơ Cấu Chi Phí', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 350,
                          child: _buildExpensePieChart(financeProvider),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Expense Ledger
            _buildExpenseTable(context, financeProvider, currencyFormat),
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, double value, Color iconColor, IconData icon, NumberFormat formatter, {bool isNet = false}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
         color: isNet ? _textPrimary : Colors.white,
         borderRadius: BorderRadius.circular(16),
         boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Row(
               children: [
                  Container(
                     padding: const EdgeInsets.all(8),
                     decoration: BoxDecoration(color: isNet ? Colors.white.withOpacity(0.1) : iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                     child: Icon(icon, color: isNet ? Colors.white : iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: GoogleFonts.inter(color: isNet ? Colors.white70 : _textSecondary, fontWeight: FontWeight.w500)),
               ]
            ),
            const SizedBox(height: 16),
            Text(formatter.format(value), style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: isNet ? Colors.white : _textPrimary)),
         ]
      )
    );
  }

  Widget _buildRevenueChart(FinanceProvider provider) {
    if (provider.totalGrossRevenue == 0 && provider.totalExpenses == 0) {
      return const Center(child: Text('Chưa có dữ liệu giao dịch.'));
    }

    // Dynamic scaling for both positive and negative values
    final double maxVal = math.max(provider.totalGrossRevenue, provider.totalExpenses);
    final double minVal = math.min(0.0, provider.netProfit);

    // Calculate a balanced range to keep 0 reasonably centered if there are negative values
    final double padding = 1.4;
    final double chartMaxY = maxVal == 0 ? 1000 : maxVal * padding;
    final double chartMinY = minVal == 0 ? 0 : minVal * padding;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMaxY,
        minY: chartMinY,
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => Colors.transparent, 
            tooltipMargin: 8,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                NumberFormat.currency(locale: 'vi_VN', symbol: 'đ', decimalDigits: 0).format(rod.toY),
                GoogleFonts.inter(
                  color: _textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 42, // Ensure enough space for labels + padding
              getTitlesWidget: (double value, TitleMeta meta) {
                const style = TextStyle(color: _textSecondary, fontWeight: FontWeight.bold, fontSize: 13);
                switch (value.toInt()) {
                  case 0: return SideTitleWidget(meta: meta, space: 12, child: const Text('Doanh Thu', style: style));
                  case 1: return SideTitleWidget(meta: meta, space: 12, child: const Text('Chi Phí', style: style));
                  case 2: return SideTitleWidget(meta: meta, space: 12, child: const Text('Lợi Nhuận', style: style));
                  default: return const Text('');
                }
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxVal > 0 ? maxVal / 5 : 1000,
          getDrawingHorizontalLine: (value) {
            if (value == 0) {
              return const FlLine(color: _textSecondary, strokeWidth: 1); // Baseline at 0
            }
            return const FlLine(color: _borderColor, strokeWidth: 0.5, dashArray: [5, 5]);
          },
        ),
        borderData: FlBorderData(show: false),
        barGroups: [
          BarChartGroupData(x: 0, barRods: [
            BarChartRodData(
              fromY: 0,
              toY: provider.totalGrossRevenue, 
              color: _primaryGreen, 
              width: 60, 
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            )
          ]),
          BarChartGroupData(x: 1, barRods: [
            BarChartRodData(
              fromY: 0,
              toY: provider.totalExpenses, 
              color: _warningRed, 
              width: 60, 
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8)),
            )
          ]),
          BarChartGroupData(x: 2, barRods: [
            BarChartRodData(
              fromY: 0,
              toY: provider.netProfit, 
              color: _infoBlue, 
              width: 60, 
              borderRadius: provider.netProfit >= 0 
                  ? const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
                  : const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8)),
            )
          ]),
        ],
      ),
    );
  }

  Widget _buildExpensePieChart(FinanceProvider provider) {
    final Map<String, double> categories = {};
    for (var exp in provider.expenses) {
      categories[exp.category] = (categories[exp.category] ?? 0) + exp.amount;
    }

    if (categories.isEmpty) return const Center(child: Text('Chưa có chi phí ghi nhận.'));

    final colors = [Colors.blue, Colors.orange, Colors.purple, Colors.teal, Colors.red];

    return PieChart(
      PieChartData(
        sections: categories.entries.map((e) {
          final index = categories.keys.toList().indexOf(e.key) % colors.length;
          return PieChartSectionData(
            value: e.value,
            title: e.key,
            color: colors[index],
            radius: 100,
            titleStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildExpenseTable(BuildContext context, FinanceProvider provider, NumberFormat formatter) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10)]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nhật Ký Chi Phí Thực Tế', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                Text('${provider.expenses.length} bản ghi', style: GoogleFonts.inter(color: _textSecondary)),
              ],
            ),
          ),
          const Divider(height: 1),
          if (provider.expenses.isEmpty)
            const Padding(padding: EdgeInsets.all(48), child: Center(child: Text('Chưa có ghi nhận chi phí nào.')))
          else
            DataTable(
              headingRowColor: WidgetStateProperty.all(_bgGray),
              columns: const [
                DataColumn(label: Text('Ngày')),
                DataColumn(label: Text('Danh mục')),
                DataColumn(label: Text('Mô tả')),
                DataColumn(label: Text('Số tiền')),
                DataColumn(label: Text('Thao tác')),
              ],
              rows: provider.expenses.map((expense) {
                return DataRow(cells: [
                  DataCell(Text(DateFormat('dd/MM/yyyy').format(expense.date))),
                  DataCell(Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: _infoBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Text(expense.category, style: const TextStyle(color: _infoBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                  )),
                  DataCell(Text(expense.description)),
                  DataCell(Text(formatter.format(expense.amount), style: const TextStyle(fontWeight: FontWeight.bold, color: _warningRed))),
                  DataCell(IconButton(
                    icon: const Icon(Icons.delete_outline, color: _warningRed),
                    onPressed: () => provider.deleteExpense(expense.id),
                  )),
                ]);
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _showAddExpenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddExpenseDialog(),
    );
  }
}

class _AddExpenseDialog extends StatefulWidget {
  const _AddExpenseDialog();

  @override
  State<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<_AddExpenseDialog> {
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  String _selectedCategory = 'Vận chuyển';
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  Future<void> _handleSave() async {
    final amountText = _amountController.text.replaceAll(RegExp(r'[^0-9]'), '');
    final amount = double.tryParse(amountText) ?? 0;
    
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền hợp lệ (> 0 đ)'), backgroundColor: _warningRed),
      );
      return;
    }

    setState(() => _isSaving = true);
    
    try {
      final expense = ExpenseModel(
        id: '',
        amount: amount,
        category: _selectedCategory,
        date: _selectedDate,
        description: _descController.text.trim(),
      );

      await context.read<FinanceProvider>().addExpense(expense);
      
      // Log Action for Security Audit
      await AuditService.logAction(
        type: AuditActionType.create,
        module: AuditModule.finance,
        description: "Ghi nhận chi phí mới: ${expense.category} - ${NumberFormat('#,###').format(expense.amount)} đ",
        details: {
          'category': expense.category,
          'amount': expense.amount,
          'description': expense.description,
          'date': expense.date.toIso8601String(),
        },
      );
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu ghi nhận chi phí thành công'), backgroundColor: _primaryGreen),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Lỗi hệ thống'),
            content: Text('Không thể lưu dữ liệu: $e.\nVui lòng kiểm tra kết nối mạng hoặc quyền truy cập Firestore.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng')),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Vận chuyển', 'Chuyên gia', 'Kho bãi', 'Marketing', 'Khác'];

    return AlertDialog(
      title: Text('Ghi nhận chi phí mới', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Số tiền (đ)', 
                border: OutlineInputBorder(),
                hintText: 'Ví dụ: 500000',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: _isSaving ? null : (val) => setState(() => _selectedCategory = val!),
              decoration: const InputDecoration(labelText: 'Danh mục', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _isSaving ? null : () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _selectedDate = date);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'Ngày chi', border: OutlineInputBorder()),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                    const Icon(Icons.calendar_today, size: 18, color: _textSecondary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              maxLines: 2,
              enabled: !_isSaving,
              decoration: const InputDecoration(labelText: 'Mô tả / Ghi chú', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context), 
          child: const Text('Hủy', style: TextStyle(color: _textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryGreen,
            minimumSize: const Size(120, 45),
          ),
          child: _isSaving 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Text('Lưu ghi nhận', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
