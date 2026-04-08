import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AgriculturalPriceDashboard extends StatefulWidget {
  const AgriculturalPriceDashboard({Key? key}) : super(key: key);

  @override
  State<AgriculturalPriceDashboard> createState() => _AgriculturalPriceDashboardState();
}

class _AgriculturalPriceDashboardState extends State<AgriculturalPriceDashboard> {
  // --- MÀU SẮC THEO MOCKUP ---
  final Color _bgColor = const Color(0xFFF8F9FA);
  final Color _cardColor = Colors.white;
  final Color _darkGreen = const Color(0xFF1B4332);
  final Color _lightGreen = const Color(0xFFE8F5E9);
  final Color _textMain = const Color(0xFF2D3748);
  final Color _textMuted = const Color(0xFF718096);
  final Color _borderColor = const Color(0xFFE2E8F0);

  // --- Filter & Sort State ---
  String _selectedProductFilter = 'Tất cả';
  String _selectedPriceSort = 'Mặc định (Giá)';
  String _selectedDateSort = 'Mới nhất';
  int _currentPage = 1; // Thêm biến lưu trang hiện tại

  // --- Chart & Forecast State ---
  bool _isChartLoading = true;
  String _selectedChartFilter = '7 Ngày';
  String _selectedProductChart = 'Cà Phê';
  List<FlSpot> _chartSpots = [];
  List<DateTime> _chartDates = [];

  Map<String, dynamic> _trendForecast = {
    'day3': 0.0,
    'trend': '',
  };

  @override
  void initState() {
    super.initState();
    _fetchChartAndForecastData(_selectedProductChart, _selectedChartFilter);
  }

