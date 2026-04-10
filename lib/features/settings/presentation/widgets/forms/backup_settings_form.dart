import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';

class BackupSettingsForm extends StatelessWidget {
  const BackupSettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.backup;

    if (config == null) return const Center(child: CircularProgressIndicator());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sao lưu & Dữ liệu',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Tự động sao lưu dữ liệu hệ thống để đảm bảo an toàn thông tin.',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 24),

        ConfigCard(
          title: 'Lịch trình sao lưu',
          children: [
            SwitchListTile(
              title: const Text('Tự động sao lưu'),
              subtitle: const Text('Hệ thống sẽ tự động thực hiện sao lưu theo lịch'),
              value: config.enableAutoBackup,
              onChanged: (val) => provider.updateBackup(
                config.copyWith(enableAutoBackup: val),
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Tần suất sao lưu',
                  border: OutlineInputBorder(),
                ),
                value: config.backupFrequency,
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('Hàng ngày')),
                  DropdownMenuItem(value: 'weekly', child: Text('Hàng tuần')),
                  DropdownMenuItem(value: 'monthly', child: Text('Hàng tháng')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    provider.updateBackup(config.copyWith(backupFrequency: val));
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                initialValue: config.backupTime,
                decoration: const InputDecoration(
                  labelText: 'Thời điểm sao lưu (HH:mm)',
                  border: OutlineInputBorder(),
                  helperText: 'Ví dụ: 02:00 (Sáng sớm để tránh cao điểm)',
                ),
                onChanged: (val) => provider.updateBackup(
                  config.copyWith(backupTime: val),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextFormField(
                initialValue: config.retentionDays.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Thời gian lưu trữ bản sao (Ngày)',
                  border: OutlineInputBorder(),
                ),
                onChanged: (val) {
                  final days = int.tryParse(val);
                  if (days != null) {
                    provider.updateBackup(config.copyWith(retentionDays: days));
                  }
                },
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'Điểm đến sao lưu',
          children: [
            SwitchListTile(
              title: const Text('Sao lưu lên Cloud Storage'),
              subtitle: const Text('Firebase Storage / Google Cloud'),
              value: config.backupToCloudStorage,
              onChanged: (val) => provider.updateBackup(
                config.copyWith(backupToCloudStorage: val),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Sao lưu lên Server bên ngoài'),
              subtitle: const Text('Tự lưu trữ trên hạ tầng riêng'),
              value: config.backupToExternalServer,
              onChanged: (val) => provider.updateBackup(
                config.copyWith(backupToExternalServer: val),
              ),
            ),
            if (config.backupToExternalServer)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextFormField(
                  initialValue: config.externalServerUrl,
                  decoration: const InputDecoration(
                    labelText: 'URL Server External',
                    border: OutlineInputBorder(),
                    hintText: 'https://backup.yourdomain.com/api',
                  ),
                  onChanged: (val) => provider.updateBackup(
                    config.copyWith(externalServerUrl: val),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
