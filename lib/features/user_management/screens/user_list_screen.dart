import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  String _searchQuery = '';
  String _selectedRole = 'Tất cả';
  int _rowsPerPage = 10;
  int _currentPage = 0;

  final List<String> _roles = ['Tất cả', 'admin', 'expert', 'farmer'];

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

          // --- Thanh công cụ: Tìm kiếm & Lọc ---
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Tìm kiếm
                SizedBox(
                  width: 300,
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Tìm theo tên, email, SĐT...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.toLowerCase();
                        _currentPage = 0; // Reset về trang 1 khi search
                      });
                    },
                  ),
                ),
                // Lọc theo Role
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedRole,
                      items: _roles.map((r) => DropdownMenuItem(value: r, child: Text(r == 'farmer' ? 'Nông dân' : (r == 'expert' ? 'Chuyên gia' : r)))).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value!;
                          _currentPage = 0; // Reset về trang 1 khi filter
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- Bảng Dữ liệu ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Chưa có dữ liệu người dùng.'));
                }

                // 1. Lọc dữ liệu Local (Client-side filtering)
                var filteredDocs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final email = (data['email'] ?? '').toString().toLowerCase();
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final phone = (data['phone'] ?? data['phoneNumber'] ?? '').toString().toLowerCase();
                  final role = data['role'] ?? 'farmer';

                  // Lọc theo Role
                  if (_selectedRole != 'Tất cả' && role != _selectedRole) return false;

                  // Lọc theo Search Query
                  if (_searchQuery.isNotEmpty) {
                    return email.contains(_searchQuery) || name.contains(_searchQuery) || phone.contains(_searchQuery);
                  }
                  return true;
                }).toList();

                // 2. Tính toán Phân trang (Pagination)
                int totalItems = filteredDocs.length;
                int totalPages = (totalItems / _rowsPerPage).ceil();
                if (_currentPage >= totalPages && totalPages > 0) _currentPage = totalPages - 1;

                int startIndex = _currentPage * _rowsPerPage;
                int endIndex = startIndex + _rowsPerPage;
                if (endIndex > totalItems) endIndex = totalItems;

                var paginatedDocs = filteredDocs.sublist(startIndex, endIndex);

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[100]),
                              columns: const [
                                DataColumn(label: Text('Tên', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('SĐT', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Vai trò', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Khóa TK', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: paginatedDocs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                final isBanned = data['isBanned'] ?? false;
                                final role = data['role'] ?? 'farmer';

                                return DataRow(
                                  cells: [
                                    DataCell(Text(data['name'] ?? '--')),
                                    DataCell(Text(data['email'] ?? 'N/A')),
                                    DataCell(Text(data['phone'] ?? data['phoneNumber'] ?? '--')),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: role == 'admin' ? Colors.purple[100] : (role == 'expert' ? Colors.blue[100] : Colors.green[100]),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          role == 'farmer' ? 'Nông dân' : (role == 'expert' ? 'Chuyên gia' : 'Admin'),
                                          style: TextStyle(
                                              color: role == 'admin' ? Colors.purple[800] : (role == 'expert' ? Colors.blue[800] : Colors.green[800]),
                                              fontSize: 12, fontWeight: FontWeight.bold
                                          ),
                                        ),
                                      ),
                                    ),
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
                          ),
                        ),
                      ),

                      // --- Footer Phân trang ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[200]!)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text('Tổng: $totalItems'),
                            const SizedBox(width: 24),
                            const Text('Số dòng:'),
                            const SizedBox(width: 8),
                            DropdownButton<int>(
                              value: _rowsPerPage,
                              underline: const SizedBox(),
                              items: [5, 10, 20, 50].map((e) => DropdownMenuItem(value: e, child: Text('$e'))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _rowsPerPage = val!;
                                  _currentPage = 0;
                                });
                              },
                            ),
                            const SizedBox(width: 24),
                            Text('${totalItems == 0 ? 0 : startIndex + 1}-${endIndex} của $totalItems'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
                            ),
                            IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
                            ),
                          ],
                        ),
                      )
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
