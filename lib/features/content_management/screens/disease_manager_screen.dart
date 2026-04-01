import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DiseaseManagerScreen extends StatelessWidget {
  const DiseaseManagerScreen({super.key});

  void _showAddDialog(BuildContext context) {
    final nameController = TextEditingController();
    final treatmentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm Sâu Bệnh Mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Tên sâu bệnh'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: treatmentController,
              decoration: const InputDecoration(labelText: 'Cách điều trị'),
              maxLines: 3,
            ),
            // Nút upload ảnh có thể được phát triển thêm ở đây
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('diseases').add({
                'name': nameController.text,
                'treatment': treatmentController.text,
                'createdAt': FieldValue.serverTimestamp(),
              });
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
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
                stream: FirebaseFirestore.instance.collection('diseases').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      var doc = snapshot.data!.docs[index];
                      return Card(
                        child: ListTile(
                          title: Text(doc['name']),
                          subtitle: Text(doc['treatment']),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => doc.reference.delete(),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}