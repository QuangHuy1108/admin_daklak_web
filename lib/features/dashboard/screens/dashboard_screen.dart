import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth <= 768;
    bool isTablet = screenWidth > 768 && screenWidth <= 1200;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderSection(),
          const SizedBox(height: 24),
          _buildTopRow(isMobile, isTablet),
          const SizedBox(height: 24),
          _buildMiddleRow(isMobile, isTablet),
          const SizedBox(height: 24),
          _buildBottomRow(isMobile),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ===========================================================================
  // 1. CÁC PHẦN BỐ CỤC (LAYOUT SECTIONS)
  // ===========================================================================

  Widget _buildHeaderSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Chào buổi sáng!', style: AppTextStyles.heading1),
        SizedBox(height: 8),
        Text(
          'Theo dõi và tối ưu hoạt động nông nghiệp với dữ liệu thời gian thực',
          style: AppTextStyles.subtitle,
        ),
      ],
    );
  }

  Widget _buildTopRow(bool isMobile, bool isTablet) {
    if (isMobile) {
      return Column(
        children: [
          _WeatherCard(),
          const SizedBox(height: 16),
          _buildFarmerStatCard(),
          const SizedBox(height: 16),
          _buildExpertStatCard(),
          const SizedBox(height: 16),
          _buildAppointmentStatCard(),
        ],
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _WeatherCard()),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildFarmerStatCard()),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildExpertStatCard()),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildAppointmentStatCard()),
        ],
      ),
    );
  }

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

  // ===========================================================================
  // 2. CÁC HÀM XÂY DỰNG THẺ THỐNG KÊ (STAT BUILDERS)
  // ===========================================================================

  Widget _buildFarmerStatCard() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getTotalFarmers(), _getNewFarmersToday()]),
      builder: (context, snapshot) {
        final total = snapshot.data?[0] ?? 0;
        final news = snapshot.data?[1] ?? 0;
        return _EnhancedStatCard(
          title: 'Nông dân',
          value: total.toString(),
          trendText: '+$news mới hôm nay',
          isPositive: true,
          icon: Icons.people_alt_rounded,
          color: Colors.green,
          chartData: const [FlSpot(0, 5), FlSpot(1, 10), FlSpot(2, 8), FlSpot(3, 15)],
        );
      },
    );
  }

  Widget _buildExpertStatCard() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getTotalExperts(), _getOnlineExperts()]),
      builder: (context, snapshot) {
        final total = snapshot.data?[0] ?? 0;
        final online = snapshot.data?[1] ?? 0;
        return _EnhancedStatCard(
          title: 'Chuyên gia',
          value: total.toString(),
          trendText: '$online đang online',
          isPositive: true,
          icon: Icons.engineering_rounded,
          color: Colors.blue,
          chartData: const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 5)],
        );
      },
    );
  }

  Widget _buildAppointmentStatCard() {
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_getPendingAppointments(), _getUrgentAppointments()]),
      builder: (context, snapshot) {
        final pending = snapshot.data?[0] ?? 0;
        final urgent = snapshot.data?[1] ?? 0;
        return _EnhancedStatCard(
          title: 'Lịch hẹn chờ',
          value: pending.toString(),
          trendText: '$urgent khẩn cấp',
          isPositive: urgent == 0,
          icon: Icons.calendar_today_rounded,
          color: Colors.orange,
        );
      },
    );
  }

  // ===========================================================================
  // 3. CÁC HÀM TRUY VẤN DỮ LIỆU (FIRESTORE DATA FETCHERS)
  // ===========================================================================

  Future<int> _getTotalFarmers() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['farmer', 'Farmer', 'Nông dân']).count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> _getNewFarmersToday() async {
    try {
      final startOfToday = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['farmer', 'Farmer', 'Nông dân'])
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday))
          .count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> _getTotalExperts() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['expert', 'Expert', 'Chuyên gia']).count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> _getOnlineExperts() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['expert', 'Expert', 'Chuyên gia'])
          .where('isOnline', isEqualTo: true).count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> _getPendingAppointments() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('appointments')
          .where('status', whereIn: ['pending', 'Pending']).count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }

  Future<int> _getUrgentAppointments() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('appointments')
          .where('status', whereIn: ['pending', 'Pending'])
          .where('priority', isEqualTo: 'Urgent').count().get();
      return snap.count ?? 0;
    } catch (e) { return 0; }
  }
}

// ===========================================================================
// 4. CÁC THÀNH PHẦN HIỂN THỊ (UI COMPONENTS)
// ===========================================================================

