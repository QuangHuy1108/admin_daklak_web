import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import 'notification_tile.dart';

class NotificationDropdown extends StatelessWidget {
  final List<AdminNotification> notifications;
  final VoidCallback onAction;

  const NotificationDropdown({
    super.key,
    required this.notifications,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: Container(
        width: 380, // Chiều rộng phù hợp cho dashboard web
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Thông báo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  if (notifications.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        await NotificationService.markAllAsRead();
                        onAction();
                      },
                      child: const Text(
                        'Đánh dấu tất cả đã đọc',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            
            // Notification List
            notifications.isEmpty
                ? Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.notifications_none_rounded, size: 48, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Không có thông báo mới',
                            style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  )
                : Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        return NotificationTile(
                          notification: notifications[index],
                          onAction: onAction,
                        );
                      },
                    ),
                  ),
            
            // Footer
            if (notifications.isNotEmpty) ...[
              const Divider(height: 1),
              InkWell(
                onTap: () {
                   // Tính năng mở rộng màn hình thông báo chính trong tương lai
                   onAction();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  alignment: Alignment.center,
                  child: Text(
                    'Xem tất cả thông báo',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
