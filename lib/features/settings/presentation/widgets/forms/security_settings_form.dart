import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:admin_daklak_web/core/constants/app_text_styles.dart';

class SecuritySettingsForm extends StatelessWidget {
  const SecuritySettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.security;

    if (config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bảo mật & Quyền',
          style: AppTextStyles.heading2,
        ),
        const SizedBox(height: 8),
        Text(
          'Quản lý các chính sách bảo mật, truy cập và bảo vệ dữ liệu hệ thống.',
          style: AppTextStyles.subtitle,
        ),
        const SizedBox(height: 24),

        ConfigCard(
          title: 'Chính sách truy cập',
          icon: Icons.lock_person,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Số lần đăng nhập sai tối đa',
                    initialValue: config.maxLoginAttempts.toString(),
                    helperText: 'Khóa tạm thời nếu vượt quá số lần này.',
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 5;
                      provider.updateSecurity(config.copyWith(maxLoginAttempts: parsed));
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Thời gian khóa (Phút)',
                    initialValue: config.lockoutDurationMinutes.toString(),
                    onChanged: (val) {
                      final parsed = int.tryParse(val) ?? 15;
                      provider.updateSecurity(config.copyWith(lockoutDurationMinutes: parsed));
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              activeColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
              title: const Text('Bắt buộc xác thực 2 lớp (2FA)'),
              subtitle: const Text('Áp dụng cho tất cả tài khoản quản trị viên và chuyên gia.'),
              value: config.forceTwoFactorAuth,
              onChanged: (val) {
                provider.updateSecurity(config.copyWith(forceTwoFactorAuth: val));
              },
            ),
          ],
        ),

        ConfigCard(
          title: 'Hành động khẩn cấp',
          icon: Icons.emergency_share,
          subtitle: 'Các thao tác ảnh hưởng đến tất cả người dùng.',
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.04),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Buộc đăng xuất toàn hệ thống',
                        style: AppTextStyles.heading3.copyWith(color: Colors.redAccent, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Thao tác này sẽ yêu cầu TẤT CẢ người dùng phải xác thực lại. Chỉ sử dụng trong sự cố nghiêm trọng.',
                    style: TextStyle(fontSize: 13, color: AppColors.textHeading),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showForceLogoutDialog(context, provider),
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Buộc đăng xuất tất cả thiết bị'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                  if (config.globalForceLogoutTimestamp != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Lần cuối: ${DateFormat('HH:mm dd/MM/yyyy').format(config.globalForceLogoutTimestamp!)}',
                      style: AppTextStyles.label.copyWith(fontStyle: FontStyle.italic, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required String initialValue,
    String? helperText,
    required ValueChanged<String> onChanged,
  }) {
    return TextFormField(
      initialValue: initialValue,
      style: AppTextStyles.bodyText,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        fillColor: AppColors.cardBg,
        filled: true,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }

  void _showForceLogoutDialog(BuildContext context, SettingsProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận buộc đăng xuất?'),
        content: const Text(
          'Hành động này sẽ buộc tất cả người dùng phải đăng nhập lại. Thao tác này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.triggerGlobalForceLogout();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? 'Phát lệnh thành công!' : 'Lỗi hệ thống.'),
                    backgroundColor: success ? AppColors.primary : Colors.redAccent,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }
}
