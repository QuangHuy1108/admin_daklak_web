import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class FeatureFlagsForm extends StatelessWidget {
  const FeatureFlagsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.featureFlags;

    if (config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Flags & Lab',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Quản lý trạng thái bật/tắt các module và các tính năng đang trong giai đoạn thử nghiệm.'),
        const SizedBox(height: 32),

        ConfigCard(
          title: 'Trạng thái vận hành',
          icon: Icons.power_settings_new,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: config.isMaintenanceMode ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: config.isMaintenanceMode ? Colors.orange.withOpacity(0.3) : Colors.green.withOpacity(0.2),
                ),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Chế độ bảo trì hệ thống'),
                    subtitle: const Text('Khi bật, người dùng phổ thông sẽ không thể truy cập ứng dụng.'),
                    value: config.isMaintenanceMode,
                    activeColor: Colors.orange,
                    onChanged: (val) {
                      provider.updateFeatureFlags(config.copyWith(isMaintenanceMode: val));
                    },
                  ),
                  if (config.isMaintenanceMode) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: config.maintenanceMessage,
                      decoration: const InputDecoration(
                        labelText: 'Thông báo hiển thị cho khách hàng',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      onChanged: (val) {
                        provider.updateFeatureFlags(config.copyWith(maintenanceMessage: val));
                      },
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Quản lý Module',
          icon: Icons.view_module,
          children: [
            SwitchListTile(
              title: const Text('Hệ thống AI Analytics'),
              subtitle: const Text('Bật/tắt dashboard phân tích AI, chatbot chuyên gia và dự báo giá.'),
              value: config.customFlags['ai_analytics'] ?? true,
              onChanged: (val) {
                final newFlags = Map<String, bool>.from(config.customFlags);
                newFlags['ai_analytics'] = val;
                provider.updateFeatureFlags(config.copyWith(customFlags: newFlags));
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Hệ thống Voucher & Khuyến mãi'),
              subtitle: const Text('Quản lý việc áp dụng mã giảm giá và các chương trình ưu đãi.'),
              value: config.enablePromotions,
              onChanged: (val) {
                provider.updateFeatureFlags(config.copyWith(enablePromotions: val));
              },
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Tính năng Beta'),
              subtitle: const Text('Cho phép một nhóm nhỏ người dùng thử nghiệm các tính năng mới.'),
              value: config.enableBetaFeatures,
              onChanged: (val) {
                provider.updateFeatureFlags(config.copyWith(enableBetaFeatures: val));
              },
            ),
            if (config.enableBetaFeatures) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Tỷ lệ áp dụng Beta: '),
                  Expanded(
                    child: Slider(
                      value: config.betaRolloutPercentage.toDouble(),
                      min: 0,
                      max: 100,
                      divisions: 10,
                      label: '${config.betaRolloutPercentage}%',
                      onChanged: (val) {
                        provider.updateFeatureFlags(config.copyWith(betaRolloutPercentage: val.toInt()));
                      },
                    ),
                  ),
                  Text('${config.betaRolloutPercentage}%'),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
