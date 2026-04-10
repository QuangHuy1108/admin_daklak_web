import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class MonitoringSettingsForm extends StatelessWidget {
  const MonitoringSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.monitoring;

    if (config == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monitoring & Health',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Theo dõi hiệu năng hệ thống, ngưỡng cảnh báo và quy tắc lưu trữ nhật ký.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        ConfigCard(
          title: 'Hiệu năng & Cảnh báo',
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ngưỡng trễ API (ms): ${config.apiLatencyThresholdMs}ms'),
                  Slider(
                    value: config.apiLatencyThresholdMs.toDouble(),
                    min: 100,
                    max: 5000,
                    divisions: 49,
                    label: '${config.apiLatencyThresholdMs}ms',
                    activeColor: Theme.of(context).primaryColor,
                    onChanged: (val) => provider.updateMonitoring(
                      config.copyWith(apiLatencyThresholdMs: val.toInt()),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tỷ lệ lỗi cảnh báo (%): ${config.errorRateAlertThreshold}%'),
                  Slider(
                    value: config.errorRateAlertThreshold,
                    min: 0,
                    max: 20,
                    divisions: 20,
                    label: '${config.errorRateAlertThreshold}%',
                    activeColor: Colors.redAccent,
                    onChanged: (val) => provider.updateMonitoring(
                      config.copyWith(errorRateAlertThreshold: val),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Dữ liệu nhật ký (Logs)',
          children: [
            SwitchListTile(
              title: const Text('Theo dõi Firestore Usage'),
              subtitle: const Text('Ghi lại các hoạt động đọc/ghi để tối ưu chi phí'),
              value: config.enableFirestoreUsageTracking,
              onChanged: (val) => provider.updateMonitoring(
                config.copyWith(enableFirestoreUsageTracking: val),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Thống kê AI Usage'),
              subtitle: const Text('Theo dõi số lượng tokens và chi phí OpenAI/Gemini'),
              value: config.enableAIUsageStats,
              onChanged: (val) => provider.updateMonitoring(
                config.copyWith(enableAIUsageStats: val),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<int>(
                decoration: const InputDecoration(
                  labelText: 'Thời gian lưu trữ Logs',
                  border: OutlineInputBorder(),
                ),
                value: config.logRetentionDays,
                items: const [
                  DropdownMenuItem(value: 7, child: Text('7 Ngày')),
                  DropdownMenuItem(value: 30, child: Text('30 Ngày')),
                  DropdownMenuItem(value: 90, child: Text('90 Ngày')),
                  DropdownMenuItem(value: 365, child: Text('1 Năm')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateMonitoring(config.copyWith(logRetentionDays: val));
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
