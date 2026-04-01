import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // FarmVista Dashboard is a responsive layout
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 768;
    bool isTablet = screenWidth > 768 && screenWidth <= 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Section
          _buildHeaderSection(),
          const SizedBox(height: 24),

          // 2. Top Row (Widgets)
          _buildTopRow(isMobile, isTablet),
          const SizedBox(height: 24),

          // 3. Middle Row
          _buildMiddleRow(isMobile, isTablet),
          const SizedBox(height: 24),

          // 4. Bottom Row
          _buildBottomRow(isMobile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==================== 1. HEADER SECTION ====================
  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Good Morning!', style: AppTextStyles.heading1),
              SizedBox(height: 8),
              Text(
                'Optimize Your Farm Operations with Real-Time Insights',
                style: AppTextStyles.subtitle,
              ),
            ],
          ),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('This Month', style: AppTextStyles.label),
                  SizedBox(width: 8),
                  Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.textMuted),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded, size: 18),
              label: const Text('Export', style: AppTextStyles.buttonText),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
            ),
          ],
        )
      ],
    );
  }

  // ==================== 2. TOP ROW ====================
  Widget _buildTopRow(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _WeatherCard(),
          const SizedBox(height: 16),
          _ProductionOverviewCard(),
          const SizedBox(height: 16),
          _SmallStatCard(title: 'Total Land Area', valueFuture: _getAreaStats(), subtitle: '+5% increase'),
          const SizedBox(height: 16),
          _SmallStatCard(title: 'Revenue', valueFuture: _getRevenueStats(), subtitle: '+12% growth', prefix: '\$'),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Weather: 3 cols approx (25%)
          Expanded(flex: 3, child: _WeatherCard()),
          const SizedBox(width: 24),
          // Chart: 5 cols approx (40%)
          Expanded(flex: 5, child: _ProductionOverviewCard()),
          const SizedBox(width: 24),
          // Stats: 4 cols approx (35%)
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Expanded(child: _SmallStatCard(title: 'Total Land Area', valueFuture: _getAreaStats(), subtitle: '+5% increase')),
                const SizedBox(height: 24),
                Expanded(child: _SmallStatCard(title: 'Revenue', valueFuture: _getRevenueStats(), subtitle: '+12% growth', prefix: '\$')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 3. MIDDLE ROW ====================
  Widget _buildMiddleRow(bool isMobile, bool isTablet) {
    if (isMobile || isTablet) {
      return Column(
        children: [
          _SalesPriceTrendCard(),
          const SizedBox(height: 24),
          _FieldImageCard(),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: _SalesPriceTrendCard()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _FieldImageCard()),
        ],
      ),
    );
  }

  // ==================== 4. BOTTOM ROW ====================
  Widget _buildBottomRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _TaskManagementTable(),
          const SizedBox(height: 24),
          _VegetableHarvestSummary(),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: _TaskManagementTable()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _VegetableHarvestSummary()),
        ],
      ),
    );
  }

  // --- Data Fetchers for Top Row Stats ---
  Future<String> _getAreaStats() async {
    // Querying total land area from Firestore (farm_stats collection).
    // If empty/error, return 0.
    final snapshot = await FirebaseFirestore.instance.collection('farm_stats').doc('area').get();
    if (snapshot.exists && snapshot.data() != null) {
      return "${snapshot.data()!['value']} acres";
    }
    return "... acres"; 
  }

  Future<String> _getRevenueStats() async {
    final snapshot = await FirebaseFirestore.instance.collection('farm_stats').doc('revenue').get();
    if (snapshot.exists && snapshot.data() != null) {
      return "${snapshot.data()!['value']}";
    }
    return "...";
  }
}

// ==================== CHILD WIDGETS ====================

// --- 1. Weather Card ---
class _WeatherCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Typically fetches from 'weather_service.dart'.
    // Here using a StreamBuilder to weather collection or direct Future.
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary, // Green background for weather
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Chicago', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              Icon(Icons.cloud_queue, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 16),
          Text(DateFormat('EEEE, d MMM').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('24°C', style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
          const Text('Cloudy', style: TextStyle(color: Colors.white, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _weatherInfo('H/L', '26°/18°'),
              _weatherInfo('Feels', '25°'),
            ],
          )
        ],
      ),
    );
  }

  Widget _weatherInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- 2. Production Overview (Arc Chart) ---
