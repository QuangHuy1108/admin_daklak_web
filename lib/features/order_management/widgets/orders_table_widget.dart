import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'order_detail_dialog.dart';
import 'order_detail_dialog.dart';
import 'package:admin_daklak_web/features/logs/services/bulk_service.dart';
import 'package:admin_daklak_web/features/logs/widgets/bulk_action_bar.dart';
import 'package:admin_daklak_web/features/logs/models/audit_log_model.dart';
import '../../../core/widgets/common/glass_container.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

  Color _getBgGray(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant.withValues(alpha: 0.5) : const Color(0xFFF5F7FA);
  Color _getTextPrimary(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  Color _getTextSecondary(BuildContext context) => Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280);
  Color _getBorderColor(BuildContext context) => Theme.of(context).dividerColor;
  Color _getPrimaryGreen(BuildContext context) => Theme.of(context).primaryColor;
  Color _getSuccessGreen(BuildContext context) => Colors.green;
  Color _getErrorRed(BuildContext context) => Theme.of(context).colorScheme.error;
  Color _getInfoBlue(BuildContext context) => Colors.blue;

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white)),
      backgroundColor: _getTextPrimary(context),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      margin: const EdgeInsets.only(bottom: 24, right: 24, left: 24),
    ),
  );
}

class OrdersTableWidget extends StatefulWidget {
  final DateTimeRange? dateRange;
  final bool isDashboard; // Add flag to conditionally style for hub
  
  const OrdersTableWidget({
    Key? key,
    this.dateRange,
    this.isDashboard = false,
  }) : super(key: key);

  @override
  State<OrdersTableWidget> createState() => OrdersTableWidgetState();
}

class OrdersTableWidgetState extends State<OrdersTableWidget> {
  String _selectedStatus = 'Tất cả trạng thái';
  final Map<String, String> _statusValueMap = {
    'Tất cả trạng thái': 'All Status',
    'Đang chờ': 'Pending',
    'Đang xử lý': 'Processing',
    'Đang giao': 'In Transit',
    'Hoàn thành': 'Completed',
    'Đã hủy': 'Cancelled',
    'Thất bại': 'Failed',
  };
  final Set<String> _selectedIds = {};
  
  bool _isSearchMode = false;
  String _activeSearchId = '';
  String? _firebaseIndexErrorUrl;
  
  List<DocumentSnapshot> _docs = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  StreamSubscription? _streamSub;

  @override
  void initState() {
    super.initState();
    _startListeningToOrders();
  }

