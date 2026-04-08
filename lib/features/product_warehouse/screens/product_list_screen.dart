import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../widgets/product_dialog.dart';

const Color _bgGray = Color(0xFFF5F7FA);
const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);
const Color _borderColor = Color(0xFFE5E7EB);
const Color _warningRed = Color(0xFFD32F2F);
const Color _infoBlue = Color(0xFF1976D2);

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All Categories';

  final List<String> _filterCategories = [
    'All Categories',
    'Durian',
    'Coffee',
    'Pepper',
    'Fruits',
    'Vegetables',
    'Seeds',
    'Agricultural Supplies'
  ];

  void _showProductDialog({String? productId, Map<String, dynamic>? data}) {
    showDialog(
      context: context,
      builder: (_) => ProductDialog(productId: productId, initialData: data),
    );
  }

  void _confirmDelete(String productId, String productName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Product', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textPrimary)),
        content: Text('Are you sure you want to delete "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.inter(color: _textSecondary)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseFirestore.instance.collection('products').doc(productId).delete();
              if (mounted) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Product "$productName" deleted.')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Delete', style: GoogleFonts.inter(color: Colors.white)),
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
                          'Agricultural Products',
                          style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _textPrimary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage warehouse inventory, variant pricing, and stock levels.',
                          style: GoogleFonts.inter(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showProductDialog(),
                  icon: const Icon(Icons.add, color: Colors.white, size: 20),
                  label: Text('Add New Product', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
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
            // Main Content Table
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                   // Table Action Bar
                   Padding(
                     padding: const EdgeInsets.all(24.0),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('Active Inventory', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: _textPrimary)),
                         Row(
                            children: [
                               SizedBox(
                                 width: 250,
                                 height: 40,
                                 child: TextField(
                                    decoration: InputDecoration(
                                       hintText: 'Search product name...',
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
                               const SizedBox(width: 16),
                               Container(
                                 height: 40,
                                 padding: const EdgeInsets.symmetric(horizontal: 12),
                                 decoration: BoxDecoration(border: Border.all(color: _borderColor), borderRadius: BorderRadius.circular(8)),
                                 child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: _selectedCategory,
                                      icon: const Icon(Icons.category, color: _textSecondary, size: 18),
                                      style: GoogleFonts.inter(color: _textPrimary, fontSize: 14),
                                      items: _filterCategories.map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                                      onChanged: (newValue) {
                                        if (newValue != null) {
                                          setState(() { _selectedCategory = newValue; });
                                        }
                                      },
                                    ),
                                 ),
                               ),
                            ]
                         )
                       ]
                     )
                   ),
                   const Divider(height: 1, color: _borderColor),
                   // Data Stream
                   StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('products').snapshots(),
                      builder: (context, snapshot) {
                         if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: CircularProgressIndicator()));
                         }
                         if (snapshot.hasError) {
                            return Padding(padding: const EdgeInsets.all(48.0), child: Center(child: Text("Error fetching products: ${snapshot.error}", style: const TextStyle(color: Colors.red))));
                         }
                         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No products found in the warehouse.")));
                         }

                         var docs = snapshot.data!.docs;
                         
                         // Apply local filters since we use a full stream on a relatively small collection
                         if (_selectedCategory != 'All Categories') {
                            docs = docs.where((doc) => (doc.data() as Map)['category'] == _selectedCategory).toList();
                         }
                         if (_searchQuery.isNotEmpty) {
                            docs = docs.where((doc) {
                               final data = doc.data() as Map<String, dynamic>;
                               final name = (data['name'] ?? '').toString().toLowerCase();
                               return name.contains(_searchQuery);
                            }).toList();
                         }

                         if (docs.isEmpty) {
                            return const Padding(padding: EdgeInsets.all(48.0), child: Center(child: Text("No products match your filters.")));
                         }

                         return DataTable(
                            headingRowColor: WidgetStateProperty.all(_bgGray),
                            dataRowMaxHeight: 80,
                            dataRowMinHeight: 80,
                            columns: [
                               _buildDataColumn('Thumbnail'),
                               _buildDataColumn('Product Code'),
                               _buildDataColumn('Name'),
                               _buildDataColumn('Category'),
                               _buildDataColumn('Selling Price'),
                               _buildDataColumn('In Stock'),
                               _buildDataColumn('Actions'),
                            ],
                            rows: docs.map((doc) {
                               final data = doc.data() as Map<String, dynamic>;
                               final String name = data['name'] ?? 'Unnamed';
                               final String category = data['category'] ?? 'Uncategorized';
                               final num priceNum = data['price'] ?? 0;
                               final int stock = data['stock'] ?? 0;
                               final String imgUrl = data['imageUrl'] ?? '';
                               
                               // Low Stock Warning Threshold Logic
                               final bool isLowStock = stock <= 10;

                               return DataRow(
                                  color: WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
                                    if (isLowStock) return _warningRed.withOpacity(0.05); // Highlight low stock rows
                                    return null;
                                  }),
                                  cells: [
                                     DataCell(
                                        Container(
                                           width: 48, height: 48,
                                           decoration: BoxDecoration(
                                              color: _bgGray,
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: _borderColor),
                                              image: imgUrl.isNotEmpty && imgUrl.startsWith('http') 
                                                 ? DecorationImage(image: NetworkImage(imgUrl), fit: BoxFit.cover, onError: (_,__) => const DecorationImage(image: AssetImage('assets/placeholder.png')))
                                                 : null, // Fallback icon below
                                           ),
                                           child: (imgUrl.isEmpty || !imgUrl.startsWith('http')) ? const Icon(Icons.image, color: Colors.grey) : null,
                                        )
                                     ),
                                     DataCell(Text(doc.id.length > 6 ? doc.id.substring(0, 6).toUpperCase() : doc.id.toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textSecondary))),
                                     DataCell(
                                        SizedBox(
                                           width: 200,
                                           child: Text(name, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: _textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                                        )
                                     ),
                                     DataCell(
                                        Container(
                                           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                           decoration: BoxDecoration(color: _infoBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                           child: Text(category, style: GoogleFonts.inter(color: _infoBlue, fontWeight: FontWeight.w600, fontSize: 12)),
                                        )
                                     ),
                                     DataCell(Text('${priceNum.toStringAsFixed(0)} đ', style: GoogleFonts.inter(fontWeight: FontWeight.w500))),
                                     DataCell(
                                        Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                              Text(stock.toString(), style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isLowStock ? _warningRed : _primaryGreen, fontSize: 16)),
                                              if (isLowStock) ...[
                                                 const SizedBox(width: 8),
                                                 const Tooltip(
                                                    message: 'Low Stock Level',
                                                    child: Icon(Icons.warning_amber_rounded, color: _warningRed, size: 20),
                                                 )
                                              ]
                                           ]
                                        )
                                     ),
                                     DataCell(
                                        Row(
                                           mainAxisSize: MainAxisSize.min,
                                           children: [
                                              IconButton(
                                                 icon: const Icon(Icons.edit_outlined, color: _textSecondary),
                                                 tooltip: 'Edit',
                                                 onPressed: () => _showProductDialog(productId: doc.id, data: data),
                                              ),
                                              IconButton(
                                                 icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                 tooltip: 'Delete',
                                                 onPressed: () => _confirmDelete(doc.id, name),
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
}
