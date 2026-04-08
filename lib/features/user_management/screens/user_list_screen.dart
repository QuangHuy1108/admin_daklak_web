import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // --- Biến trạng thái ---
  String _searchQuery = '';
  String _selectedTab = 'Tất cả';
  int _currentPage = 0;
  final int _rowsPerPage = 8;

  final Color _primaryGreen = const Color(0xFF1B3D2F);
  final Color _accentBrown = const Color(0xFF8E4A1D);
  final Color _bgColor = const Color(0xFFF7F8F3);

  // --- Logic Firebase ---

  Future<void> _addUser(Map<String, dynamic> userData) async {
    await FirebaseFirestore.instance.collection('users').doc(userData['id']).set({
      'displayName': userData['displayName'], // Đã đổi thành displayName
      'email': userData['email'],
      'phone': userData['phone'],
      'role': userData['role'],
      'password': userData['password'], // Lưu mật khẩu (Lưu ý: Thực tế nên mã hóa)
      'isBanned': false,
      'isOnline': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // --- Dialogs & UI Logic ---

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final TextEditingController passController = TextEditingController();

    String suggestedId = 'AG-${Random().nextInt(90000) + 10000}';
    String displayName = '';
    String email = '';
    String phone = '';
    String role = 'farmer';
    String password = '';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Thêm người dùng mới', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 450,
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTextField(
                    label: 'ID hệ thống (Tự động)',
                    initialValue: suggestedId,
                    readOnly: true,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Tên hiển thị *',
                    hint: 'Nhập tên đầy đủ',
                    onChanged: (v) => displayName = v,
                    validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Email *',
                    hint: 'abc@gmail.com',
                    onChanged: (v) => email = v,
                    validator: (v) => (v == null || !v.contains('@gmail.com')) ? 'Email phải có @gmail.com' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    label: 'Số điện thoại',
                    onChanged: (v) => phone = v,
                  ),
                  const SizedBox(height: 16),

                  // --- Mục Mật khẩu ---
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: passController,
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Mật khẩu (6 số) *',
                            border: OutlineInputBorder(),
                            counterText: "", // Ẩn dòng đếm chữ
                          ),
                          validator: (v) => (v == null || v.length != 6 || !RegExp(r'^[0-9]+$').hasMatch(v))
                              ? 'Phải nhập đủ 6 số' : null,
                          onChanged: (v) => password = v,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          obscureText: true,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            labelText: 'Nhập lại mật khẩu *',
                            border: OutlineInputBorder(),
                            counterText: "",
                          ),
                          validator: (v) => v != passController.text ? 'Mật khẩu không khớp' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: role,
                    decoration: const InputDecoration(labelText: 'Vai trò', border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
                      DropdownMenuItem(value: 'expert', child: Text('Chuyên gia')),
                      DropdownMenuItem(value: 'farmer', child: Text('Nông dân')),
                    ],
                    onChanged: (v) => role = v!,
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                _addUser({
                  'id': suggestedId,
                  'displayName': displayName,
                  'email': email,
                  'phone': phone,
                  'role': role,
                  'password': password,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã thêm người dùng thành công!')));
              }
            },
            child: const Text('Lưu thông tin', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    String? initialValue,
    String? hint,
    bool readOnly = false,
    Function(String)? onChanged,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      initialValue: initialValue,
      readOnly: readOnly,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        filled: readOnly,
        fillColor: readOnly ? Colors.grey[100] : Colors.white,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Quản lý người dùng', style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryGreen)),
                const Spacer(),
                _buildSearchBar(),
                const SizedBox(width: 20),
              ],
            ),
            const SizedBox(height: 32),
            _buildFirestoreStats(),
            const SizedBox(height: 32),

            Row(
              children: [
                _buildTabButton('Tất cả'),
                const SizedBox(width: 10),
                _buildTabButton('Nông dân'),
                const SizedBox(width: 10),
                _buildTabButton('Chuyên gia'),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _showAddUserDialog,
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  label: const Text('Thêm người dùng mới', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(backgroundColor: _accentBrown, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildUserTable(),
          ],
        ),
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase(); // Sửa lỗi: Cập nhật biến tìm kiếm
            _currentPage = 0; // Reset về trang 1 khi tìm kiếm
          });
        },
        decoration: const InputDecoration(
            hintText: 'Tìm theo tên, email...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12)
        ),
      ),
    );
  }

  Widget _buildTabButton(String label) {
    bool isSelected = _selectedTab == label;
    return InkWell(
      onTap: () => setState(() { _selectedTab = label; _currentPage = 0; }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? _primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _buildFirestoreStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const LinearProgressIndicator();
        int total = snapshot.data!.docs.length;
        int farmers = snapshot.data!.docs.where((d) => (d.data() as Map)['role'] == 'farmer').length;
        int experts = snapshot.data!.docs.where((d) => (d.data() as Map)['role'] == 'expert').length;
        return Row(
          children: [
            _buildStatCard('Tổng người dùng', total.toString(), Icons.eco, Colors.green[50]!, Colors.green[800]!),
            const SizedBox(width: 24),
            _buildStatCard('Nông dân', farmers.toString(), Icons.agriculture, Colors.orange[50]!, Colors.orange[800]!),
            const SizedBox(width: 24),
            _buildStatCard('Chuyên gia', experts.toString(), Icons.psychology, Colors.teal[50]!, Colors.teal[800]!),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 30)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
              Text(value, style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryGreen)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // 1. Lọc dữ liệu Real-time
          var filteredDocs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final name = (data['name'] ?? '').toString().toLowerCase();
            final email = (data['email'] ?? '').toString().toLowerCase();
            final role = data['role'] ?? 'farmer';

            bool matchesTab = (_selectedTab == 'Tất cả') ||
                (_selectedTab == 'Nông dân' && role == 'farmer') ||
                (_selectedTab == 'Chuyên gia' && role == 'expert');

            // Tìm theo tên HOẶC email
            bool matchesSearch = name.contains(_searchQuery) || email.contains(_searchQuery);

            return matchesTab && matchesSearch;
          }).toList();

          int totalItems = filteredDocs.length;
          int totalPages = (totalItems / _rowsPerPage).ceil();
          if (totalPages == 0) totalPages = 1;

          int startIndex = _currentPage * _rowsPerPage;
          int endIndex = min(startIndex + _rowsPerPage, totalItems);

          var paginatedDocs = totalItems == 0 ? [] : filteredDocs.sublist(startIndex, endIndex);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(children: [
                  _headerCell('NGƯỜI DÙNG', flex: 3), _headerCell('LIÊN HỆ', flex: 3),
                  _headerCell('VAI TRÒ', flex: 2), _headerCell('TRẠNG THÁI', flex: 2), _headerCell('HÀNH ĐỘNG', flex: 1),
                ]),
              ),
              const Divider(height: 1),
              if (paginatedDocs.isEmpty)
                const Padding(padding: EdgeInsets.all(40), child: Text('Không có dữ liệu phù hợp.'))
              else
                ...paginatedDocs.map((doc) => _buildUserRow(doc)).toList(),
              _buildTableFooter(totalItems, totalPages),
            ],
          );
        },
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(flex: flex, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)));

  Widget _buildUserRow(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'] ?? 'farmer';
    final isOnline = data['isOnline'] ?? false;
    final isBanned = data['isBanned'] ?? false;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
      child: Row(
        children: [
          Expanded(flex: 3, child: Row(children: [
            const CircleAvatar(radius: 20, child: Icon(Icons.person)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row( // <-- Thêm Row để chứa tên và nhãn
                children: [
                  Text(data['displayName'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (isBanned) ...[ // Nếu bị khóa thì thêm Badge đỏ
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red[100], borderRadius: BorderRadius.circular(4)),
                      child: const Text('ĐÃ KHÓA', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
              Text('ID: ${doc.id}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
            )
          ])),
          Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['email'] ?? ''), Text(data['phone'] ?? '', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Expanded(flex: 2, child: _buildRoleBadge(role)),
          Expanded(flex: 2, child: _buildStatusCell(isOnline)),
          Expanded(flex: 1, child: _buildActionMenu(doc.id, isBanned)),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        _headerCell('NGƯỜI DÙNG', flex: 3), _headerCell('LIÊN HỆ', flex: 3),
        _headerCell('VAI TRÒ', flex: 2), _headerCell('TRẠNG THÁI', flex: 2), _headerCell('HÀNH ĐỘNG', flex: 1),
      ]),
    );
  }

  Widget _buildStatusCell(bool isOnline) {
    return Row(children: [
      Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : Colors.grey),
      const SizedBox(width: 8),
      Text(isOnline ? 'Đang hoạt động' : 'Ngoại tuyến', style: TextStyle(color: isOnline ? Colors.green[700] : Colors.grey, fontSize: 13)),
    ]);
  }

  Widget _buildActionMenu(String docId, bool isBanned) {
    return PopupMenuButton<String>(
      onSelected: (val) {
        if (val == 'delete') _showConfirmDialog(title: 'Xóa', content: 'Xóa người dùng này?', onConfirm: () => _deleteUser(docId));
        if (val == 'block') _toggleBanStatus(docId, isBanned);
      },
      itemBuilder: (ctx) => [
        PopupMenuItem(value: 'block', child: Text(isBanned ? 'Mở khóa' : 'Khóa')),
        const PopupMenuItem(value: 'delete', child: Text('Xóa', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    Color bg = role == 'admin' ? Colors.purple[50]! : (role == 'expert' ? Colors.green[50]! : Colors.orange[50]!);
    Color txt = role == 'admin' ? Colors.purple[700]! : (role == 'expert' ? Colors.green[700]! : Colors.orange[700]!);
    String label = role == 'admin' ? 'QUẢN TRỊ VIÊN' : (role == 'expert' ? 'CHUYÊN GIA' : 'NÔNG DÂN');
    return UnconstrainedBox(alignment: Alignment.centerLeft, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: txt)),
    ));
  }

  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(content),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen), onPressed: () { onConfirm(); Navigator.pop(context); }, child: const Text('Xác nhận', style: TextStyle(color: Colors.white)))],
    ));
  }

  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
  }

  Future<void> _toggleBanStatus(String userId, bool currentBanStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBanned': !currentBanStatus});
  }

  Widget _buildTableFooter(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text('Hiển thị ${total == 0 ? 0 : _currentPage * _rowsPerPage + 1} - ${min((_currentPage + 1) * _rowsPerPage, total)} trong $total người dùng', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const Spacer(),
          _pageBox(Icons.chevron_left, enabled: _currentPage > 0, onTap: () => setState(() => _currentPage--)),
          ...List.generate(totalPages, (index) {
            if (totalPages > 5 && (index > _currentPage + 1 || index < _currentPage - 1) && index != 0 && index != totalPages - 1) {
              if (index == 1 || index == totalPages - 2) return const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Text('...'));
              return const SizedBox();
            }
            return _pageBox('${index + 1}', active: _currentPage == index, onTap: () => setState(() => _currentPage = index));
          }),
          _pageBox(Icons.chevron_right, enabled: _currentPage < totalPages - 1, onTap: () => setState(() => _currentPage++)),
        ],
      ),
    );
  }

  Widget _pageBox(dynamic content, {bool active = false, bool enabled = true, VoidCallback? onTap}) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(left: 8),
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: active ? _primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? _primaryGreen : Colors.grey[200]!),
        ),
        child: Center(
          child: content is IconData
              ? Icon(content, size: 18, color: enabled ? (active ? Colors.white : Colors.black) : Colors.grey)
              : Text(content.toString(), style: TextStyle(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ),
    );
  }
}