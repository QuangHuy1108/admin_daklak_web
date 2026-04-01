import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatelessWidget {
  const UserListScreen({super.key});

  Future<void> _toggleBanStatus(String userId, bool currentStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'isBanned': !currentStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quản lý Người dùng', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('Chưa có dữ liệu người dùng.');
                }

                final users = snapshot.data!.docs;

                return Card(
                  child: ListView(
                    children: [
                      DataTable(
                        columns: const [
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Vai trò')),
                          DataColumn(label: Text('Trạng thái Khóa')),
                        ],
                        rows: users.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final isBanned = data['isBanned'] ?? false;

                          return DataRow(
                            cells: [
                              DataCell(Text(data['email'] ?? 'N/A')),
                              DataCell(Text(data['role'] ?? 'Nông dân')),
                              DataCell(
                                Switch(
                                  value: isBanned,
                                  activeColor: Colors.red,
                                  onChanged: (value) => _toggleBanStatus(doc.id, isBanned),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}