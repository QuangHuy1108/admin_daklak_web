import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/menu_provider.dart';
import '../constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';

class _MenuItem {
  final IconData icon;
  final String label;
  final String route;
  const _MenuItem(this.icon, this.label, this.route);
}

const _mainMenu = [
  _MenuItem(Icons.dashboard_rounded, 'Dashboard', '/dashboard'),
  _MenuItem(Icons.shopping_cart_outlined, 'Quản lý Đơn hàng', '/sales'),
  _MenuItem(Icons.image_outlined, 'Banner', '/banners'),
  _MenuItem(Icons.people_outlined, 'Tài khoản', '/users'),
  _MenuItem(Icons.calendar_today_outlined, 'Lịch hẹn chuyên gia', '/appointments'),
  _MenuItem(Icons.chat_bubble_outline_rounded, 'AI Chat Logs', '/ai-logs'),
  _MenuItem(Icons.bug_report_outlined, 'Sâu bệnh', '/diseases'),
  _MenuItem(Icons.attach_money_outlined, 'Giá nông sản', '/prices'),
  _MenuItem(Icons.bar_chart_outlined, 'Báo cáo & Thống kê', '/reports'),
  _MenuItem(Icons.security_outlined, 'Nhật ký hệ thống', '/audit-logs'),
  _MenuItem(Icons.settings_outlined, 'Cài đặt hệ thống', '/settings'),
];

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    bool isDrawer = screenWidth <= 768;
    bool showIconsOnly = screenWidth > 768 && screenWidth <= 1024;

    bool _providerExpanded = context.watch<MenuProvider>().isExpanded;
    bool isExpanded = isDrawer ? true : (showIconsOnly ? false : _providerExpanded);

    final currentRoute = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 240 : 80,
      clipBehavior: Clip.antiAlias,
      height: MediaQuery.of(context).size.height,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────────
          Container(
            height: 64, // Đồng bộ 64px với Header mới
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 24),
                ),
                if (isExpanded)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(width: 12),
                          const Text(
                            'FarmVista',
                            style: TextStyle(
                              color: AppColors.textHeading,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ── Menu items ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 8), // Bỏ padding ngang để viền trái chạm lề
              children: _mainMenu.map((item) => _SidebarTile(
                item: item,
                isExpanded: isExpanded,
                isActive: currentRoute.startsWith(item.route),
              )).toList(),
            ),
          ),

          // ── Logout ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(12),
            child: _LogoutButton(isExpanded: isExpanded),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatefulWidget {
  final _MenuItem item;
  final bool isExpanded;
  final bool isActive;
  const _SidebarTile({required this.item, required this.isExpanded, required this.isActive});

  @override
  State<_SidebarTile> createState() => _SidebarTileState();
}

class _SidebarTileState extends State<_SidebarTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: () {
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
          context.go(widget.item.route);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8, right: 16), // Thêm margin phải
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 16 : 0,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withOpacity(0.08) // Nền xanh nhạt giống ảnh
                : _hovered
                ? AppColors.background
                : Colors.transparent,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
            border: Border(
              left: BorderSide(
                color: active ? AppColors.primary : Colors.transparent, // Vạch dọc bên trái
                width: 4,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
              if (widget.isExpanded)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          widget.item.label,
                          style: TextStyle(
                            color: active ? AppColors.primary : AppColors.textMuted,
                            fontSize: 14,
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  final bool isExpanded;
  const _LogoutButton({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        await AuthService().logout();
        if (context.mounted) context.go('/login');
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isExpanded ? 16 : 0,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 22, color: AppColors.textMuted),
            if (isExpanded)
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 16),
                      const Text(
                        'Đăng xuất',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}