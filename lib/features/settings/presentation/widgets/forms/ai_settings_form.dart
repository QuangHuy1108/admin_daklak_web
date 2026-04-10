import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../logic/settings_provider.dart';
import '../common/config_card.dart';
import '../common/secure_text_field.dart';

class AISettingsForm extends StatelessWidget {
  const AISettingsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SettingsProvider>();
    final config = provider.ai;

    if (config == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI & Tích hợp',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text('Cấu hình các thành phần trí tuệ nhân tạo và các dịch vụ tích hợp bên thứ ba.'),
        const SizedBox(height: 32),

        ConfigCard(
          title: 'Cấu hình Gemini & LLM',
          icon: Icons.auto_awesome,
          children: [
            DropdownButtonFormField<String>(
              value: config.selectedModel,
              decoration: const InputDecoration(
                labelText: 'Model AI chính',
                border: OutlineInputBorder(),
              ),
              items: ['gemini-1.5-pro', 'gemini-1.5-flash', 'gpt-4o', 'gpt-4o-mini']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (val) {
                if (val != null) provider.updateAI(config.copyWith(selectedModel: val));
              },
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Temperature: '),
                Expanded(
                  child: Slider(
                    value: config.temperature,
                    min: 0,
                    max: 1.0,
                    divisions: 10,
                    label: config.temperature.toString(),
                    onChanged: (val) => provider.updateAI(config.copyWith(temperature: val)),
                  ),
                ),
                Text(config.temperature.toStringAsFixed(1)),
              ],
            ),
            const SizedBox(height: 20),
            TextFormField(
              initialValue: config.systemPrompt,
              decoration: const InputDecoration(
                labelText: 'System Prompt (Dùng cho chatbot & chuyên gia)',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (val) => provider.updateAI(config.copyWith(systemPrompt: val)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'API Keys & Secrets',
          icon: Icons.vpn_key,
          subtitle: 'Các khóa bí mật dùng để kết nối với các dịch vụ bên thứ ba.',
          children: [
            SecureTextField(
              label: 'Gemini API Key',
              initialValue: config.apiKey,
              onChanged: (val) => provider.updateAI(config.copyWith(apiKey: val)),
            ),
            const SizedBox(height: 20),
            SecureTextField(
              label: 'Weather API Key (OpenWeather)',
              initialValue: config.weatherApiKey,
              onChanged: (val) => provider.updateAI(config.copyWith(weatherApiKey: val)),
            ),
            const SizedBox(height: 20),
            SecureTextField(
              label: 'Email API Key (SendGrid/Mailgun)',
              initialValue: config.emailApiKey,
              onChanged: (val) => provider.updateAI(config.copyWith(emailApiKey: val)),
            ),
          ],
        ),

        const SizedBox(height: 24),

        ConfigCard(
          title: 'AI Governance',
          icon: Icons.gavel,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: config.governance.dailyUsageLimit.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Hạn mức sử dụng hàng ngày (Request)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      final limit = int.tryParse(val) ?? 0;
                      provider.updateAI(config.copyWith(
                        governance: config.governance.copyWith(dailyUsageLimit: limit),
                      ));
                    },
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: config.governance.fallbackModel,
                    decoration: const InputDecoration(
                      labelText: 'Model dự phòng',
                      border: OutlineInputBorder(),
                    ),
                    items: ['gpt-4o-mini', 'claude-3-haiku', 'gemini-1.5-flash']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        provider.updateAI(config.copyWith(
                          governance: config.governance.copyWith(fallbackModel: val),
                        ));
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              title: const Text('Bật bộ lọc an toàn (Safety Filters)'),
              subtitle: const Text('Tự động chặn các phản hồi không phù hợp hoặc nguy hiểm.'),
              value: config.governance.enableSafetyFilters,
              onChanged: (val) {
                provider.updateAI(config.copyWith(
                  governance: config.governance.copyWith(enableSafetyFilters: val),
                ));
              },
            ),
          ],
        ),
      ],
    );
  }
}
