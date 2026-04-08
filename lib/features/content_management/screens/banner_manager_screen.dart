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

  String _selectedFilter = 'Tất cả';
  String _sortBy = 'order';
  final TextEditingController _searchCtrl = TextEditingController();

  // Biến phục vụ phân trang
  int _currentPage = 1;
  final int _itemsPerPage = 8;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
              title: Text(isEditing ? 'Chỉnh sửa Banner' : 'Thêm Banner Mới', style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 500,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
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
                          decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(8)),
                          clipBehavior: Clip.antiAlias,
                          child: newImageBytes != null
                              ? Image.memory(newImageBytes!, fit: BoxFit.cover)
                              : (existingImageUrl != null && existingImageUrl.isNotEmpty
                              ? Image.network(existingImageUrl, fit: BoxFit.cover)
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3D7E50)),
                  onPressed: _isLoading ? null : () async {
                    if (titleCtrl.text.isEmpty || (newImageBytes == null && existingImageUrl == null)) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập tiêu đề và chọn ảnh')));
                      return;
                    }

                    setStateDialog(() => _isLoading = true);

                    try {
                      String finalImageUrl = existingImageUrl ?? '';

                      if (newImageBytes != null) {
                        String fileName = 'banners/${DateTime.now().millisecondsSinceEpoch}.png';
                        TaskSnapshot snapshot = await FirebaseStorage.instance.ref(fileName).putData(newImageBytes!);
                        finalImageUrl = await snapshot.ref.getDownloadURL();

                        if (isEditing && existingImageUrl != null && existingImageUrl.contains('firebase')) {
                          try { await FirebaseStorage.instance.refFromURL(existingImageUrl).delete(); } catch (_) {}
                        }
                      }

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

                      if (isEditing) {
                        await existingDoc!.reference.update(bannerData);
                      } else {
                        bannerData['isActive'] = true;
                        bannerData['clicks'] = 0;
                        bannerData['impressions'] = 0;
                        bannerData['createdAt'] = FieldValue.serverTimestamp();
                        await _firestore.collection('home_banners').add(bannerData);
                      }

                      setStateDialog(() => _isLoading = false);
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đăng banner thành công!'), backgroundColor: Color(0xFF3D7E50)));

                    } catch (e) {
                      setStateDialog(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red));
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEditing ? 'Cập nhật' : 'Tạo mới', style: const TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
      ),
    );
  }

  Future<void> _deleteBanner(DocumentSnapshot doc) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa banner này vĩnh viễn?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hủy')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Xóa', style: TextStyle(color: Colors.white))),
        ],
      ),
    );

    if (confirm == true) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['imageUrl'] != null && data['imageUrl'].toString().contains('firebase')) {
        try { await FirebaseStorage.instance.refFromURL(data['imageUrl']).delete(); } catch (e) { debugPrint('Lỗi: $e'); }
      }
      await doc.reference.delete();
      // Reset về trang 1 sau khi xóa nếu trang hiện tại hết item
      setState(() { _currentPage = 1; });
    }
  }

  Widget _buildStatusBadge(bool isActive, bool isExpired) {
    if (isExpired) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(12)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 8, color: Color(0xFFD15F5F)), SizedBox(width: 4),
          Text('Hết hạn', style: TextStyle(fontSize: 12, color: Color(0xFFD15F5F)))
        ]),
      );
    }
    if (isActive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(12)),
        child: const Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.circle, size: 8, color: Color(0xFF3D7E50)), SizedBox(width: 4),
          Text('Đang chạy', style: TextStyle(fontSize: 12, color: Color(0xFF3D7E50)))
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFE6E6E6), borderRadius: BorderRadius.circular(12)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.circle, size: 8, color: Color(0xFFE27C37)), SizedBox(width: 4),
        Text('Tạm dừng', style: TextStyle(fontSize: 12, color: Color(0xFFE27C37)))
      ]),
    );
  }

  Widget _buildKPICard(String title, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        height: 100,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFDCDCDC))),
        child: Row(children: [
          Container(width: 60, height: 60, decoration: const BoxDecoration(color: Color(0xFFE6E6E6), shape: BoxShape.circle), child: Icon(icon, color: color, size: 30)),
          const SizedBox(width: 16),
          Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: TextStyle(color: Colors.grey.shade700, fontSize: 14)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))])
        ]),
      ),
    );
  }

  Widget _buildFilterButton(String text, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? const Color(0xFF3D7E50) : const Color(0xFFE6E6E6),
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Text(text),
    );
  }

  // --- WIDGET PHÂN TRANG (PageBox) ---
  Widget _buildPageButton(dynamic content, {bool isIcon = false, bool isActive = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1E4B2E) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: isActive ? const Color(0xFF1E4B2E) : Colors.grey.shade300),
        ),
        child: Center(
          child: isIcon
              ? Icon(content as IconData, size: 18, color: onTap == null ? Colors.grey.shade300 : Colors.black87)
              : Text(content as String, style: TextStyle(color: isActive ? Colors.white : Colors.black87, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
        ),
      ),
    );
  }

  Widget _buildPaginationBox(int totalItems, int totalPages, int start, int end) {
    if (totalItems == 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.transparent,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Hiển thị $start - $end trong $totalItems banner',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
          ),
          Row(
            children: [
              _buildPageButton(Icons.chevron_left, isIcon: true, onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null),
              const SizedBox(width: 8),
              ...List.generate(totalPages, (index) {
                int page = index + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildPageButton(page.toString(), isActive: page == _currentPage, onTap: () => setState(() => _currentPage = page)),
                );
              }),
              _buildPageButton(Icons.chevron_right, isIcon: true, onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null),
            ],
          )
        ],
      ),
    );
  }
  // ------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('home_banners').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF3D7E50)));
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Đã xảy ra lỗi khi tải dữ liệu.'));
          }

          final allDocs = snapshot.data?.docs ?? [];
          int activeCount = 0, expiredCount = 0, totalClicks = 0;
          final now = DateTime.now();
          List<DocumentSnapshot> filteredDocs = [];

          // 1. Tính toán KPI và Lọc dữ liệu Local
          for (var doc in allDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final isActive = data['isActive'] ?? false;
            final isExpired = data['endDate'] != null && (data['endDate'] as Timestamp).toDate().isBefore(now);

            totalClicks += (data['clicks'] ?? 0) as int;
            if (isExpired) {
              expiredCount++;
            } else if (isActive) {
              activeCount++;
            }

            // Lọc
            if (_selectedFilter == 'Đang chạy' && (!isActive || isExpired)) continue;
            if (_selectedFilter == 'Tạm dừng' && (isActive || isExpired)) continue;
            if (_selectedFilter == 'Hết hạn' && !isExpired) continue;
            if (_searchCtrl.text.isNotEmpty) {
              final title = (data['title'] ?? '').toString().toLowerCase();
              if (!title.contains(_searchCtrl.text.toLowerCase())) continue;
            }

            filteredDocs.add(doc);
          }

          // 2. Sắp xếp Local
          filteredDocs.sort((a, b) {
            final dataA = a.data() as Map<String, dynamic>;
            final dataB = b.data() as Map<String, dynamic>;
            if (_sortBy == 'newest') {
              Timestamp? tA = dataA['createdAt'];
              Timestamp? tB = dataB['createdAt'];
              if (tA == null && tB == null) return 0;
              if (tA == null) return 1;
              if (tB == null) return -1;
              return tB.compareTo(tA);
            } else {
              int orderA = dataA['order'] ?? 999;
              int orderB = dataB['order'] ?? 999;
              return orderA.compareTo(orderB);
            }
          });

          // 3. Xử lý Logic Phân trang
          final totalItems = filteredDocs.length;
          final totalPages = (totalItems / _itemsPerPage).ceil();

          // Đảm bảo currentPage không bị vượt quá giới hạn khi xóa item hoặc tìm kiếm
          if (_currentPage > totalPages && totalPages > 0) {
            _currentPage = totalPages;
          } else if (totalPages == 0) {
            _currentPage = 1;
          }

          // Lấy danh sách item cho trang hiện tại
          final pagedDocs = filteredDocs.skip((_currentPage - 1) * _itemsPerPage).take(_itemsPerPage).toList();

          int startItem = totalItems == 0 ? 0 : (_currentPage - 1) * _itemsPerPage + 1;
          int endItem = startItem + pagedDocs.length - 1;

          String clicksText = totalClicks > 999 ? "${(totalClicks / 1000).toStringAsFixed(1)}k" : totalClicks.toString();

          return CustomScrollView(
            slivers: [
              // HEADER ROW
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    children: [
                      const Text('Quản lý Banner', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                      const Spacer(),
                      SizedBox(
                        width: 300,
                        height: 42,
                        child: TextField(
                          controller: _searchCtrl,
                          onChanged: (val) => setState(() => _currentPage = 1), // Reset page khi search
                          decoration: InputDecoration(
                            hintText: 'Tìm kiếm banner...',
                            prefixIcon: const Icon(Icons.search, size: 20, color: Colors.grey),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                            filled: true, fillColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // KPI CARDS
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(children: [
                    _buildKPICard('Banner đang chạy', activeCount.toString(), const Color(0xFF3D7E50), Icons.play_circle_fill),
                    const SizedBox(width: 16),
                    _buildKPICard('Đã hết hạn', expiredCount.toString(), const Color(0xFFD15F5F), Icons.timer_off),
                    const SizedBox(width: 16),
                    _buildKPICard('Tổng lượt click', clicksText, const Color(0xFFE27C37), Icons.ads_click),
                  ]),
                ),
              ),

              // FILTER BAR
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(children: [
                    Row(
                      children: ['Tất cả', 'Đang chạy', 'Tạm dừng', 'Hết hạn'].map((f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildFilterButton(f, _selectedFilter == f, () => setState(() {
                          _selectedFilter = f;
                          _currentPage = 1; // Reset page khi đổi filter
                        })),
                      )).toList(),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFDCDCDC))),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: const Icon(Icons.sort, size: 18),
                          items: const [DropdownMenuItem(value: 'order', child: Text('Ưu tiên hiển thị')), DropdownMenuItem(value: 'newest', child: Text('Mới nhất ▼'))],
                          onChanged: (val) => setState(() => _sortBy = val!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showBannerFormDialog(),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Tạo banner mới'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E4B2E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      ),
                    ),
                  ]),
                ),
              ),

              // LIST BANNER
              if (pagedDocs.isEmpty)
                SliverFillRemaining(
                    child: Center(
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 80, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('Chưa có banner nào', style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () => _showBannerFormDialog(),
                                icon: const Icon(Icons.add),
                                label: const Text('Tạo banner ngay'),
                              )
                            ]
                        )
                    )
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final doc = pagedDocs[index];
                      final data = doc.data() as Map<String, dynamic>;
                      final isActive = data['isActive'] ?? false;
                      bool isExpired = false;
                      if (data['endDate'] != null) isExpired = (data['endDate'] as Timestamp).toDate().isBefore(DateTime.now());

                      final int order = data['order'] ?? 999;
                      String prioLabel = order <= 1 ? "Cao ($order)" : "Trung bình ($order)";

                      int views = data['impressions'] ?? 0;
                      int clicks = data['clicks'] ?? 0;
                      double ctr = views > 0 ? (clicks / views * 100) : 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFEBEBEB))),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(data['imageUrl'] ?? '', width: 140, height: 80, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 140, height: 80, color: Colors.grey[200], child: const Icon(Icons.broken_image, color: Colors.grey))),
                            ),
                            const SizedBox(width: 20),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(data['title'] ?? '(Không tiêu đề)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2C3E50))),
                                const SizedBox(width: 12),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE6F2E9), borderRadius: BorderRadius.circular(6)), child: Text((data['type'] ?? 'ADS').toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3D7E50)))),
                              ]),
                              const SizedBox(height: 6),
                              Text(data['description'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 12),
                              Row(children: [
                                const Icon(Icons.priority_high, size: 14, color: Colors.grey), const SizedBox(width: 4),
                                Text('Độ ưu tiên: $prioLabel', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                const SizedBox(width: 20),
                                const Icon(Icons.remove_red_eye, size: 14, color: Colors.grey), const SizedBox(width: 4),
                                Text('Lượt xem: $views', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                const SizedBox(width: 20),
                                const Icon(Icons.touch_app, size: 14, color: Colors.grey), const SizedBox(width: 4),
                                Text('Lượt click: $clicks', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                                const SizedBox(width: 20),
                                const Icon(Icons.trending_up, size: 14, color: Colors.green), const SizedBox(width: 4),
                                Text('CTR: ${ctr.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                              ]),
                            ])),
                            const SizedBox(width: 24),
                            Row(children: [
                              Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _buildStatusBadge(isActive, isExpired),
                                    const SizedBox(height: 8),
                                    Switch(
                                      value: isActive,
                                      activeColor: const Color(0xFF3D7E50),
                                      onChanged: (val) {
                                        doc.reference.update({'isActive': val});
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? 'Đã bật banner' : 'Đã tắt banner'), backgroundColor: const Color(0xFF3D7E50), duration: const Duration(seconds: 1)));
                                      },
                                    ),
                                  ]
                              ),
                              const SizedBox(width: 24),
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFF0F5FF), borderRadius: BorderRadius.circular(8)),
                                child: IconButton(icon: const Icon(Icons.edit_square, color: Colors.blueAccent, size: 20), onPressed: () => _showBannerFormDialog(existingDoc: doc)),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: const Color(0xFFFFF0F0), borderRadius: BorderRadius.circular(8)),
                                child: IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20), onPressed: () => _deleteBanner(doc)),
                              ),
                            ]),
                          ]),
                        ),
                      );
                    }, childCount: pagedDocs.length),
                  ),
                ),

              // PAGINATION BOX Ở CUỐI CÙNG
              SliverToBoxAdapter(
                child: _buildPaginationBox(totalItems, totalPages, startItem, endItem),
              )
            ],
          );
        },
      ),
    );
  }
}