  // --- LẤY DỮ LIỆU BIỂU ĐỒ & DỰ BÁO ---
  Future<void> _fetchChartAndForecastData(String product, String timeFilter) async {
    setState(() => _isChartLoading = true);
    String docId = product == 'Cà Phê' ? 'Coffee' : (product == 'Hồ Tiêu' ? 'Pepper' : 'Durian');

    try {
      int limitDays = timeFilter == '7 Ngày' ? 7 : (timeFilter == '30 Ngày' ? 30 : 90);
      QuerySnapshot historySnap = await FirebaseFirestore.instance
          .collection('Price').doc(docId).collection('History')
          .limit(limitDays).get();

      List<FlSpot> spots = [];
      List<DateTime> dates = [];

      var docs = historySnap.docs.toList();
      docs.sort((a, b) => a.id.compareTo(b.id));

      for (int i = 0; i < docs.length; i++) {
        var doc = docs[i];
        DateTime date;
        try { date = DateTime.parse(doc.id); } catch (_) { continue; }

        double avgPrice = 0;
        var dataList = (doc.data() as Map<String, dynamic>)['data'] ?? [];

        if (dataList is List && dataList.isNotEmpty) {
          if (product == 'Sầu Riêng') {
            avgPrice = _parsePriceHelper(dataList[0]['Khu vực - Miền Tây Nam bộ'] ?? dataList[0]['Khu vực-Miền Tây Nam bộ']);
          } else {
            avgPrice = _parsePriceHelper(dataList[0]['price']);
          }
        }

        if (avgPrice > 0) {
          spots.add(FlSpot(i.toDouble(), avgPrice));
          dates.add(date);
        }
      }

      DocumentSnapshot forecastDoc = await FirebaseFirestore.instance
          .collection('Price').doc(docId).collection('Forecast').doc('latest').get();

      Map<String, dynamic> forecastDataObj = {'day3': 0.0, 'trend': ''};
      if (forecastDoc.exists) {
        var forecastData = (forecastDoc.data() as Map<String, dynamic>)['data'] ?? {};
        if (forecastData.isNotEmpty) {
          var firstForecast = forecastData.values.first;
          forecastDataObj = {
            'day3': double.tryParse(firstForecast['day_3'].toString()) ?? 0.0,
            'trend': firstForecast['trend_desc'] ?? '',
          };
        }
      }

      if (mounted) {
        setState(() {
          _chartSpots = spots;
          _chartDates = dates;
          _trendForecast = forecastDataObj;
          _isChartLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi fetch Chart/Forecast: $e");
      if (mounted) setState(() => _isChartLoading = false);
    }
  }

  // --- HELPERS ---
  double _parsePriceHelper(dynamic priceRaw) {
    if (priceRaw == null || priceRaw.toString().isEmpty) return 0;
    String cleanStr = priceRaw.toString().replaceAll(RegExp(r'[^0-9\-]'), '');
    if (cleanStr.contains('-')) {
      try {
        var parts = cleanStr.split('-');
        return (double.parse(parts[0].trim()) + double.parse(parts[1].trim())) / 2;
      } catch (_) { return 0; }
    }
    return double.tryParse(cleanStr) ?? 0;
  }

  String _formatDateString(dynamic isoString) {
    if (isoString == null || isoString.toString().isEmpty) return '';
    try {
      final dateTime = DateTime.parse(isoString.toString()).toLocal();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')} - ${dateTime.day}/${dateTime.month}';
    } catch (_) {
      return isoString.toString();
    }
  }

  String _getStatusFromChange(String change) {
    if (change.isEmpty) return '';
    if (change.toLowerCase().contains('không đổi')) return 'Ổn định';
    if (change.contains('+')) {
      double? val = double.tryParse(change.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (val != null && val > 5.0) return 'Tăng mạnh';
      return 'Tăng nhẹ';
    } else if (change.contains('-')) {
      double? val = double.tryParse(change.replaceAll(RegExp(r'[^0-9.]'), ''));
      if (val != null && val > 5.0) return 'Giảm mạnh';
      return 'Giảm nhẹ';
    }
    return 'Ổn định';
  }

  // =======================================================================
  // ========================= UI RENDER ===================================
  // =======================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('Price').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu'));
            }

            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Center(child: CircularProgressIndicator(color: _darkGreen));
            }

            Map<String, Map<String, dynamic>> kpiData = {
              'Cà Phê': {'price': '', 'change': ''},
              'Hồ Tiêu': {'price': '', 'change': ''},
              'Sầu Riêng': {'price': '', 'change': ''},
            };
            List<Map<String, dynamic>> allRows = [];
            Set<String> dynamicCrops = {};
            String globalLastUpdated = 'Đang tải...';

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                if (docData['updated_at'] != null) {
                  globalLastUpdated = _formatDateString(docData['updated_at']);
                  break;
                }
              }

              for (var doc in snapshot.data!.docs) {
                String cropId = doc.id;
                Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
                List<dynamic> dataList = docData['latest_data'] ?? [];

                String rawUpdate = docData['updated_at']?.toString() ?? '';
                String updated = _formatDateString(rawUpdate);

                String cropName = cropId == 'Coffee' ? 'Cà Phê' : (cropId == 'Pepper' ? 'Hồ Tiêu' : (cropId == 'Durian' ? 'Sầu Riêng' : cropId));
                dynamicCrops.add(cropName);

                if (cropId == 'Durian') {
                  if (dataList.isNotEmpty) {
                    var firstEntry = dataList[0] as Map<String, dynamic>;
                    String firstPrice = firstEntry.values.firstWhere(
                            (v) => v != null && v.toString().contains(RegExp(r'[0-9]')),
                        orElse: () => ''
                    ).toString();
                    kpiData['Sầu Riêng'] = {'price': firstPrice, 'change': 'Không đổi'};
                  }

                  for (var item in dataList) {
                    String subType = item['sub_type']?.toString() ?? item['loai']?.toString() ?? '';
                    bool hasKeys = false;
                    item.forEach((key, value) {
                      if (key != 'loai' && key != 'sub_type' && value != null && value.toString().contains(RegExp(r'[0-9]'))) {
                        allRows.add({
                          'region': '',
                          'name': cropName,
                          'sub_type': subType,
                          'price': value.toString(),
                          'change': 'Không đổi',
                          'update': updated,
                          'raw_date': rawUpdate,
                          'status': 'Ổn định',
                        });
                        hasKeys = true;
                      }
                    });
                    if (!hasKeys && item.containsKey('price')) {
                      allRows.add({
                        'region': '',
                        'name': cropName,
                        'sub_type': subType,
                        'price': item['price']?.toString() ?? '',
                        'change': item['change']?.toString() ?? '',
                        'update': updated,
                        'raw_date': rawUpdate,
                        'status': _getStatusFromChange(item['change']?.toString() ?? ''),
                      });
                    }
                  }
                } else {
                  if (dataList.isNotEmpty) {
                    kpiData[cropName] = {
                      'price': dataList[0]['price']?.toString() ?? '',
                      'change': dataList[0]['change']?.toString() ?? ''
                    };
                  }

                  for (var item in dataList) {
                    String changeVal = item['change']?.toString() ?? '';
                    allRows.add({
                      'region': item['location']?.toString() ?? '',
                      'name': cropName,
                      'sub_type': item['sub_type']?.toString() ?? '',
                      'price': item['price']?.toString() ?? '',
                      'change': changeVal,
                      'update': updated,
                      'raw_date': rawUpdate,
                      'status': _getStatusFromChange(changeVal),
                    });
                  }
                }
              }
            }

