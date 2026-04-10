import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: TabBarView(
          children: [
            _BusinessOverviewTab(
              future: _businessFuture,
              alertsFuture: _alertsFuture,
              insightsFuture: _insightsFuture,
              onRefresh: _refreshData,
            ),
            _AgriExpertTab(
              future: _agriFuture,
            ),
            _AISystemTab(
              stream: _aiStream,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Text(
        "Reports & Statistics",
        style: GoogleFonts.inter(
          color: AppColors.textHeading,
          fontWeight: FontWeight.bold,
          fontSize: 24,
        ),
      ),
      actions: [
        _buildExportButton(),
        const SizedBox(width: 16),
        _buildFilterCluster(),
        const SizedBox(width: 24),
      ],
      bottom: TabBar(
        isScrollable: true,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.primary,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        tabs: const [
          Tab(text: "Business Overview"),
          Tab(text: "Agriculture & Experts"),
          Tab(text: "Users & AI System"),
        ],
      ),
    );
  }

  Widget _buildExportButton() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: PopupMenuButton<String>(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi xuất dữ liệu: $e")),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Widget _buildFilterCluster() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.filter_list, size: 20),
            onPressed: () {},
            tooltip: "Advanced Filters",
          ),
          const VerticalDivider(width: 1, indent: 8, endIndent: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              "Last 30 Days",
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textHeading),
            ),
          ),
        ],
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildAIInsightTop(),
              const SizedBox(height: 24),
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
                            labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: RankingList(
                            title: "Top Products (Quantity)",
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
                        labels: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"],
                      ),
                      const SizedBox(height: 24),
                      RankingList(
                        title: "Top Products (Quantity)",
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
      padding: const EdgeInsets.all(24),
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

  Widget _buildAIInsightTop() {
    return Column(
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: insightsFuture,
          builder: (context, snapshot) {
            final insights = snapshot.data ?? [];
            if (insights.isEmpty) return const SizedBox.shrink();
            
            final latest = insights.first;
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "AI Analysis: ${latest['content'] ?? 'No recent insights available.'}",
                      style: GoogleFonts.inter(color: Colors.blue[900], fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: alertsFuture,
          builder: (context, snapshot) {
            final alerts = snapshot.data ?? [];
            if (alerts.isEmpty) return const SizedBox.shrink();

            return Column(
              children: alerts.map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
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
                        alert['content'] ?? "Anomaly detected.",
                        style: GoogleFonts.inter(color: Colors.orange[900], fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              )).toList(),
            );
          },
        ),
      ],
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
              title: "Total Revenue",
              value: "${(data['totalRevenue'] ?? 0).toInt()} đ",
              subtitle: "All-time accumulated value",
              trend: "↑ 12.5%",
              isPositive: true,
              icon: Icons.payments_outlined,
              iconColor: AppColors.primary,
              onTap: () => context.push('/finance'),
            ),
            ReportKPICard(
              title: "Today's Orders",
              value: "${data['todayOrders'] ?? 0}",
              subtitle: "Orders placed since midnight",
              trend: "↑ 4.2%",
              isPositive: true,
              icon: Icons.shopping_basket_outlined,
              iconColor: Colors.blue,
              onTap: () => context.push('/orders'),
            ),
            ReportKPICard(
              title: "Volume",
              value: "${data['totalOrders'] ?? 0}",
              subtitle: "Total lifetime orders count",
              trend: "Stable",
              isPositive: true,
              icon: Icons.inventory_2_outlined,
              iconColor: Colors.orange,
              onTap: () => context.push('/products'),
            ),
            ReportKPICard(
              title: "Today Revenue",
              value: "${(data['todayRevenue'] ?? 0).toInt()} đ",
              subtitle: "Real-time earnings today",
              trend: "Live",
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
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: ReportKPICard(
                      title: "Consultant Appointments",
                      value: "${data['totalAppointments']}",
                      subtitle: "Scheduled expert sessions",
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
                      title: "Active Experts",
                      value: "${data['activeExperts']}",
                      subtitle: "Verified agriculture specialists",
                      trend: "Stable",
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
          padding: const EdgeInsets.all(24),
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
                      title: "Success Rate",
                      value: "${(data['successRate'] ?? 0.0).toString()}%",
                      subtitle: "AI questions correctly processed",
                      trend: "Target > 90%",
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
                      title: "Popular Topic Queries",
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
