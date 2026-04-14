import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common/custom_admin_table.dart';
import '../../../core/widgets/common/custom_admin_badge.dart';
import '../../../core/widgets/common/custom_admin_toolbar.dart';
import '../../../core/widgets/common/custom_admin_pagination.dart';
import '../models/expert_verification_request_model.dart';
import '../services/expert_verification_service.dart';
import '../widgets/expert_request_detail_dialog.dart';

class ExpertVerificationScreen extends StatefulWidget {
  const ExpertVerificationScreen({super.key});

  @override
  State<ExpertVerificationScreen> createState() =>
      _ExpertVerificationScreenState();
}

class _ExpertVerificationScreenState extends State<ExpertVerificationScreen> {
  final ExpertVerificationService _service = ExpertVerificationService();
  
  // State variables for filtering and pagination
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<String> _selectedStatus = ValueNotifier<String>('Tất cả');
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1);
  final int _itemsPerPage = 10;

  @override
  void dispose() {
    _searchQuery.dispose();
    _selectedStatus.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _showDetailDialog(ExpertVerificationRequestModel request) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExpertRequestDetailDialog(
        request: request,
        onProcessed: () {
          // Stream updates automatically
        },
      ),
    );
  }

  void _exportToCsv(List<ExpertVerificationRequestModel> data) {
    String csvString = '\uFEFF"Họ tên","Số điện thoại","Chuyên môn","Trạng thái","Ngày gửi"\n';
    
    for (var item in data) {
      final String statusText = _getStatusText(item.status);
      final String dateText = DateFormat('dd/MM/yyyy').format(item.createdAt);
      final String phoneFormatted = '="""${item.phone}"""';
      
      csvString += '"${item.fullName}",$phoneFormatted,"${item.expertise}","$statusText","$dateText"\n';
    }

    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "danh_sach_chuyen_gia_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải tệp CSV...'), backgroundColor: AppColors.primary),
    );
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return 'Đã duyệt';
      case 'rejected': return 'Đã từ chối';
      default: return 'Chờ duyệt';
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<ExpertVerificationRequestModel>>(
        stream: _service.getAllRequests(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return _buildErrorState(snapshot.error);
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allData = snapshot.data ?? [];

          return ValueListenableBuilder<String>(
            valueListenable: _searchQuery,
            builder: (context, query, _) {
              return ValueListenableBuilder<String>(
                valueListenable: _selectedStatus,
                builder: (context, status, _) {
                  final filteredData = allData.where((item) {
                    final matchesSearch = item.fullName.toLowerCase().contains(query.toLowerCase()) || 
                                         item.expertise.toLowerCase().contains(query.toLowerCase());
                    final matchesStatus = status == 'Tất cả' || _getStatusText(item.status) == status;
                    return matchesSearch && matchesStatus;
                  }).toList();

                  return _buildMainContent(filteredData);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(List<ExpertVerificationRequestModel> data) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(data),
          const SizedBox(height: 32),
          _buildToolbar(),
          const SizedBox(height: 24),
          Expanded(child: _buildTable(data)),
        ],
      ),
    );
  }

  Widget _buildHeader(List<ExpertVerificationRequestModel> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Duyệt chuyên gia',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Xem và quản lý các yêu cầu xác minh từ các chuyên gia.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _exportToCsv(data),
          icon: const Icon(Icons.download_rounded, size: 20),
          label: const Text('Xuất CSV'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildToolbar() {
    return CustomAdminToolbar(
      searchField: TextField(
        onChanged: (val) {
          _searchQuery.value = val;
          _currentPage.value = 1;
        },
        decoration: InputDecoration(
          hintText: 'Tìm kiếm chuyên gia...',
          prefixIcon: Icon(Icons.search, color: Theme.of(context).textTheme.bodySmall?.color),
          filled: true,
          fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
      centerFilters: [
        ValueListenableBuilder<String>(
          valueListenable: _selectedStatus,
          builder: (context, current, _) {
            return DropdownButtonFormField<String>(
              value: current,
              decoration: InputDecoration(
                filled: true,
                fillColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              items: ['Tất cả', 'Chờ duyệt', 'Đã duyệt', 'Đã từ chối']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  _selectedStatus.value = val;
                  _currentPage.value = 1;
                }
              },
            );
          },
        ),
      ],
      trailingActions: [
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.filter_list, size: 20),
          label: const Text('Thêm bộ lọc'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<ExpertVerificationRequestModel> data) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, page, _) {
        final startIndex = (page - 1) * _itemsPerPage;
        if (data.isEmpty) return _buildEmptyState();
        
        final endIndex = startIndex + _itemsPerPage > data.length ? data.length : startIndex + _itemsPerPage;
        final pageItems = data.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: CustomAdminTable(
                flex: const [3, 3, 2, 2, 1],
                labels: const ['Họ tên', 'Lĩnh vực', 'Trạng thái', 'Ngày gửi', 'Thao tác'],
                itemCount: pageItems.length,
                onRowTapWithIndex: (index) => _showDetailDialog(pageItems[index]),
                rowBuilder: (context, index) {
                  final item = pageItems[index];
                  return [
                    // Name
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(item.fullName.isNotEmpty ? item.fullName[0].toUpperCase() : '?', 
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
                        ),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.fullName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                              Text(item.phone, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Field
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        label: Text(item.expertise, style: Theme.of(context).textTheme.labelSmall),
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : AppColors.background,
                        side: BorderSide.none,
                      ),
                    ),
                    // Status
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CustomAdminBadge(
                        text: _getStatusText(item.status),
                        color: _getStatusColor(item.status),
                      ),
                    ),
                    // Date
                    Text(DateFormat('dd/MM/yyyy').format(item.createdAt), style: Theme.of(context).textTheme.bodyMedium),
                    // Actions
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: AppColors.primary),
                        onPressed: () => _showDetailDialog(item),
                        tooltip: 'Xem chi tiết',
                      ),
                    ),
                  ];
                },
              ),
            ),
            const SizedBox(height: 24),
            CustomAdminPagination(
              totalItems: data.length,
              itemsPerPage: _itemsPerPage,
              currentPage: page,
              onPageChanged: (val) => _currentPage.value = val,
              label: 'yêu cầu',
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Theme.of(context).dividerColor),
          const SizedBox(height: 16),
          Text('Không tìm thấy yêu cầu nào', style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text('Lỗi: $error', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red)),
        ],
      ),
    );
  }
}
