import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AiLogsScreen extends StatelessWidget {
  const AiLogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Lịch sử & Theo dõi Hệ thống', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: Colors.green,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.green,
            tabs: [
              Tab(icon: Icon(Icons.chat_bubble_outline), text: "Lịch sử Chat AI"),
              Tab(icon: Icon(Icons.admin_panel_settings), text: "Nhật ký Admin (Audit)"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AiChatLogsTab(),
            _AdminLogsTab(),
          ],
        ),
      ),
    );
  }
}

// ================= TAB 1: AI CHAT LOGS =================
class _AiChatLogsTab extends StatelessWidget {
  const _AiChatLogsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: StreamBuilder<QuerySnapshot>(
          // Giả sử dữ liệu chat lưu ở collection 'ai_chat_logs'
          stream: FirebaseFirestore.instance.collection('ai_chat_logs').orderBy('timestamp', descending: true).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có lịch sử Chat AI.'));

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 20,
                  headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[100]),
                  columns: const [
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Người dùng')),
                    DataColumn(label: Text('Câu hỏi (Prompt)')),
                    DataColumn(label: Text('AI Trả lời')),
                  ],
                  rows: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime? time;
                    if (data['timestamp'] != null) {
                      time = (data['timestamp'] as Timestamp).toDate();
                    }

                    return DataRow(cells: [
                      DataCell(Text(time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time) : '--')),
                      DataCell(Text(data['userId'] ?? data['userEmail'] ?? 'Unknown')),
                      DataCell(SizedBox(
                          width: 250,
                          child: Text(data['prompt'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis)
                      )),
                      DataCell(SizedBox(
                          width: 300,
                          child: Text(data['response'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.grey))
                      )),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ================= TAB 2: ADMIN LOGS (AUDIT) =================
class _AdminLogsTab extends StatelessWidget {
  const _AdminLogsTab();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        child: StreamBuilder<QuerySnapshot>(
          // Giả sử log hành động admin lưu ở collection 'admin_logs'
          stream: FirebaseFirestore.instance.collection('admin_logs').orderBy('timestamp', descending: true).limit(50).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text('Chưa có nhật ký hoạt động.'));

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  columnSpacing: 40,
                  headingRowColor: WidgetStateProperty.resolveWith((states) => Colors.grey[100]),
                  columns: const [
                    DataColumn(label: Text('Thời gian')),
                    DataColumn(label: Text('Admin')),
                    DataColumn(label: Text('Hành động')),
                    DataColumn(label: Text('Mục tiêu')),
                  ],
                  rows: snapshot.data!.docs.map((doc) {
                    var data = doc.data() as Map<String, dynamic>;
                    DateTime? time;
                    if (data['timestamp'] != null) {
                      time = (data['timestamp'] as Timestamp).toDate();
                    }

                    return DataRow(cells: [
                      DataCell(Text(time != null ? DateFormat('dd/MM/yyyy HH:mm').format(time) : '--')),
                      DataCell(Text(data['adminEmail'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(data['action'] ?? '', style: TextStyle(color: Colors.blue[800], fontSize: 12)),
                          )
                      ),
                      DataCell(Text(data['target'] ?? data['details'] ?? '')),
                    ]);
                  }).toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}