import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';
import '../common/settings_form_header.dart';
import '../common/settings_form_footer.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';

class LocalizationSettingsForm extends StatelessWidget {
  const LocalizationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.localization;

    if (config == null) return const Center(child: CircularProgressIndicator(color: AppColors.primary));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Premium Header
        SettingsFormHeader(
          title: 'Định dạng & Ngôn ngữ',
          subtitle: 'Cấu hình múi giờ, tiền tệ và các định dạng hiển thị mặc định trên hệ thống.',
          isLoading: provider.isLoading,
          onSave: () => provider.saveLocalization(),
        ),

        // 2. Regional Settings
        ConfigCard(
          title: 'Cài đặt khu vực',
          icon: Icons.language_rounded,
          iconCircleColor: const Color(0xFFE8ECEB),
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Ngôn ngữ mặc định',
                    value: config.defaultLanguage,
                    items: const [
                      DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.updateLocalization(config.copyWith(defaultLanguage: val));
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDropdown(
                    label: 'Tiền tệ mặc định',
                    value: config.defaultCurrency,
                    items: const [
                      DropdownMenuItem(value: 'VND', child: Text('Việt Nam Đồng (VND)')),
                      DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.updateLocalization(config.copyWith(defaultCurrency: val));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 16),

        // 3. Time & Units
        ConfigCard(
          title: 'Thời gian & Đơn vị',
          icon: Icons.date_range_rounded,
          iconCircleColor: const Color(0xFFFFF3E0),
          children: [
            _buildDropdown(
              label: 'Múi giờ hệ thống',
              value: config.defaultTimezone,
              items: const [
                DropdownMenuItem(value: 'Asia/Ho_Chi_Minh', child: Text('Asia/Ho_Chi_Minh (GMT+7)')),
                DropdownMenuItem(value: 'UTC', child: Text('UTC (GMT+0)')),
              ],
              onChanged: (val) {
                if (val != null) provider.updateLocalization(config.copyWith(defaultTimezone: val));
              },
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Định dạng ngày',
                    value: config.dateFormat,
                    items: const [
                      DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
                      DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/dd/yyyy')),
                      DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.updateLocalization(config.copyWith(dateFormat: val));
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildDropdown(
                    label: 'Hệ thống đơn vị',
                    value: config.unitSystem,
                    items: const [
                      DropdownMenuItem(value: 'metric', child: Text('Hệ mét (kg, m)')),
                      DropdownMenuItem(value: 'imperial', child: Text('Hệ Anh (lb, ft)')),
                    ],
                    onChanged: (val) {
                      if (val != null) provider.updateLocalization(config.copyWith(unitSystem: val));
                    },
                  ),
                ),
              ],
            ),
          ],
        ),

        // 4. Premium Footer
        SettingsFormFooter(
          isLoading: provider.isLoading,
          onSave: () => provider.saveLocalization(),
          onDiscard: () => provider.discardChanges(),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textHeading)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceVariant.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          ),
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textHeading),
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
