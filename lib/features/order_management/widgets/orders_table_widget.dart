import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'order_detail_dialog.dart';

const Color _bgGray = Color(0xFFF5F7FA);
const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _successGreen = Color(0xFF388E3C);
const Color _errorRed = Color(0xFFD32F2F);
const Color _infoBlue = Color(0xFF1976D2);

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: _textPrimary,
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
  String _selectedStatus = 'All Status';
  
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
    if (_selectedStatus != 'All Status') {
      q = q.where('status', isEqualTo: _selectedStatus);
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
    if (_selectedStatus != 'All Status') q = q.where('status', isEqualTo: _selectedStatus);
    
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: widget.isDashboard ? const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                Row(
                  children: [
                    SizedBox(
                      width: 250,
                      height: 40,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search exact Order ID...',
                          hintStyle: GoogleFonts.inter(color: _textSecondary, fontSize: 13),
                          prefixIcon: const Icon(Icons.search, size: 20, color: _textSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
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
                      decoration: BoxDecoration(border: Border.all(color: _borderColor), borderRadius: BorderRadius.circular(8)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStatus,
                          icon: const Icon(Icons.arrow_drop_down, color: _textSecondary),
                          style: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
                          items: <String>['All Status', 'Pending', 'Processing', 'In Transit', 'Completed', 'Cancelled', 'Failed']
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
          const Divider(height: 1, color: _borderColor),
          
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
                      icon: const Icon(Icons.refresh, color: _primaryGreen),
                      label: Text("Load More Orders", style: GoogleFonts.inter(color: _primaryGreen, fontWeight: FontWeight.w600)),
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
                      Text("Firebase Index Required", style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16)),
                   ]
                ),
                const SizedBox(height: 8),
                Text("This specific filter requires a Composite Index in Firestore.", style: GoogleFonts.inter()),
                const SizedBox(height: 8),
                SelectableText("Please copy and paste this link in your browser to build the index:\n${_firebaseIndexErrorUrl!}", style: GoogleFonts.inter(color: Colors.blue, decoration: TextDecoration.underline)),
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
          headingRowColor: WidgetStateProperty.all(_bgGray),
          showCheckboxColumn: false,
          dataRowMaxHeight: 70,
          dataRowMinHeight: 70,
          columns: [
            _buildDataColumn('Order Code'),
            _buildDataColumn('Customer Name'),
            _buildDataColumn('Total Price'),
            _buildDataColumn('Order Status'),
            _buildDataColumn('Date'),
            _buildDataColumn('Action'),
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
              onSelectChanged: (selected) {
                 if (selected == true) {
                    showDialog(
                        context: context,
                        builder: (context) => OrderDetailDialog(
                           orderId: doc.id,
                           orderData: data,
                           onStatusChange: _updateOrderStatus,
                        )
                    );
                 }
              },
              cells: [
                DataCell(Text(doc.id.length > 8 ? doc.id.substring(0, 8).toUpperCase() : doc.id.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                DataCell(Text(data['customerName'] ?? 'No Name', style: GoogleFonts.inter())),
                DataCell(Text('${amount.toStringAsFixed(0)} đ', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                DataCell(_buildStatusBadge(data['status'] ?? 'Pending')),
                DataCell(Text(dateString, style: GoogleFonts.inter(color: _textSecondary))),
                DataCell(
                  PopupMenuButton<String>(
                    onSelected: (val) => _updateOrderStatus(doc.id, val),
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'Processing', child: Text('Mark Processing')),
                      PopupMenuItem(value: 'Completed', child: Text('Mark Completed')),
                      PopupMenuItem(value: 'Cancelled', child: Text('Cancel Order', style: TextStyle(color: Colors.red))),
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
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color statusColor;
    Color statusBg;

    switch (status) {
      case 'Pending':
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        break;
      case 'Processing':
        statusColor = _infoBlue;
        statusBg = _infoBlue.withOpacity(0.1);
        break;
      case 'In Transit':
        statusColor = Colors.purple;
        statusBg = Colors.purple.withOpacity(0.1);
        break;
      case 'Completed':
        statusColor = _successGreen;
        statusBg = _successGreen.withOpacity(0.1);
        break;
      case 'Cancelled':
      case 'Failed':
        statusColor = _errorRed;
        statusBg = _errorRed.withOpacity(0.1);
        break;
      default:
        statusColor = _textSecondary;
        statusBg = _bgGray;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: GoogleFonts.inter(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }

  Future<void> _updateOrderStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(docId).update({'status': newStatus});
      if (mounted) _showToast(context, 'Order updated to $newStatus');
    } catch (e) {
      if (mounted) _showToast(context, 'Error updating order: $e');
    }
  }
}
