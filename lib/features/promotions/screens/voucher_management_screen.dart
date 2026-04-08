import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/voucher_model.dart';
import '../services/voucher_service.dart';

class VoucherManagementScreen extends StatefulWidget {
  const VoucherManagementScreen({super.key});

  @override
  State<VoucherManagementScreen> createState() =>
      _VoucherManagementScreenState();
}

class _VoucherManagementScreenState extends State<VoucherManagementScreen> {
  final VoucherService _voucherService = VoucherService();
  final TextEditingController _searchController = TextEditingController();
  late VoucherDataSource _dataSource;

  Timer? _debounce;
  String _searchSellerId = '';

  @override
  void initState() {
    super.initState();
    _dataSource = VoucherDataSource(
      voucherService: _voucherService,
      context: context,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// 500ms Debounce implementation for search filter
  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchSellerId = value.trim();
        _dataSource.updateSearch(_searchSellerId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF7F8F3,
      ), // Consistent with User List background
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),

            const SizedBox(height: 32),

            // Filter & Table Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar Section
                    _buildSearchBar(),

                    const SizedBox(height: 24),

                    // Paginated Data Table with architectural constraints
                    Theme(
                      data: Theme.of(
                        context,
                      ).copyWith(cardTheme: const CardThemeData(elevation: 0)),
                      child: PaginatedDataTable(
                        header: Text(
                          'Automation Vouchers',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B3D2F),
                          ),
                        ),
                        rowsPerPage: 10,
                        columnSpacing: 24,
                        showFirstLastButtons: true,
                        columns: [
                          const DataColumn(label: Text('Voucher Code')),
                          const DataColumn(label: Text('Seller (Name)')),
                          const DataColumn(label: Text('Type')),
                          const DataColumn(label: Text('Value')),
                          const DataColumn(label: Text('Usage (Limit)')),
                          const DataColumn(label: Text('Expiry')),
                          const DataColumn(label: Text('Status')),
                          const DataColumn(label: Text('Actions')),
                        ],
                        source: _dataSource,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1B3D2F)),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back to Dashboard',
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voucher Management System',
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1B3D2F),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage and monitor AI-generated automated vouchers for agriculture sellers.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        SizedBox(
          width: 350,
          child: TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Search by Seller ID...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            style: GoogleFonts.inter(fontSize: 14),
          ),
        ),
        const Spacer(),
        // Indicator showing that search is active
        if (_debounce?.isActive ?? false)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }
}

/// Dynamic Data Source for PaginatedDataTable
/// Handles cursor-based pagination to avoid massive document reads.
class VoucherDataSource extends DataTableSource {
  final VoucherService voucherService;
  final BuildContext context;

  List<VoucherModel> _vouchers = [];
  bool _isLoading = false;
  DocumentSnapshot? _lastFetchedDoc;
  String? _currentSearchSellerId;
  bool _hasMore = true;

  VoucherDataSource({required this.voucherService, required this.context}) {
    _fetchNextPage();
  }

  void updateSearch(String sellerId) {
    _currentSearchSellerId = sellerId;
    _vouchers = [];
    _lastFetchedDoc = null;
    _hasMore = true;
    notifyListeners();
    _fetchNextPage();
  }

  Future<void> _fetchNextPage() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      final snapshot = await voucherService.fetchVouchersPage(
        sellerIdSearch: _currentSearchSellerId,
        lastDoc: _lastFetchedDoc,
        limit: 20, // Strict architectural limit
      );

      if (snapshot.docs.isNotEmpty) {
        _lastFetchedDoc = snapshot.docs.last;
        final newVouchers = snapshot.docs
            .map((doc) => VoucherModel.fromFirestore(doc))
            .toList();
        _vouchers.addAll(newVouchers);

        if (snapshot.docs.length < 20) {
          _hasMore = false;
        }
      } else {
        _hasMore = false;
      }
    } catch (e) {
      debugPrint('Error fetching vouchers: $e');
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  DataRow? getRow(int index) {
    // Check if we need to load more data when we reach near the end of current list
    if (index >= _vouchers.length) {
      if (_hasMore) {
        _fetchNextPage();
      }
      return null;
    }

    final voucher = _vouchers[index];

    return DataRow(
      cells: [
        DataCell(
          Text(
            voucher.code.toUpperCase(),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2E7D32),
            ),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                voucher
                    .sellerName, // Denormalized field used here (No extra reads)
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              Text(
                'ID: ${voucher.sellerId}',
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        DataCell(Text(voucher.type.replaceAll('_', ' '))),
        DataCell(
          Text(
            voucher.discountType == 'Percentage'
                ? '${voucher.value.toStringAsFixed(0)}%'
                : '${voucher.value.toStringAsFixed(0)} đ',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold),
          ),
        ),
        DataCell(Text('${voucher.usageCount} / ${voucher.usageLimit}')),
        DataCell(
          Text(
            '${voucher.expiryDate.day}/${voucher.expiryDate.month}/${voucher.expiryDate.year}',
          ),
        ),
        DataCell(_buildStatusBadge(voucher)),
        DataCell(
          Switch(
            value: voucher.isActive,
            activeColor: const Color(0xFF2E7D32),
            onChanged: (val) async {
              // Optimistic update for UI responsiveness
              try {
                await voucherService.updateVoucherStatus(voucher.id, val);
                // In this design, since we are not using a Stream,
                // we manually update the local object for immediate UI response.
                _vouchers[index] = VoucherModel(
                  id: voucher.id,
                  code: voucher.code,
                  createdAt: voucher.createdAt,
                  createdBy: voucher.createdBy,
                  discountType: voucher.discountType,
                  expiryDate: voucher.expiryDate,
                  isActive: val,
                  minOrderValue: voucher.minOrderValue,
                  sellerId: voucher.sellerId,
                  sellerName: voucher.sellerName,
                  type: voucher.type,
                  usageCount: voucher.usageCount,
                  usageLimit: voucher.usageLimit,
                  value: voucher.value,
                );
                notifyListeners();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update status: $e')),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(VoucherModel voucher) {
    final bool isExpired = DateTime.now().isAfter(voucher.expiryDate);
    final String label = !voucher.isActive
        ? 'Inactive'
        : (isExpired ? 'Expired' : 'Active');
    final Color color = !voucher.isActive
        ? Colors.grey
        : (isExpired ? Colors.red : const Color(0xFF2E7D32));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _vouchers.length;

  @override
  int get selectedRowCount => 0;
}