class _ProductionOverviewCard extends StatelessWidget {
  Future<Map<String, double>> _getProductionData() async {
    // Real query without mock data
    final snapshot = await FirebaseFirestore.instance.collection('production_overview').get();
    Map<String, double> data = {};
    for (var doc in snapshot.docs) {
      data[doc.id] = (doc['percentage'] as num).toDouble();
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Production Overview', style: AppTextStyles.heading3),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, double>>(
              future: _getProductionData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                // If no real data, display empty indicator
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return const Center(child: Text('No data submitted yet', style: AppTextStyles.label));
                }

                final data = snapshot.data!;

                return Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sectionsSpace: 4,
                              centerSpaceRadius: 40,
                              startDegreeOffset: 180, // Arc style starts at bottom if needed, pie is simpler to ensure stability
                              sections: data.entries.map((e) => PieChartSectionData(
                                color: _getColorForCrop(e.key),
                                value: e.value,
                                radius: 25,
                                showTitle: false,
                              )).toList(),
                            ),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text('Total', style: AppTextStyles.label),
                              Text('1,000', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Text('Tons', style: AppTextStyles.label),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: data.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              Container(width: 12, height: 12, decoration: BoxDecoration(color: _getColorForCrop(e.key), shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Expanded(child: Text(e.key, style: AppTextStyles.bodyText)),
                              Text('${e.value}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )).toList(),
                      ),
                    )
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getColorForCrop(String name) {
    if (name.toLowerCase() == 'wheat') return const Color(0xFFF59E0B);
    if (name.toLowerCase() == 'corn') return AppColors.primary;
    if (name.toLowerCase() == 'rice') return const Color(0xFF3B82F6);
    return Colors.grey;
  }
}

// --- 3. Small Stats Card ---
class _SmallStatCard extends StatelessWidget {
  final String title;
  final Future<String> valueFuture;
  final String subtitle;
  final String prefix;

  const _SmallStatCard({required this.title, required this.valueFuture, required this.subtitle, this.prefix = ''});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.subtitle),
              const Icon(Icons.show_chart, color: AppColors.primaryLight, size: 20),
            ],
          ),
          const Spacer(),
          FutureBuilder<String>(
            future: valueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 30, child: CircularProgressIndicator());
              final val = snapshot.data ?? 'No data';
              return Text('$prefix$val', style: AppTextStyles.statValue);
            },
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: const TextStyle(color: AppColors.primaryLight, fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --- 4. Sales Price Trend Analysis (Thay thế Monthly Yield) ---
// --- 4. Sales Price Trend Analysis (Thay thế Monthly Yield) ---
class _SalesPriceTrendCard extends StatelessWidget {
  Future<Map<String, dynamic>> _getPriceData() async {
    try {
      // Dựa theo hình ảnh bạn cung cấp: Collection là "Price", Document là "Coffee"
      final doc = await FirebaseFirestore.instance.collection('Price').doc('Coffee').get();
      
      if (!doc.exists || doc.data() == null) {
        return {'spots': <FlSpot>[], 'locations': <String>[]};
      }
      
      final data = doc.data()!;
      if (!data.containsKey('latest_data')) {
        return {'spots': <FlSpot>[], 'locations': <String>[]};
      }
      
      List<dynamic> latestData = data['latest_data'];
      List<FlSpot> spots = [];
      List<String> locations = [];
      
      for (int i = 0; i < latestData.length; i++) {
        var item = latestData[i];
        String loc = item['location'] ?? 'Vùng $i';
        String priceStr = item['price'] ?? '0';
        
        // Chuỗi giá có thể là "93.000 - 94.000" hoặc "93.000"
        // Ta cắt lấy số đầu tiên trước dấu "-", xóa dấu chấm phân cách ngàn để ra số thực
        String cleanPriceStr = priceStr.split('-')[0].trim().replaceAll('.', '');
        double price = double.tryParse(cleanPriceStr) ?? 0.0;
        
        spots.add(FlSpot(i.toDouble(), price));
        
        // Rút gọn tên địa phương (VD: "Cà phê (Tây Nguyên)" -> "Tây Nguyên")
        if (loc.contains('(') && loc.contains(')')) {
          loc = loc.substring(loc.indexOf('(') + 1, loc.indexOf(')'));
        }
        locations.add(loc);
      }
      
      return {'spots': spots, 'locations': locations};
    } catch (e) {
      print("Lỗi khi lấy dữ liệu giá: $e");
      return {'spots': <FlSpot>[], 'locations': <String>[], 'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 400, // Fixed height for chart visibility
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Biến động Giá Nông Sản (Cà phê)', style: AppTextStyles.heading3),
              Row(
                children: [
                  _filterGhostButton('Hôm nay'),
                  const SizedBox(width: 8),
                  _filterGhostButton('...', icon: Icons.more_horiz),
                ],
              )
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              future: _getPriceData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final mapData = snapshot.data;
                if (mapData == null) return const Center(child: Text('Lỗi tải dữ liệu.'));
                
                if (mapData.containsKey('error')) {
                  return Center(child: Text('Lỗi: ${mapData['error']}', style: const TextStyle(color: Colors.red)));
                }

                final List<FlSpot> spots = mapData['spots'] ?? [];
                final List<String> locations = mapData['locations'] ?? [];

                if (spots.isEmpty) return const Center(child: Text('Chưa có dữ liệu giá hợp lệ.', style: AppTextStyles.label));

                return LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (value) => FlLine(color: AppColors.border, strokeWidth: 1),
                    ),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            int index = value.toInt();
                            if (index >= 0 && index < locations.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(locations[index], style: const TextStyle(fontSize: 11, color: AppColors.textMuted)), 
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 50,
                          getTitlesWidget: (value, meta) => Text('${(value / 1000).toInt()}k', style: AppTextStyles.label), // Ví dụ format giá K
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 5,
                              color: Colors.white,
                              strokeWidth: 2,
                              strokeColor: AppColors.primary,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [AppColors.primary.withOpacity(0.4), AppColors.primary.withOpacity(0.0)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterGhostButton(String label, {IconData icon = Icons.keyboard_arrow_down}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(6)),
      child: Row(
        children: [
           Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
           const SizedBox(width: 4),
           Icon(icon, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}

// --- 5. Field Image Card ---
class _FieldImageCard extends StatelessWidget {
  Future<Map<String, dynamic>?> _getFieldData() async {
    final snapshot = await FirebaseFirestore.instance.collection('fields').doc('primary_field').get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getFieldData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
          
          final data = snapshot.data;
          // Placeholder image if data is missing, otherwise network image.
          // Since mock data is forbidden, if data is missing we show empty state.
          if (data == null) {
            return const SizedBox(height: 300, child: Center(child: Text('No field data found in DB.')));
          }

          String imgUrl = data['imageUrl'] ?? 'https://images.unsplash.com/photo-1595974482597-4b8da8879cee'; // Placeholder fallback just in case DB field is empty
          
          return Column(
            children: [
              Image.network(imgUrl, height: 180, width: double.infinity, fit: BoxFit.cover),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? 'Corn Field', style: AppTextStyles.heading3),
                    const SizedBox(height: 16),
                    _fieldInfoRow('Crop Health', data['health'] ?? 'Good', true),
                    const SizedBox(height: 8),
                    _fieldInfoRow('Planting Date', data['planting_date'] ?? 'Apr 12, 2024', false),
                    const SizedBox(height: 8),
                    _fieldInfoRow('Harvest Time', data['harvest_time'] ?? 'Oct 20, 2024', false),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AppColors.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('More Details', style: TextStyle(color: AppColors.textHeading, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _fieldInfoRow(String label, String value, bool isStatus) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        isStatus 
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: AppColors.statusProgressBg, borderRadius: BorderRadius.circular(4)),
              child: Text(value, style: const TextStyle(color: AppColors.statusProgressText, fontSize: 12, fontWeight: FontWeight.bold)),
            )
          : Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// --- 6. Task Management Table ---
class _TaskManagementTable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Task Management', style: AppTextStyles.heading3),
              Row(
                children: [
                  TextButton(onPressed: () {}, child: const Text('View All', style: TextStyle(color: AppColors.textMuted))),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Add New Task', style: TextStyle(color: Colors.white)),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),
          // SingleChildScrollView enables horizontal scroll to prevent layout errors on mobile
          SizedBox(
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tasks').limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('No tasks active.'));

                  return DataTable(
                    horizontalMargin: 0,
                    columnSpacing: 32,
                    headingTextStyle: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold, fontSize: 13),
                    dataTextStyle: const TextStyle(color: AppColors.textHeading, fontSize: 14),
                    columns: const [
                      DataColumn(label: Text('Task Name')),
                      DataColumn(label: Text('Assigned To')),
                      DataColumn(label: Text('Due Date')),
                      DataColumn(label: Text('Status')),
                    ],
                    rows: snapshot.data!.docs.map((doc) {
                      var data = doc.data() as Map<String, dynamic>;
                      bool isPending = data['status'] == 'Pending';
                      return DataRow(
                        cells: [
                          DataCell(Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                          DataCell(Row(
                            children: [
                              const CircleAvatar(radius: 12, backgroundColor: AppColors.border, child: Icon(Icons.person, size: 14, color: AppColors.textMuted)),
                              const SizedBox(width: 8),
                              Text(data['assignedTo'] ?? ''),
                            ],
                          )),
                          DataCell(Text(data['dueDate'] ?? '')),
                          DataCell(
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending ? AppColors.statusPendingBg : AppColors.statusProgressBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                data['status'] ?? '',
                                style: TextStyle(
                                  color: isPending ? AppColors.statusPendingText : AppColors.statusProgressText,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}

// --- 7. Vegetable Harvest Summary ---
class _VegetableHarvestSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Harvest Summary', style: AppTextStyles.heading3),
              IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert, color: AppColors.textMuted))
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('harvest_summary').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('No harvest data yet.'));

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.grass, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeading)),
                                const Text('Harvested Today', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                              ],
                            ),
                          ),
                          Text('${data['tons'] ?? 0} tons', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          )
        ],
      ),
    );
  }
}