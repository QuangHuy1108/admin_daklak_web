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
  _MenuItem(Icons.image_outlined, 'Banner', '/banners'),
  _MenuItem(Icons.people_outlined, 'Tài khoản', '/users'),
  _MenuItem(Icons.calendar_today_outlined, 'Lịch hẹn chuyên gia', '/appointments'),
  _MenuItem(Icons.chat_bubble_outline_rounded, 'AI Chat Logs', '/ai-logs'),
  _MenuItem(Icons.bug_report_outlined, 'Sâu bệnh', '/diseases'),
  _MenuItem(Icons.attach_money_outlined, 'Giá nông sản', '/prices'),
  _MenuItem(Icons.bar_chart_outlined, 'Báo cáo & Thống kê', '/reports'),
  _MenuItem(Icons.settings_outlined, 'Cài đặt hệ thống', '/settings'),
];

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Tự động điều chỉnh kích thước sidebar dựa trên Breakpoint (Desktop, Tablet, Mobile)
    final screenWidth = MediaQuery.of(context).size.width;
    bool isDrawer = screenWidth <= 768;
    bool showIconsOnly = screenWidth > 768 && screenWidth <= 1024;
    
    // Nếu màn hình quá nhỏ thì sidebar được mở từ Drawer và được phép xem full width chữ
    // Nếu ở chế độ desktop thì dùng MenuProvider để người dùng tự toggle.
    bool _providerExpanded = context.watch<MenuProvider>().isExpanded;
    bool isExpanded = isDrawer ? true : (showIconsOnly ? false : _providerExpanded);

    final currentRoute = GoRouterState.of(context).matchedLocation;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isExpanded ? 240 : 80,
      decoration: const BoxDecoration(
        color: AppColors.sidebarBg,
        border: Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Column(
        children: [
          // ── Logo ─────────────────────────────────────────────
          Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.eco_rounded, color: Colors.white, size: 22),
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'DakLak Agent',
                      style: TextStyle(
                        color: AppColors.textHeading,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Menu items ────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
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
          // Xử lý đóng Drawer nếu chạy trên Mobile
          if (Scaffold.of(context).isDrawerOpen) {
            Navigator.pop(context);
          }
          context.go(widget.item.route);
        },
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 8),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isExpanded ? 16 : 0,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : _hovered
                    ? AppColors.background
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: widget.isExpanded
                ? MainAxisAlignment.start
                : MainAxisAlignment.center,
            children: [
              Icon(
                widget.item.icon,
                size: 22,
                color: active ? Colors.white : AppColors.textMuted,
              ),
              if (widget.isExpanded) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      color: active ? Colors.white : AppColors.textMuted,
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
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
          mainAxisAlignment:
              isExpanded ? MainAxisAlignment.start : MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 22, color: AppColors.textMuted),
            if (isExpanded) ...[
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
          ],
        ),
      ),
    );
  }
}