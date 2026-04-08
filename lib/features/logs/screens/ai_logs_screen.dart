import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:math';
import 'package:admin_daklak_web/features/auth/services/admin_service.dart';

const Color primaryDarkGreen = Color(0xFF1B3D2F);
const Color bgLightGreen = Color(0xFFF7F8F3);
const Color cardWhite = Colors.white;
const Color textGrey = Color(0xFF6B7280);

class AiLogsScreen extends StatefulWidget {
  const AiLogsScreen({super.key});

  @override
  State<AiLogsScreen> createState() => _AiLogsScreenState();
}

class _AiLogsScreenState extends State<AiLogsScreen> {
  int _currentTabIndex = 0;
  String _searchQuery = "";
  DateTimeRange? _selectedDateRange;

  int _currentPage = 0;
  final int _rowsPerPage = 8;

  late final Stream<QuerySnapshot> _chatLogsStream;
  late final Stream<QuerySnapshot> _adminLogsStream;

  @override
  void initState() {
    super.initState();
    _chatLogsStream = FirebaseFirestore.instance.collection('ai_chat_logs').orderBy('timestamp', descending: true).snapshots();
    _adminLogsStream = FirebaseFirestore.instance.collection('admin_logs').orderBy('timestamp', descending: true).snapshots();
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
            colorScheme: const ColorScheme.light(primary: primaryDarkGreen, onPrimary: Colors.white),
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

  String _escapeCSV(String text) {
    return '"${text.replaceAll('"', '""')}"';
  }

  void _downloadCSV(List<QueryDocumentSnapshot> docs, String fileNamePrefix) {
    String csvContent = "Thoi gian,ID Chat,User ID,Chu de,Trang thai,Hanh dong,Cau hoi,Tra loi\n";
    for (var doc in docs) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      DateTime? time = _parseDateTime(d['timestamp']);
      String timeStr = time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time) : '';
      String chatId = doc.id;
      String userId = d['userId']?.toString() ?? 'UID-${doc.id.substring(0, 5).toUpperCase()}';

      csvContent += "$timeStr,$chatId,$userId,${d['category_tag']},${d['status']},${d['action_triggered']},${_escapeCSV(d['prompt'] ?? '')},${_escapeCSV(d['response'] ?? '')}\n";
    }
    _triggerDownload(csvContent, fileNamePrefix);
  }

  void _downloadAdminCSV(List<QueryDocumentSnapshot> docs) {
    String csvContent = "Thoi gian,Admin,Hanh dong,Muc tieu / Chi tiet\n";
    for (var doc in docs) {
      var d = doc.data() as Map<String, dynamic>? ?? {};
      DateTime? time = _parseDateTime(d['timestamp']);
      String timeStr = time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time) : '';
      String target = d['target'] ?? d['details'] ?? '';
      csvContent += "$timeStr,${d['adminEmail']},${d['action']},${_escapeCSV(target)}\n";
    }
    _triggerDownload(csvContent, "NhatKyAdmin");
  }

  void _triggerDownload(String csvContent, String fileNamePrefix) {
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = '${fileNamePrefix}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.csv';

    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đang tải tệp CSV về máy...")));
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
        title: const Text("Chi tiết Chat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(8)),
                child: Text("Hỏi:\n${data['prompt'] ?? '--'}", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                child: Text("AI Trả lời:\n${data['response'] ?? '--'}"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Đóng", style: TextStyle(color: primaryDarkGreen))
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
      backgroundColor: bgLightGreen,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Lịch sử & Theo dõi Hệ thống', style: TextStyle(color: primaryDarkGreen, fontSize: 28, fontWeight: FontWeight.bold)),
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
                      icon: Icon(Icons.calendar_month, color: _selectedDateRange == null ? textGrey : primaryDarkGreen),
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
                    const SizedBox(width: 10),
                    _buildTabButton("Nhật ký Admin", 2),
                  ],
                ),
                _buildExportButton(),
              ],
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Container(
                decoration: BoxDecoration(color: cardWhite, borderRadius: BorderRadius.circular(24)),
                child: IndexedStack(
                  index: _currentTabIndex == 2 ? 1 : 0,
                  children: [
                    _buildChatTable(),   // index 0 (khi _currentTabIndex là 0 hoặc 1)
                    _buildAdminTable(),  // index 1 (khi _currentTabIndex là 2)
                  ],
                ),
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
      decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(30)),
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
          color: isSelected ? primaryDarkGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildExportButton() {
    return StreamBuilder<QuerySnapshot>(
      // THÊM KEY ĐỂ FIX LỖI CACHE DỮ LIỆU
        key: ValueKey('export_btn_$_currentTabIndex'),
        stream: _currentTabIndex == 2 ? _adminLogsStream : _chatLogsStream,
        builder: (context, snapshot) {
          return ElevatedButton.icon(
            onPressed: () {
              if (!snapshot.hasData) return;
              var allDocs = snapshot.data!.docs;

              if (_currentTabIndex == 2) {
                var filteredDocs = allDocs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>? ?? {};
                  String adminEmail = (data['adminEmail'] ?? '').toString().toLowerCase();
                  String action = (data['action'] ?? '').toString().toLowerCase();
                  return adminEmail.contains(_searchQuery) || action.contains(_searchQuery);
                }).toList();
                _downloadAdminCSV(filteredDocs);
              } else {
                Map<String, int> promptCounts = {};
                for (var doc in allDocs) {
                  var d = doc.data() as Map<String, dynamic>? ?? {};
                  String key = "${d['userId'] ?? d['userEmail']}_${(d['prompt'] ?? '').toString().trim().toLowerCase()}";
                  promptCounts[key] = (promptCounts[key] ?? 0) + 1;
                }
                var filteredDocs = _getFilteredChatDocs(allDocs, promptCounts);
                _downloadCSV(filteredDocs, _currentTabIndex == 1 ? "DanhSachLoi" : "ToanBoChat");
              }
            },
            icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
            label: Text(
                _currentTabIndex == 2 ? "Tải nhật ký admin" : (_currentTabIndex == 1 ? "Tải danh sách lỗi" : "Xuất toàn bộ chat"),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
            ),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E4A1D),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
            ),
          );
        }
    );
  }

  Widget _buildFirestoreStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: _chatLogsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 104, child: Center(child: CircularProgressIndicator()));

        var allChatDocs = snapshot.data!.docs;
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
            _buildStatCard('Tổng số Log', NumberFormat('#,###').format(totalLogs), Icons.bar_chart, Colors.green[50]!, Colors.green[800]!),
            const SizedBox(width: 24),
            _buildStatCard('Cần huấn luyện AI', NumberFormat('#,###').format(failedCount), Icons.psychology, Colors.orange[50]!, Colors.orange[800]!),
            const SizedBox(width: 24),
            _buildStatCard('Log thành công', NumberFormat('#,###').format(successCount), Icons.check_circle, Colors.teal[50]!, Colors.teal[800]!),
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
              Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryDarkGreen)),
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

      bool matchDate = true;
      if (_selectedDateRange != null) {
        DateTime? time = _parseDateTime(data['timestamp']);
        if (time != null) {
          DateTime start = _selectedDateRange!.start;
          DateTime end = _selectedDateRange!.end.add(const Duration(days: 1));
          matchDate = time.isAfter(start) && time.isBefore(end);
        } else {
          matchDate = false;
        }
      }

      if (!matchSearch || !matchDate) return false;

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

  // --- BẢNG CHAT ---
  Widget _buildChatTable() {
    return StreamBuilder<QuerySnapshot>(
      // THÊM KEY ĐỂ BẮT BUỘC FLUTTER RENDER LẠI KHI ĐỔI TAB
        stream: _chatLogsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Có lỗi xảy ra khi tải dữ liệu Chat."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var allDocs = snapshot.data!.docs;
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
                    ? const Center(child: Text("Không có dữ liệu phù hợp.", style: TextStyle(color: textGrey)))
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

                    bool isFlagged = data['isFlagged'] == true || _currentTabIndex == 1;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(timeStr, style: const TextStyle(fontSize: 13, height: 1.4))),
                          Expanded(flex: 2, child: Text("#$chatId", style: const TextStyle(fontSize: 13, color: primaryDarkGreen, fontWeight: FontWeight.bold))),
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
                                        Text('ID: $userIdDisplay', style: const TextStyle(color: textGrey, fontSize: 12), overflow: TextOverflow.ellipsis),
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
                          Expanded(flex: 4, child: Text(displayPrompt, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontStyle: FontStyle.italic, color: textGrey, fontSize: 13))),
                          Expanded(
                            flex: 1,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(icon: const Icon(Icons.remove_red_eye, color: textGrey, size: 20), onPressed: () => _showDetailDialog(data), padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
                                IconButton(icon: Icon(isFlagged ? Icons.flag : Icons.flag_outlined, color: isFlagged ? Colors.red : textGrey, size: 20), onPressed: () => _toggleFlag(doc.id, data['isFlagged'] == true, userIdDisplay, data['prompt'] ?? ''), padding: const EdgeInsets.all(4), constraints: const BoxConstraints()),
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
    );
  }

  // --- BẢNG ADMIN ---
  Widget _buildAdminTable() {
    return StreamBuilder<QuerySnapshot>(
      // THÊM KEY ĐỂ BẮT BUỘC FLUTTER RENDER LẠI KHI ĐỔI TAB
        stream: _adminLogsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Có lỗi xảy ra khi tải Nhật ký Admin."));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var allDocs = snapshot.data!.docs;
          var filteredDocs = allDocs.where((doc) {
            var data = doc.data() as Map<String, dynamic>? ?? {};
            String adminEmail = (data['adminEmail'] ?? '').toString().toLowerCase();
            String action = (data['action'] ?? '').toString().toLowerCase();
            String target = (data['target'] ?? data['details'] ?? '').toString().toLowerCase();

            bool matchSearch = adminEmail.contains(_searchQuery) || action.contains(_searchQuery) || target.contains(_searchQuery);

            bool matchDate = true;
            if (_selectedDateRange != null) {
              DateTime? time = _parseDateTime(data['timestamp']);
              if (time != null) {
                DateTime start = _selectedDateRange!.start;
                DateTime end = _selectedDateRange!.end.add(const Duration(days: 1));
                matchDate = time.isAfter(start) && time.isBefore(end);
              } else {
                matchDate = false;
              }
            }
            return matchSearch && matchDate;
          }).toList();

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
                  _headerCell('THỜI GIAN', flex: 2), _headerCell('ADMIN', flex: 3),
                  _headerCell('HÀNH ĐỘNG', flex: 3), _headerCell('MỤC TIÊU / CHI TIẾT', flex: 4),
                ]),
              ),
              const Divider(height: 1),
              Expanded(
                child: pagedDocs.isEmpty
                    ? const Center(child: Text("Không có dữ liệu phù hợp.", style: TextStyle(color: textGrey)))
                    : ListView.builder(
                  itemCount: pagedDocs.length,
                  itemBuilder: (context, index) {
                    var doc = pagedDocs[index];
                    var data = doc.data() as Map<String, dynamic>? ?? {};
                    DateTime? time = _parseDateTime(data['timestamp']);

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey[50]!))),
                      child: Row(
                        children: [
                          Expanded(flex: 2, child: Text(time != null ? DateFormat('dd/MM/yyyy\nHH:mm').format(time) : '--', style: const TextStyle(fontSize: 13, height: 1.4))),
                          Expanded(flex: 3, child: Text(data['adminEmail'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 3, child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: const Color(0xFFE2EED8), borderRadius: BorderRadius.circular(8)),
                              child: Text(data['action'] ?? '', style: const TextStyle(color: Color(0xFF4C8C2B), fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          )),
                          Expanded(flex: 4, child: Text(data['target'] ?? data['details'] ?? '', style: const TextStyle(color: textGrey))),
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
    );
  }

  Widget _headerCell(String label, {int flex = 1}) => Expanded(flex: flex, child: Text(label, textAlign: flex == 1 ? TextAlign.center : TextAlign.left, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)));

  Widget _buildTableFooter(int total, int totalPages) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Text('Hiển thị ${total == 0 ? 0 : _currentPage * _rowsPerPage + 1} - ${min((_currentPage + 1) * _rowsPerPage, total)} trong $total kết quả', style: const TextStyle(color: Colors.grey, fontSize: 13)),
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
          color: active ? primaryDarkGreen : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(color: active ? primaryDarkGreen : Colors.grey[200]!),
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