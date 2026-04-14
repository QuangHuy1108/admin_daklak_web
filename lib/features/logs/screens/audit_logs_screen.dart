import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../models/audit_log_model.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  List<AuditLogModel> _logs = [];
  bool _isLoading = false;
  String? _error;

  // Filters
  AuditModule? _selectedModule;
  DateTimeRange? _selectedDateRange;
  final TextEditingController _adminSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      Query query = _firestore.collection('audit_logs')
          .orderBy('timestamp', descending: true)
          .limit(50);

      // Apply Filter: Module
      if (_selectedModule != null) {
        query = query.where('module', isEqualTo: _selectedModule!.name);
      }

      // Apply Filter: Date
      if (_selectedDateRange != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: _selectedDateRange!.start);
        query = query.where('timestamp', isLessThanOrEqualTo: _selectedDateRange!.end.add(const Duration(days: 1)));
      }

      final snapshot = await query.get();
      
      List<AuditLogModel> fetchedLogs = snapshot.docs
          .map((doc) => AuditLogModel.fromFirestore(doc))
          .toList();

      // Client-side Filter: Admin (Email or ID)
      if (_adminSearchController.text.isNotEmpty) {
        String search = _adminSearchController.text.toLowerCase();
        fetchedLogs = fetchedLogs.where((log) => 
          log.adminEmail.toLowerCase().contains(search) || 
          log.adminId.toLowerCase().contains(search)
        ).toList();
      }

      setState(() {
        _logs = fetchedLogs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Lỗi khi tải nhật ký: $e";
        _isLoading = false;
      });
    }
  }

  void _showDetailDialog(AuditLogModel log) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Chi tiết thao tác", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailRow("ID Nhật ký", log.id),
                _detailRow("Thời gian", DateFormat('dd/MM/yyyy HH:mm:ss').format(log.timestamp)),
                _detailRow("Quản trị viên", log.adminEmail),
                _detailRow("ID Quản trị", log.adminId),
                _detailRow("Địa chỉ IP", log.ipAddress),
                const Divider(height: 32),
                _detailRow("Tính năng", log.module.label),
                _detailRow("Hành động", log.actionType.label),
                _detailRow("Mô tả", log.description),
                const SizedBox(height: 16),
                Text("Dữ liệu chi tiết (JSON):", style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: SelectableText(
                    log.details != null ? JsonEncoder.withIndent('  ').convert(log.details) : "Không có dữ liệu chi tiết.",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontFamily: 'monospace', fontSize: 12, color: Colors.blueGrey[800]),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Đóng")),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text("$label:", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13))),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13))),
        ],
      ),
    );
  }

  Color _getActionColor(AuditActionType type) {
    switch (type) {
      case AuditActionType.create: return Colors.green;
      case AuditActionType.update: return Colors.blue;
      case AuditActionType.delete: return Theme.of(context).colorScheme.error;
      case AuditActionType.login: return Colors.teal;
      case AuditActionType.export: return Colors.orange;
      case AuditActionType.security: return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Nhật ký hệ thống", style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                    Text("Theo dõi hoạt động bảo mật và thay đổi dữ liệu", style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _fetchLogs,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text("Làm mới"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            _buildFilterBar(),
            const SizedBox(height: 16),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: _isLoading 
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                    : _buildLogTable(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          // Module Filter
          Expanded(
            child: DropdownButtonFormField<AuditModule>(
              decoration: const InputDecoration(labelText: "Tính năng", border: OutlineInputBorder()),
              initialValue: _selectedModule,
              items: [
                const DropdownMenuItem(value: null, child: Text("Tất cả tính năng")),
                ...AuditModule.values.map((m) => DropdownMenuItem(value: m, child: Text(m.label))),
              ],
              onChanged: (val) => setState(() => _selectedModule = val),
            ),
          ),
          const SizedBox(width: 16),
          
          // Date Filter
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(context: context, firstDate: DateTime(2023), lastDate: DateTime.now());
                if (picked != null) setState(() => _selectedDateRange = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(labelText: "Khoảng thời gian", border: OutlineInputBorder(), suffixIcon: Icon(Icons.calendar_today)),
                child: Text(_selectedDateRange == null ? "Tất cả thời gian" : "${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}"),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Admin Search
          Expanded(
            child: TextField(
              controller: _adminSearchController,
              decoration: const InputDecoration(labelText: "Quản trị viên (Email/ID)", border: OutlineInputBorder(), prefixIcon: Icon(Icons.person_search)),
              onSubmitted: (_) => _fetchLogs(),
            ),
          ),
          const SizedBox(width: 16),

          IconButton(
            onPressed: () {
              setState(() {
                _selectedModule = null;
                _selectedDateRange = null;
                _adminSearchController.clear();
              });
              _fetchLogs();
            },
            icon: const Icon(Icons.clear_all, color: Colors.redAccent),
            tooltip: "Xóa lọc",
          ),
          const SizedBox(width: 8),
          
          ElevatedButton(
            onPressed: _fetchLogs,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey[800], foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18)),
            child: const Text("Áp dụng"),
          ),
        ],
      ),
    );
  }

  Widget _buildLogTable() {
    if (_logs.isEmpty) return const Center(child: Text("Không tìm thấy nhật ký nào phù hợp."));

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[50]),
          columns: [
            DataColumn(label: Text("Thời gian", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Quản trị viên", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Hành động", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Tính năng", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("Mô tả", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("IP", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
            DataColumn(label: Text("", style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold))),
          ],
          rows: _logs.map((log) => DataRow(
            cells: [
              DataCell(Text(DateFormat('dd/MM/yyyy\nHH:mm').format(log.timestamp), style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12))),
              DataCell(Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.adminEmail, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).primaryColor)),
                  Text("ID: ${log.adminId.substring(0, 6)}...", style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _getActionColor(log.actionType).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (log.module == AuditModule.users) 
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(Icons.admin_panel_settings, size: 10, color: Theme.of(context).primaryColor),
                      ),
                    Text(log.actionType.label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: _getActionColor(log.actionType), fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
              DataCell(Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: log.module == AuditModule.users ? AppColors.primary.withValues(alpha: 0.05) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  log.module.label, 
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 13, 
                    fontWeight: log.module == AuditModule.users ? FontWeight.bold : FontWeight.normal,
                    color: log.module == AuditModule.users ? Theme.of(context).primaryColor : Theme.of(context).colorScheme.onSurface,
                  )
                ),
              )),
              DataCell(SizedBox(width: 250, child: Text(log.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)))),
              DataCell(Text(log.ipAddress, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color))),
              DataCell(IconButton(icon: const Icon(Icons.info_outline, size: 20), onPressed: () => _showDetailDialog(log))),
            ],
          )).toList(),
        ),
      ),
    );
  }
}
