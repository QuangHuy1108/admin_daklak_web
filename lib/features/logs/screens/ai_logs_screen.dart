import 'package:flutter/material.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import 'dart:async';
import 'package:admin_daklak_web/features/auth/services/admin_service.dart';
import 'package:admin_daklak_web/features/reports/services/export_service.dart';
import '../../../core/widgets/common/glass_container.dart';

  Color _getPrimaryDarkGreen(BuildContext context) => Theme.of(context).primaryColor;
  Color _getTextGrey(BuildContext context) => Theme.of(context).textTheme.bodySmall?.color ?? const Color(0xFF6B7280);
  Color _getCardBg(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? AppColors.darkSurfaceVariant : Colors.white;

class AiLogsScreen extends StatefulWidget {
  const AiLogsScreen({super.key});

  @override
  State<AiLogsScreen> createState() => _AiLogsScreenState();
}

class _AiLogsScreenState extends State<AiLogsScreen> {
  final ExportService _exportService = ExportService();
  int _currentTabIndex = 0;
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;

  int _currentPage = 0;
  final int _rowsPerPage = 8;
  bool _isExporting = false;

  // Cached data to keep export button responsive
  List<QueryDocumentSnapshot> _chatDocs = [];
  StreamSubscription? _chatSub;
  String? _chatError;

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _chatSub = FirebaseFirestore.instance
        .collection('ai_chat_logs')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen(
      (snap) {
        if (mounted) setState(() { _chatDocs = snap.docs; _chatError = null; });
      },
      onError: (err) {
        if (mounted) setState(() => _chatError = err.toString());
      },
    );
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: _getPrimaryDarkGreen(context), onPrimary: Colors.white),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
        _currentPage = 0;
      });
    }
  }

  void _handleExport() async {
    List<QueryDocumentSnapshot> sourceDocs = _chatDocs;
    
    // Initial filtering based on search/date/tab
    List<QueryDocumentSnapshot> filteredDocs;
    
    Map<String, int> promptCounts = {};
    for (var doc in sourceDocs) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      String key = "${d['userId'] ?? d['userEmail']}_${(d['prompt'] ?? '').toString().trim().toLowerCase()}";
      promptCounts[key] = (promptCounts[key] ?? 0) + 1;
    }
    filteredDocs = _getFilteredChatDocs(sourceDocs, promptCounts);

    if (filteredDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Không có dữ liệu để xuất!")));
      return;
    }

    setState(() => _isExporting = true);
    
    try {
      final List<Map<String, dynamic>> exportData = filteredDocs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return { ...data, 'id': doc.id, 'timestamp': _parseDateTime(data['timestamp']) };
      }).toList();
      
      String fileName = _currentTabIndex == 1 ? "Danh_Sach_Loi_AI" : "Toan_Bo_Chat_AI";
      _exportService.exportAiChatLogsToCsv(exportData, fileName);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang khởi tạo tải xuống...")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi khi chuẩn bị dữ liệu: $e")));
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  bool _matchDate(dynamic timestamp) {
    if (_selectedDateRange == null) return true;
    DateTime? time = _parseDateTime(timestamp);
    if (time == null) return false;
    DateTime start = _selectedDateRange!.start;
    DateTime end = _selectedDateRange!.end.add(const Duration(days: 1));
    return time.isAfter(start) && time.isBefore(end);
  }

  void _toggleFlag(String docId, bool currentFlag, String userId, String prompt) {
    FirebaseFirestore.instance.collection('ai_chat_logs').doc(docId).update({
      'isFlagged': !currentFlag
    });

    AdminService.logAction(
        action: !currentFlag ? "Đánh dấu lỗi AI" : "Gỡ đánh dấu lỗi AI",
        target: "User ID: $userId | Câu hỏi: ${prompt.characters.take(30)}..."
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Chi tiết Chat", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: _getPrimaryDarkGreen(context))),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text("Hỏi:\n${data['prompt'] ?? '--'}", style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text("AI Trả lời:\n${data['response'] ?? '--'}"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Đóng", style: Theme.of(context).textTheme.labelLarge?.copyWith(color: _getPrimaryDarkGreen(context)))
          )
        ],
      ),
    );
  }

  String _getNameFromEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return "Người dùng";
    String namePart = email.split('@')[0];
    return namePart.substring(0, 1).toUpperCase() + namePart.substring(1);
  }

  DateTime? _parseDateTime(dynamic timestampData) {
    if (timestampData == null) return null;
    if (timestampData is Timestamp) return timestampData.toDate();
    if (timestampData is String) return DateTime.tryParse(timestampData);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Lịch sử & Theo dõi Hệ thống',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    if (_selectedDateRange != null)
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.redAccent),
                        onPressed: () => setState(() {
                          _selectedDateRange = null;
                          _currentPage = 0;
                        }),
                      ),
                    IconButton(
                      icon: Icon(Icons.calendar_month, color: _selectedDateRange == null ? _getTextGrey(context) : _getPrimaryDarkGreen(context)),
                      onPressed: _pickDateRange,
                    ),
                    const SizedBox(width: 8),
                    _buildSearchBar(),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            _buildFirestoreStats(),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildTabButton("Tất cả Chat AI", 0),
                    const SizedBox(width: 10),
                    _buildTabButton("Câu trả lời lỗi", 1),
                  ],
                ),
                _buildExportButton(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: GlassContainer(
                child: _buildChatTable(),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      width: 300,
      decoration: BoxDecoration(color: Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.grey[200], borderRadius: BorderRadius.circular(30)),
      child: TextField(
        onChanged: (val) {
          setState(() {
            _searchQuery = val.toLowerCase();
            _currentPage = 0;
          });
        },
        decoration: const InputDecoration(
            hintText: 'Tìm theo ID, Email, Hành động...',
            prefixIcon: Icon(Icons.search),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 12)
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, int index) {
    bool isSelected = _currentTabIndex == index;
    return InkWell(
      onTap: () => setState(() {
        _currentTabIndex = index;
        _currentPage = 0;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _getPrimaryDarkGreen(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isSelected ? Colors.white : _getTextGrey(context),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    String label = "Xuất toàn bộ chat";
    if (_currentTabIndex == 1) label = "Tải danh sách lỗi";

    bool canExport = !_isExporting && _chatDocs.isNotEmpty;

    return ElevatedButton.icon(
      onPressed: canExport ? _handleExport : null,
      icon: _isExporting 
        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : const Icon(Icons.download_rounded, color: Colors.white, size: 18),
      label: Text(
          _isExporting ? "Đang xử lý..." : label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)
      ),
      style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF8E4A1D),
          disabledBackgroundColor: Colors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
      ),
    );
  }

  Widget _buildFirestoreStats() {
    if (_chatError != null) return Text("Lỗi tải thống kê: $_chatError", style: const TextStyle(color: Colors.red));
    if (_chatDocs.isEmpty) return const SizedBox(height: 104, child: Center(child: CircularProgressIndicator()));

    var allChatDocs = _chatDocs;
    int totalLogs = allChatDocs.length;

    Map<String, int> userPromptCounts = {};
    for (var doc in allChatDocs) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      String key = "${d['userId'] ?? d['userEmail']}_${(d['prompt'] ?? '').toString().trim().toLowerCase()}";
      userPromptCounts[key] = (userPromptCounts[key] ?? 0) + 1;
    }

    int failedCount = allChatDocs.where((doc) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      String key = "${d['userId'] ?? d['userEmail']}_${(d['prompt'] ?? '').toString().trim().toLowerCase()}";
      return d['status'] == 'error' || d['isFlagged'] == true || (userPromptCounts[key] ?? 0) > 3;
    }).length;

    int successCount = totalLogs - failedCount;

    return Row(
      children: [
        _buildStatCard(context, 'Tổng số Log', NumberFormat('#,###').format(totalLogs), Icons.bar_chart, Colors.green.withOpacity(0.1), Colors.green),
        const SizedBox(width: 24),
        _buildStatCard(context, 'Cần huấn luyện AI', NumberFormat('#,###').format(failedCount), Icons.psychology, Colors.orange.withOpacity(0.1), Colors.orange),
        const SizedBox(width: 24),
        _buildStatCard(context, 'Log thành công', NumberFormat('#,###').format(successCount), Icons.check_circle, Colors.teal.withOpacity(0.1), Colors.teal),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon, Color bg, Color iconColor) {
    return Expanded(
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)), child: Icon(icon, color: iconColor, size: 30)),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _getTextGrey(context))),
              Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: _getPrimaryDarkGreen(context))),
            ])
          ],
        ),
      ),
    );
  }

  List<QueryDocumentSnapshot> _getFilteredChatDocs(List<QueryDocumentSnapshot> allDocs, Map<String, int> promptCounts) {
    return allDocs.where((doc) {
      var data = doc.data() as Map<String, dynamic>? ?? {};

      String userId = (data['userId'] ?? '').toString().toLowerCase();
      String email = (data['userEmail'] ?? '').toString().toLowerCase();
      String docId = doc.id.toLowerCase();
      String category = (data['category_tag'] ?? '').toString().toLowerCase();
      bool matchSearch = userId.contains(_searchQuery) || email.contains(_searchQuery) || docId.contains(_searchQuery) || category.contains(_searchQuery);

      if (!matchSearch || !_matchDate(data['timestamp'])) return false;

      if (_currentTabIndex == 1) {
        String key = "${data['userId'] ?? data['userEmail']}_${(data['prompt'] ?? '').toString().trim().toLowerCase()}";
        bool isError = data['status'] == 'error';
        bool isFlagged = data['isFlagged'] == true;
        bool isRepeated = (promptCounts[key] ?? 0) > 3;
        return isError || isFlagged || isRepeated;
      }
      return true;
    }).toList();
  }

  Widget _buildChatTable() {
    if (_chatError != null) return _buildErrorMessage("Lỗi tải Chat: $_chatError");
    if (_chatDocs.isEmpty) return const Center(child: CircularProgressIndicator());

    var allDocs = _chatDocs;
    Map<String, int> promptCounts = {};
    for (var doc in allDocs) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      String key = "${d['userId'] ?? d['userEmail']}_${(d['prompt'] ?? '').toString().trim().toLowerCase()}";
      promptCounts[key] = (promptCounts[key] ?? 0) + 1;
    }

    var filteredDocs = _getFilteredChatDocs(allDocs, promptCounts);

    int totalItems = filteredDocs.length;
    int totalPages = (totalItems / _rowsPerPage).ceil();
    if (totalPages == 0) totalPages = 1;
    if (_currentPage >= totalPages) _currentPage = max(0, totalPages - 1);

    int startIndex = _currentPage * _rowsPerPage;
    int endIndex = min(startIndex + _rowsPerPage, totalItems);
    var pagedDocs = totalItems == 0 ? [] : filteredDocs.sublist(startIndex, endIndex);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(children: [
            _headerCell('THỜI GIAN', flex: 2), _headerCell('ID CHAT', flex: 2),
            _headerCell('NGƯỜI DÙNG', flex: 3), _headerCell('CHỦ ĐỀ', flex: 2),
            _headerCell('NỘI DUNG', flex: 4), _headerCell('HÀNH ĐỘNG', flex: 1),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: pagedDocs.isEmpty
              ? Center(child: Text("Không có dữ liệu phù hợp.", style: TextStyle(color: _getTextGrey(context))))
              : ListView.builder(
            itemCount: pagedDocs.length,
            itemBuilder: (context, index) {
              var doc = pagedDocs[index];
              var data = doc.data() as Map<String, dynamic>? ?? {};

              DateTime? time = _parseDateTime(data['timestamp']);
              String timeStr = time != null ? "${DateFormat('HH:mm').format(time)},\n${DateFormat('dd/MM').format(time)}" : "--";

              String chatId = doc.id.substring(0, 8).toUpperCase();
              String email = data['userEmail'] ?? '';
              String displayName = _getNameFromEmail(email);
              String userIdDisplay = data['userId']?.toString() ?? 'UID-${doc.id.substring(0, 5).toUpperCase()}';

              String promptText = (data['prompt'] ?? '').toString().trim();
              String displayPrompt = promptText.isNotEmpty ? '"$promptText"' : '--';

              bool isFlagged = data['isFlagged'] == true;

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(timeStr, style: const TextStyle(fontSize: 13, height: 1.4))),
                    Expanded(flex: 2, child: Text("#$chatId", style: TextStyle(fontSize: 13, color: _getPrimaryDarkGreen(context), fontWeight: FontWeight.bold))),
                    Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(radius: 16, backgroundColor: Colors.blueGrey[100], child: Text(displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold, fontSize: 14))),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis),
                                  Text('ID: $userIdDisplay', style: TextStyle(color: _getTextGrey(context), fontSize: 12), overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          ],
                        )
                    ),
                    Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(color: const Color(0xFFFBE4D7).withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
                            child: Text(data['category_tag'] ?? 'Khác', style: const TextStyle(color: Color(0xFFD96B40), fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        )
                    ),
                    Expanded(flex: 4, child: Text(displayPrompt, maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontStyle: FontStyle.italic, color: _getTextGrey(context), fontSize: 13))),
                    Expanded(
                      flex: 1,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(icon: Icon(Icons.remove_red_eye, color: _getTextGrey(context), size: 20), onPressed: () => _showDetailDialog(data), padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                          IconButton(icon: Icon(isFlagged ? Icons.flag : Icons.flag_outlined, color: isFlagged ? Colors.red : _getTextGrey(context), size: 20), onPressed: () => _toggleFlag(doc.id, data['isFlagged'] == true, userIdDisplay, data['prompt'] ?? ''), padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        _buildTableFooter(totalItems, totalPages),
      ],
    );
  }


  Widget _buildErrorMessage(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(msg, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Text("Vui lòng kiểm tra index Firestore hoặc quyền truy cập.", style: TextStyle(fontSize: 12, color: _getTextGrey(context))),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(flex: flex, child: Text(label, textAlign: flex == 1 ? TextAlign.center : TextAlign.left, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold, color: _getTextGrey(context))));

  Widget _buildTableFooter(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text('Hiển thị ${total == 0 ? 0 : _currentPage * _rowsPerPage + 1} - ${min((_currentPage + 1) * _rowsPerPage, total)} trong $total kết quả', style: TextStyle(color: _getTextGrey(context), fontSize: 13)),
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
          color: active ? _getPrimaryDarkGreen(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? _getPrimaryDarkGreen(context) : Theme.of(context).dividerColor),
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