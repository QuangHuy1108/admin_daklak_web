import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class DiseaseManagerScreen extends StatefulWidget {
  const DiseaseManagerScreen({super.key});

  @override
  State<DiseaseManagerScreen> createState() => _DiseaseManagerScreenState();
}

class _DiseaseManagerScreenState extends State<DiseaseManagerScreen> {
  final _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Hàm hiển thị Dialog Thêm/Sửa Sâu bệnh
  void _showDiseaseFormDialog({DocumentSnapshot? existingDoc}) {
    final bool isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final treatmentController = TextEditingController(text: data['treatment'] ?? '');

    String? existingImageUrl = data['imageUrl'];
    Uint8List? newImageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Chỉnh sửa Sâu bệnh' : 'Thêm Sâu bệnh Mới'),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 400,
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
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[400]!),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: newImageBytes != null
                              ? Image.memory(newImageBytes!, fit: BoxFit.cover)
                              : (existingImageUrl != null && existingImageUrl.isNotEmpty
                              ? Image.network(existingImageUrl, fit: BoxFit.cover)
                              : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Tải ảnh minh họa lên', style: TextStyle(color: Colors.grey)),
                            ],
                          )),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(labelText: 'Tên sâu bệnh', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: treatmentController,
                        decoration: const InputDecoration(labelText: 'Cách điều trị / Phòng ngừa', border: OutlineInputBorder()),
                        maxLines: 4,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
                ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (nameController.text.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tên sâu bệnh')));
                      return;
                    }

                    setStateDialog(() => _isLoading = true);

                    try {
                      String finalImageUrl = existingImageUrl ?? '';

                      // Upload ảnh mới nếu có
                      if (newImageBytes != null) {
                        String fileName = 'diseases/${DateTime.now().millisecondsSinceEpoch}.png';
                        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putData(newImageBytes!);
                        finalImageUrl = await snapshot.ref.getDownloadURL();

                        // Xóa ảnh cũ (nếu có) để tiết kiệm dung lượng
                        if (isEditing && existingImageUrl != null && existingImageUrl.contains('firebase')) {
                          try { await FirebaseStorage.instance.refFromURL(existingImageUrl).delete(); } catch (_) {}
                        }
                      }

                      Map<String, dynamic> diseaseData = {
                        'name': nameController.text.trim(),
                        'treatment': treatmentController.text.trim(),
                        'imageUrl': finalImageUrl,
                        'updatedAt': FieldValue.serverTimestamp(),
                      };

                      if (isEditing) {
                        await existingDoc!.reference.update(diseaseData);
                      } else {
                        diseaseData['createdAt'] = FieldValue.serverTimestamp();
                        await _firestore.collection('diseases').add(diseaseData);
                      }

                      setStateDialog(() => _isLoading = false);
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu dữ liệu thành công!')));
                    } catch (e) {
                      setStateDialog(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(isEditing ? 'Cập nhật' : 'Lưu'),
                ),
              ],
            );
          }
      ),
    );
  }

  // Hàm Xóa
  Future<void> _deleteDisease(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Xóa dữ liệu này vĩnh viễn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Xóa')
          ),
        ],
      ),
    );

    if (confirm == true) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['imageUrl'] != null && data['imageUrl'].toString().contains('firebase')) {
        try { await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete(); } catch (_) {}
      }
      await doc.reference.delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý Sâu Bệnh', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('diseases').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có dữ liệu.'));

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      var data = doc.data() as Map<String, dynamic>;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                                ? Image.network(data['imageUrl'], width: 80, height: 80, fit: BoxFit.cover)
                                : Container(width: 80, height: 80, color: Colors.grey[300], child: const Icon(Icons.bug_report, color: Colors.grey)),
                          ),
                          title: Text(data['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              data['treatment'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showDiseaseFormDialog(existingDoc: doc),
                                tooltip: 'Chỉnh sửa',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteDisease(doc),
                                tooltip: 'Xóa',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDiseaseFormDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm Sâu bệnh'),
      ),
    );
  }
}