import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/common/custom_admin_table.dart';
import '../../../core/widgets/common/custom_admin_badge.dart';
import '../../../core/widgets/common/custom_admin_toolbar.dart';
import '../../../core/widgets/common/custom_admin_pagination.dart';
import '../models/system_log_model.dart';
import '../services/system_log_service.dart';

class SystemLogScreen extends StatefulWidget {
  const SystemLogScreen({super.key});

  @override
  State<SystemLogScreen> createState() => _SystemLogScreenState();
}

class _SystemLogScreenState extends State<SystemLogScreen> {
  final SystemLogService _service = SystemLogService();
  
  // State variables for filtering and pagination
  final ValueNotifier<String> _searchQuery = ValueNotifier<String>('');
  final ValueNotifier<String> _selectedAction = ValueNotifier<String>('Tất cả');
  final ValueNotifier<String> _selectedStatus = ValueNotifier<String>('Tất cả');
  final ValueNotifier<int> _currentPage = ValueNotifier<int>(1);
  final int _itemsPerPage = 15;

  @override
  void dispose() {
    _searchQuery.dispose();
    _selectedAction.dispose();
    _selectedStatus.dispose();
    _currentPage.dispose();
    super.dispose();
  }

  void _exportToCsv(List<SystemLogModel> data) {
    String csvString = '\uFEFF"Thời gian","Người thực hiện","Hành động","Chi tiết","Trạng thái"\n';
    
    for (var item in data) {
      final String timeText = DateFormat('dd/MM/yyyy HH:mm:ss').format(item.createdAt);
      csvString += '"$timeText","${item.actorName}","${item.action}","${item.details}","${item.status}"\n';
    }

    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8;');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute("download", "nhat_ky_he_thong_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv")
      ..click();
    html.Url.revokeObjectUrl(url);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đang tải tệp CSV...'), backgroundColor: AppColors.primary),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<SystemLogModel>>(
        stream: _service.getAllLogs(),
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
                valueListenable: _selectedAction,
                builder: (context, actionFilter, _) {
                  return ValueListenableBuilder<String>(
                    valueListenable: _selectedStatus,
                    builder: (context, statusFilter, _) {
                      final filteredData = allData.where((item) {
                        final matchesSearch = item.actorName.toLowerCase().contains(query.toLowerCase()) || 
                                             item.details.toLowerCase().contains(query.toLowerCase());
                        
                        bool matchesAction = false;
                        if (actionFilter == 'Tất cả') {
                          matchesAction = true;
                        } else if (actionFilter == 'Thêm') {
                          matchesAction = item.action == 'Thêm' || 
                                         item.action == 'Thêm mới' || 
                                         item.action.toUpperCase().contains('THÊM');
                        } else if (actionFilter == 'Sửa') {
                          matchesAction = item.action == 'Sửa' || 
                                         item.action == 'Cập nhật' || 
                                         item.action.toUpperCase().contains('SỬA');
                        } else {
                          matchesAction = item.action == actionFilter;
                        }

                        final matchesStatus = statusFilter == 'Tất cả' || item.status == statusFilter;
                        
                        return matchesSearch && matchesAction && matchesStatus;
                      }).toList();

                      return _buildMainContent(filteredData);
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildMainContent(List<SystemLogModel> data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
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

  Widget _buildHeader(List<SystemLogModel> data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nhật ký hệ thống',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textHeading),
            ),
            SizedBox(height: 8),
            Text(
              'Theo dõi và quản lý các hoạt động trên hệ thống.',
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _exportToCsv(data),
          icon: const Icon(Icons.download_rounded, size: 20),
          label: const Text('Xuất dữ liệu'),
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
          hintText: 'Tìm kiếm người thực hiện hoặc chi tiết...',
          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
      centerFilters: [
        ValueListenableBuilder<String>(
          valueListenable: _selectedAction,
          builder: (context, current, _) {
            return DropdownButtonFormField<String>(
              value: current,
              decoration: _inputDecoration('Hành động'),
              items: ['Tất cả', 'Thêm', 'Sửa', 'Xóa']
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  _selectedAction.value = val;
                  _currentPage.value = 1;
                }
              },
            );
          },
        ),
        ValueListenableBuilder<String>(
          valueListenable: _selectedStatus,
          builder: (context, current, _) {
            return DropdownButtonFormField<String>(
              value: current,
              decoration: _inputDecoration('Trạng thái'),
              items: ['Tất cả', 'Thành công', 'Thất bại']
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
    );
  }

  InputDecoration _inputDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.background,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
  );

  Widget _buildTable(List<SystemLogModel> data) {
    return ValueListenableBuilder<int>(
      valueListenable: _currentPage,
      builder: (context, page, _) {
        if (data.isEmpty) return _buildEmptyState();

        final startIndex = (page - 1) * _itemsPerPage;
        final endIndex = startIndex + _itemsPerPage > data.length ? data.length : startIndex + _itemsPerPage;
        final pageItems = data.sublist(startIndex, endIndex);

        return Column(
          children: [
            Expanded(
              child: CustomAdminTable(
                flex: const [2, 2, 2, 3, 1],
                labels: const ['Thời gian', 'Người thực hiện', 'Hành động', 'Chi tiết', 'Trạng thái'],
                itemCount: pageItems.length,
                rowBuilder: (context, index) {
                  final item = pageItems[index];
                  return [
                    // Time
                    Text(
                      DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                      style: const TextStyle(fontSize: 14),
                    ),
                    // Actor
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Text(item.actorName.isNotEmpty ? item.actorName[0].toUpperCase() : 'H', 
                              style: const TextStyle(color: AppColors.primary, fontSize: 11)),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            item.actorName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    // Action
                    Text(item.action, style: const TextStyle(fontSize: 14)),
                    // Details
                    Tooltip(
                      message: item.details,
                      decoration: BoxDecoration(
                        color: AppColors.textHeading.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(12),
                      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      showDuration: const Duration(seconds: 5),
                      child: Text(
                        item.details,
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Status
                    CustomAdminBadge(
                      text: item.status,
                      color: item.status == 'Thành công' ? Colors.green : Colors.red,
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
              label: 'bản ghi',
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
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Không có dữ liệu hiển thị', style: TextStyle(color: AppColors.textMuted)),
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
          Text('Lỗi: $error', style: const TextStyle(color: Colors.red)),
        ],
      ),
    );
  }
}
