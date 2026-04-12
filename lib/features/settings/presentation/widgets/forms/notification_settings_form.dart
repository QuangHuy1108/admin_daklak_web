import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';
import '../common/settings_form_header.dart';
import '../common/settings_form_footer.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

class NotificationSettingsForm extends StatelessWidget {
  const NotificationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.notification;

    if (config == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Premium Header
        SettingsFormHeader(
          title: 'Thông báo',
          subtitle: 'Quản lý cách hệ thống gửi thông báo cho người dùng và quản trị viên.',
          isLoading: provider.isLoading,
          onSave: () => provider.saveNotification(),
        ),

        // 2. Notification Channels
        ConfigCard(
          title: 'Kênh thông báo',
          icon: Icons.hub_rounded,
          iconCircleColor: const Color(0xFFE3F2FD),
          children: [
            _buildSwitchTile(
              title: 'Thông báo qua Email',
              subtitle: 'Gửi báo cáo và thông tin đơn hàng qua email',
              value: config.enableEmailNotifications,
              onChanged: (val) => provider.updateNotification(config.copyWith(enableEmailNotifications: val)),
            ),
            const Divider(height: 32, color: AppColors.border),
            _buildSwitchTile(
              title: 'Thông báo qua SMS',
              subtitle: 'Gửi mã OTP và thông báo khẩn cấp qua tin nhắn',
              value: config.enableSMSNotifications,
              onChanged: (val) => provider.updateNotification(config.copyWith(enableSMSNotifications: val)),
            ),
            const Divider(height: 32, color: AppColors.border),
            _buildSwitchTile(
              title: 'Thông báo Push',
              subtitle: 'Gửi thông báo trực tiếp đến ứng dụng di động',
              value: config.enablePushNotifications,
              onChanged: (val) => provider.updateNotification(config.copyWith(enablePushNotifications: val)),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Trigger Rules
        ConfigCard(
          title: 'Quy tắc kích hoạt',
          icon: Icons.rule_rounded,
          iconCircleColor: const Color(0xFFE8F5E9),
          children: [
            _buildCheckboxTile(
              title: 'Đơn hàng mới',
              subtitle: 'Thông báo khi có khách hàng đặt hàng mới',
              value: config.triggerRules.notifyOnNewOrder,
              onChanged: (val) => provider.updateNotification(config.copyWith(
                triggerRules: config.triggerRules.copyWith(notifyOnNewOrder: val ?? false),
              )),
            ),
            const Divider(height: 24, color: AppColors.border),
            _buildCheckboxTile(
              title: 'Sắp hết hàng',
              subtitle: 'Thông báo khi sản phẩm trong kho xuống dưới mức tối thiểu',
              value: config.triggerRules.notifyOnLowStock,
              onChanged: (val) => provider.updateNotification(config.copyWith(
                triggerRules: config.triggerRules.copyWith(notifyOnLowStock: val ?? false),
              )),
            ),
            const Divider(height: 24, color: AppColors.border),
            _buildCheckboxTile(
              title: 'Lỗi hệ thống',
              subtitle: 'Thông báo khẩn cấp khi có sự cố kỹ thuật nghiêm trọng',
              value: config.triggerRules.notifyOnSystemError,
              onChanged: (val) => provider.updateNotification(config.copyWith(
                triggerRules: config.triggerRules.copyWith(notifyOnSystemError: val ?? false),
              )),
            ),
            const Divider(height: 24, color: AppColors.border),
            _buildCheckboxTile(
              title: 'Yêu cầu từ chuyên gia',
              subtitle: 'Thông báo khi có lịch hẹn tư vấn mới cho chuyên gia',
              value: config.triggerRules.notifyOnNewExpertAppointment,
              onChanged: (val) => provider.updateNotification(config.copyWith(
                triggerRules: config.triggerRules.copyWith(notifyOnNewExpertAppointment: val ?? false),
              )),
            ),
          ],
        ),

        // 4. Premium Footer
        SettingsFormFooter(
          isLoading: provider.isLoading,
          onSave: () => provider.saveNotification(),
          onDiscard: () => provider.discardChanges(),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textHeading)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildCheckboxTile({required String title, required String subtitle, required bool value, required ValueChanged<bool?> onChanged}) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textHeading)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: AppColors.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
    );
  }
}
