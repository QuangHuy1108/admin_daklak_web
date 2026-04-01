import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class BannerManagerScreen extends StatefulWidget {
  const BannerManagerScreen({super.key});

  @override
  State<BannerManagerScreen> createState() => _BannerManagerScreenState();
}

class _BannerManagerScreenState extends State<BannerManagerScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Hàm gom chung cho cả Thêm mới và Chỉnh sửa
  void _showBannerFormDialog({DocumentSnapshot? existingDoc}) {
    final bool isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final titleCtrl = TextEditingController(text: data['title'] ?? '');
    final descCtrl = TextEditingController(text: data['description'] ?? '');
    final actionUrlCtrl = TextEditingController(text: data['actionUrl'] ?? '');
    final orderCtrl = TextEditingController(text: (data['order'] ?? 0).toString());
    
    String selectedType = data['type'] ?? 'ads';
    String? existingImageUrl = data['imageUrl'];
    Uint8List? newImageBytes;
    
    DateTime? startDate = data['startDate'] != null ? (data['startDate'] as Timestamp).toDate() : null;
    DateTime? endDate = data['endDate'] != null ? (data['endDate'] as Timestamp).toDate() : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: Text(isEditing ? 'Chỉnh sửa Banner' : 'Thêm Banner Mới'),
            content: SingleChildScrollView(
              child: SizedBox(
                width: 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Khu vực chọn ảnh
                    InkWell(
                      onTap: () async {
                        final ImagePicker picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          final bytes = await image.readAsBytes();
                          setStateDialog(() => newImageBytes = bytes);
                        }
                      },
                      child: Container(
                        height: 180,
                        width: double.infinity,
                        color: Colors.grey[200],
                        child: newImageBytes != null
                            ? Image.memory(newImageBytes!, fit: BoxFit.cover)
                            : (existingImageUrl != null
                                ? Image.network(existingImageUrl!, fit: BoxFit.cover)
                                : const Icon(Icons.add_a_photo, size: 50, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Tiêu đề', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Mô tả ngắn gọn', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: actionUrlCtrl, decoration: const InputDecoration(labelText: 'Đường link (Action URL)', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: const InputDecoration(labelText: 'Loại điều hướng', border: OutlineInputBorder()),
                            items: const [
                              DropdownMenuItem(value: 'ads', child: Text('Quảng cáo ngoài')),
                              DropdownMenuItem(value: 'product', child: Text('Chi tiết sản phẩm')),
                              DropdownMenuItem(value: 'category', child: Text('Danh mục')),
                              DropdownMenuItem(value: 'warning', child: Text('Cảnh báo khẩn')),
                            ],
                            onChanged: (val) => setStateDialog(() => selectedType = val!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: orderCtrl, 
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Thứ tự ưu tiên', border: OutlineInputBorder())
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Lên lịch hiển thị
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(startDate != null ? "${startDate!.day}/${startDate!.month}/${startDate!.year}" : 'Ngày bắt đầu'),
                            onPressed: () async {
                              final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setStateDialog(() => startDate = date);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.event_busy),
                            label: Text(endDate != null ? "${endDate!.day}/${endDate!.month}/${endDate!.year}" : 'Ngày kết thúc'),
                            onPressed: () async {
                              final date = await showDatePicker(context: context, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                              if (date != null) setStateDialog(() => endDate = date);
                            },
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
              ElevatedButton(
  onPressed: _isLoading ? null : () async {
    if (titleCtrl.text.isEmpty || (newImageBytes == null && existingImageUrl == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề và chọn ảnh')));
      return;
    }
    
    // 1. Dùng setStateDialog để vòng tròn trên nút bắt đầu xoay
    setStateDialog(() => _isLoading = true);

    try {
      String finalImageUrl = existingImageUrl ?? '';

      // Upload ảnh
      if (newImageBytes != null) {
        String fileName = 'banners/${DateTime.now().millisecondsSinceEpoch}.png';
        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putData(newImageBytes!);
        finalImageUrl = await snapshot.ref.getDownloadURL();
        
        if (isEditing && existingImageUrl != null && existingImageUrl!.contains('firebase')) {
           try { await FirebaseStorage.instance.refFromURL(existingImageUrl!).delete(); } catch (_) {}
        }
      }

      // Chuẩn bị dữ liệu
      Map<String, dynamic> bannerData = {
        'title': titleCtrl.text,
        'description': descCtrl.text,
        'actionUrl': actionUrlCtrl.text,
        'imageUrl': finalImageUrl,
        'type': selectedType,
        'order': int.tryParse(orderCtrl.text) ?? 0,
        'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
        'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Lưu vào Firestore
      if (isEditing) {
        await existingDoc!.reference.update(bannerData);
      } else {
        bannerData['isActive'] = true;
        bannerData['clicks'] = 0;
        bannerData['impressions'] = 0;
        bannerData['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('home_banners').add(bannerData);
      }

      // 2. Thành công -> Tắt xoay, Đóng Form và Báo thành công
      setStateDialog(() => _isLoading = false);
      if (context.mounted) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng banner thành công!')));

    } catch (e) {
      // 3. Nếu LỖI -> Tắt xoay và In lỗi màu đỏ ra màn hình để biết nguyên nhân
      setStateDialog(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Lỗi: $e'), 
        backgroundColor: Colors.red,
      ));
    }
  },
  child: _isLoading 
      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
      : Text(isEditing ? 'Cập nhật' : 'Tạo mới'),
),
            ],
          );
        }
      ),
    );
  }

  // Hàm Xóa Banner (Xóa cả Database và Storage)
  Future<void> _deleteBanner(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa banner này vĩnh viễn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa')),
        ],
      ),
    );

    if (confirm == true) {
      final data = doc.data() as Map<String, dynamic>;
      // Xóa file ảnh trên Storage
      if (data['imageUrl'] != null && data['imageUrl'].toString().contains('firebase')) {
        try {
          await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete();
        } catch (e) {
          debugPrint('Lỗi xóa ảnh Storage: $e');
        }
      }
      // Xóa document trên Firestore
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý Banner & Điều hướng')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBannerFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Banner'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Sắp xếp theo thứ tự hiển thị (order) từ nhỏ đến lớn
        stream: _firestore.collection('home_banners').orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Chưa có banner nào.'));
          }

          final banners = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final doc = banners[index];
              final data = doc.data() as Map<String, dynamic>;
              final isActive = data['isActive'] ?? false;
              
              // Cảnh báo nếu banner đã hết hạn
              bool isExpired = false;
              if (data['endDate'] != null) {
                isExpired = (data['endDate'] as Timestamp).toDate().isBefore(DateTime.now());
              }

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(8),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(data['imageUrl'] ?? '', width: 100, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.broken_image, size: 50)),
                  ),
                  title: Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loại: ${data['type']} | Ưu tiên: ${data['order']}'),
                      Text('Clicks: ${data['clicks'] ?? 0} | Lượt xem: ${data['impressions'] ?? 0}', style: const TextStyle(color: Colors.blue)),
                      if (isExpired) const Text('⚠️ Đã hết hạn hiển thị', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: isActive,
                        activeColor: Colors.green,
                        onChanged: (val) => doc.reference.update({'isActive': val}),
                      ),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showBannerFormDialog(existingDoc: doc)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBanner(doc)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}