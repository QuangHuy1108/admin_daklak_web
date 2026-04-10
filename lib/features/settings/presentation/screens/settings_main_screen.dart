import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/settings_provider.dart';
import '../widgets/common/sticky_save_bar.dart';
import '../widgets/forms/global_settings_form.dart';
import '../widgets/forms/ai_settings_form.dart';
import '../widgets/forms/business_settings_form.dart';
import '../widgets/forms/security_settings_form.dart';
import '../widgets/forms/feature_flags_form.dart';
import '../widgets/forms/notification_settings_form.dart';
import '../widgets/forms/localization_settings_form.dart';
import '../widgets/forms/monitoring_settings_form.dart';
import '../widgets/forms/backup_settings_form.dart';
import '../widgets/common/visual_horizontal_nav.dart';
import '../../data/models/settings_group.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:flutter/gestures.dart';
import 'dart:ui';

class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});

  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  int _selectedIndex = 0;

  final List<SettingsGroup> _groups = [
    SettingsGroup(
      title: 'Hệ thống chung',
      icon: Icons.grid_view_rounded,
      builder: (context) => const GlobalSettingsForm(),
    ),
    SettingsGroup(
      title: 'Cấu hình Kinh doanh',
      icon: Icons.business_center_rounded,
      builder: (context) => const BusinessSettingsForm(),
    ),
    SettingsGroup(
      title: 'AI & Tích hợp',
      icon: Icons.psychology_rounded,
      builder: (context) => const AISettingsForm(),
    ),
    SettingsGroup(
      title: 'Bảo mật & Quyền',
      icon: Icons.security_rounded,
      builder: (context) => const SecuritySettingsForm(),
    ),
    SettingsGroup(
      title: 'Thông báo',
      icon: Icons.notifications_rounded,
      builder: (context) => const NotificationSettingsForm(),
    ),
    SettingsGroup(
      title: 'Feature Flags',
      icon: Icons.flag_rounded,
      builder: (context) => const FeatureFlagsForm(),
    ),
    SettingsGroup(
      title: 'Định dạng & Ngôn ngữ',
      icon: Icons.language_rounded,
      builder: (context) => const LocalizationSettingsForm(),
    ),
    SettingsGroup(
      title: 'Monitoring & Health',
      icon: Icons.insights_rounded,
      builder: (context) => const MonitoringSettingsForm(),
    ),
    SettingsGroup(
      title: 'Sao lưu & Dữ liệu',
      icon: Icons.backup_rounded,
      builder: (context) => const BackupSettingsForm(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().loadAllSettings();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDirty = context.watch<SettingsProvider>().isAnyDirty;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              // Top Horizontal Visual Navigation (Pro Max Rich Card Style)
              VisualHorizontalNav(
                groups: _groups,
                selectedIndex: _selectedIndex,
                onSelected: (index) => setState(() => _selectedIndex = index),
              ),
              
              // Detail Content
              Expanded(
                child: Consumer<SettingsProvider>(
                  builder: (context, provider, child) {
                    if (provider.isLoading && provider.global == null) {
                      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                    }
                    
                    if (provider.errorMessage != null && provider.global == null) {
                      return Center(
                        child: Text(
                          provider.errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      );
                    }

                    return ScrollConfiguration(
                      behavior: ScrollConfiguration.of(context).copyWith(
                        dragDevices: {
                          PointerDeviceKind.touch,
                          PointerDeviceKind.mouse,
                        },
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                        child: Center(
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 1000),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _groups[_selectedIndex].builder(context),
                                const SizedBox(height: 120), // Space for Sticky Bar
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          
          if (isDirty)
            const Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: StickySaveBar(),
            ),
        ],
      ),
    );
  }
}
