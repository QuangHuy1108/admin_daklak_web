import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../widgets/voucher_dialog.dart';

const Color _bgGray = Color(0xFFF5F7FA);
const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _warningRed = Color(0xFFD32F2F);

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  String _searchQuery = '';

  void _showVoucherDialog({String? voucherId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (_) => VoucherDialog(voucherId: voucherId, initialData: data),
    );
  }

  void _confirmSoftDelete(String voucherId, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Deactivate Voucher', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textPrimary)),
        content: Text('Are you sure you want to deactivate voucher "$code"?\nThis will prevent future uses but keep historical data intact.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('vouchers').doc(voucherId).update({'isActive': false});
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Voucher "$code" deactivated safely.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _warningRed),
            child: Text('Deactivate', style: GoogleFonts.inter(color: Colors.white)),
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGray,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
              Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: _textPrimary),
                      onPressed: () => context.pop(),
                      tooltip: 'Back to Dashboard',
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Promotions & Vouchers',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Create and manage discount codes for customer campaigns.',
                          style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showVoucherDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: Text('Create Voucher', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Data Container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Action Bar
                   Padding(
                     padding: const EdgeInsets.all(24.0),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Active Campaigns', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                         SizedBox(
                           width: 250,
                           height: 40,
                           child: TextField(
                              decoration: InputDecoration(
                                 hintText: 'Search code...',
                                 hintStyle: GoogleFonts.inter(color: _textSecondary, fontSize: 13),
                                 prefixIcon: const Icon(Icons.search, size: 20, color: _textSecondary),
                                 contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                 border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
                                 enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _borderColor)),
                              ),
                              onChanged: (val) {
                                 setState(() {
                                    _searchQuery = val.trim().toLowerCase();
                                 });
                              },
                           )
                         ),
                       ]
                     )
                   ),
                   const Divider(height: 1, color: _borderColor),
                   // StreamBuilder
                   StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('vouchers').orderBy('createdAt', descending: true).snapshots(),
                      builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator()));
                         }
                         if (snapshot.hasError) {
                            return Padding(padding: const EdgeInsets.all(48.0), child: Center(child: Text("Error fetching vouchers: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
                         }
                         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No vouchers found.")));
                         }

                         var docs = snapshot.data!.docs;
                         
                         if (_searchQuery.isNotEmpty) {
                            docs = docs.where((doc) {
                               final data = doc.data() as Map<String, dynamic>;
                               final code = (data['code'] ?? '').toString().toLowerCase();
                               return code.contains(_searchQuery);
                            }).toList();
                         }

                         if (docs.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No vouchers match your search.")));
                         }

                         return DataTable(
                            headingRowColor: WidgetStateProperty.all(_bgGray),
                            dataRowMinHeight: 70,
                            dataRowMaxHeight: 70,
                            columns: [
                               _buildDataColumn('Code'),
                               _buildDataColumn('Type & Value'),
                               _buildDataColumn('Min Order'),
                               _buildDataColumn('Usage'),
                               _buildDataColumn('Expiry Date'),
                               _buildDataColumn('Status'),
                               _buildDataColumn('Actions'),
                            ],
                            rows: docs.map((doc) {
                               final data = doc.data() as Map<String, dynamic>;
                               final String code = data['code'] ?? '';
                               final String type = data['discountType'] ?? 'Percentage';
                               final num value = data['value'] ?? 0;
                               final num minOrder = data['minOrderValue'] ?? 0;
                               final int usageCount = data['usageCount'] ?? 0;
                               final int limit = data['usageLimit'] ?? 0;
                               final bool isActive = data['isActive'] ?? true;
                               final DateTime? expiry = data['expiryDate'] != null ? (data['expiryDate'] as Timestamp).toDate() : null;
                               final String expiryString = expiry != null ? "${expiry.day}/${expiry.month}/${expiry.year}" : "";

                               // Hybrid state logic
                               bool isSystemExpired = false;
                               if (expiry != null && DateTime.now().isAfter(expiry)) {
                                  isSystemExpired = true;
                               }
                               if (limit > 0 && usageCount >= limit) {
                                  isSystemExpired = true;
                               }

                               return DataRow(
                                  cells: [
                                     DataCell(Text(code.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primaryGreen))),
                                     DataCell(Text(type == 'Percentage' ? '${value.toStringAsFixed(0)}%' : '${value.toStringAsFixed(0)} đ', style: GoogleFonts.inter(fontWeight: FontWeight.w600))),
                                     DataCell(Text(minOrder > 0 ? '${minOrder.toStringAsFixed(0)} đ' : 'None', style: GoogleFonts.inter(color: _textSecondary))),
                                     DataCell(Text('$usageCount / $limit', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: (usageCount >= limit) ? _warningRed : _textPrimary))),
                                     DataCell(Text(expiryString, style: GoogleFonts.inter(color: isSystemExpired ? _warningRed : _textSecondary))),
                                     DataCell(_buildStatusBadge(isActive, isSystemExpired)),
                                     DataCell(
                                        Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                              IconButton(
                                                 icon: const Icon(Icons.edit_outlined, color: _textSecondary),
                                                 tooltip: 'Edit',
                                                 onPressed: () => _showVoucherDialog(voucherId: doc.id, data: data),
                                              ),
                                              if (isActive)
                                                IconButton(
                                                   icon: const Icon(Icons.block, color: _warningRed),
                                                   tooltip: 'Deactivate',
                                                   onPressed: () => _confirmSoftDelete(doc.id, code),
                                                ),
                                           ]
                                        )
                                     )
                                  ]
                               );
                            }).toList()
                         );
                      }
                   )
                ]
              )
            )
          ]
        )
      )
    );
  }

  DataColumn _buildDataColumn(String label) {
    return DataColumn(
      label: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13)),
    );
  }

  Widget _buildStatusBadge(bool isActive, bool isSystemExpired) {
    if (!isActive) {
      return _badge('Inactive', _textSecondary, _bgGray);
    }
    if (isSystemExpired) {
      return _badge('Expired', _warningRed, _warningRed.withOpacity(0.1));
    }
    return _badge('Active', _primaryGreen, _primaryGreen.withOpacity(0.1));
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(text, style: GoogleFonts.inter(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}
