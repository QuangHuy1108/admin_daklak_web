import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _bgGray = Color(0xFFF5F7FA);

class OrderDetailDialog extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> orderData;
  final Function(String docId, String newStatus) onStatusChange;

  const OrderDetailDialog({
    Key? key,
    required this.orderId,
    required this.orderData,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final customerName = orderData['customerName'] ?? 'No Name';
    final phone = orderData['phone'] ?? 'N/A';
    final address = orderData['address'] ?? 'N/A';
    final status = orderData['status'] ?? 'Pending';
    final amount = (orderData['totalAmount'] ?? 0) is num ? (orderData['totalAmount'] as num).toDouble() : double.tryParse((orderData['totalAmount']).toString()) ?? 0;
    
    final itemsRaw = orderData['items'];
    List<dynamic> items = [];
    if (itemsRaw is List) {
       items = itemsRaw;
    }

    return Dialog(
       backgroundColor: Colors.white,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
       child: SizedBox(
          width: 600,
          child: Column(
             mainAxisSize: MainAxisSize.min,
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                // Header
                Container(
                   padding: const EdgeInsets.all(24),
                   decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: _borderColor)),
                   ),
                   child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                               Text('Order Details', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: _textPrimary)),
                               const SizedBox(height: 4),
                               Text('#${orderId.toUpperCase()}', style: GoogleFonts.inter(color: _textSecondary, fontSize: 13)),
                            ]
                         ),
                         IconButton(
                            icon: const Icon(Icons.close, color: _textSecondary),
                            onPressed: () => Navigator.of(context).pop(),
                         )
                      ]
                   )
                ),
                Flexible(
                   child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                            // User Info Section
                            Text('Customer Information', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textPrimary, fontSize: 16)),
                            const SizedBox(height: 16),
                            Container(
                               padding: const EdgeInsets.all(16),
                               decoration: BoxDecoration(color: _bgGray, borderRadius: BorderRadius.circular(12)),
                               child: Column(
                                  children: [
                                     _buildInfoRow(Icons.person_outline, 'Name', customerName),
                                     const SizedBox(height: 12),
                                     _buildInfoRow(Icons.phone_outlined, 'Phone', phone),
                                     const SizedBox(height: 12),
                                     _buildInfoRow(Icons.location_on_outlined, 'Address', address),
                                  ]
                               )
                            ),
                            const SizedBox(height: 32),
                            // Products Table
                            Text('Ordered Items', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textPrimary, fontSize: 16)),
                            const SizedBox(height: 16),
                            Container(
                               decoration: BoxDecoration(
                                  border: Border.all(color: _borderColor),
                                  borderRadius: BorderRadius.circular(12),
                               ),
                               child: Column(
                                  children: [
                                     Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                        decoration: const BoxDecoration(color: _bgGray, borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
                                        child: Row(
                                           children: [
                                              Expanded(flex: 3, child: Text('Product Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13))),
                                              Expanded(flex: 1, child: Text('Qty', textAlign: TextAlign.center, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13))),
                                              Expanded(flex: 2, child: Text('Unit Price', textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13))),
                                              Expanded(flex: 2, child: Text('Total', textAlign: TextAlign.right, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textSecondary, fontSize: 13))),
                                           ]
                                        )
                                     ),
                                     ...items.map((item) {
                                         final itemName = item['productName'] ?? 'Unknown';
                                         final qty = item['quantity'] ?? 1;
                                         final price = (item['price'] ?? 0) is num ? (item['price'] as num).toDouble() : double.tryParse(item['price'].toString()) ?? 0;
                                         return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                            decoration: const BoxDecoration(border: Border(top: BorderSide(color: _borderColor))),
                                            child: Row(
                                               children: [
                                                  Expanded(flex: 3, child: Text(itemName, style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.w500))),
                                                  Expanded(flex: 1, child: Text('x$qty', textAlign: TextAlign.center, style: GoogleFonts.inter(color: _textSecondary))),
                                                  Expanded(flex: 2, child: Text('${price.toStringAsFixed(0)} đ', textAlign: TextAlign.right, style: GoogleFonts.inter(color: _textSecondary))),
                                                  Expanded(flex: 2, child: Text('${(price * qty).toStringAsFixed(0)} đ', textAlign: TextAlign.right, style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.w600))),
                                               ]
                                            )
                                         );
                                     }).toList(),
                                  ]
                               )
                            ),
                            const SizedBox(height: 24),
                            // Total Section
                            Row(
                               mainAxisAlignment: MainAxisAlignment.end,
                               children: [
                                  Text('Total Amount:', style: GoogleFonts.inter(color: _textSecondary, fontSize: 16)),
                                  const SizedBox(width: 16),
                                  Text('${amount.toStringAsFixed(0)} đ', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _primaryGreen, fontSize: 24)),
                               ]
                            )
                         ]
                      )
                   )
                ),
                // Footer (Status Actions)
                Container(
                   padding: const EdgeInsets.all(24),
                   decoration: const BoxDecoration(
                      color: _bgGray,
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                   ),
                   child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Change Status:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textPrimary)),
                         Row(
                            children: [
                               _buildStatusButton('Pending', Colors.orange, status, context),
                               const SizedBox(width: 8),
                               _buildStatusButton('Processing', Colors.blue, status, context),
                               const SizedBox(width: 8),
                               _buildStatusButton('In Transit', Colors.purple, status, context),
                               const SizedBox(width: 8),
                               _buildStatusButton('Completed', Colors.green, status, context),
                               const SizedBox(width: 8),
                               _buildStatusButton('Cancelled', Colors.red, status, context),
                            ]
                         )
                      ]
                   )
                )
             ]
          )
       )
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
      return Row(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Icon(icon, size: 20, color: _textSecondary),
            const SizedBox(width: 12),
            SizedBox(
               width: 80,
               child: Text(label, style: GoogleFonts.inter(color: _textSecondary)),
            ),
            Expanded(child: Text(value, style: GoogleFonts.inter(color: _textPrimary, fontWeight: FontWeight.w500))),
         ]
      );
  }

  Widget _buildStatusButton(String targetStatus, MaterialColor color, String currentStatus, BuildContext context) {
      final isCurrent = currentStatus == targetStatus;
      return InkWell(
         onTap: () {
            if (!isCurrent) {
               onStatusChange(orderId, targetStatus);
               Navigator.of(context).pop();
            }
         },
         borderRadius: BorderRadius.circular(8),
         child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
               color: isCurrent ? color : Colors.white,
               border: Border.all(color: isCurrent ? color : _borderColor),
               borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
               targetStatus,
               style: GoogleFonts.inter(
                  color: isCurrent ? Colors.white : _textSecondary,
                  fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
               )
            )
         )
      );
  }
}
