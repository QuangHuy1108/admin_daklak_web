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
import 'dart:math' as math;

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
          const ExpertOverviewCard(), // (hoặc _buildExpertStatCard() cũ)
          const SizedBox(height: 16),
          _buildAppointmentStatCard(),
        ],
      );
    }

    // ✅ ĐÚNG: Luôn có return bao bọc ở cuối hàm cho màn hình lớn
    return SizedBox(
      height: 300, // Chiều cao cố định
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 3, child: _WeatherCard()),
          const SizedBox(width: 20),
          Expanded(flex: 3, child: _buildFarmerStatCard()),
          const SizedBox(width: 20),
          const Expanded(flex: 3, child: ExpertOverviewCard()),
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
          _PopularDiseaseMentionCard(),
        ],
      );
    }
    return SizedBox(
      height: 400, // Chiều cao khớp với _SalesPriceTrendCard của bạn
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 8, child: _SalesPriceTrendCard()),
          const SizedBox(width: 24),
          Expanded(flex: 4, child: _PopularDiseaseMentionCard()),
        ],
      ),
    );
  }

  Widget _buildBottomRow(bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          const SizedBox(height: 24),
        ],
      );
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(width: 24),
        ],
      ),
    );
  }

  Widget _buildFarmerStatCard() {
    return DashboardStatCard(
      titleTotal: 'Nông dân',
      titleNew: 'Hôm nay',
      iconTotal: Icons.people_alt_rounded,
      iconNew: Icons.person_add_alt_1_rounded,
      colorTotal: Colors.green,
      colorNew: Colors.green,
      chartColor: Colors.green,
      futureTotal: _getTotalFarmers(),
      futureNew: _getNewFarmersToday(),
      futureChart: _getChartData7Days(),
    );
  }

  Widget _buildExpertStatCard() {
    return DashboardStatCard(
      titleTotal: 'Chuyên gia',
      titleNew: 'Đang online',
      chartTitle: 'Tỷ lệ trạng thái', // Đổi tên phần dưới
      iconTotal: Icons.engineering_rounded,
      iconNew: Icons.wifi_rounded,
      colorTotal: Colors.blue,
      colorNew: Colors.lightBlue,
      chartColor: Colors.lightBlue, // Màu của phần tử Online trong biểu đồ tròn
      isPieChart: true, // Bật chế độ biểu đồ tròn
      futureTotal: _getTotalExperts(),
      futureNew: _getOnlineExperts(),
      // Không cần truyền futureChart nữa
    );
  }

  Widget _buildAppointmentStatCard() {
    return DashboardStatCard(
      // Cột 1 (Pending)
      titleTotal: 'Chờ',
      iconTotal: Icons.hourglass_empty_rounded,
      colorTotal: Colors.orange,
      futureTotal: _getAppointmentsCount('pending'),

      // Cột 2 (Confirmed)
      titleNew: 'Đã nhận',
      iconNew: Icons.check_circle_outline_rounded,
      colorNew: Colors.green,
      futureNew: _getAppointmentsCount('confirmed'),

      // Cột 3 (Cancelled)
      titleThird: 'Đã hủy',
      iconThird: Icons.cancel_outlined,
      colorThird: Colors.red,
      futureThird: _getAppointmentsCount('cancelled'),

      // Tùy chỉnh biểu đồ
      chartTitle: 'Phân bố trạng thái',
      chartColor: Colors.transparent, // Không dùng cho Bar chart
      isHorizontalBar: true, // Bật biểu đồ cột ngang
    );
  }
  // Hàm tạo data biểu đồ giả cho Chuyên gia & Lịch hẹn để tránh lỗi UI
  Future<List<FlSpot>> _getDummyChartData() async {
    return const [FlSpot(0, 2), FlSpot(1, 4), FlSpot(2, 3), FlSpot(3, 7), FlSpot(4, 5), FlSpot(5, 8), FlSpot(6, 6)];
  }

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
        
    print("✅ Đếm thành công: ${snap.count}"); // In ra nếu thành công
    return snap.count ?? 0;
  } catch (e) { 
    print("❌ LỖI FIREBASE KHI ĐẾM: $e"); // BẮT BUỘC PHẢI CÓ DÒNG NÀY
    return 0; 
  }
}

  Future<List<FlSpot>> _getChartData7Days() async {
    List<Future<AggregateQuerySnapshot>> futures = [];
    DateTime now = DateTime.now();
    // Mốc 00:00:00 của ngày hôm nay
    DateTime todayStart = DateTime(now.year, now.month, now.day);

    // Vòng lặp lấy dữ liệu từ 6 ngày trước cho đến hôm nay (tổng 7 ngày)
    for (int i = 6; i >= 0; i--) {
      // Xác định khoảng thời gian của từng ngày
      DateTime targetDayStart = todayStart.subtract(Duration(days: i));
      DateTime targetDayEnd = targetDayStart.add(const Duration(days: 1));

      // Tạo câu truy vấn cho ngày đó
      var query = FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['farmer', 'Farmer', 'Nông dân'])
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(targetDayStart))
          .where('createdAt', isLessThan: Timestamp.fromDate(targetDayEnd))
          .count()
          .get();

      futures.add(query);
    }

    try {
      // Chờ cả 7 ngày đếm xong cùng lúc
      final snapshots = await Future.wait(futures);
      List<FlSpot> spots = [];

      // Map kết quả ra định dạng FlSpot(toạ độ x, toạ độ y)
      for (int i = 0; i < snapshots.length; i++) {
        double x = i.toDouble(); // Trục X: 0 đến 6 (0 là 6 ngày trước, 6 là hôm nay)
        double y = (snapshots[i].count ?? 0).toDouble(); // Trục Y: Số lượng người
        spots.add(FlSpot(x, y));
      }

      return spots;
    } catch (e) {
      print("❌ Lỗi lấy dữ liệu biểu đồ: $e");
      // Nếu lỗi, trả về một mảng trống hoặc dữ liệu mặc định để app không crash
      return const [FlSpot(0, 0)];
    }
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

      print("✅ Đếm chuyên gia online thành công: ${snap.count}");
      return snap.count ?? 0;
    } catch (e) {
      // BẮT BUỘC THÊM DÒNG NÀY ĐỂ TÌM LỖI
      print("❌ LỖI FIREBASE KHI ĐẾM EXPERT ONLINE: $e");
      return 0;
    }
  }