            // LỌC & SẮP XẾP
            List<Map<String, dynamic>> processedTableData = allRows.where((row) {
              if (_selectedProductFilter == 'Tất cả') return true;
              return row['name'].toString().contains(_selectedProductFilter);
            }).toList();

            processedTableData.sort((a, b) {
              if (_selectedPriceSort != 'Mặc định (Giá)') {
                double priceA = _parsePriceHelper(a['price']);
                double priceB = _parsePriceHelper(b['price']);
                int priceComp = priceA.compareTo(priceB);
                if (priceComp != 0) {
                  return _selectedPriceSort == 'Giá tăng dần' ? priceComp : -priceComp;
                }
              }
              String dateA = a['raw_date']?.toString() ?? '';
              String dateB = b['raw_date']?.toString() ?? '';
              int dateComp = dateA.compareTo(dateB);
              return _selectedDateSort == 'Mới nhất' ? -dateComp : dateComp;
            });

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quản lý Giá Nông Sản', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A202C))),
                  const SizedBox(height: 24),
                  _buildKPIRow(kpiData),
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildMainChart()),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTrendForecast(),
                            const SizedBox(height: 24),
                            _buildTopMovers(allRows),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // GỌI HÀM BẢNG CUSTOM
                  _buildCustomTableSection(processedTableData, dynamicCrops.toList(), globalLastUpdated),
                ],
              ),
            );
          }
      ),
    );
  }

  // --- CÁC WIDGET PHÍA TRÊN GIỮ NGUYÊN ---
