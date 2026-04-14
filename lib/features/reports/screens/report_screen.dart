import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:admin_daklak_web/features/reports/services/report_service.dart';
import 'package:admin_daklak_web/features/reports/services/export_service.dart';
import 'package:admin_daklak_web/features/reports/widgets/report_skeleton.dart';
import 'package:admin_daklak_web/features/reports/widgets/report_widgets.dart';
import 'package:admin_daklak_web/features/reports/widgets/report_charts.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final ReportService _reportService = ReportService();
  final ExportService _exportService = ExportService();
  
  bool _isExporting = false;
  late Future<Map<String, dynamic>> _businessFuture;
  late Future<Map<String, dynamic>> _agriFuture;
  late Stream<Map<String, dynamic>> _aiStream;
  late Future<List<Map<String, dynamic>>> _alertsFuture;
  late Future<List<Map<String, dynamic>>> _insightsFuture;
  int _selectedTabIndex = 0;
  bool _isSidebarExpanded = true;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _businessFuture = _reportService.getBusinessOverview();
      _agriFuture = _reportService.getAgriExpertStats();
      _aiStream = _reportService.getAISystemStatsStream();
      _alertsFuture = _reportService.getLatestAlerts();
      _insightsFuture = _reportService.getLatestInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    // isDark removed as it was unused locally
    return Container(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Title and Stacked Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 32, 0), // Adjusted to align with Dashboard standards
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Báo cáo & Thống kê',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32, // HeadlineLarge standard
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Phân tích và theo dõi hiệu suất hoạt động toàn diện của hệ thống',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFilterCluster(),
                    const SizedBox(width: 12),
                    _buildExportButton(),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12), // Sitting tight with the subtitle

          // Main Sidebar + Content Row
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ReportSidebar(
                  selectedIndex: _selectedTabIndex,
                  isExpanded: _isSidebarExpanded,
                  onSelected: (index) => setState(() => _selectedTabIndex = index),
                  onToggle: () => setState(() => _isSidebarExpanded = !_isSidebarExpanded),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 24, right: 32),
                    child: _buildTabContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTabIndex) {
      case 0:
        return _BusinessOverviewTab(
          future: _businessFuture,
          alertsFuture: _alertsFuture,
          insightsFuture: _insightsFuture,
          onRefresh: _refreshData,
        );
      case 1:
        return _AgriExpertTab(
          future: _agriFuture,
        );
      case 2:
        return _AISystemTab(
          stream: _aiStream,
        );
      default:
        return const SizedBox.shrink();
    }
  }



  Widget _buildExportButton() {
    return PopupMenuButton<String>(
      onSelected: _handleExport,
      enabled: !_isExporting,
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'orders', child: Text("Xuất Đơn Hàng")),
        const PopupMenuItem(value: 'expenses', child: Text("Xuất Chi Phí")),
        const PopupMenuItem(value: 'all', child: Text("Xuất Tất Cả")),
      ],
      child: OutlinedButton.icon(
        onPressed: null, // Disabled because PopupMenuButton handles tap
        icon: _isExporting 
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.download, size: 18),
        label: Text(_isExporting ? "Đang xuất..." : "Xuất File"),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          disabledForegroundColor: AppColors.primary,
        ),
      ),
    );
  }

  Future<void> _handleExport(String type) async {
    setState(() => _isExporting = true);
    try {
      if (type == 'orders' || type == 'all') {
        final orders = await _reportService.fetchAllOrders();
        _exportService.exportOrdersToCsv(orders);
      }
      
      if (type == 'expenses' || type == 'all') {
        final expenses = await _reportService.fetchAllExpenses();
        _exportService.exportExpensesToCsv(expenses);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Xuất dữ liệu thành công!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi xuất dữ liệu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildFilterCluster() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.filter_list, size: 20),
              onPressed: () {},
              tooltip: "Bộ lọc nâng cao",
            ),
            const VerticalDivider(width: 1, indent: 8, endIndent: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "30 ngày qua",
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Tab 1: Business Overview ---

class _BusinessOverviewTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  final Future<List<Map<String, dynamic>>> alertsFuture;
  final Future<List<Map<String, dynamic>>> insightsFuture;
  final VoidCallback onRefresh;

  const _BusinessOverviewTab({
    required this.future,
    required this.alertsFuture,
    required this.insightsFuture,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        final data = snapshot.data ?? {};
        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              _buildAlertsSection(),
              _buildKPIGrid(data),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth > 1000) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          flex: 2,
                          child: TrendLineChart(
                            spots: [
                               FlSpot(0, 1200000), FlSpot(1, 1500000), 
                               FlSpot(2, 1100000), FlSpot(3, 1800000), 
                               FlSpot(4, 2100000), FlSpot(5, 1900000), 
                               FlSpot(6, 2500000)
                            ],
                            maxY: 2500000,
                            labels: ["Th 2", "Th 3", "Th 4", "Th 5", "Th 6", "Th 7", "CN"],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: RankingList(
                            title: "Top sản phẩm (Số lượng)",
                            items: data['topProducts'] ?? [],
                          ),
                        ),
                      ],
                    );
                  }
                  return Column(
                    children: [
                      const TrendLineChart(
                        spots: [
                           FlSpot(0, 1200000), FlSpot(1, 1500000), 
                           FlSpot(2, 1100000), FlSpot(3, 1800000), 
                           FlSpot(4, 2100000), FlSpot(5, 1900000), 
                           FlSpot(6, 2500000)
                        ],
                        maxY: 2500000,
                        labels: ["Th 2", "Th 3", "Th 4", "Th 5", "Th 6", "Th 7", "CN"],
                      ),
                      const SizedBox(height: 24),
                      RankingList(
                        title: "Top sản phẩm (Số lượng)",
                        items: data['topProducts'] ?? [],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(child: ReportSkeletonCard()),
              SizedBox(width: 24),
              Expanded(child: ReportSkeletonCard()),
            ],
          ),
          const SizedBox(height: 24),
          const SkeletonContainer(width: double.infinity, height: 300),
        ],
      ),
    );
  }

  // _buildAIInsightTop was removed, replaced with _buildAlertsSection
  Widget _buildAlertsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: alertsFuture,
      builder: (context, snapshot) {
        final alerts = snapshot.data ?? [];
        if (alerts.isEmpty) return const SizedBox.shrink();

        return Column(
          children: alerts.map((alert) => Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    alert['content'] ?? "Đã phát hiện bất thường.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.orange[900],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )).toList(),
        );
      },
    );
  }

  Widget _buildKPIGrid(Map<String, dynamic> data) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 1.6,
          children: [
            ReportKPICard(
              title: "Tổng doanh thu",
              value: "${(data['totalRevenue'] ?? 0).toInt()} đ",
              subtitle: "Giá trị tích lũy toàn thời gian",
              trend: "↑ 12.5%",
              isPositive: true,
              icon: Icons.payments_outlined,
              iconColor: AppColors.primary,
              onTap: () => context.push('/finance'),
            ),
            ReportKPICard(
              title: "Đơn hàng hôm nay",
              value: "${data['todayOrders'] ?? 0}",
              subtitle: "Số đơn hàng mới từ 0h sáng",
              trend: "↑ 4.2%",
              isPositive: true,
              icon: Icons.shopping_basket_outlined,
              iconColor: Colors.blue,
              onTap: () => context.push('/orders'),
            ),
            ReportKPICard(
              title: "Sản lượng",
              value: "${data['totalOrders'] ?? 0}",
              subtitle: "Tổng số lượng đơn hàng tích lũy",
              trend: "Ổn định",
              isPositive: true,
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.orange,
              onTap: () => context.push('/products'),
            ),
            ReportKPICard(
              title: "Doanh thu hôm nay",
              value: "${(data['todayRevenue'] ?? 0).toInt()} đ",
              subtitle: "Thu nhập thực tế trong ngày",
              trend: "Trực tiếp",
              isPositive: true,
              icon: Icons.trending_up,
              iconColor: Colors.teal,
              onTap: () => context.push('/finance'),
            ),
          ],
        );
      },
    );
  }
}

