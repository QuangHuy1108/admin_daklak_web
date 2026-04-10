import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class NotificationSettingsForm extends StatelessWidget {
  const NotificationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.notification;

    if (config == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thông báo',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Quản lý cách hệ thống gửi thông báo cho người dùng và quản trị viên.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        ConfigCard(
          title: 'Kênh thông báo',
          children: [
            SwitchListTile(
              title: const Text('Thông báo qua Email'),
              subtitle: const Text('Gửi báo cáo và thông tin đơn hàng qua email'),
              value: config.enableEmailNotifications,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(enableEmailNotifications: val),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Thông báo qua SMS'),
              subtitle: const Text('Gửi mã OTP và thông báo khẩn cấp qua tin nhắn'),
              value: config.enableSMSNotifications,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(enableSMSNotifications: val),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Thông báo Push'),
              subtitle: const Text('Gửi thông báo trực tiếp đến ứng dụng di động'),
              value: config.enablePushNotifications,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(enablePushNotifications: val),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Quy tắc kích hoạt',
          children: [
            CheckboxListTile(
              title: const Text('Đơn hàng mới'),
              subtitle: const Text('Thông báo khi có khách hàng đặt hàng mới'),
              value: config.triggerRules.notifyOnNewOrder,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(
                  triggerRules: config.triggerRules.copyWith(notifyOnNewOrder: val ?? false),
                ),
              ),
            ),
            CheckboxListTile(
              title: const Text('Sắp hết hàng'),
              subtitle: const Text('Thông báo khi sản phẩm trong kho xuống dưới mức tối thiểu'),
              value: config.triggerRules.notifyOnLowStock,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(
                  triggerRules: config.triggerRules.copyWith(notifyOnLowStock: val ?? false),
                ),
              ),
            ),
            CheckboxListTile(
              title: const Text('Lỗi hệ thống'),
              subtitle: const Text('Thông báo khẩn cấp khi có sự cố kỹ thuật nghiêm trọng'),
              value: config.triggerRules.notifyOnSystemError,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(
                  triggerRules: config.triggerRules.copyWith(notifyOnSystemError: val ?? false),
                ),
              ),
            ),
            CheckboxListTile(
              title: const Text('Yêu cầu từ chuyên gia'),
              subtitle: const Text('Thông báo khi có lịch hẹn tư vấn mới cho chuyên gia'),
              value: config.triggerRules.notifyOnNewExpertAppointment,
              onChanged: (val) => provider.updateNotification(
                config.copyWith(
                  triggerRules: config.triggerRules.copyWith(notifyOnNewExpertAppointment: val ?? false),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