  @override
  void didUpdateWidget(covariant OrdersTableWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dateRange != oldWidget.dateRange) {
      _startListeningToOrders();
    }
  }

  void _startListeningToOrders() {
    setState(() {
      _isLoading = true;
      _hasMore = true;
      _docs.clear();
      _firebaseIndexErrorUrl = null;
    });
    _streamSub?.cancel();

    Query q = FirebaseFirestore.instance.collection('orders');
    final firestoreStatus = _statusValueMap[_selectedStatus] ?? 'All Status';
    if (firestoreStatus != 'All Status') {
      q = q.where('status', isEqualTo: firestoreStatus);
    }
    
    if (widget.dateRange != null) {
      q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.start))
           .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.end));
    }

    q = q.orderBy('createdAt', descending: true).limit(50);

    _streamSub = q.snapshots().listen((snapshot) {
      if (!mounted) return;
      setState(() {
         _docs = snapshot.docs;
         _isLoading = false;
         if (snapshot.docs.length < 50) _hasMore = false;
      });
    }, onError: (Object error) {
      if (!mounted) return;
      setState(() {
         _isLoading = false;
         _hasMore = false;
         if (error.toString().contains('requires an index')) {
            final regExp = RegExp(r'https:\/\/console\.firebase\.google\.com[^\s]*');
            final match = regExp.firstMatch(error.toString());
            if (match != null) {
              _firebaseIndexErrorUrl = match.group(0);
            }
         } else {
             _showToast(context, 'Firebase Error: $error');
         }
      });
    });
  }

  Future<void> _fetchMoreOrders() async {
    if (!_hasMore || _isLoadingMore || _docs.isEmpty) return;
    setState(() => _isLoadingMore = true);

    Query q = FirebaseFirestore.instance.collection('orders');
    final firestoreStatus = _statusValueMap[_selectedStatus] ?? 'All Status';
    if (firestoreStatus != 'All Status') q = q.where('status', isEqualTo: firestoreStatus);
    
    if (widget.dateRange != null) {
       q = q.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.start))
            .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(widget.dateRange!.end));
    }
    
    q = q.orderBy('createdAt', descending: true)
         .startAfterDocument(_docs.last)
         .limit(50);

    try {
        final snapshot = await q.get();
        if (mounted) {
          setState(() {
            if (snapshot.docs.length < 50) _hasMore = false;
            _docs.addAll(snapshot.docs);
            _isLoadingMore = false;
          });
        }
    } catch(error) {
        if (!mounted) return;
        setState(() => _isLoadingMore = false);
        if (error.toString().contains('requires an index')) {
            final regExp = RegExp(r'https:\/\/console\.firebase\.google\.com[^\s]*');
            final match = regExp.firstMatch(error.toString());
            if (match != null) {
              setState(() => _firebaseIndexErrorUrl = match.group(0));
            }
        }
    }
  }

  void _performSearch(String query) {
    final str = query.trim();
    if (str.isEmpty) {
      setState(() { _isSearchMode = false; _activeSearchId = ''; });
      _startListeningToOrders();
      return;
    }
    
    _streamSub?.cancel();
    setState(() {
      _isSearchMode = true;
      _activeSearchId = str;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }

  void exportToCSV() {
    if (_docs.isEmpty) {
      _showToast(context, 'No data to export.');
      return;
    }

    final List<List<dynamic>> rows = [
      ['Order ID', 'Customer Name', 'Total Amount']
    ];

    for (var doc in _docs) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final amount = (data['totalAmount'] ?? 0) is num ? (data['totalAmount'] as num).toDouble() : double.tryParse((data['totalAmount']).toString()) ?? 0;
      final customerName = data['customerName'] ?? 'No Name';
      rows.add([doc.id.toUpperCase(), customerName, amount]);
    }

    final String csvData = const ListToCsvConverter().convert(rows);
    final bytes = utf8.encode(csvData);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'orders_export_${DateTime.now().toIso8601String().split('T')[0].replaceAll('-', '')}.csv';
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    _showToast(context, 'Export successful!');
  }

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đơn hàng gần đây', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _getTextPrimary(context))),
                _selectedIds.isNotEmpty 
                ? Expanded(
                    child: BulkActionBar(
                      selectedCount: _selectedIds.length,
                      onClearSelection: () => setState(() => _selectedIds.clear()),
                      actions: [
                        _buildBulkStatusDropdown(),
                      ],
                    ),
                  )
                : Row(
                    children: [
                      SizedBox(
                        width: 250,
                        height: 40,
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Tìm mã đơn hàng chính xác...',
                            hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _getTextSecondary(context), fontSize: 13),
                            prefixIcon: Icon(Icons.search, size: 20, color: _getTextSecondary(context)),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _getBorderColor(context))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: _getBorderColor(context))),
                          ),
                          onChanged: (val) {
                            if (val.isEmpty) _performSearch('');
                          },
                          onSubmitted: (val) => _performSearch(val),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(border: Border.all(color: _getBorderColor(context)), borderRadius: BorderRadius.circular(8)),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedStatus,
                            icon: Icon(Icons.arrow_drop_down, color: _getTextSecondary(context)),
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: _getTextPrimary(context)),
                            items: <String>['Tất cả trạng thái', 'Đang chờ', 'Đang xử lý', 'Đang giao', 'Hoàn thành', 'Đã hủy', 'Thất bại']
                                .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                            onChanged: (newValue) {
                              if (newValue != null) {
                                setState(() { _selectedStatus = newValue; });
                                if (!_isSearchMode) _startListeningToOrders();
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  )
              ],
            ),
          ),
          Divider(height: 1, color: _getBorderColor(context)),
          
          if (_firebaseIndexErrorUrl != null)
             _buildFirebaseIndexErrorBubble()
          else if (_isSearchMode)
             _buildSearchFutureResult()
          else if (_isLoading)
             const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator()))
          else if (_docs.isEmpty)
             const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No orders found matching the filter.")))
          else
             _buildDataTableBody(_docs),
             
          if (!_isSearchMode && _hasMore && !_isLoading && _firebaseIndexErrorUrl == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: _isLoadingMore 
                  ? const CircularProgressIndicator() 
                  : TextButton.icon(
                      onPressed: _fetchMoreOrders,
                      icon: Icon(Icons.refresh, color: _getPrimaryGreen(context)),
                      label: Text("Tải thêm đơn hàng", style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _getPrimaryGreen(context), fontWeight: FontWeight.w600)),
                    ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFirebaseIndexErrorBubble() {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Row(
                   children: [
                       const Icon(Icons.warning_rounded, color: Colors.red),
                       const SizedBox(width: 8),
                       Text("Firebase Index Required", style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                    ]
                 ),
                 const SizedBox(height: 4),
                 Text("This specific filter requires a Composite Index in Firestore.", style: Theme.of(context).textTheme.bodySmall),
                 const SizedBox(height: 8),
                 SelectableText("Please copy and paste this link in your browser to build the index:\n${_firebaseIndexErrorUrl!}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.blue, decoration: TextDecoration.underline)),
             ]
          )
        )
      );
  }

  Widget _buildSearchFutureResult() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('orders').doc(_activeSearchId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists) {
           return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No exact match found for this Order ID.")));
        }
        
        return _buildDataTableBody([snapshot.data!]);
      },
    );
  }

  Widget _buildDataTableBody(List<DocumentSnapshot> displayDocs) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - (widget.isDashboard ? 100 : 64)),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(_getBgGray(context)),
          showCheckboxColumn: true,
          dataRowMaxHeight: 70,
          dataRowMinHeight: 70,
          onSelectAll: (selected) {
            setState(() {
              if (selected == true) {
                _selectedIds.addAll(displayDocs.map((d) => d.id));
              } else {
                _selectedIds.clear();
              }
            });
          },
          columns: [
            _buildDataColumn('Mã đơn hàng'),
            _buildDataColumn('Khách hàng'),
            _buildDataColumn('Tổng tiền'),
            _buildDataColumn('Trạng thái'),
            _buildDataColumn('Ngày tạo'),
            _buildDataColumn('Hành động'),
          ],
          rows: displayDocs.map((doc) {
            Map<String, dynamic> data;
            try {
              data = doc.data() as Map<String, dynamic>? ?? {};
            } catch(e) {
              data = {};
            }
            
            final date = (data['createdAt'] as Timestamp?)?.toDate();
            final dateString = date != null ? "${date.day}/${date.month}/${date.year}" : "";
            final amount = (data['totalAmount'] ?? 0) is num ? (data['totalAmount'] as num).toDouble() : double.tryParse((data['totalAmount']).toString()) ?? 0;

            return DataRow(
              selected: _selectedIds.contains(doc.id),
              onSelectChanged: (selected) {
                setState(() {
                  if (selected == true) {
                    _selectedIds.add(doc.id);
                  } else {
                    _selectedIds.remove(doc.id);
                  }
                });
              },
              cells: [
                DataCell(
                  InkWell(
                    onTap: () => _viewOrderDetail(doc.id, data),
                    child: Text(doc.id.length > 8 ? doc.id.substring(0, 8).toUpperCase() : doc.id.toUpperCase(), style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  )
                ),
                DataCell(Text(data['customerName'] ?? 'No Name', style: Theme.of(context).textTheme.bodyMedium)),
                DataCell(Text('${amount.toStringAsFixed(0)} đ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
                DataCell(_buildStatusBadge(data['status'] ?? 'Pending')),
                DataCell(Text(dateString, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _getTextSecondary(context)))),
                DataCell(
                  PopupMenuButton<String>(
                    onSelected: (val) => _updateOrderStatus(doc.id, val),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Processing', child: Text('Đang xử lý')),
                      PopupMenuItem(value: 'Completed', child: Text('Hoàn thành')),
                      PopupMenuItem(value: 'Cancelled', child: Text('Hủy đơn hàng', style: TextStyle(color: Colors.red))),
                    ]
                  )
                ),
              ],
            );
          }).toList(),
        ),

      ),
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: _getTextSecondary(context))),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    Color statusBg;

    switch (status) {
      case 'Pending':
        statusColor = Colors.orange;
        statusBg = Colors.orange.withOpacity(0.1);
        break;
      case 'Processing':
        statusColor = _getInfoBlue(context);
        statusBg = _getInfoBlue(context).withOpacity(0.1);
        break;
      case 'In Transit':
        statusColor = Colors.purple;
        statusBg = Colors.purple.withOpacity(0.1);
        break;
      case 'Completed':
        statusColor = _getSuccessGreen(context);
        statusBg = _getSuccessGreen(context).withOpacity(0.1);
        break;
      case 'Cancelled':
      case 'Failed':
        statusColor = _getErrorRed(context);
        statusBg = _getErrorRed(context).withOpacity(0.1);
        break;
      default:
        statusColor = _getTextSecondary(context);
        statusBg = _getBgGray(context);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: statusColor, fontWeight: FontWeight.w600)),
    );
  }

  Future<void> _updateOrderStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (mounted) _showToast(context, 'Order updated to $newStatus');
    } catch (e) {
      if (mounted) _showToast(context, 'Error updating order: $e');
    }
  }

  void _viewOrderDetail(String orderId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailDialog(
        orderId: orderId,
        orderData: data,
        onStatusChange: _updateOrderStatus,
      )
    );
  }

  Widget _buildBulkStatusDropdown() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text("Cập nhật trạng thái", style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
          icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
          items: <String>['Pending', 'Processing', 'In Transit', 'Completed', 'Cancelled']
              .map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              _confirmBulkUpdate(newValue);
            }
          },
        ),
      ),
    );
  }

  void _confirmBulkUpdate(String newStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận cập nhật hàng loạt", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        content: Text("Bạn có chắc chắn muốn cập nhật trạng thái cho ${_selectedIds.length} đơn hàng sang '$newStatus'?", style: Theme.of(context).textTheme.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _executeBulkUpdate(newStatus);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _getPrimaryGreen(context)),
            child: const Text("Xác nhận", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeBulkUpdate(String newStatus) async {
    setState(() => _isLoading = true);
    try {
      await BulkService.updateDocuments(
        collection: 'orders',
        docIds: _selectedIds.toList(),
        data: {'status': newStatus},
        module: AuditModule.orders,
        actionDescription: "Cập nhật hàng loạt trạng thái đơn hàng sang '$newStatus'",
      );
      if (mounted) {
        _showToast(context, "Đã cập nhật ${_selectedIds.length} đơn hàng thành công.");
        setState(() {
          _selectedIds.clear();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showToast(context, "Lỗi khi cập nhật hàng loạt: $e");
        setState(() => _isLoading = false);
      }
    }
  }
}