// Hàm đếm số lượng lịch hẹn theo trạng thái
  Future<int> _getAppointmentsCount(String status) async {
    try {
      // Cho phép linh hoạt chữ hoa chữ thường
      List<String> statusFilter;
      if (status == 'pending') statusFilter = ['pending', 'Pending', 'Chờ xác nhận'];
      else if (status == 'confirmed') statusFilter = ['confirmed', 'Confirmed', 'Đã xác nhận'];
      else statusFilter = ['cancelled', 'Cancelled', 'Đã hủy'];

      final snap = await FirebaseFirestore.instance.collection('appointments')
          .where('status', whereIn: statusFilter)
          .count().get();
      return snap.count ?? 0;
    } catch (e) {
      print("❌ Lỗi đếm Lịch hẹn $status: $e");
      return 0;
    }
  }
}

class DashboardStatCard extends StatelessWidget {
  final String titleTotal;
  final String titleNew;
  final String chartTitle;
  final IconData iconTotal;
  final IconData iconNew;
  final Color colorTotal;
  final Color colorNew;
  final Color chartColor;

  final bool isPieChart;

  // MỚI: Thêm các tham số cho cột thứ 3 (Tùy chọn)
  final String? titleThird;
  final IconData? iconThird;
  final Color? colorThird;
  final Future<int>? futureThird;
  // MỚI: Thêm cờ để bật biểu đồ thanh ngang
  final bool isHorizontalBar;

  final Future<int> futureTotal;
  final Future<int> futureNew;
  final Future<List<FlSpot>>? futureChart;

