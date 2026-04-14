import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_sidebar.dart';
import 'admin_header.dart';
import '../constants/app_colors.dart';
import '../providers/theme_provider.dart';
import '../providers/menu_provider.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  const AdminLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [
                  AppColors.glassGradientStartDark,
                  AppColors.glassGradientMidDark,
                  AppColors.glassGradientEndDark,
                ]
              : [
                  AppColors.glassGradientStartLight,
                  AppColors.glassGradientMidLight,
                  AppColors.glassGradientEndLight,
                ],
          ),
        ),
        // Hiển thị Drawer trên Mobile
        child: MediaQuery.of(context).size.width <= 768
            ? Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: AdminHeader(),
                        ),
                        Expanded(child: child),
                      ],
                    ),
                  )
                ],
              )
            : Consumer<MenuProvider>(
                builder: (context, menuProvider, _) {
                  final sidebarWidth = menuProvider.isExpanded ? 260.0 : 88.0;
                  final totalSidebarSpace = sidebarWidth + 24.0; 

                  return Stack(
                    children: [
                      // 1. Right Content Area (Bottom Layer)
                      Positioned.fill(
                        left: totalSidebarSpace,
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
                              child: AdminHeader(),
                            ),
                            Expanded(child: child),
                          ],
                        ),
                      ),

                      // 2. Sidebar Floating (Top Layer / High Z-Index)
                      Positioned(
                        left: 24,
                        top: 24,
                        bottom: 24,
                        width: sidebarWidth,
                        child: const AdminSidebar(),
                      ),
                    ],
                  );
                },
              ),
      ),
      drawer: MediaQuery.of(context).size.width <= 768 ? const AdminSidebar() : null,
    );
  }
}