class _EnhancedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trendText;
  final bool isPositive;
  final IconData icon;
  final Color color;
  final List<FlSpot>? chartData;

  const _EnhancedStatCard({
    required this.title,
    required this.value,
    required this.trendText,
    required this.isPositive,
    required this.icon,
    required this.color,
    this.chartData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Stack(
        children: [
          // Sparkline chìm phía sau
          if (chartData != null)
            Positioned(
              bottom: -10, right: 0, left: 0,
              height: 50,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: chartData!,
                      isCurved: true,
                      color: color.withValues(alpha: 0.2),
                      barWidth: 2,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.05)),
                    ),
                  ],
                ),
              ),
            ),

          // Nội dung thông tin được căn lề lên trên
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: AppTextStyles.subtitle),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                  value,
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: AppColors.textHeading)
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                      isPositive ? Icons.trending_up : Icons.priority_high,
                      color: isPositive ? Colors.green : Colors.red,
                      size: 14
                  ),
                  const SizedBox(width: 4),
                  Text(
                      trendText,
                      style: TextStyle(color: isPositive ? Colors.green : Colors.red, fontSize: 12, fontWeight: FontWeight.bold)
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// --- 1. Weather Card (Real API Integration) ---
class _WeatherCard extends StatefulWidget {
  @override
  State<_WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<_WeatherCard> {
  late Future<Map<String, dynamic>> weatherData;

  // Em hãy đăng ký và dán API Key của OpenWeatherMap vào đây
  final String apiKey = "4be89a65fe75c2f972c0f24084943bc1";
  final String city = "Dak Lak";

  Future<Map<String, dynamic>> fetchWeather() async {
    // Thử đổi tên thành phố sang không dấu để API nhận diện tốt hơn
    const String cityName = "Buon Ma Thuot";
    final url = Uri.parse('https://api.openweathermap.org/data/2.5/weather?q=$cityName,VN&appid=$apiKey&units=metric&lang=vi');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        // In ra Console mã lỗi và nội dung trả về từ server
        print("Mã lỗi API: ${response.statusCode}");
        print("Nội dung lỗi: ${response.body}");
        throw Exception('Mã lỗi ${response.statusCode}');
      }
    } catch (e) {
      print("Lỗi kết nối: $e");
      throw Exception('Không thể kết nối đến máy chủ thời tiết');
    }
  }
  @override
  void initState() {
    super.initState();
    weatherData = fetchWeather();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x11000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: FutureBuilder<Map<String, dynamic>>(
        future: weatherData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          if (snapshot.hasError) {
            // IN LỖI RA CONSOLE ĐỂ DEBUG
            print("LỖI THỜI TIẾT: ${snapshot.error}");
            return Center(child: Text('Lỗi: ${snapshot.error}', style: const TextStyle(color: Colors.white, fontSize: 12)));
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Không có dữ liệu', style: TextStyle(color: Colors.white)));
          }

          final data = snapshot.data!;
          final temp = data['main']['temp'].round();
          final tempMax = data['main']['temp_max'].round();
          final tempMin = data['main']['temp_min'].round();
          final feelsLike = data['main']['feels_like'].round();
          // Viết hoa chữ cái đầu của mô tả thời tiết (vd: Mây rải rác -> Mây rải rác)
          final description = (data['weather'][0]['description'] as String).replaceFirstMapped(RegExp(r'^[a-z]'), (match) => match.group(0)!.toUpperCase());
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Đắk Lắk', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.cloud_queue, color: Colors.white, size: 28),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                  DateFormat('EEEE, d MMM', 'vi_VN').format(DateTime.now()), style: const TextStyle(color: Colors.white70, fontSize: 14)
              ),
              const SizedBox(height: 8),
              Text('$temp°C', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
              Text(description, style: const TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _weatherInfo('Cao/Thấp', '$tempMax°/$tempMin°'),
                  _weatherInfo('Cảm giác', '$feelsLike°'),
                ],
              )
            ],
          );
        },
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

