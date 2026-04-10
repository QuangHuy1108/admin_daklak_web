import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class LocalizationSettingsForm extends StatelessWidget {
  const LocalizationSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.localization;

    if (config == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Định dạng & Ngôn ngữ',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Cấu hình múi giờ, tiền tệ và các định dạng hiển thị mặc định trên hệ thống.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        ConfigCard(
          title: 'Cài đặt khu vực',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Ngôn ngữ mặc định',
                  border: OutlineInputBorder(),
                ),
                value: config.defaultLanguage,
                items: const [
                  DropdownMenuItem(value: 'vi', child: Text('Tiếng Việt')),
                  DropdownMenuItem(value: 'en', child: Text('English')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateLocalization(config.copyWith(defaultLanguage: val));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tiền tệ',
                  border: OutlineInputBorder(),
                ),
                value: config.defaultCurrency,
                items: const [
                  DropdownMenuItem(value: 'VND', child: Text('Việt Nam Đồng (VND)')),
                  DropdownMenuItem(value: 'USD', child: Text('US Dollar (USD)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateLocalization(config.copyWith(defaultCurrency: val));
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Thời gian & Đơn vị',
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Múi giờ',
                  border: OutlineInputBorder(),
                ),
                value: config.defaultTimezone,
                items: const [
                  DropdownMenuItem(value: 'Asia/Ho_Chi_Minh', child: Text('Asia/Ho_Chi_Minh (GMT+7)')),
                  DropdownMenuItem(value: 'UTC', child: Text('UTC (GMT+0)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateLocalization(config.copyWith(defaultTimezone: val));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Định dạng ngày',
                  border: OutlineInputBorder(),
                ),
                value: config.dateFormat,
                items: const [
                  DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('dd/MM/yyyy')),
                  DropdownMenuItem(value: 'MM/dd/yyyy', child: Text('MM/dd/yyyy')),
                  DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('yyyy-MM-dd')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateLocalization(config.copyWith(dateFormat: val));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Hệ thống đơn vị',
                  border: OutlineInputBorder(),
                ),
                value: config.unitSystem,
                items: const [
                  DropdownMenuItem(value: 'metric', child: Text('Hệ mét (kg, m)')),
                  DropdownMenuItem(value: 'imperial', child: Text('Hệ Anh (lb, ft)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateLocalization(config.copyWith(unitSystem: val));
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
