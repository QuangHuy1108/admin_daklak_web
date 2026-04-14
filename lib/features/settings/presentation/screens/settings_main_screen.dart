import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../logic/settings_provider.dart';
import '../widgets/forms/global_settings_form.dart';
import '../widgets/forms/ai_settings_form.dart';
import '../widgets/forms/business_settings_form.dart';
import '../widgets/forms/security_settings_form.dart';
import '../widgets/forms/feature_flags_form.dart';
import '../widgets/forms/notification_settings_form.dart';
import '../widgets/forms/localization_settings_form.dart';
import '../widgets/forms/monitoring_settings_form.dart';
import '../widgets/forms/backup_settings_form.dart';
import '../../data/models/settings_group.dart';
import 'package:admin_daklak_web/core/constants/app_colors.dart';
import 'package:admin_daklak_web/core/constants/app_text_styles.dart';

class SettingsMainScreen extends StatefulWidget {
  const SettingsMainScreen({super.key});

  @override
  State<SettingsMainScreen> createState() => _SettingsMainScreenState();
}

class _SettingsMainScreenState extends State<SettingsMainScreen> {
  int _selectedIndex = 0;

  late final List<SettingsGroup> _groups = [
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
      title: 'Tính năng thử nghiệm',
      icon: Icons.flag_rounded,
      builder: (context) => const FeatureFlagsForm(),
    ),
    SettingsGroup(
      title: 'Định dạng & Ngôn ngữ',
      icon: Icons.language_rounded,
      builder: (context) => const LocalizationSettingsForm(),
    ),
    SettingsGroup(
      title: 'Giám sát & Sức khỏe',
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left Sidebar (Master) ───────────────────────────────────
          _SettingsSidebar(
            groups: _groups,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
          ),

          // ── Right Content Area (Detail) ─────────────────────────────
          Expanded(
            child: Container(
              color: Colors.transparent,
              child: Consumer<SettingsProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading && provider.global == null) {
                    return Center(
                      child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
                    );
                  }

                  if (provider.errorMessage != null && provider.global == null) {
                    return Center(
                      child: Text(
                        provider.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.redAccent),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cài đặt hệ thống',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Quản lý cấu hình toàn cục và các thông số kỹ thuật của hệ thống.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 32),
                            _groups[_selectedIndex].builder(context),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSidebar extends StatelessWidget {
  final List<SettingsGroup> groups;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _SettingsSidebar({
    required this.groups,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.3), width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
            child: Text(
              'CÀI ĐẶT HỆ THỐNG',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: groups.length,
              itemBuilder: (context, index) {
                final group = groups[index];
                final isSelected = index == selectedIndex;

                return _SidebarItem(
                  title: group.title,
                  icon: group.icon,
                  isSelected: isSelected,
                  onTap: () => onSelected(index),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final activeColor = Theme.of(context).primaryColor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? activeColor.withOpacity(0.1)
                  : _isHovered
                      ? (Theme.of(context).brightness == Brightness.dark ? Colors.white12 : Colors.black.withOpacity(0.05))
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 20,
                  color: widget.isSelected ? activeColor : Theme.of(context).textTheme.bodySmall?.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                      color: widget.isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (widget.isSelected)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

