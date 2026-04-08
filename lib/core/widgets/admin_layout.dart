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
      // Hiển thị Drawer trên Mobile
      drawer: MediaQuery.of(context).size.width <= 768 ? const AdminSidebar() : null,
      body: Row(
        children: [
          // 1. Sidebar (Cố định trên Desktop - Tự điều chỉnh chiều rộng)
          if (MediaQuery.of(context).size.width > 768)
            const AdminSidebar(),

          // 2. Right Content Area
          Expanded(
            child: Column(
              children: [
                // Header (Cố định phía trên)
                const AdminHeader(),

                // Main Content (Phần nội dung có thể scroll)
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}