class _ProductionOverviewCard extends StatelessWidget {
  Future<Map<String, double>> _getProductionData() async {
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
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No data', style: AppTextStyles.label));

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
                              startDegreeOffset: 180,
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

class _SalesPriceTrendCard extends StatelessWidget {
  // Hàm này giờ nhận cropDocId từ dropdown
  Future<Map<String, dynamic>> _getPriceData(String cropDocId) async {
    try {
      final doc = await FirebaseFirestore.instance.collection('Price').doc(cropDocId).get();
      
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
        
        String cleanPriceStr = priceStr.split('-')[0].trim().replaceAll('.', '');
        double price = double.tryParse(cleanPriceStr) ?? 0.0;
        
        spots.add(FlSpot(i.toDouble(), price));
        
        if (loc.contains('(') && loc.contains(')')) {
          loc = loc.substring(loc.indexOf('(') + 1, loc.indexOf(')'));
        }
        locations.add(loc);
      }
      
      return {'spots': spots, 'locations': locations};
    } catch (e) {
      return {'spots': <FlSpot>[], 'locations': <String>[], 'error': e.toString()};
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi cây trồng từ Provider
    final selectedCrop = context.watch<DashboardProvider>().selectedCrop;

    return Container(
      height: 400,
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
              const Text('Biến động Giá Nông Sản', style: AppTextStyles.heading3),
              // Filter động thông qua Dropdown thay vì Text thuần
              Container(
                height: 35,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCrop,
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
                    items: const [
                      DropdownMenuItem(value: 'Coffee', child: Text('Cà phê')),
                      DropdownMenuItem(value: 'Pepper', child: Text('Hồ tiêu')),
                      DropdownMenuItem(value: 'Rubber', child: Text('Cao su')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        context.read<DashboardProvider>().setSelectedCrop(val);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: FutureBuilder<Map<String, dynamic>>(
              // Reload dữ liệu khi selectedCrop thay đổi
              future: _getPriceData(selectedCrop),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                
                final mapData = snapshot.data;
                if (mapData == null) return const Center(child: Text('Lỗi tải dữ liệu.'));
                if (mapData.containsKey('error')) return Center(child: Text('Lỗi: ${mapData['error']}', style: const TextStyle(color: Colors.red)));

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
                          getTitlesWidget: (value, meta) => Text('${(value / 1000).toInt()}k', style: AppTextStyles.label),
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
                            // Thay withOpacity() thành withValues(alpha:) để xử lý lỗi deprecated
                            colors: [AppColors.primary.withValues(alpha: 0.4), AppColors.primary.withValues(alpha: 0.0)],
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
}

class _FieldImageCard extends StatelessWidget {
  // Lấy dữ liệu field dựa trên tham số được truyền vào
  Future<Map<String, dynamic>?> _getFieldData(String fieldId) async {
    final snapshot = await FirebaseFirestore.instance.collection('fields').doc(fieldId).get();
    return snapshot.data();
  }

  @override
  Widget build(BuildContext context) {
    // Lắng nghe thay đổi khu vực từ Provider
    final selectedField = context.watch<DashboardProvider>().selectedFieldId;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: FutureBuilder<Map<String, dynamic>?>(
        future: _getFieldData(selectedField),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
          
          final data = snapshot.data;
          
          return Column(
            children: [
              // Header cho phép Admin chuyển đổi khu vực
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 10, top: 10, bottom: 5),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Khu Vực', style: AppTextStyles.heading3),
                    DropdownButton<String>(
                      value: selectedField,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: 'primary_field', child: Text('Khu Vực Chính')),
                        DropdownMenuItem(value: 'field_2', child: Text('Khu Vực 2')),
                      ],
                      onChanged: (val) {
                        if (val != null) context.read<DashboardProvider>().setSelectedField(val);
                      },
                    ),
                  ],
                ),
              ),
              if (data == null)
                 const SizedBox(height: 200, child: Center(child: Text('Chưa có dữ liệu cho khu vực này.')))
              else ...[
                Image.network(
                  data['imageUrl'] ?? 'https://images.unsplash.com/photo-1595974482597-4b8da8879cee', 
                  height: 180, 
                  width: double.infinity, 
                  fit: BoxFit.cover
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['name'] ?? 'Vườn Cà phê A', style: AppTextStyles.heading3),
                      const SizedBox(height: 16),
                      _fieldInfoRow('Sức khỏe cây', data['health'] ?? 'Tốt', true),
                      const SizedBox(height: 8),
                      _fieldInfoRow('Ngày trồng', data['planting_date'] ?? '12/04/2024', false),
                      const SizedBox(height: 8),
                      _fieldInfoRow('Dự kiến thu hoạch', data['harvest_time'] ?? '20/10/2024', false),
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
                          child: const Text('Xem Chi Tiết', style: TextStyle(color: AppColors.textHeading, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                )
              ]
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

class _PlatformStatCard extends StatelessWidget {
  final String title;
  final Future<int> valueFuture;
  final IconData icon;
  final Color color;

  const _PlatformStatCard({
    required this.title,
    required this.valueFuture,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg, // Sử dụng màu từ app_colors.dart của em
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 24),
              ),
            ],
          ),
          const Spacer(),
          FutureBuilder<int>(
            future: valueFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 30, child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator(strokeWidth: 2)));
              }
              final val = snapshot.data ?? 0;
              return Text(val.toString(), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textHeading));
            },
          ),
          const SizedBox(height: 8),
          const Text('Cập nhật realtime', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}