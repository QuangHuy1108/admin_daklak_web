import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';

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
                          'Financial Ledger & Reconciliation',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Read-only overview of completed cash flows and operating costs.',
                          style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Financial Data Engine
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('orders').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text("Data Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)));
                }

                final docs = snapshot.data?.docs ?? [];
                
                // Analytics Computation
                double totalGross = 0;
                
                // For drawing the chart (Daily Revenue)
                Map<int, double> dailyGross = {};

                for (var doc in docs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['status'] ?? '';
                  final amount = (data['totalAmount'] ?? 0) is num ? (data['totalAmount'] as num).toDouble() : double.tryParse((data['totalAmount']).toString()) ?? 0;
                  
                  if (status == 'Completed') {
                     totalGross += amount;
                     
                     // Aggregate day for simple chart
                     if (data['createdAt'] != null) {
                        final date = (data['createdAt'] as Timestamp).toDate();
                        final val = dailyGross[date.day] ?? 0;
                        dailyGross[date.day] = val + amount;
                     }
                  }
                }

                // Core Cost Modeling
                final double operatingCosts = totalGross * 0.40;
                final double netProfit = totalGross - operatingCosts;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI Row
                    Row(
                      children: [
                        Expanded(child: _buildKPICard('Gross Revenue', totalGross, _primaryGreen, Icons.account_balance_wallet)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildKPICard('Operating Costs (40%)', operatingCosts, _infoBlue, Icons.local_shipping)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildKPICard('Net Profit', netProfit, _warningRed, Icons.trending_up, isNet: true)),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // Gross Vs Net Profit Chart
                    Container(
                       padding: const EdgeInsets.all(24),
                       decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                       child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                             Text('Cash Flow Trajectory (Daily completed pulses)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: _textPrimary)),
                             const SizedBox(height: 24),
                             SizedBox(
                               height: 300,
                               child: _buildRevenueChart(dailyGross),
                             )
                          ]
                       )
                    ),
                    const SizedBox(height: 32),

                    // Strict Read Only Ledger
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                           Padding(
                             padding: const EdgeInsets.all(24.0),
                             child: Text('Raw Transaction Ledger', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                           ),
                           const Divider(height: 1, color: _borderColor),
                           if (docs.isEmpty) 
                             const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No transactions recorded.")))
                           else
                             SingleChildScrollView(
                               scrollDirection: Axis.horizontal,
                               child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(_bgGray),
                                  columns: [
                                     _buildDataColumn('Transaction Date'),
                                     _buildDataColumn('Order ID'),
                                     _buildDataColumn('Customer Name'),
                                     _buildDataColumn('Total Amount'),
                                     _buildDataColumn('Calculated Net'),
                                     _buildDataColumn('Audit Status'),
                                  ],
                                  rows: docs.map((doc) {
                                     final data = doc.data() as Map<String, dynamic>;
                                     final String name = data['customerName'] ?? 'No Name';
                                     final String status = data['status'] ?? 'Pending';
                                     final double amount = (data['totalAmount'] ?? 0) is num ? (data['totalAmount'] as num).toDouble() : double.tryParse((data['totalAmount']).toString()) ?? 0;
                                     final DateTime? date = data['createdAt'] != null ? (data['createdAt'] as Timestamp).toDate() : null;
                                     final String dateString = date != null ? "${date.day}/${date.month}/${date.year}" : "";

                                     final isCompleted = status == 'Completed';
                                     final isFailed = status == 'Cancelled' || status == 'Failed';
                                     
                                     // Math for the row
                                     final double rowNet = isCompleted ? (amount * 0.60) : 0;

                                     return DataRow(
                                        cells: [
                                          DataCell(Text(dateString, style: GoogleFonts.inter(color: _textSecondary))),
                                          DataCell(Text(doc.id.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textSecondary, fontSize: 13))),
                                          DataCell(Text(name, style: GoogleFonts.inter())),
                                          DataCell(Text(isFailed ? '0 đ' : '${amount.toStringAsFixed(0)} đ', style: GoogleFonts.inter(decoration: isFailed ? TextDecoration.lineThrough : null, color: isFailed ? _textSecondary : _textPrimary))),
                                          DataCell(Text(rowNet > 0 ? '+${rowNet.toStringAsFixed(0)} đ' : '0 đ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: rowNet > 0 ? _primaryGreen : _textSecondary))),
                                          DataCell(
                                             Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: isFailed ? _warningRed.withOpacity(0.1) : (isCompleted ? _primaryGreen.withOpacity(0.1) : _bgGray), borderRadius: BorderRadius.circular(12)),
                                                child: Text(isFailed ? 'Loss/Risk' : (isCompleted ? 'Recognized' : 'Pending Audit'), style: GoogleFonts.inter(color: isFailed ? _warningRed : (isCompleted ? _primaryGreen : _textSecondary), fontWeight: FontWeight.w600, fontSize: 12)),
                                             )
                                          ),
                                        ]
                                     );
                                  }).toList()
                               ),
                             )
                        ]
                      )
                    )
                  ]
                );
              }
            )
          ],
        ),
      ),
    );
  }

  Widget _buildKPICard(String title, double value, Color iconColor, IconData icon, {bool isNet = false}) {
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
            Text('${value.toStringAsFixed(0)} đ', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: isNet ? Colors.white : _textPrimary)),
         ]
      )
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13)),
    );
  }

  Widget _buildRevenueChart(Map<int, double> dailyGross) {
    if (dailyGross.isEmpty) {
       return const Center(child: Text("Not enough complete data for charting."));
    }

    final sortedKeys = dailyGross.keys.toList()..sort();
    
    final List<FlSpot> grossSpots = [];
    final List<FlSpot> netSpots = [];
    
    double maxVal = 1000;
    
    for (int i = 0; i < sortedKeys.length; i++) {
        final double gross = dailyGross[sortedKeys[i]]!;
        if (gross > maxVal) maxVal = gross;
        
        grossSpots.add(FlSpot(i.toDouble(), gross));
        netSpots.add(FlSpot(i.toDouble(), gross * 0.60)); // Net is 60% of Gross
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (sortedKeys.length - 1).toDouble() > 0 ? (sortedKeys.length - 1).toDouble() : 1,
        minY: 0,
        maxY: maxVal * 1.2,
        gridData: const FlGridData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final int idx = value.toInt();
                if (idx >= 0 && idx < sortedKeys.length) {
                   return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text('Day ${sortedKeys[idx]}', style: GoogleFonts.inter(color: _textSecondary, fontSize: 10)),
                   );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: grossSpots,
            isCurved: true,
            color: _primaryGreen.withOpacity(0.5),
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: _primaryGreen.withOpacity(0.05)),
          ),
          LineChartBarData(
            spots: netSpots,
            isCurved: true,
            color: _infoBlue,
            barWidth: 4,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: _infoBlue.withOpacity(0.1)),
          ),
        ],
      )
    );
  }
}
