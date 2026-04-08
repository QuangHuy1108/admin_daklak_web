import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color _primaryGreen = Color(0xFF2E7D32);
const Color _textPrimary = Color(0xFF1C2826);
const Color _textSecondary = Color(0xFF6B7280);

class ProductDialog extends StatefulWidget {
  final String? productId;
  final Map<String, dynamic>? initialData;

  const ProductDialog({Key? key, this.productId, this.initialData}) : super(key: key);

  @override
  State<ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends State<ProductDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _imageController;
  String? _selectedCategory;
  bool _isLoading = false;

  final List<String> _categories = [
    'Durian',
    'Coffee',
    'Pepper',
    'Fruits',
    'Vegetables',
    'Seeds',
    'Agricultural Supplies'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData?['name'] ?? '');
    _priceController = TextEditingController(text: widget.initialData?['price']?.toString() ?? '');
    _stockController = TextEditingController(text: widget.initialData?['stock']?.toString() ?? '');
    _imageController = TextEditingController(text: widget.initialData?['imageUrl'] ?? '');
    
    // Ensure category is in our list
    if (widget.initialData != null && widget.initialData!['category'] != null) {
      if (_categories.contains(widget.initialData!['category'])) {
        _selectedCategory = widget.initialData!['category'];
      }
    }
  }

  void _showToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message, style: GoogleFonts.inter(color: Colors.white)),
      backgroundColor: _textPrimary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ));
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      _showToast("Please select a category.");
      return;
    }

    setState(() => _isLoading = true);
    
    try {
      final name = _nameController.text.trim();
      final price = double.tryParse(_priceController.text) ?? 0;
      final stock = int.tryParse(_stockController.text) ?? 0;
      final image = _imageController.text.trim();
      
      if (widget.productId == null) {
        // Create new
        final batch = FirebaseFirestore.instance.batch();
        final prodRef = FirebaseFirestore.instance.collection('products').doc();
        batch.set(prodRef, {
          'name': name,
          'price': price,
          'stock': stock,
          'category': _selectedCategory,
          'imageUrl': image,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Sync with product_stats
        final statRef = FirebaseFirestore.instance.collection('product_stats').doc(prodRef.id);
        batch.set(statRef, {
          'name': name,
          'quantitySold': 0,
        }, SetOptions(merge: true));
        
        await batch.commit();
        _showToast('Product added successfully!');
      } else {
        // Update existing
        // Update purely the name in stats as well to keep consistency
        final batch = FirebaseFirestore.instance.batch();
        batch.update(FirebaseFirestore.instance.collection('products').doc(widget.productId), {
          'name': name,
          'price': price,
          'stock': stock,
          'category': _selectedCategory,
          'imageUrl': image,
        });
        batch.set(FirebaseFirestore.instance.collection('product_stats').doc(widget.productId), {
           'name': name,
        }, SetOptions(merge: true));

        await batch.commit();
        _showToast('Product updated successfully!');
      }
      
      if (mounted) Navigator.of(context).pop(true);
    } catch(e) {
      _showToast('Error saving product: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.productId == null ? 'Add New Product' : 'Edit Product', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: _textPrimary)),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: SizedBox(
        width: 450,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Product Name', border: OutlineInputBorder()),
                  validator: (val) => (val == null || val.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                  value: _selectedCategory,
                  items: _categories.map((cat) {
                    return DropdownMenuItem<String>(
                      value: cat,
                      child: Text(cat),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedCategory = val),
                  validator: (val) => val == null ? 'Category is required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Selling Price (đ)', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (double.tryParse(val) == null) return 'Invalid price';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Inventory Stock', border: OutlineInputBorder()),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Required';
                          if (int.tryParse(val) == null) return 'Invalid stock';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _imageController,
                  decoration: const InputDecoration(labelText: 'Image URL (Optional)', border: OutlineInputBorder(), hintText: 'https://...'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Cancel', style: GoogleFonts.inter(color: _textSecondary)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
          child: _isLoading 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(widget.productId == null ? 'Create Product' : 'Save Changes', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    );
  }
}