// --- Tab 2: Agri & Experts (Simulated Real Data) ---

class _AgriExpertTab extends StatelessWidget {
  final Future<Map<String, dynamic>> future;
  const _AgriExpertTab({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportKPICard(
                      title: "Lịch hẹn tư vấn",
                      value: "${data['totalAppointments']}",
                      subtitle: "Buổi làm việc với chuyên gia",
                      trend: "↑ 8%",
                      isPositive: true,
                      icon: Icons.event,
                      iconColor: Colors.blue,
                      onTap: () => context.push('/appointments'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ReportKPICard(
                      title: "Chuyên gia hoạt động",
                      value: "${data['activeExperts']}",
                      subtitle: "Chuyên gia nông nghiệp đã xác minh",
                      trend: "Ổn định",
                      isPositive: true,
                      icon: Icons.verified,
                      iconColor: AppColors.primary,
                      onTap: () => context.push('/users'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const AgriPriceChart(),
            ],
          ),
        );
      },
    );
  }
}

// --- Tab 3: Users & AI System (Live Logs) ---

class _AISystemTab extends StatelessWidget {
  final Stream<Map<String, dynamic>> stream;
  const _AISystemTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final data = snapshot.data ?? {
          'fallbackPercent': 0.0,
          'totalQuestions': 0,
          'successRate': 100.0,
          'popularQuestions': [],
        };

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: AIHealthCard(
                      fallbackPercent: (data['fallbackPercent'] as num?)?.toDouble() ?? 0.0,
                      totalQuestions: data['totalQuestions'] ?? 0,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 1,
                    child: ReportKPICard(
                      title: "Tỷ lệ thành công",
                      value: "${(data['successRate'] ?? 0.0).toString()}%",
                      subtitle: "Câu hỏi AI được xử lý đúng",
                      trend: "Mục tiêu > 90%",
                      isPositive: (data['successRate'] ?? 0.0) >= 90,
                      icon: Icons.check_circle_outline,
                      iconColor: Colors.teal,
                      onTap: () => context.push('/ai-logs'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 1,
                    child: RankingList(
                      title: "Chủ đề truy vấn phổ biến",
                      items: data['popularQuestions'] ?? [],
                    ),
                  ),
                  const SizedBox(width: 24),
                  const Expanded(
                    flex: 1,
                    child: SizedBox(), // Empty space for balanced layout
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// --- Sidebar Widgets ---

class _ReportSidebar extends StatelessWidget {
  final int selectedIndex;
  final bool isExpanded;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggle;

  const _ReportSidebar({
    required this.selectedIndex,
    required this.isExpanded,
    required this.onSelected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final List<Map<String, dynamic>> items = [
      {'icon': Icons.analytics_rounded, 'label': 'Tổng quan kinh doanh'},
      {'icon': Icons.agriculture_rounded, 'label': 'Nông nghiệp & Chuyên gia'},
      {'icon': Icons.psychology_rounded, 'label': 'Người dùng & Hệ thống AI'},
    ];

    const itemHeight = 48.0;

    final sidebarWidth = isExpanded ? 260.0 : 88.0;

    return Transform.translate(
      offset: const Offset(-40, 0), // Increased overlap to fully cover main sidebar's rounded edge
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: sidebarWidth + 40, // Increased width to compensate for the overlap
        margin: const EdgeInsets.fromLTRB(0, 0, 0, 24), // Edge-to-edge body proximity (0 spacing)
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC1E2538) : Colors.white.withValues(alpha: 0.75),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ), 
          border: Border.all(
            color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 40), // Push content back to visible area
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isExpanded ? 1.0 : 0.0,
                  child: isExpanded ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Text(
                      'DANH MỤC',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                        color: Theme.of(context).textTheme.bodySmall?.color,
                      ),
                    ),
                  ) : const SizedBox(height: 12),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Stack(
                    children: [
                      // Moving Pill Indicator
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeInOutCubic,
                        top: selectedIndex * (itemHeight + 8),
                        left: 0,
                        right: 0,
                        height: itemHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.primary.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                      ),
                      
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _ReportSidebarTile(
                            icon: items[index]['icon'],
                            label: items[index]['label'],
                            isSelected: selectedIndex == index,
                            isExpanded: isExpanded,
                            onTap: () => onSelected(index),
                            height: itemHeight,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _ReportCollapseToggle(
                isExpanded: isExpanded,
                onTap: onToggle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportCollapseToggle extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onTap;

  const _ReportCollapseToggle({
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03);
    final fgColor = Theme.of(context).textTheme.bodySmall?.color;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(100),
        child: Container(
          height: 48,
          width: double.infinity,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(100), // Pill toggle 100%
          ),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isExpanded ? Icons.keyboard_arrow_left_rounded : Icons.keyboard_arrow_right_rounded,
                key: ValueKey(isExpanded),
                size: 20,
                color: fgColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}


class _ReportSidebarTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;
  final double height;

  const _ReportSidebarTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
    required this.height,
  });

  @override
  State<_ReportSidebarTile> createState() => _ReportSidebarTileState();
}

class _ReportSidebarTileState extends State<_ReportSidebarTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final activeColor = AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(100), // Pill shape 100%
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: widget.height,
          padding: EdgeInsets.symmetric(horizontal: widget.isExpanded ? 16 : 0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            color: _isHovered && !isSelected
                ? (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03))
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 20,
                color: isSelected ? activeColor : Theme.of(context).textTheme.bodySmall?.color,
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
