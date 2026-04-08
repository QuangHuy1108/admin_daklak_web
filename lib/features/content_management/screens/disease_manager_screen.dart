import 'dart:async';
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

  // Variables cho Search, Filter, View State và Pagination
  String _searchQuery = '';
  Timer? _debounce;
  String _selectedFilterType = 'Tất cả';
  String _sortBy = 'Mới nhất';
  bool _isViewingPending = false;

  // Variables cho Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 8; // Số item hiển thị trên 1 trang giống thiết kế

  static const List<String> _types = ['Tất cả', 'Côn trùng', 'Nấm', 'Vi-rút', 'Khác'];
  static const List<String> _sortOptions = ['Mới nhất', 'Mức độ nguy hiểm'];

  List<String> _stringToList(String input) {
    if (input.isEmpty) return [];
    return input.split(RegExp(r'[,\n]')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = query.toLowerCase();
        _currentPage = 1; // Reset về trang 1 khi search
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  // =========================================================================
  // LOGIC THÊM/SỬA SÂU BỆNH
  // =========================================================================
  void _showDiseaseFormDialog({DocumentSnapshot? existingDoc}) {
    final bool isEditing = existingDoc != null;
    final data = isEditing ? existingDoc.data() as Map<String, dynamic> : {};

    final nameController = TextEditingController(text: data['name'] ?? '');
    final seasonController = TextEditingController(text: data['season'] ?? '');
    final emergencyController = TextEditingController(text: data['emergency_level'] ?? '');
    final affectedPartsController = TextEditingController(text: (data['affected_parts'] as List? ?? []).join(', '));
    final symptomsController = TextEditingController(text: (data['symptoms'] as List? ?? []).join('\n'));
    final treatmentController = TextEditingController(text: (data['treatment'] as List? ?? []).join('\n'));
    final preventionController = TextEditingController(text: (data['prevention'] as List? ?? []).join('\n'));
    final tagsController = TextEditingController(text: (data['tags'] as List? ?? []).join(', '));

    String selectedType = data['type'] ?? 'Nấm';
    if (!_types.contains(selectedType) && selectedType != 'Tất cả') selectedType = 'Khác';

    bool isActive = data['isActive'] ?? true;

    String? existingImageUrl = data['imageUrl'];
    Uint8List? newImageBytes;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text(isEditing ? 'Chỉnh sửa: ${data['name']}' : 'Thêm Sâu bệnh Mới'),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () async {
                      final XFile? image = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (image != null) {
                        final bytes = await image.readAsBytes();
                        setStateDialog(() => newImageBytes = bytes);
                      }
                    },
                    child: Container(
                      height: 180, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                      child: newImageBytes != null
                          ? Image.memory(newImageBytes!, fit: BoxFit.contain)
                          : (existingImageUrl != null ? Image.network(existingImageUrl) : const Icon(Icons.add_a_photo, size: 50)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Tên bệnh', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Switch(
                        value: isActive,
                        onChanged: (val) => setStateDialog(() => isActive = val),
                        activeColor: const Color(0xFF1B4332),
                      ),
                      Text(isActive ? "Đã duyệt (Đang hiển thị)" : "Chờ xử lý (Đang ẩn)", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        value: selectedType,
                        items: ['Côn trùng', 'Nấm', 'Vi-rút', 'Khác'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) => selectedType = v!,
                        decoration: const InputDecoration(labelText: 'Loại', border: OutlineInputBorder()),
                      )),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: seasonController, decoration: const InputDecoration(labelText: 'Mùa vụ (VD: Mùa mưa)', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: emergencyController, decoration: const InputDecoration(labelText: 'Mức độ khẩn cấp', border: OutlineInputBorder()))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: affectedPartsController, decoration: const InputDecoration(labelText: 'Bộ phận bị hại (cách bởi dấu phẩy)', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: symptomsController, maxLines: 3, decoration: const InputDecoration(labelText: 'Triệu chứng (mỗi dòng 1 ý)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: treatmentController, maxLines: 3, decoration: const InputDecoration(labelText: 'Cách điều trị (mỗi dòng 1 ý)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: preventionController, maxLines: 3, decoration: const InputDecoration(labelText: 'Cách phòng ngừa (mỗi dòng 1 ý)', border: OutlineInputBorder())),
                  const SizedBox(height: 10),
                  TextField(controller: tagsController, decoration: const InputDecoration(labelText: 'Tags từ khóa (cách bởi dấu phẩy)', border: OutlineInputBorder())),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
              onPressed: _isLoading ? null : () async {
                setStateDialog(() => _isLoading = true);
                try {
                  String finalImageUrl = existingImageUrl ?? '';
                  if (newImageBytes != null) {
                    String fileName = 'pest_diseases/${DateTime.now().millisecondsSinceEpoch}.png';
                    TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putData(newImageBytes!);
                    finalImageUrl = await snapshot.ref.getDownloadURL();
                  }

                  Map<String, dynamic> diseaseData = {
                    'name': nameController.text.trim(),
                    'type': selectedType,
                    'season': seasonController.text.trim(),
                    'emergency_level': emergencyController.text.trim(),
                    'isActive': isActive,
                    'affected_parts': _stringToList(affectedPartsController.text),
                    'symptoms': _stringToList(symptomsController.text),
                    'treatment': _stringToList(treatmentController.text),
                    'prevention': _stringToList(preventionController.text),
                    'tags': _stringToList(tagsController.text),
                    'imageUrl': finalImageUrl,
                    'updatedAt': FieldValue.serverTimestamp(),
                  };

                  if (isEditing) {
                    await existingDoc.reference.update(diseaseData);
                  } else {
                    diseaseData['createdAt'] = FieldValue.serverTimestamp();
                    await _firestore.collection('pest_diseases').add(diseaseData);
                  }

                  if (context.mounted) Navigator.pop(context);
                } finally {
                  setStateDialog(() => _isLoading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B4332)),
              child: const Text('Lưu dữ liệu', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // LOGIC XÓA SÂU BỆNH
  // =========================================================================
  Future<void> _deleteDisease(DocumentSnapshot doc) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa "${doc['name']}" không? Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa vĩnh viễn', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        setState(() => _isLoading = true);
        final data = doc.data() as Map<String, dynamic>;

        if (data['imageUrl'] != null && data['imageUrl'].toString().contains('firebase')) {
          try {
            await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete();
          } catch (e) {
            debugPrint("Lỗi khi xóa ảnh: $e");
          }
        }
        await doc.reference.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã xóa dữ liệu thành công!'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi khi xóa: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  // =========================================================================
  // GIAO DIỆN CHÍNH
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    const Color primaryGreen = Color(0xFF1B4332);
    const Color bgSlate = Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: bgSlate,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('pest_diseases').snapshots(),
            builder: (context, pestSnapshot) {
              return StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('ai_chat_logs').snapshots(),
                  builder: (context, aiSnapshot) {
                    if (!pestSnapshot.hasData || !aiSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(color: primaryGreen));
                    }

                    final pestDocs = pestSnapshot.data!.docs;
                    final aiDocs = aiSnapshot.data!.docs;

                    // ====================================================================
                    // 1. TÍNH TOÁN DỮ LIỆU THẬT
                    // ====================================================================

                    final now = DateTime.now();
                    final sevenDaysAgo = now.subtract(const Duration(days: 7));

                    int totalPests = pestDocs.length;
                    int newIn7Days = 0;
                    int treatableCount = 0;
                    int untreatableCount = 0;

                    for (var doc in pestDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      if (data['createdAt'] != null) {
                        final createdAtDate = (data['createdAt'] as Timestamp).toDate();
                        if (createdAtDate.isAfter(sevenDaysAgo)) newIn7Days++;
                      }
                      final treatment = data['treatment'] as List?;
                      if (treatment != null && treatment.isNotEmpty) {
                        treatableCount++;
                      } else {
                        untreatableCount++;
                      }
                    }

                    double treatableRate = totalPests == 0 ? 0 : (treatableCount / totalPests * 100);
                    double untreatableRate = totalPests == 0 ? 0 : (untreatableCount / totalPests * 100);

                    // --- Dữ liệu Hàng Phân Tích ---
                    Map<String, int> typeCounts = {'Côn trùng': 0, 'Nấm': 0, 'Vi-rút': 0, 'Vi khuẩn': 0, 'Khác': 0};
                    for (var doc in pestDocs) {
                      String type = (doc.data() as Map<String, dynamic>)['type'] ?? 'Khác';
                      if(type.toLowerCase().contains('côn trùng')) type = 'Côn trùng';
                      else if(type.toLowerCase().contains('nấm')) type = 'Nấm';
                      else if(type.toLowerCase().contains('vi-rút') || type.toLowerCase().contains('virus')) type = 'Vi-rút';
                      else if(type.toLowerCase().contains('vi khuẩn')) type = 'Vi khuẩn';
                      else type = 'Khác';

                      typeCounts[type] = (typeCounts[type] ?? 0) + 1;
                    }
                    int maxTypeCount = typeCounts.isEmpty ? 1 : typeCounts.values.reduce((a, b) => a > b ? a : b);
                    if (maxTypeCount == 0) maxTypeCount = 1;

                    Map<String, int> topCategories = {};
                    for (var doc in aiDocs) {
                      final cat = (doc.data() as Map)['category_tag']?.toString();
                      if (cat != null && cat.isNotEmpty) {
                        topCategories[cat] = (topCategories[cat] ?? 0) + 1;
                      }
                    }
                    var sortedTop = topCategories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
                    int totalAILogs = aiDocs.length;

                    var pendingPestsList = pestDocs.where((doc) => (doc.data() as Map<String, dynamic>)['isActive'] == false).toList();
                    int pendingCount = pendingPestsList.length;

                    // --- Dữ liệu cho Bảng (Table) kèm Lọc thông minh ---
                    var filteredDocs = pestDocs.where((doc) {
                      var data = doc.data() as Map<String, dynamic>;

                      // Lọc theo Search
                      bool matchesSearch = (data['name'] ?? '').toLowerCase().contains(_searchQuery);

                      // Lọc theo Tab Type linh hoạt hơn (dùng contains để bao quát dữ liệu đa dạng)
                      bool matchesType = false;
                      if (_selectedFilterType == 'Tất cả') {
                        matchesType = true;
                      } else {
                        String docType = (data['type'] ?? '').toString().toLowerCase();
                        String targetType = _selectedFilterType.toLowerCase();
                        if (docType.contains(targetType)) {
                          matchesType = true;
                        } else if (targetType == 'khác' &&
                            !docType.contains('côn trùng') &&
                            !docType.contains('nấm') &&
                            !docType.contains('vi-rút') &&
                            !docType.contains('vi khuẩn')) {
                          matchesType = true;
                        }
                      }

                      // Lọc theo Trạng thái (Pending View)
                      bool matchesStatus = _isViewingPending ? (data['isActive'] == false) : (data['isActive'] == true);

                      return matchesSearch && matchesType && matchesStatus;
                    }).toList();

                    // Sort
                    filteredDocs.sort((a, b) {
                      var dataA = a.data() as Map<String, dynamic>;
                      var dataB = b.data() as Map<String, dynamic>;
                      if (_sortBy == 'Mức độ nguy hiểm') {
                        return (dataB['emergency_level'] ?? '').compareTo(dataA['emergency_level'] ?? '');
                      } else {
                        Timestamp tA = dataA['createdAt'] ?? Timestamp.now();
                        Timestamp tB = dataB['createdAt'] ?? Timestamp.now();
                        return tB.compareTo(tA);
                      }
                    });

                    // ====================================================================
                    // XỬ LÝ PHÂN TRANG (PAGINATION)
                    // ====================================================================
                    int totalFilteredItems = filteredDocs.length;
                    int totalPages = (totalFilteredItems / _itemsPerPage).ceil();

                    // Đảm bảo trang hiện tại không vượt quá tổng số trang
                    if (_currentPage > totalPages && totalPages > 0) _currentPage = totalPages;

                    // Cắt danh sách data theo trang hiện tại
                    var paginatedDocs = filteredDocs
                        .skip((_currentPage - 1) * _itemsPerPage)
                        .take(_itemsPerPage)
                        .toList();

                    // ====================================================================
                    // 2. VẼ GIAO DIỆN
                    // ====================================================================
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (_isViewingPending)
                                    IconButton(
                                      icon: const Icon(Icons.arrow_back, color: primaryGreen, size: 28),
                                      onPressed: () => setState(() {
                                        _isViewingPending = false;
                                        _currentPage = 1;
                                      }),
                                    ),
                                  Text(
                                      _isViewingPending ? "Danh sách Chờ Duyệt" : "Quản lý Thư viện Sâu Bệnh",
                                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: primaryGreen)
                                  ),
                                ],
                              ),
                              SizedBox(
                                width: 300,
                                child: TextField(
                                  onChanged: _onSearchChanged,
                                  decoration: InputDecoration(
                                    hintText: 'Tìm kiếm sâu bệnh...',
                                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                                    filled: true, fillColor: Colors.grey.shade200,
                                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                                  ),
                                ),
                              )
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Chỉ hiển thị KPI và Chart nếu KHÔNG ở màn hình Pending
                          if (!_isViewingPending) ...[
                            // (A) HÀNG KPI CHÍNH
                            Row(
                              children: [
                                Expanded(child: _buildKPICardUI("Total Diseases", "$totalPests", "Total", Colors.orange)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildKPICardUI("Added in 7 days", "+$newIn7Days", "New Entries", Colors.green)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildKPICardUI("Success Cure Rate", "${treatableRate.toStringAsFixed(1)}%", null, Colors.green, iconTail: Icons.trending_up)),
                                const SizedBox(width: 16),
                                Expanded(child: _buildKPICardUI("Uncured Rate", "${untreatableRate.toStringAsFixed(1)}%", "Optimal", Colors.green)),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // (B) HÀNG PHÂN TÍCH
                            SizedBox(
                              height: 380,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Thẻ 1: Biểu đồ
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      padding: const EdgeInsets.all(32),
                                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  const Text("Tỷ trọng Phân loại trong Thư viện", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryGreen)),
                                                  const SizedBox(height: 4),
                                                  Text("Phân bổ dữ liệu theo nhóm sinh học", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                                                ],
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                                                child: Text("UPDATE: JAN 2024", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                                              )
                                            ],
                                          ),
                                          const SizedBox(height: 40),
                                          // Biểu đồ cột
                                          Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: ['Côn trùng', 'Nấm', 'Vi-rút', 'Vi khuẩn', 'Khác'].map((key) {
                                                double heightRatio = (typeCounts[key] ?? 0) / maxTypeCount;
                                                return Column(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    if ((typeCounts[key] ?? 0) > 0)
                                                      Text("${typeCounts[key]}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                                                    const SizedBox(height: 8),
                                                    Container(
                                                      width: 35,
                                                      height: heightRatio * 150 + 5,
                                                      decoration: const BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.vertical(top: Radius.circular(6))),
                                                    ),
                                                    const SizedBox(height: 12),
                                                    Text(key.toUpperCase(), style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                                                  ],
                                                );
                                              }).toList(),
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),

                                  // Cột phải
                                  Expanded(
                                    flex: 1,
                                    child: Column(
                                      children: [
                                        // Thẻ Top AI
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(24),
                                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("TOP CHỦ ĐỀ HỎI AI", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryGreen, letterSpacing: 1.2)),
                                              const SizedBox(height: 20),
                                              if (sortedTop.isEmpty) const Text("Chưa có dữ liệu AI", style: TextStyle(color: Colors.grey)),
                                              ...List.generate(sortedTop.length > 3 ? 3 : sortedTop.length, (index) {
                                                double pct = totalAILogs == 0 ? 0 : (sortedTop[index].value / totalAILogs) * 100;
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 16),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        width: 32, height: 32,
                                                        alignment: Alignment.center,
                                                        decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                                                        child: Text("0${index + 1}", style: TextStyle(color: Colors.orange.shade800, fontWeight: FontWeight.bold, fontSize: 12)),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(child: Text(sortedTop[index].key, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.black87), overflow: TextOverflow.ellipsis)),
                                                      Text("${pct.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                                                      const SizedBox(width: 8),
                                                      const Icon(Icons.trending_up, color: Colors.grey, size: 16)
                                                    ],
                                                  ),
                                                );
                                              })
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Thẻ CẦN DUYỆT GẤP (MÀU XANH ĐẬM)
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(24),
                                            decoration: BoxDecoration(color: primaryGreen, borderRadius: BorderRadius.circular(16)),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)),
                                                    const SizedBox(width: 8),
                                                    const Text("ACTION REQUIRED", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                const Text("Cần duyệt gấp", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                                                const SizedBox(height: 4),
                                                Text("$pendingCount mục mới đang chờ xử lý", style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                                const Spacer(),
                                                SizedBox(
                                                  width: 120,
                                                  child: ElevatedButton(
                                                    onPressed: () => setState(() {
                                                      _isViewingPending = true;
                                                      _currentPage = 1;
                                                    }),
                                                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                                                    child: const Text("Xử lý ngay", style: TextStyle(fontWeight: FontWeight.bold)),
                                                  ),
                                                )
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ], // End of Dashboard Top Section

                          // (C) KHU VỰC BẢNG DỮ LIỆU CHÍNH
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Pills Filter Type
                              Row(
                                children: _types.map((type) {
                                  bool isSelected = _selectedFilterType == type;
                                  return GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedFilterType = type;
                                      _currentPage = 1; // Reset trang khi đổi tab lọc
                                    }),
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 12),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isSelected ? primaryGreen : Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Text(
                                          type,
                                          style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              // Nút Sort và Thêm Mới
                              Row(
                                children: [
                                  // Nút Sort UI Viên Thuốc
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey.shade300),
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _sortBy,
                                        icon: const Icon(Icons.sort, color: Colors.grey),
                                        items: _sortOptions.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
                                        onChanged: (v) => setState(() {
                                          _sortBy = v!;
                                          _currentPage = 1;
                                        }),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  ElevatedButton.icon(
                                    onPressed: () => _showDiseaseFormDialog(),
                                    icon: const Icon(Icons.add, color: Colors.white, size: 18),
                                    label: const Text("Thêm Sâu Bệnh", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                          const SizedBox(height: 24),

                          // TABLE KHUNG TRẮNG
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]),
                            child: Column(
                              children: [
                                // Header Bảng (Căn chỉnh khoảng cách rộng ra)
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    children: [
                                      SizedBox(width: 80, child: Text("IMAGE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
                                      SizedBox(width: 32), // Khoảng trống ngăn cách
                                      Expanded(flex: 3, child: Text("DISEASE INFO", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
                                      Expanded(flex: 2, child: Text("CLASSIFICATION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
                                      Expanded(flex: 2, child: Text("SEVERITY LEVEL", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
                                      Expanded(flex: 2, child: Text("STATUS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1))),
                                      SizedBox(width: 80, child: Text("ACTIONS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1), textAlign: TextAlign.right)),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                // Body Bảng
                                paginatedDocs.isEmpty
                                    ? const Padding(padding: EdgeInsets.all(40), child: Text("Không có dữ liệu phù hợp", style: TextStyle(color: Colors.grey)))
                                    : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: paginatedDocs.length,
                                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    var doc = paginatedDocs[index];
                                    var data = doc.data() as Map<String, dynamic>;
                                    bool isActive = data['isActive'] ?? true;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      child: Row(
                                        children: [
                                          // Image - Cố định width 80
                                          SizedBox(
                                            width: 80,
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                                                  ? Image.network(data['imageUrl'], width: 80, height: 55, fit: BoxFit.cover)
                                                  : Container(width: 80, height: 55, color: Colors.black87, child: const Icon(Icons.bug_report, color: Colors.white54)),
                                            ),
                                          ),
                                          const SizedBox(width: 32), // Khoảng trống giữa Ảnh và Info
                                          // Info
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(data['name'] ?? 'Không tên', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1E293B))),
                                                const SizedBox(height: 4),
                                                Text("MÙA VỤ: ${(data['season'] ?? 'Không rõ').toString().toUpperCase()}", style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600)),
                                              ],
                                            ),
                                          ),
                                          // Classification (Pill)
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: _buildBadge(data['type'] ?? 'Khác'),
                                            ),
                                          ),
                                          // Severity
                                          Expanded(
                                            flex: 2,
                                            child: _buildSeverityBadge(data['emergency_level'] ?? 'Bình thường'),
                                          ),
                                          // Status
                                          Expanded(
                                            flex: 2,
                                            child: Align(
                                              alignment: Alignment.centerLeft,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(
                                                    border: Border.all(color: isActive ? Colors.green : Colors.red),
                                                    borderRadius: BorderRadius.circular(30)
                                                ),
                                                child: Text(isActive ? "ĐÃ DUYỆT" : "CHỜ DUYỆT", style: TextStyle(color: isActive ? Colors.green : Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ),
                                          // Actions
                                          SizedBox(
                                            width: 80,
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(icon: const Icon(Icons.edit, color: primaryGreen, size: 18), onPressed: () => _showDiseaseFormDialog(existingDoc: doc)),
                                                IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 18), onPressed: () => _deleteDisease(doc)),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const Divider(height: 1),

                                // Giao diện Phân Trang (Pagination)
                                if (totalPages > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 24),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                            "Hiển thị ${(_currentPage - 1) * _itemsPerPage + 1} - ${((_currentPage * _itemsPerPage) > totalFilteredItems) ? totalFilteredItems : (_currentPage * _itemsPerPage)} trong $totalFilteredItems sâu bệnh",
                                            style: const TextStyle(color: Colors.grey, fontSize: 13)
                                        ),
                                        Row(
                                          children: [
                                            _buildPageButton(
                                                icon: Icons.chevron_left,
                                                onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null
                                            ),
                                            const SizedBox(width: 8),
                                            ...List.generate(totalPages, (index) {
                                              int page = index + 1;
                                              return Padding(
                                                padding: const EdgeInsets.only(right: 8),
                                                child: _buildPageButton(
                                                    text: "$page",
                                                    isActive: _currentPage == page,
                                                    onPressed: () => setState(() => _currentPage = page)
                                                ),
                                              );
                                            }),
                                            _buildPageButton(
                                                icon: Icons.chevron_right,
                                                onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                              ],
                            ),
                          )
                        ],
                      ),
                    );
                  }
              );
            }
        ),
      ),
    );
  }

  // =========================================================================
  // WIDGET HELPERS TẠO UI GIỐNG ẢNH
  // =========================================================================
  Widget _buildPageButton({String? text, IconData? icon, bool isActive = false, VoidCallback? onPressed}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1B4332) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? const Color(0xFF1B4332) : Colors.grey.shade300),
        ),
        alignment: Alignment.center,
        child: text != null
            ? Text(text, style: TextStyle(color: isActive ? Colors.white : Colors.grey.shade700, fontWeight: FontWeight.bold))
            : Icon(icon, color: onPressed == null ? Colors.grey.shade300 : Colors.grey.shade700, size: 20),
      ),
    );
  }

  Widget _buildKPICardUI(String title, String value, String? subtitle, Color valueColor, {IconData? iconTail}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF1B4332))),
              const SizedBox(width: 8),
              if (subtitle != null) Text(subtitle, style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold)),
              if (iconTail != null) Icon(iconTail, color: valueColor, size: 18)
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBadge(String type) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.grey.shade700;
    if (type.toLowerCase().contains('côn trùng')) { bg = Colors.orange.shade100; text = Colors.orange.shade900; }
    else if (type.toLowerCase().contains('nấm')) { bg = Colors.green.shade100; text = Colors.green.shade900; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(type.toUpperCase(), style: TextStyle(color: text, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildSeverityBadge(String level) {
    Color color = Colors.grey;
    if (level.toLowerCase().contains('rất cao') || level.toLowerCase().contains('nguy hiểm')) color = Colors.red;
    else if (level.toLowerCase().contains('cao')) color = Colors.orange;
    else if (level.toLowerCase().contains('trung bình')) color = Colors.amber;

    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(level, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}