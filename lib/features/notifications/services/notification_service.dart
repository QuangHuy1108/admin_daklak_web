import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:admin_daklak_web/features/notifications/models/notification_model.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class NotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _db = _firestore.collection('admin_notifications');

  /// Stream of the latest 20 unread notifications
  /// Optimized with client-side sorting to bypass Firestore index requirements.
  static Stream<List<AdminNotification>> getUnreadNotificationsStream() {
    return _db
        .where('isRead', isEqualTo: false)
        .snapshots()
        .handleError((error) {
           debugPrint('🚨 [NotificationService] Firestore Stream Error: $error');
        })
        .map((snapshot) {
          final List<AdminNotification> notifications = [];
          
          for (var doc in snapshot.docs) {
            try {
              notifications.add(AdminNotification.fromFirestore(doc));
            } catch (e) {
              debugPrint('⚠️ [NotificationService] Lỗi map dữ liệu document ${doc.id}: $e');
              // Skip corrupted documents to prevent the whole stream from crashing
            }
          }

          // Client-side sorting (Newest first) fallback
          notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          
          return notifications.take(20).toList();
        });
  }

  /// Mark a single notification as read
  static Future<void> markAsRead(String id) async {
    try {
      await _db.doc(id).update({'isRead': true});
    } catch (e) {
      debugPrint('Lỗi khi đánh dấu đã đọc: $e');
    }
  }

  /// Mark all unread notifications as read using a single atomic WriteBatch
  static Future<void> markAllAsRead() async {
    try {
      final query = await _db.where('isRead', isEqualTo: false).get();
      if (query.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {'isRead': true});
      }
      await batch.commit();
    } catch (e) {
      debugPrint('Lỗi khi đánh dấu tất cả đã đọc: $e');
    }
  }

  /// V1 Utility: Manually send a randomized test notification for verification
  static Future<void> sendTestNotification() async {
    final random = Random();
    final int caseTest = random.nextInt(3); // Random từ 0 đến 2

    String title = '';
    String message = '';
    NotificationType type = NotificationType.system;
    String? targetRoute;

    // Tạo 3 kịch bản thông báo khác nhau
    switch (caseTest) {
      case 0:
        title = 'Đơn hàng mới - VIP';
        message = 'Có đơn hàng #ORD-${random.nextInt(1000)} vừa được thanh toán thành công.';
        type = NotificationType.order;
        targetRoute = '/orders';
        break;
      case 1:
        title = 'Sản phẩm sắp hết hàng';
        message = 'Phân tích tồn kho NPK cho thấy còn dưới 10 bao trong kho!';
        type = NotificationType.lowStock;
        targetRoute = '/products';
        break;
      case 2:
        title = 'AI đang gặp sự cố';
        message = 'Hệ thống AI không thể trả lời 3 câu hỏi liên tiếp từ người dùng.';
        type = NotificationType.aiError;
        targetRoute = '/ai-logs';
        break;
    }

    try {
      final newNotif = AdminNotification(
        id: _db.doc().id,
        title: title,
        message: message,
        type: type,
        isRead: false,
        timestamp: DateTime.now(),
        targetRoute: targetRoute,
      );
      
      await _db.doc(newNotif.id).set(newNotif.toMap());
    } catch (e) {
      debugPrint('🚨 [NotificationService] Lỗi khi gửi thông báo thử nghiệm: $e');
      rethrow;
    }
  }
}
