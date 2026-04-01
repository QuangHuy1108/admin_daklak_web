import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/menu_provider.dart';
import '../constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width <= 768;

    return Container(
      height: kToolbarHeight + 1,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // ── Menu toggle (Chỉ hiện nếu trên mobile/tablet để mở drawer) ────────────────
           IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textHeading, size: 24),
              onPressed: () {
                if (isMobile) {
                  Scaffold.of(context).openDrawer();
                } else {
                  context.read<MenuProvider>().toggleMenu();
                }
              },
              tooltip: 'Toggle menu',
            ),
          const SizedBox(width: 16),

          // ── Search bar ───────────────────────────────────────
          if (MediaQuery.of(context).size.width > 500) // Ẩn thanh tìm kiếm nếu quá nhỏ
            Expanded(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, size: 18, color: AppColors.textMuted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search something here...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 14, color: AppColors.textBody),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else 
            const Spacer(),

          if (MediaQuery.of(context).size.width > 500) const Spacer(),

          // ── Notification bell ─────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textHeading, size: 24),
                onPressed: () {},
                tooltip: 'Thông báo',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, // Green dot cho FarmVista
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(width: 16),

          // ── Admin profile ─────────────────────────────────────
          PopupMenuButton<String>(
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline_rounded, size: 18),
                    SizedBox(width: 10),
                    Text('My Account'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 18),
                    SizedBox(width: 10),
                    Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout_rounded, size: 18, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().logout();
                if (context.mounted) context.go('/login');
              } else if (value == 'settings') {
                context.go('/settings');
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.background,
                  child: const Icon(Icons.person, size: 20, color: AppColors.textMuted),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  const Text(
                    'Admin',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      size: 20, color: AppColors.textMuted),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 1);
}