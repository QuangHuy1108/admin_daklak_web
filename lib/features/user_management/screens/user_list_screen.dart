import 'package:flutter/material.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:math';
import 'dart:async';
import '../../../core/widgets/common/glass_container.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  final Color _primaryGreen = const Color(0xFF1B3D2F);
  final Color _accentBrown = const Color(0xFF8E4A1D);
  final Color _bgColor = Colors.transparent;

  // --- Biến trạng thái ---
  String _searchQuery = '';
  String _selectedTab = 'Tất cả';
  final int _rowsPerPage = 10; // Đổi lên 10 cho server-side

  // --- Phase 2: Server-side Pagination State ---
  List<DocumentSnapshot> _userDocs = [];
  DocumentSnapshot? _lastDoc;
  bool _isLoading = false;
  bool _hasMore = true;
  Timer? _debounce;

  // --- Phase 1: Bulk UX & Drawer State ---
  List<String> _selectedUserIds = [];
  Map<String, dynamic>? _selectedUserForDrawer;

  @override
  void initState() {
    super.initState();
    _fetchUsers(isRefresh: true);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // --- Logic Fetch Dữ liệu (Server-side) ---

  Future<void> _fetchUsers({bool isRefresh = false}) async {
    // Nếu đang load và KHÔNG PHẢI là refresh thì mới return. 
    // Nếu là refresh (từ addUser/deleteUser) thì phải cho phép chạy.
    if (_isLoading && !isRefresh) return;
    if (!isRefresh && !_hasMore) return;

    setState(() {
      _isLoading = true;
      if (isRefresh) {
        _userDocs = [];
        _lastDoc = null;
        _hasMore = true;
      }
    });

    try {
      Query query = FirebaseFirestore.instance.collection('users');

      // 1. Lọc theo Vai trò / Trạng thái
      if (_selectedTab == 'Nông dân') {
        query = query.where('role', isEqualTo: 'farmer');
      } else if (_selectedTab == 'Chuyên gia') {
        query = query.where('role', isEqualTo: 'expert');
      } else if (_selectedTab == 'Bị khóa') {
        query = query.where('isBanned', isEqualTo: true);
      }

      // 2. Lọc theo Tìm kiếm (Prefix chuẩn hóa)
      if (_searchQuery.isNotEmpty) {
        String normalizedQuery = _normalize(_searchQuery);
        query = query
            .where('searchName', isGreaterThanOrEqualTo: normalizedQuery)
            .where('searchName', isLessThan: normalizedQuery + '\uf8ff')
            .orderBy('searchName');
      } else {
        // Mặc định sắp xếp theo ngày tạo (đảm bảo đồng nhất)
        query = query.orderBy('createdAt', descending: true);
      }

      // 3. Phân trang
      query = query.limit(_rowsPerPage);
      if (!isRefresh && _lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }

      final snapshot = await query.get();
      final newDocs = snapshot.docs;

      setState(() {
        _userDocs.addAll(newDocs);
        if (newDocs.length < _rowsPerPage) {
          _hasMore = false;
        }
        if (newDocs.isNotEmpty) {
          _lastDoc = newDocs.last;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Firebase Query Error: $e");
      // TODO: Nếu thiếu Composite Index, Link tạo Index sẽ xuất hiện ở đây trong console.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tải dữ liệu: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // --- Normalization Engine (Advanced Search) ---

  String _normalize(String text) {
    String str = text.toLowerCase();
    // Thay thế các ký tự tiếng Việt có dấu
    str = str.replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a');
    str = str.replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e');
    str = str.replaceAll(RegExp(r'[ìíịỉĩ]'), 'i');
    str = str.replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o');
    str = str.replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u');
    str = str.replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y');
    str = str.replaceAll(RegExp(r'[đ]'), 'd');
    // Xóa ký tự đặc biệt, giữ lại khoảng trắng
    str = str.replaceAll(RegExp(r'[^\w\s]'), '');
    return str.trim();
  }

  // --- Logic Firebase (Secure via Cloud Functions) ---

  Future<bool> _addUser(Map<String, dynamic> userData) async {
    setState(() => _isLoading = true);
    try {
      // Xóa createdAt nếu có để tránh lỗi Int64 trên môi trường Web
      userData.remove('createdAt');

      // Đảm bảo tất cả dữ liệu gửi đi là String để tránh lỗi Int64 trên Web
      final Map<String, String> sanitizedData = userData.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );

      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('createSystemUser');
      
      final result = await callable.call(sanitizedData);

      // Xử lý kết quả trả về một cách cực kỳ an toàn cho Web
      final dynamic responseData = result.data;
      bool isSuccess = false;
      String? message;

      if (responseData != null && responseData is Map) {
        final successValue = responseData['success'];
        isSuccess = (successValue == true || successValue.toString() == 'true');
        message = responseData['message']?.toString();
      }

      if (isSuccess) {
        await _fetchUsers(isRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Thêm người dùng thành công!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true; // Thành công
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message ?? 'Không thể tạo người dùng. Vui lòng thử lại.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return false; // Trả về false nếu isSuccess là false
      }
    } on FirebaseFunctionsException catch (e) {
      final String errorMessage = e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $errorMessage'), backgroundColor: Colors.red),
        );
      }
      return false; // Trả về false nếu bị lỗi Functions
    } catch (e) {
      // Chuyển đối tượng lỗi sang String ngay lập tức để tránh lỗi DiagnosticsNode trên Web
      final String errorStr = e.toString();
      print('Cloud Function Error: $errorStr');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi không xác định: $errorStr'), backgroundColor: Colors.red),
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteUser(String userId) async {
    setState(() => _isLoading = true);
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('deleteSystemUser');
      
      final result = await callable.call({'uid': userId.toString()});

      final dynamic responseData = result.data;
      bool isSuccess = false;

      if (responseData != null && responseData is Map) {
        final successValue = responseData['success'];
        isSuccess = (successValue == true || successValue.toString() == 'true');
      }

      if (isSuccess) {
        await _fetchUsers(isRefresh: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa người dùng thành công!'), backgroundColor: Colors.green),
          );
        }
      }
    } on FirebaseFunctionsException catch (e) {
      final String errorMessage = e.message ?? e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi xóa: $errorMessage'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      final String errorStr = e.toString();
      print('Cloud Function Delete Error: $errorStr');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi hệ thống: $errorStr'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Thêm người dùng mới', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryGreen,
              minimumSize: const Size(120, 45),
            ),
            onPressed: _isLoading ? null : () async {
              if (formKey.currentState!.validate()) {
                // Chúng ta cần setDialogState để cái spinner trong Dialog hiện lên ngay
                setDialogState(() {}); 
                
                final success = await _addUser({
                  'id': suggestedId,
                  'displayName': displayName,
                  'email': email,
                  'phone': phone,
                  'role': role,
                  'password': password,
                });

                if (success && context.mounted) {
                  Navigator.pop(context);
                } else if (context.mounted) {
                  // Nếu fail thì update lại UI để gỡ spinner
                  setDialogState(() {});
                }
              }
            },
            child: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text('Lưu thông tin', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
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
      backgroundColor: Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          bool isDesktop = constraints.maxWidth >= 800;

          Widget content = SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Quản lý người dùng', style: Theme.of(context).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
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
                    const SizedBox(width: 10),
                    _buildTabButton('Bị khóa'),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                      label: Text('Thêm người dùng mới', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentBrown,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildUserTable(),
              ],
            ),
          );

          if (isDesktop) {
            return Row(
              children: [
                Expanded(child: content),
                if (_selectedUserForDrawer != null)
                  Container(
                    width: 400,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(left: BorderSide(color: Colors.grey[200]!)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-5, 0))],
                    ),
                    child: _buildRightDrawer(),
                  ),
              ],
            );
          } else {
            return Stack(
              children: [
                content,
                if (_selectedUserForDrawer != null)
                  Positioned.fill(child: _buildRightDrawer()),
              ],
            );
          }
        },
      ),
    );
  }

  // --- Widgets ---

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
            ? AppColors.darkSurfaceVariant 
            : Colors.grey[200], 
        borderRadius: BorderRadius.circular(30)
      ),
      child: TextField(
        onChanged: (val) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            setState(() {
              _searchQuery = val.trim();
            });
            _fetchUsers(isRefresh: true);
          });
        },
        decoration: const InputDecoration(
            hintText: 'Tìm theo tên...',
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
      onTap: () {
        if (!isSelected) {
          setState(() => _selectedTab = label);
          _fetchUsers(isRefresh: true);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(color: isSelected ? _primaryGreen : Colors.transparent, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey[600]), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 30)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.6))),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? Colors.white : _primaryGreen)),
            ])
          ],
        ),
      ),
    );
  }

  Widget _buildUserTable() {
    return GlassContainer(
      child: Column(
        children: [
          if (_userDocs.isEmpty && _isLoading)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else ...[
            if (_selectedUserIds.isNotEmpty)
              _buildBulkActionBar()
            else
              _buildTableHeader(_userDocs),
            const Divider(height: 1),
            if (_userDocs.isEmpty)
              const Padding(padding: EdgeInsets.all(40), child: Text('Không có dữ liệu phù hợp.'))
            else
              ..._userDocs.map((doc) => _buildUserRow(doc)).toList(),
            _buildTableFooter(_userDocs.length),
          ]
        ],
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(flex: flex, child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey)));

  Widget _buildUserRow(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final role = data['role'] ?? 'farmer';
    final isOnline = data['isOnline'] ?? false;
    final isBanned = data['isBanned'] ?? false;
    final isSelected = _selectedUserIds.contains(doc.id);

    final String? imageUrl = data['photoURL'] ?? data['avatar'];
    final Widget avatarWidget = (imageUrl != null && imageUrl.isNotEmpty)
        ? CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl))
        : const CircleAvatar(radius: 20, child: Icon(Icons.person));

    return InkWell(
      onTap: () => setState(() => _selectedUserForDrawer = {...data, 'id': doc.id}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green.withOpacity(0.05) : Colors.transparent,
          border: Border(bottom: BorderSide(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkBorder : Colors.grey[50]!)),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 40,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {}, // Prevent InkWell splash
                child: Checkbox(
                  value: isSelected,
                  activeColor: _primaryGreen,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedUserIds.add(doc.id);
                      } else {
                        _selectedUserIds.remove(doc.id);
                      }
                    });
                  },
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  avatarWidget,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      data['displayName'] ?? 'Không tên',
                                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isBanned) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.lock_rounded, size: 14, color: Colors.red),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'ID: ${doc.id}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey, fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    data['email'] ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    data['phone'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(flex: 2, child: _buildRoleBadge(role)),
            Expanded(flex: 2, child: _buildStatusCell(isOnline, isBanned)),
            Expanded(flex: 1, child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {}, // Prevent InkWell splash
              child: _buildActionMenu(doc.id, isBanned),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(List<DocumentSnapshot> visibleDocs) {
    bool allPaginatedSelected = visibleDocs.isNotEmpty && visibleDocs.every((doc) => _selectedUserIds.contains(doc.id));

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(children: [
        SizedBox(
          width: 40,
          child: Checkbox(
            value: allPaginatedSelected,
            activeColor: _primaryGreen,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  for (var doc in visibleDocs) {
                    if (!_selectedUserIds.contains(doc.id)) _selectedUserIds.add(doc.id);
                  }
                } else {
                  for (var doc in visibleDocs) {
                    _selectedUserIds.remove(doc.id);
                  }
                }
              });
            },
          ),
        ),
        _headerCell('NGƯỜI DÙNG', flex: 3),
        _headerCell('LIÊN HỆ', flex: 3),
        _headerCell('VAI TRÒ', flex: 2),
        _headerCell('TRẠNG THÁI', flex: 2),
        _headerCell('HÀNH ĐỘNG', flex: 1),
      ]),
    );
  }

  Widget _buildStatusCell(bool isOnline, bool isBanned) {
    if (isBanned) {
      return Text('---', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey));
    }
    return Row(children: [
      Icon(Icons.circle, size: 8, color: isOnline ? Colors.green : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey)),
      const SizedBox(width: 8),
      Text(isOnline ? 'Đang hoạt động' : 'Ngoại tuyến', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: isOnline ? Colors.green[700] : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkTextMuted : Colors.grey))),
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
        PopupMenuItem(value: 'delete', child: Text('Xóa', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.red))),
      ],
    );
  }

  Widget _buildRoleBadge(String role) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color bg = role == 'admin' 
        ? (isDark ? Colors.purple[900]!.withOpacity(0.3) : Colors.purple[50]!) 
        : (role == 'expert' ? (isDark ? Colors.green[900]!.withOpacity(0.3) : Colors.green[50]!) : (isDark ? Colors.orange[900]!.withOpacity(0.3) : Colors.orange[50]!));
    Color txt = role == 'admin' 
        ? (isDark ? Colors.purple[200]! : Colors.purple[700]!) 
        : (role == 'expert' ? (isDark ? Colors.green[200]! : Colors.green[700]!) : (isDark ? Colors.orange[200]! : Colors.orange[700]!));
    String label = role == 'admin' ? 'QUẢN TRỊ VIÊN' : (role == 'expert' ? 'CHUYÊN GIA' : 'NÔNG DÂN');
    return UnconstrainedBox(alignment: Alignment.centerLeft, child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: txt)),
    ));
  }

  Widget _buildBulkActionBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: _primaryGreen.withOpacity(0.05),
      child: Row(
        children: [
          Checkbox(
            value: true,
            activeColor: _primaryGreen,
            onChanged: (val) => setState(() => _selectedUserIds.clear()),
          ),
          const SizedBox(width: 8),
          Text('Đã chọn ${_selectedUserIds.length} người dùng', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.black87)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng khóa hàng loạt đang phát triển'))),
            icon: const Icon(Icons.block, size: 18, color: Colors.red),
            label: Text('Khóa tài khoản', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.red)),
          ),
          const SizedBox(width: 16),
          ElevatedButton.icon(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tính năng thông báo hàng loạt đang phát triển'))),
            icon: const Icon(Icons.send_rounded, size: 18, color: Colors.white),
            label: Text('Gửi thông báo', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white)),
            style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLog(String targetUid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('audit_logs')
          .where('targetUid', isEqualTo: targetUid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text('Chưa có lịch sử hoạt động.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final log = doc.data() as Map<String, dynamic>;
            final DateTime? ts = (log['timestamp'] as Timestamp?)?.toDate();
            final String timeStr = ts != null 
                ? '${ts.day}/${ts.month} ${ts.hour}:${ts.minute.toString().padLeft(2, '0')}'
                : 'Đang chờ...';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    log['action'] == 'CREATE_USER' ? Icons.add_circle_outline : Icons.delete_outline,
                    size: 18,
                    color: _primaryGreen,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log['action'] == 'CREATE_USER' ? 'Tạo tài khoản' : 'Xóa tài khoản',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          log['details'] ?? '',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(timeStr, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildRightDrawer() {
    final data = _selectedUserForDrawer!;
    final role = data['role'] ?? 'farmer';
    final String? imageUrl = data['photoURL'] ?? data['avatar'];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Text('Chi tiết người dùng', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(onPressed: () => setState(() => _selectedUserForDrawer = null), icon: const Icon(Icons.close)),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty) ? NetworkImage(imageUrl) : null,
                  child: (imageUrl == null || imageUrl.isEmpty) ? const Icon(Icons.person, size: 50) : null,
                ),
                const SizedBox(height: 16),
                Text(data['displayName'] ?? 'Không tên', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                Text('ID: ${data['id']}', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
                const SizedBox(height: 12),
                _buildRoleBadge(role),
                const SizedBox(height: 32),

                _drawerInfoTile(Icons.email_outlined, 'Email', data['email'] ?? 'Chưa cập nhật'),
                _drawerInfoTile(Icons.phone_outlined, 'Số điện thoại', data['phone'] ?? 'Chưa cập nhật'),
                const Divider(height: 48),

                if (role == 'farmer') ...[
                  _drawerSectionHeader('HOẠT ĐỘNG NÔNG DÂN'),
                  _drawerActionTile(Icons.agriculture, 'Vườn đã đăng ký', '2 vườn'),
                  _drawerActionTile(Icons.medical_services_outlined, 'Lịch sử chẩn đoán AI', '15 lần'),
                ] else if (role == 'expert') ...[
                  _drawerSectionHeader('QUẢN LÝ CHUYÊN GIA'),
                  _drawerActionTile(Icons.calendar_today_outlined, 'Lịch hẹn chờ duyệt', '3 lịch'),
                  _drawerActionTile(Icons.description_outlined, 'Bài viết chuyên môn', '8 bài'),
                ],

                const Divider(height: 48),
                _drawerSectionHeader('ACTIVITY LOG (NHẬT KÝ HÀNH ĐỘNG)'),
                _buildActivityLog(data['uid'] ?? data['id']),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _drawerInfoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.grey)),
              Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            ],
          )
        ],
      ),
    );
  }

  Widget _drawerSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey[400], letterSpacing: 1.1)),
      ),
    );
  }

  Widget _drawerActionTile(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: _primaryGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold)),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        ],
      ),
    );
  }

  void _showConfirmDialog({required String title, required String content, required VoidCallback onConfirm}) {
    showDialog(context: context, builder: (context) => AlertDialog(
      title: Text(title), content: Text(content),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: _primaryGreen), onPressed: () { onConfirm(); Navigator.pop(context); }, child: Text('Xác nhận', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)))],
    ));
  }

  // _deleteUser đã được di chuyển lên trên phần logic Firebase

  Future<void> _toggleBanStatus(String userId, bool currentBanStatus) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'isBanned': !currentBanStatus});
    _fetchUsers(isRefresh: true);
  }

  Widget _buildTableFooter(int currentCount) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text('Hiển thị $currentCount người dùng', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
          const Spacer(),
          if (_isLoading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          else if (_hasMore)
            ElevatedButton(
              onPressed: () => _fetchUsers(),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text('Tải thêm', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            )
          else
            Text('Đã tải hết danh sách.', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey)),
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
              : Text(content.toString(), style: Theme.of(context).textTheme.labelLarge?.copyWith(color: active ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}