  const DashboardStatCard({
    Key? key,
    required this.titleTotal,
    required this.titleNew,
    this.chartTitle = 'Biểu đồ 7 ngày qua',
    required this.iconTotal,
    required this.iconNew,
    required this.colorTotal,
    required this.colorNew,
    required this.chartColor,
    this.isPieChart = false,
    this.isHorizontalBar = false, // Mặc định tắt
    this.titleThird,
    this.iconThird,
    this.colorThird,
    this.futureThird,
    required this.futureTotal,
    required this.futureNew,
    this.futureChart,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Thu thập các future cần thiết
    final List<Future<dynamic>> futures = [futureTotal, futureNew];
    if (futureThird != null) futures.add(futureThird!);
    if (futureChart != null) futures.add(futureChart!);

    return FutureBuilder<List<dynamic>>(
      future: Future.wait(futures),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingOrErrorContainer(const CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _buildLoadingOrErrorContainer(const Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.red, fontSize: 12)));
        }

        final data1 = snapshot.data?[0] ?? 0;
        final data2 = snapshot.data?[1] ?? 0;
        // Logic lấy data3 và chartData phụ thuộc vào việc futureThird có được truyền vào không
        final int data3 = futureThird != null ? (snapshot.data?[2] ?? 0) : 0;
        final chartData = (futureChart != null)
            ? (snapshot.data?.last as List<FlSpot>?) ?? const [FlSpot(0, 0)]
            : const [FlSpot(0, 0)];

        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // ================= NỬA TRÊN =================
                Expanded(
                  flex: 1,
                  child: Row(
                    children: [
                      Expanded(child: _buildStatItem(titleTotal, data1.toString(), iconTotal, colorTotal)),
                      Container(width: 1, color: AppColors.border),
                      Expanded(child: _buildStatItem(titleNew, data2.toString(), iconNew, colorNew)),
                      // Thêm cột thứ 3 nếu có
                      if (titleThird != null && iconThird != null && colorThird != null) ...[
                        Container(width: 1, color: AppColors.border),
                        Expanded(child: _buildStatItem(titleThird!, data3.toString(), iconThird!, colorThird!)),
                      ]
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Container(height: 1, color: AppColors.border),
                ),

                // ================= NỬA DƯỚI =================
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(chartTitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      // Hiển thị biểu đồ tương ứng
                      Expanded(
                        child: isHorizontalBar
                            ? MiniHorizontalBarChart(pending: data1, confirmed: data2, cancelled: data3) // Gọi Bar Chart
                            : isPieChart
                            ? _buildPieChart(data1, data2, colorNew)
                            : _buildLineChart(chartData, chartColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  // --- CÁC HÀM HELPER HIỂN THỊ ---

  Widget _buildStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHeading)),
        const SizedBox(height: 2),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // MỚI: Hàm vẽ biểu đồ tròn
  Widget _buildPieChart(int total, int online, Color activeColor) {
    int offline = total - online;
    if (offline < 0) offline = 0;

    if (total == 0) {
      return const Center(child: Text('Chưa có dữ liệu', style: TextStyle(fontSize: 11, color: AppColors.textMuted)));
    }

    // Tính toán tỷ lệ phần trăm
    double onlinePercent = (online / total) * 100;
    double offlinePercent = (offline / total) * 100;

    return Row(
      children: [
        Expanded(
          flex: 5, // Tăng không gian cho biểu đồ để nó to hơn
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 18, // Tăng khoảng trống ở giữa
              sections: [
                PieChartSectionData(
                  value: online.toDouble(),
                  color: activeColor,
                  radius: 35, // Phóng to bán kính khối Online (Cũ là 18)
                  title: '${onlinePercent.toStringAsFixed(1)}%', // Hiển thị 1 chữ số thập phân (VD: 25.5%)
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                  ),
                  showTitle: true, // Bật hiển thị chữ
                ),
                PieChartSectionData(
                  value: offline.toDouble(),
                  color: AppColors.border,
                  radius: 28, // Phóng to bán kính khối Offline (Cũ là 15)
                  title: '${offlinePercent.toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textHeading // Dùng màu chữ tối để dễ đọc trên nền xám
                  ),
                  showTitle: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Chú thích nhỏ bên cạnh (Legend)
        Expanded(
          flex: 4, // Thu hẹp không gian chú thích lại một chút
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLegendItem('Online', activeColor),
              const SizedBox(height: 8),
              _buildLegendItem('Offline', AppColors.border),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 10, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // Hàm vẽ biểu đồ đường (cũ)
// Hàm vẽ biểu đồ đường
  Widget _buildLineChart(List<FlSpot> spots, Color color) {
    final validSpots = spots.isEmpty ? const [FlSpot(0, 0)] : spots;
    return LineChart(
      LineChartData(
        // Thêm lineTouchData để tùy chỉnh tooltip (số liệu khi chạm vào biểu đồ)
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            // Cài đặt nền trong suốt
            getTooltipColor: (LineBarSpot touchedSpot) => Colors.transparent,
            tooltipPadding: const EdgeInsets.all(4),
            // Tùy chỉnh màu chữ số liệu
            getTooltipItems: (List<LineBarSpot> touchedSpots) {
              return touchedSpots.map((LineBarSpot touchedSpot) {
                return LineTooltipItem(
                  touchedSpot.y.toInt().toString(),
                  TextStyle(
                    color: color, // Màu chữ trùng với màu của đường line
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        minX: 0, maxX: 6, minY: 0,
        lineBarsData: [
          LineChartBarData(
            spots: validSpots,
            isCurved: true,
            color: color,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(show: true, color: color.withOpacity(0.15)),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingOrErrorContainer(Widget child) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16)),
        child: Center(child: child),
      ),
    );
  }
}


// MỚI: Widget vẽ biểu đồ thanh ngang mini
class MiniHorizontalBarChart extends StatelessWidget {
  final int pending;
  final int confirmed;
  final int cancelled;

  const MiniHorizontalBarChart({
    Key? key,
    required this.pending,
    required this.confirmed,
    required this.cancelled,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    int total = pending + confirmed + cancelled;
    if (total == 0) {
      return const Center(child: Text('Chưa có lịch hẹn', style: TextStyle(fontSize: 11, color: AppColors.textMuted)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildBarRow('Chờ', pending, total, constraints.maxWidth, Colors.orange),
            _buildBarRow('Đã nhận', confirmed, total, constraints.maxWidth, Colors.green),
            _buildBarRow('Đã hủy', cancelled, total, constraints.maxWidth, Colors.red),
          ],
        );
      },
    );
  }

  Widget _buildBarRow(String label, int value, int total, double maxWidth, Color color) {
    // Dành 50px cho Label, 30px cho Value, phần còn lại cho Bar
    double barMaxWidth = maxWidth - 50 - 30 - 16;
    double barWidth = total > 0 ? (value / total) * barMaxWidth : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          // Nhãn (Label)
          SizedBox(
            width: 50,
            child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 8),

          // Thanh tiến trình (Bar)
          Container(
            width: barMaxWidth,
            height: 12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.centerLeft,
            child: Container(
              width: barWidth,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Giá trị (Value)
          Container(
            width: 30,
            alignment: Alignment.centerRight,
            child: Text(value.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textHeading)),
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

class ExpertOverviewCard extends StatefulWidget {
  const ExpertOverviewCard({Key? key}) : super(key: key);

  @override
  State<ExpertOverviewCard> createState() => _ExpertOverviewCardState();
}

class _ExpertOverviewCardState extends State<ExpertOverviewCard> {
  // Lấy tổng số chuyên gia và số online để vẽ biểu đồ
  Future<Map<String, int>> _getExpertStats() async {
    try {
      final totalSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['expert', 'Expert', 'Chuyên gia']).count().get();

      final onlineSnap = await FirebaseFirestore.instance.collection('users')
          .where('role', whereIn: ['expert', 'Expert', 'Chuyên gia'])
          .where('isOnline', isEqualTo: true).count().get();

      return {
        'total': totalSnap.count ?? 0,
        'online': onlineSnap.count ?? 0,
      };
    } catch (e) {
      return {'total': 0, 'online': 0};
    }
  }

  // Lấy top 3 chuyên gia có rating cao nhất
  Future<List<Map<String, dynamic>>> _getTopRatedExperts() async {
    try {
      print("⏳ Bắt đầu truy vấn chuyên gia...");

      // ĐỔI TỪ whereIn SANG isEqualTo ĐỂ KHỚP TUYỆT ĐỐI VỚI INDEX BẠN VỪA TẠO
      final snap = await FirebaseFirestore.instance.collection('users')
          .where('role', isEqualTo: 'expert')
          .orderBy('rating', descending: true)
          .limit(3)
          .get();

      print("✅ Thành công! Tìm thấy ${snap.docs.length} người có rating.");

      // In ra tên để kiểm tra xem nó có lấy được trường displayName không
      for (var doc in snap.docs) {
        final data = doc.data();
        print("👉 Tên: ${data['displayName'] ?? data['name'] ?? 'Không có tên'} - Rating: ${data['rating']}");
      }

      return snap.docs.map((doc) => doc.data()).toList();

    } catch (e) {
      print("❌ LỖI KHI TẢI: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // ================= NỬA TRÊN: THỐNG KÊ TỔNG =================
          Expanded(
            flex: 3,
            child: FutureBuilder<Map<String, int>>(
              future: _getExpertStats(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snapshot.data ?? {'total': 0, 'online': 0};

                return Row(
                  children: [
                    Expanded(
                      child: _buildTopStatItem('Chuyên gia', data['total'].toString(), Icons.engineering_rounded, Colors.blue),
                    ),
                    Container(width: 1, color: AppColors.border),
                    Expanded(
                      child: _buildTopStatItem('Đang online', data['online'].toString(), Icons.wifi_rounded, Colors.lightBlue),
                    ),
                  ],
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Container(height: 1, color: AppColors.border),
          ),

          // ================= NỬA DƯỚI: LIST RATING & PIE CHART =================
          Expanded(
            flex: 5,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cột Trái: Danh sách Top Rating
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Top Đánh Giá', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: FutureBuilder<List<Map<String, dynamic>>>(
                          future: _getTopRatedExperts(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            }
                            final experts = snapshot.data ?? [];
                            if (experts.isEmpty) {
                              return const Center(child: Text('Chưa có đánh giá', style: TextStyle(fontSize: 10, color: AppColors.textMuted)));
                            }

                            return ListView.builder(
                              physics: const NeverScrollableScrollPhysics(), // Tắt cuộn để thẻ gọn gàng
                              itemCount: experts.length,
                              itemBuilder: (context, index) {
                                final expert = experts[index];

                                // 1. Tìm rating ở ngoài trước, nếu không có thì tìm trong expertInfo
                                // Nếu cả 2 đều không có thì mặc định là 0.0
                                double ratingVal = 0.0;

                                if (expert['rating'] != null) {
                                  ratingVal = double.tryParse(expert['rating'].toString()) ?? 0.0;
                                } else if (expert['expertInfo'] != null && expert['expertInfo']['rating'] != null) {
                                  ratingVal = double.tryParse(expert['expertInfo']['rating'].toString()) ?? 0.0;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    children: [
                                      // Avatar giả lập (nếu có trường avatar thì thay vào đây)
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: AppColors.primary.withOpacity(0.1),
                                        child: const Icon(Icons.person, size: 14, color: AppColors.primary),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(expert['displayName'] ?? 'Ẩn danh', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textHeading), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text(expert['specialty'] ?? 'Chuyên gia', style: const TextStyle(fontSize: 9, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 12),
                                          const SizedBox(width: 2),
                                          Builder(
                                            builder: (context) {
                                              // Cách lấy dữ liệu "chống đạn":
                                              // Chấp nhận cả int và double, sau đó ép về double và định dạng 1 chữ số thập phân
                                              final ratingData = expert['rating'];
                                              double displayRating = 0.0;

                                              if (ratingData is num) {
                                                displayRating = ratingData.toDouble();
                                              } else if (ratingData is String) {
                                                displayRating = double.tryParse(ratingData) ?? 0.0;
                                              }

                                              return Text(
                                                displayRating.toStringAsFixed(1), // Sẽ luôn hiển thị dạng 4.8 hoặc 5.0
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              );
                                            },
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Đường chia dọc giữa 2 phần dưới
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(width: 1, color: AppColors.border),
                ),

                // Cột Phải: Biểu đồ tròn Online/Offline
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tỷ lệ trạng thái', style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: FutureBuilder<Map<String, int>>(
                          future: _getExpertStats(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) return const SizedBox();
                            int total = snapshot.data!['total'] ?? 0;
                            int online = snapshot.data!['online'] ?? 0;
                            int offline = total - online;
                            if (offline < 0) offline = 0;

                            if (total == 0) return const Center(child: Text('Trống', style: TextStyle(fontSize: 10, color: AppColors.textMuted)));

                            double onlinePct = (online / total) * 100;
                            double offlinePct = (offline / total) * 100;

                            return Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: PieChart(
                                    PieChartData(
                                      sectionsSpace: 2,
                                      centerSpaceRadius: 12,
                                      sections: [
                                        PieChartSectionData(
                                          value: online.toDouble(),
                                          color: Colors.lightBlue,
                                          radius: 20,
                                          title: '${onlinePct.toStringAsFixed(0)}%',
                                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                                        ),
                                        PieChartSectionData(
                                          value: offline.toDouble(),
                                          color: AppColors.border,
                                          radius: 16,
                                          title: '${offlinePct.toStringAsFixed(0)}%',
                                          titleStyle: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.textHeading),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  flex: 4,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildLegendItem('Online', Colors.lightBlue),
                                      const SizedBox(height: 4),
                                      _buildLegendItem('Offline', AppColors.border),
                                    ],
                                  ),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hàm hỗ trợ vẽ icon thống kê nửa trên
  Widget _buildTopStatItem(String title, String value, IconData icon, Color color) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeading)),
        Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  // Hàm hỗ trợ vẽ chú thích biểu đồ
  Widget _buildLegendItem(String title, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
        const SizedBox(width: 4),
        Expanded(child: Text(title, style: const TextStyle(fontSize: 9, color: AppColors.textMuted), overflow: TextOverflow.ellipsis)),
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
    // Lắng nghe thay đổi cây trồng từ Provider (ĐÂY LÀ BIẾN BỊ THIẾU GÂY LỖI)
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
              // Bọc thẻ Text bằng Expanded để tự động co giãn không bị tràn màn hình
              const Expanded(
                child: Text(
                  'Biến động Giá Nông Sản',
                  style: AppTextStyles.heading3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),

              // Filter động thông qua Dropdown
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
                      DropdownMenuItem(value: 'Durian', child: Text('Sầu riêng')),
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
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        // 1. Đổi màu nền của tooltip (Ví dụ: Đổi sang nền Trắng hoặc Xám nhạt)
                        getTooltipColor: (LineBarSpot touchedSpot) => Colors.transparent,

                        // Bo góc cho hộp tooltip đẹp hơn
                        tooltipBorderRadius: BorderRadius.circular(8),
                        // Căn chỉnh khoảng cách bên trong
                        tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                        // 2. Tùy chỉnh nội dung và màu chữ
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((LineBarSpot touchedSpot) {
                            return LineTooltipItem(
                              // Format lại số cho đẹp (nếu cần), hiện tại đang in thẳng số y
                              touchedSpot.y.toInt().toString(),

                              const TextStyle(
                                // Đổi màu chữ sang màu tối (ví dụ: xanh đậm hoặc đen) để nổi bật trên nền sáng
                                color: Color(0xFF1B5E20), // Hoặc dùng AppColors.primary của bạn
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            );
                          }).toList();
                        },
                      ),
                    ),
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
                          interval: 1, // THÊM DÒNG NÀY: Ép biểu đồ chỉ nhảy từng bước 1
                          reservedSize: 30, // Thêm khoảng không gian bên dưới để chữ không bị cắt
                          getTitlesWidget: (value, meta) {
                            // Đảm bảo value là số nguyên thực sự (tránh sai số dấu phẩy động)
                            if (value != value.toInt()) return const SizedBox.shrink();

                            int index = value.toInt();
                            if (index >= 0 && index < locations.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  locations[index],
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  textAlign: TextAlign.center,
                                ),
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

class _PopularDiseaseMentionCard extends StatefulWidget {
  const _PopularDiseaseMentionCard({Key? key}) : super(key: key);

  @override
  State<_PopularDiseaseMentionCard> createState() => _PopularDiseaseMentionCardState();
}

class _PopularDiseaseMentionCardState extends State<_PopularDiseaseMentionCard> {
  late Future<List<Map<String, dynamic>>> _mentionsFuture;

  @override
  void initState() {
    super.initState();
    // 2. Chỉ gọi hàm lấy dữ liệu MỘT LẦN duy nhất khi widget được khởi tạo
    _mentionsFuture = _fetchAggregatedMentions();
  }
  // Hàm tổng hợp dữ liệu từ 4 collections
  Future<List<Map<String, dynamic>>> _fetchAggregatedMentions() async {
    try {
      // Logic mock data tạm thời để test UI (Thực tế nên dùng Cloud Functions)
      await Future.delayed(const Duration(milliseconds: 1000));

      Map<String, int> mentionCounts = {
        'Rầy nâu (Lúa)': 145,
        'Xì mủ thân (Sầu riêng)': 320,
        'Sâu đục thân (Cà phê)': 89,
        'Đạo ôn (Lúa)': 210,
        'Rệp sáp (Cà phê)': 56,
      };

      List<Map<String, dynamic>> results = mentionCounts.entries
          .map((e) => {'name': e.key, 'mentions': e.value})
          .toList();

      // Sắp xếp: Đề cập NHIỀU NHẤT nằm ở DƯỚI CÙNG
      results.sort((a, b) => (a['mentions'] as int).compareTo(b['mentions'] as int));

      return results;
    } catch (e) {
      print("Lỗi tổng hợp dữ liệu: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // Thay bằng AppColors.cardBg
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Tần Suất Đề Cập Sâu Bệnh',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), // Thay bằng AppTextStyles.heading3
                    overflow: TextOverflow.ellipsis
                ),
              ),
              Tooltip(
                message: 'Dữ liệu tổng hợp từ Bài viết, Lịch sử AI, Chat & Lịch hẹn',
                child: Icon(Icons.info_outline, color: Colors.grey[400], size: 20),
              )
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _mentionsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data ?? [];
                if (data.isEmpty) {
                  return const Center(child: Text('Chưa có dữ liệu.'));
                }

                // Tìm giá trị max để tính toán tỷ lệ chiều dài cột
                double maxMentions = data.map((e) => (e['mentions'] as num).toDouble()).reduce(math.max);

                return ListView.builder(
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return _buildHorizontalBarRow(
                      name: item['name'],
                      value: item['mentions'],
                      maxValue: maxMentions,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget Biểu đồ cột ngang (Horizontal Bar)
  Widget _buildHorizontalBarRow({
    required String name,
    required int value,
    required double maxValue,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Trục Y: Tên bệnh
          SizedBox(
            width: 120, // Cố định chiều rộng cho tên để các cột bắt đầu cùng 1 điểm
            child: Text(
              name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 12),

          // Trục X: Cột ngang (Bar)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Trừ không gian cho text hiển thị số liệu phía sau (khoảng 40px)
                double availableWidth = constraints.maxWidth - 40;
                double barWidth = maxValue > 0 ? (value / maxValue) * availableWidth : 0;

                return Row(
                  children: [
                    // Thanh cột ngang
                    Container(
                      height: 16, // Độ dày của cột
                      width: barWidth,
                      decoration: BoxDecoration(
                        color: Colors.green, // Thay bằng AppColors.primary
                        borderRadius: BorderRadius.circular(4), // Bo góc cho đẹp
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Con số hiển thị
                    Text(
                      '$value',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
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