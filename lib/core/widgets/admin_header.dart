import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../../features/auth/services/auth_service.dart';
import '../../features/notifications/services/notification_service.dart';
import '../../features/notifications/models/notification_model.dart';
import '../../features/notifications/widgets/notification_dropdown.dart';

class AdminHeader extends StatelessWidget implements PreferredSizeWidget {
  const AdminHeader({super.key});

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width <= 768;

    return Container(
      height: 64, // Cập nhật chiều cao 64 cho không gian thoáng hơn
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.cardBg,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [

          // ── Feature 2: Search Bar ──────────────────────────────
          if (!isMobile)
            Expanded(
              flex: 5,
              child: Container(
                height: 40, // Tăng chiều cao search bar cho phù hợp với header 64
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 16),
                    Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Colors.grey.shade500,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search something here.....',
                          hintStyle: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textBody,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(flex: 3),

          // ── Feature 3: Actions Group ───────────────────────────
          // Notification item
          StreamBuilder<List<AdminNotification>>(
            stream: NotificationService.getUnreadNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                debugPrint('🚨 [AdminHeader] StreamBuilder Error: ${snapshot.error}');
              }
              final unreadList = snapshot.data ?? [];
              final unreadCount = unreadList.length;

              return Row(
                children: [
                   // Hidden Debug Button (only during V1/Dev)
                  IconButton(
                    icon: Icon(Icons.bug_report_outlined, color: Colors.grey.shade400, size: 18),
                    onPressed: () async {
                      try {
                        await NotificationService.sendTestNotification();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã gửi thông báo thử nghiệm thành công!')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi khi gửi thông báo: $e')),
                          );
                        }
                      }
                    },
                    tooltip: 'Gửi Test Notification',
                  ),
                  const SizedBox(width: 8),

                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: PopupMenuButton<void>(
                          padding: EdgeInsets.zero,
                          tooltip: 'Thông báo',
                          offset: const Offset(0, 50),
                          icon: Icon(
                            unreadCount > 0 ? Icons.notifications_active_rounded : Icons.notifications_none_rounded,
                            color: unreadCount > 0 ? AppColors.primary : AppColors.textHeading,
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          itemBuilder: (context) => [
                            PopupMenuItem<void>(
                              enabled: false, // Dropdown handle events internally
                              padding: EdgeInsets.zero,
                              child: NotificationDropdown(
                                notifications: unreadList,
                                onAction: () => Navigator.pop(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),

          const SizedBox(width: 20),

          // Vertical Divider ngăn cách chuông và profile
          Container(height: 24, width: 1, color: Colors.grey.shade300),

          const SizedBox(width: 20),

          // Profile item
          PopupMenuButton<String>(
            offset: const Offset(0, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                const CircleAvatar(
                  radius: 16, // Giảm kích thước avatar
                  backgroundImage: NetworkImage(
                    'https://i.pravatar.cc/150?img=11',
                  ),
                  backgroundColor: AppColors.background,
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Albert Flores',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      Text(
                        'albert45@mail.com',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64);
}
