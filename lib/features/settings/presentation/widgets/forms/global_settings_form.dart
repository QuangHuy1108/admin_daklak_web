import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class GlobalSettingsForm extends StatelessWidget {
  const GlobalSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.global;

    if (config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hệ thống chung',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Quản lý thông tin thương hiệu và trạng thái vận hành của toàn bộ hệ thống.'),
        const SizedBox(height: 32),
        
        ConfigCard(
          title: 'Thông tin thương hiệu',
          icon: Icons.branding_watermark,
          children: [
            TextFormField(
              initialValue: config.appName,
              decoration: const InputDecoration(
                labelText: 'Tên ứng dụng',
                border: OutlineInputBorder(),
              ),
              onChanged: (val) => provider.updateGlobal(config.copyWith(appName: val)),
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.logoUrl,
              decoration: const InputDecoration(
                labelText: 'Logo URL',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
              onChanged: (val) => provider.updateGlobal(config.copyWith(logoUrl: val)),
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        
        ConfigCard(
          title: 'Thông tin liên hệ',
          icon: Icons.contact_support,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.contactPhone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => provider.updateGlobal(config.copyWith(contactPhone: val)),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: TextFormField(
                    initialValue: config.contactEmail,
                    decoration: const InputDecoration(
                      labelText: 'Email liên hệ',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (val) => provider.updateGlobal(config.copyWith(contactEmail: val)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.address,
              decoration: const InputDecoration(
                labelText: 'Địa chỉ trụ sở',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              onChanged: (val) => provider.updateGlobal(config.copyWith(address: val)),
            ),
          ],
        ),
        
      ],
    );
  }
}