// --- (A) KPI ROW ---
// --- (A) KPI ROW ---
  Widget _buildKPIRow(Map<String, Map<String, dynamic>> kpiData) {
    return Row(
      children: [
        // Cà phê -> Màu Nâu (Colors.brown)
        Expanded(child: _buildKPICard('Cà phê', kpiData['Cà Phê']?['price'], kpiData['Cà Phê']?['change'], Icons.coffee, Colors.brown)),
        const SizedBox(width: 20),

        // Hồ tiêu -> Màu Xanh lá (Colors.green[700])
        Expanded(child: _buildKPICard('Hồ tiêu', kpiData['Hồ Tiêu']?['price'], kpiData['Hồ Tiêu']?['change'], Icons.eco, Colors.green[700]!)),
        const SizedBox(width: 20),

        // Sầu riêng -> Màu Cam Vàng (Colors.orange[600])
        Expanded(child: _buildKPICard('Sầu riêng', kpiData['Sầu Riêng']?['price'], kpiData['Sầu Riêng']?['change'], Icons.brightness_high, Colors.orange[600]!)),
      ],
    );
  }

  Widget _buildKPICard(String title, String? value, String? change, IconData topIcon, Color iconColor) {
    bool isEmpty = (value == null || value.isEmpty);
    bool isUp = (change ?? '').contains('+');
    bool isDown = (change ?? '').contains('-');
    bool isFlat = !isUp && !isDown;

    Color changeColor = isFlat ? _textMuted : (isUp ? _darkGreen : Colors.red);
    IconData? changeIcon = isFlat ? null : (isUp ? Icons.trending_up : Icons.trending_down);

    return Container(
      height: 145, // 1. Tăng nhẹ chiều cao để không gian thở thoải mái hơn
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // 2. Tối ưu lại padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 3. Dùng spaceBetween để tự cân đối khoảng cách
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(title, style: TextStyle(color: _textMuted, fontSize: 13, fontWeight: FontWeight.w500)),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(topIcon, size: 20, color: iconColor),
              ),
            ],
          ),

          // 4. Bọc giá tiền để đảm bảo không lấn chiếm không gian quá mức
          Flexible(
            child: Text(
              isEmpty ? '--' : '$value đ/kg',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _textMain),
              overflow: TextOverflow.ellipsis, // Tránh tràn nếu số quá dài
            ),
          ),

          if (!isEmpty && (change ?? '').isNotEmpty)
            Row(
              children: [
                if (changeIcon != null) ...[
                  Icon(changeIcon, color: changeColor, size: 14),
                  const SizedBox(width: 4),
                ],
                Expanded( // 5. Để text thay đổi tự do xuống dòng hoặc thu nhỏ nếu cần
                  child: Text(
                    isFlat ? '— Không đổi' : change!,
                    style: TextStyle(color: changeColor, fontWeight: FontWeight.w600, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

// --- (B) BIỂU ĐỒ CHÍNH ---
  Widget _buildMainChart() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
          color: _cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Biểu đồ giá trung bình theo\nthời gian', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textMain, height: 1.3)),
                  const SizedBox(height: 8),
                  Text('Dữ liệu thị trường ${_selectedProductChart.toLowerCase()} toàn vùng', style: TextStyle(fontSize: 13, color: _textMuted)),
                ],
              ),
              Row(
                children: [
                  Container(
                    height: 40, padding: const EdgeInsets.symmetric(horizontal: 16), decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProductChart, icon: const Icon(Icons.keyboard_arrow_down, size: 18), style: TextStyle(color: _textMain, fontWeight: FontWeight.w600, fontSize: 13),
                        items: <String>['Cà Phê', 'Hồ Tiêu', 'Sầu Riêng'].map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
                        onChanged: (newValue) {
                          if (newValue != null && newValue != _selectedProductChart) {
                            setState(() => _selectedProductChart = newValue);
                            _fetchChartAndForecastData(newValue, _selectedChartFilter);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    height: 40, decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: ['7 Ngày', '30 Ngày', '3 Tháng'].map((time) {
                        bool isSelected = _selectedChartFilter == time;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedChartFilter = time);
                            _fetchChartAndForecastData(_selectedProductChart, time);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16), alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? _darkGreen : Colors.transparent, borderRadius: BorderRadius.circular(20)),
                            child: Text(time, style: TextStyle(color: isSelected ? Colors.white : _textMuted, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, fontSize: 12)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 40),
          Expanded(
            child: _isChartLoading
                ? Center(child: CircularProgressIndicator(color: _darkGreen))
                : _chartSpots.isEmpty
                ? Center(child: Text("Chưa đủ dữ liệu lịch sử", style: TextStyle(color: _textMuted)))
                : LineChart(
              LineChartData(
                // 1. HIỂN THỊ LƯỚI NGANG (GRID LÀM NỀN)
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.15),
                      strokeWidth: 1,
                      dashArray: [5, 5], // Lưới đứt nét cho thanh lịch
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true, reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index < 0 || index >= _chartDates.length) return const SizedBox();
                          if (index != 0 && index != _chartDates.length - 1 && index % (_chartDates.length ~/ 4) != 0) return const SizedBox();
                          String text = DateFormat('dd/MM').format(_chartDates[index]);
                          if (index == _chartDates.length - 1) text = 'Hôm\nnay';
                          return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(text, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: _textMuted, fontWeight: index == _chartDates.length -1 ? FontWeight.bold : FontWeight.normal)));
                        },
                      )
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                      spots: _chartSpots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: _darkGreen,
                      barWidth: 4, // 2. LÀM ĐƯỜNG DÀY HƠN
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      // 3. ĐỔ BÓNG CHO ĐƯỜNG LINE
                      shadow: Shadow(
                        color: _darkGreen.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                      // 4. MÀU GRADIENT DƯỚI BIỂU ĐỒ
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            _darkGreen.withOpacity(0.25), // Đậm ở trên
                            _darkGreen.withOpacity(0.0),  // Mờ dần xuống dưới
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      )
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendForecast() {
    bool isIncrease = _trendForecast['trend'].toString().contains('tăng');
    bool isEmpty = _trendForecast['trend'].toString().isEmpty;

    return Container(
      height: 140, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned(right: -10, bottom: -10, child: Icon(Icons.bar_chart, size: 80, color: Colors.white.withOpacity(0.1))),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(children: [const Icon(Icons.auto_awesome, color: Colors.white, size: 20), const SizedBox(width: 8), Text('Dự báo Xu hướng: $_selectedProductChart', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))]),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dự báo 3 ngày', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(isEmpty ? '--' : '${NumberFormat('#,###').format(_trendForecast['day3'])}đ', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Xu hướng', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(isEmpty ? '--' : _trendForecast['trend'].toString().toUpperCase(), style: TextStyle(color: isIncrease ? Colors.greenAccent : Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopMovers(List<Map<String, dynamic>> allData) {
    var validData = allData.where((e) => !e['change'].toLowerCase().contains('không đổi') && e['change'] != '0.0%' && e['change'] != '0%' && e['change'].toString().isNotEmpty).toList();
    validData.sort((a, b) {
      double valA = double.tryParse(a['change'].replaceAll('%', '').replaceAll('+', '')) ?? 0;
      double valB = double.tryParse(b['change'].replaceAll('%', '').replaceAll('+', '')) ?? 0;
      return valB.compareTo(valA);
    });

    var topTang = validData.where((e) => e['change'].contains('+')).take(2).toList();
    var topGiam = validData.reversed.where((e) => e['change'].contains('-')).take(1).toList();

    return Container(
      height: 236,
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.arrow_upward, size: 16, color: _textMuted), const SizedBox(width: 8), Text('Top Tăng Giá (24h)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain))]),
          const SizedBox(height: 16),
          if (topTang.isEmpty) Text('Không có dữ liệu', style: TextStyle(color: _textMuted, fontSize: 13)),
          ...topTang.map((e) => _buildMoverItem(e['name'], e['sub_type'], e['change'], true)),
          const Spacer(),
          Row(children: [Icon(Icons.arrow_downward, size: 16, color: _textMuted), const SizedBox(width: 8), Text('Top Giảm Giá (24h)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _textMain))]),
          const SizedBox(height: 16),
          if (topGiam.isEmpty) Text('Không có dữ liệu', style: TextStyle(color: _textMuted, fontSize: 13)),
          ...topGiam.map((e) => _buildMoverItem(e['name'], e['sub_type'], e['change'], false)),
        ],
      ),
    );
  }

  Widget _buildMoverItem(String name, String subType, String value, bool isUp) {
    String initials = name.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
    Color avatarBg = isUp ? const Color(0xFFC8E6C9) : const Color(0xFFFFCCBC);
    Color avatarText = isUp ? _darkGreen : Colors.red;
    String displaySub = subType.isNotEmpty ? ' ($subType)' : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          CircleAvatar(radius: 16, backgroundColor: avatarBg, child: Text(initials, style: TextStyle(color: avatarText, fontSize: 10, fontWeight: FontWeight.bold))),
          const SizedBox(width: 12),
          Expanded(child: Text('$name$displaySub', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: _textMain), maxLines: 1, overflow: TextOverflow.ellipsis)),
          Text(value, style: TextStyle(color: isUp ? _darkGreen : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildDropdownPill({required String label, required String currentValue, required List<String> options, required Function(String) onSelected}) {
    String displayText = (currentValue == 'Tất cả' || currentValue.contains('Mặc định') || currentValue == 'Mới nhất') ? label : currentValue;
    return PopupMenuButton<String>(
      onSelected: (val) {
        setState(() => _currentPage = 1); // Reset trang về 1 khi chọn filter
        onSelected(val);
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 40),
      itemBuilder: (context) => options.map((choice) => PopupMenuItem<String>(value: choice, child: Text(choice, style: TextStyle(fontWeight: choice == currentValue ? FontWeight.bold : FontWeight.normal, color: choice == currentValue ? _darkGreen : _textMain)))).toList(),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(20)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayText, style: TextStyle(fontWeight: FontWeight.w600, color: _textMain, fontSize: 12)),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down, size: 16, color: _textMuted),
          ],
        ),
      ),
    );
  }

  // ============================================================================
  // HỆ THỐNG BẢNG CUSTOM VÀ PAGINATION MỚI (GIỐNG MOCKUP)
  // ============================================================================
  Widget _buildCustomTableSection(List<Map<String, dynamic>> processedTableData, List<String> dynamicCrops, String lastUpdated) {
    List<String> productFilterOptions = ['Tất cả', ...dynamicCrops];

    // Tính toán số liệu phân trang
    int rowsPerPage = 10;
    int totalItems = processedTableData.length;
    int totalPages = (totalItems / rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage > totalPages) _currentPage = totalPages;

    int startIndex = (_currentPage - 1) * rowsPerPage;
    int endIndex = startIndex + rowsPerPage;
    if (endIndex > totalItems) endIndex = totalItems;

    List<Map<String, dynamic>> currentPageData = processedTableData.isEmpty ? [] : processedTableData.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(color: _cardColor, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Chi Tiết Giá Nông Sản', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _textMain)),
              Row(
                children: [
                  Text('Cập nhật: $lastUpdated', style: TextStyle(color: _textMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  Icon(Icons.refresh, size: 16, color: _textMain),
                ],
              )
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _buildDropdownPill(label: 'Nông sản', currentValue: _selectedProductFilter, options: productFilterOptions, onSelected: (val) => setState(() => _selectedProductFilter = val)),
              _buildDropdownPill(label: 'Giá', currentValue: _selectedPriceSort, options: ['Mặc định (Giá)', 'Giá tăng dần', 'Giá giảm dần'], onSelected: (val) => setState(() => _selectedPriceSort = val)),
              _buildDropdownPill(label: 'Cập nhật', currentValue: _selectedDateSort, options: ['Mới nhất', 'Lâu nhất'], onSelected: (val) => setState(() => _selectedDateSort = val)),
            ],
          ),
          const SizedBox(height: 20),

          // VẼ BẢNG (Màu sắc giống mockup)
          if (currentPageData.isEmpty)
            const Padding(padding: EdgeInsets.all(40.0), child: Center(child: Text("Không có dữ liệu.")))
          else
            SizedBox(
              width: double.infinity,
              child: DataTable(
                headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: _textMuted, fontSize: 11, letterSpacing: 0.5),
                dataRowHeight: 60,
                headingRowHeight: 48,
                horizontalMargin: 0,
                columnSpacing: 20,
                dividerThickness: 0.5,
                columns: const [
                  DataColumn(label: Text('KHU VỰC')),
                  DataColumn(label: Text('NÔNG SẢN')),
                  DataColumn(label: Text('PHÂN LOẠI')),
                  DataColumn(label: Text('GIÁ HIỆN TẠI')),
                  DataColumn(label: Text('THAY ĐỔI')),
                  DataColumn(label: Text('CẬP NHẬT')),
                  DataColumn(label: Text('TRẠNG THÁI')),
                ],
                rows: currentPageData.map((item) => _buildDataRow(item)).toList(),
              ),
            ),

          if (currentPageData.isNotEmpty) ...[
            const SizedBox(height: 20),
            // VẼ THANH PAGINATION GIỐNG MOCKUP
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Hiển thị ${startIndex + 1}-$endIndex của $totalItems khu vực', style: TextStyle(color: _textMuted, fontSize: 13)),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      color: _currentPage > 1 ? _textMain : Colors.grey[300],
                      onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                    ),
                    ..._buildPageNumbers(totalPages),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      color: _currentPage < totalPages ? _textMain : Colors.grey[300],
                      onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                    ),
                  ],
                )
              ],
            )
          ]
        ],
      ),
    );
  }

  // --- HÀM VẼ DÒNG DỮ LIỆU ---
  DataRow _buildDataRow(Map<String, dynamic> item) {
    String change = item['change']?.toString() ?? '';
    bool isUp = change.contains('+');
    bool isFlat = change.isEmpty || change.toLowerCase().contains('không đổi') || change == '0.0%' || change == '0%';
    Color changeColor = isFlat ? _textMuted : (isUp ? _darkGreen : Colors.red);

    String status = item['status']?.toString() ?? '';
    Color badgeBg = isFlat ? Colors.grey[100]! : (status.contains('Tăng') ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE));
    Color badgeText = isFlat ? _textMuted : (status.contains('Tăng') ? _darkGreen : Colors.red[800]!);

    String priceStr = item['price']?.toString() ?? '';
    String formattedPrice = priceStr;
    if (!priceStr.contains('-') && double.tryParse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')) != null) {
      formattedPrice = NumberFormat('#,###').format(double.parse(priceStr.replaceAll(RegExp(r'[^0-9.]'), '')));
    }

    Color dotColor = item['name'].toString().contains('Cà') ? _darkGreen : (item['name'].toString().contains('Sầu') ? Colors.orange[800]! : Colors.brown);

    return DataRow(
      cells: [
        DataCell(Text(item['region'].toString(), style: TextStyle(fontWeight: FontWeight.bold, color: _textMain, fontSize: 13))),
        DataCell(Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            const SizedBox(width: 8),
            Text(item['name'].toString(), style: TextStyle(fontWeight: FontWeight.w600, color: _textMain, fontSize: 13)),
          ],
        )),
        DataCell(Text(item['sub_type'].toString(), style: TextStyle(color: _textMuted, fontSize: 13))),
        DataCell(Text('$formattedPrice đ', style: TextStyle(fontWeight: FontWeight.bold, color: _textMain, fontSize: 13))),
        DataCell(Text(isFlat ? '0 đ' : change, style: TextStyle(color: changeColor, fontWeight: FontWeight.bold, fontSize: 13))),
        DataCell(Text(item['update'].toString(), style: TextStyle(color: _textMuted, fontSize: 12))),
        DataCell(status.isEmpty
            ? const SizedBox()
            : Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeText.withOpacity(0.1))),
          child: Text(status.toUpperCase(), style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold)),
        )
        ),
      ],
    );
  }

  // --- HÀM VẼ SỐ TRANG ---
  List<Widget> _buildPageNumbers(int totalPages) {
    List<Widget> widgets = [];

    void addPage(int page) {
      bool isActive = page == _currentPage;
      widgets.add(GestureDetector(
          onTap: () => setState(() => _currentPage = page),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive ? _darkGreen : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Text('$page', style: TextStyle(color: isActive ? Colors.white : _textMuted, fontWeight: FontWeight.bold, fontSize: 13)),
          )
      ));
    }

    void addDots() {
      widgets.add(Container(margin: const EdgeInsets.symmetric(horizontal: 4), alignment: Alignment.center, child: Text('...', style: TextStyle(color: _textMuted, fontWeight: FontWeight.bold))));
    }

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) addPage(i);
    } else {
      if (_currentPage <= 3) {
        addPage(1); addPage(2); addPage(3); addDots(); addPage(totalPages);
      } else if (_currentPage >= totalPages - 2) {
        addPage(1); addDots(); addPage(totalPages - 2); addPage(totalPages - 1); addPage(totalPages);
      } else {
        addPage(1); addDots(); addPage(_currentPage); addDots(); addPage(totalPages);
      }
    }
    return widgets;
  }
}