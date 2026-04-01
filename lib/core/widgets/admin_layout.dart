import 'package:flutter/material.dart';
import 'admin_sidebar.dart';
import 'admin_header.dart';
import '../constants/app_colors.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const AdminHeader(),
      drawer: MediaQuery.of(context).size.width <= 768 ? const AdminSidebar() : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hiển thị Sidebar cố định trên Desktop, thu gọn thành icon nếu width nằm trong khoảng 768-1024
          if (MediaQuery.of(context).size.width > 768) 
             const AdminSidebar(),
             
          // Phần thân (Body)
          Expanded(
            child: Container(
              color: AppColors.background,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}