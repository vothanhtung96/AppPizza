import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizza_app_vs_010/services/theme_service.dart';
import 'package:pizza_app_vs_010/service/shared_pref.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String userName = "";

  @override
  void initState() {
    super.initState();
    getUserName();
  }

  getUserName() async {
    userName = await SharedPreferenceHelper().getUserName() ?? "User";
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cài đặt'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.surface.withOpacity(0.1),
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User Profile Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        FontAwesomeIcons.user,
                        color: theme.colorScheme.onPrimary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(userName, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            'Người dùng',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Theme Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao diện',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Current Theme Display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.outline.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            themeService.getThemeModeIcon(),
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Chế độ hiện tại',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                ),
                                Text(
                                  themeService.getThemeModeName(),
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme Options
                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.light,
                      'Chế độ sáng',
                      'Giao diện sáng với màu nền trắng',
                      Icons.light_mode,
                    ),

                    const SizedBox(height: 8),

                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.dark,
                      'Chế độ tối',
                      'Giao diện tối với màu nền đen',
                      Icons.dark_mode,
                    ),

                    const SizedBox(height: 8),

                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.system,
                      'Theo hệ thống',
                      'Tự động theo cài đặt hệ thống',
                      Icons.brightness_auto,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Other Settings Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Khác',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.bell,
                      title: 'Thông báo',
                      subtitle: 'Quản lý thông báo đơn hàng',
                      onTap: () {
                        // TODO: Navigate to notification settings
                      },
                    ),

                    const Divider(),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.language,
                      title: 'Ngôn ngữ',
                      subtitle: 'Tiếng Việt',
                      onTap: () {
                        // TODO: Navigate to language settings
                      },
                    ),

                    const Divider(),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.shield,
                      title: 'Bảo mật',
                      subtitle: 'Đổi mật khẩu, bảo mật tài khoản',
                      onTap: () {
                        // TODO: Navigate to security settings
                      },
                    ),

                    const Divider(),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.circleQuestion,
                      title: 'Trợ giúp',
                      subtitle: 'Hướng dẫn sử dụng, liên hệ hỗ trợ',
                      onTap: () {
                        // TODO: Navigate to help page
                      },
                    ),

                    const Divider(),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.circleInfo,
                      title: 'Về ứng dụng',
                      subtitle: 'Phiên bản 1.0.0',
                      onTap: () {
                        // TODO: Show app info
                      },
                    ),

                    const Divider(),

                    _buildSettingItem(
                      icon: FontAwesomeIcons.palette,
                      title: 'Demo Theme',
                      subtitle: 'Xem demo giao diện',
                      onTap: () {
                        Navigator.pushNamed(context, '/theme_demo');
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Show confirmation dialog
                  bool? confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Đăng xuất'),
                      content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Hủy'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Đăng xuất'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    // Clear user data and navigate to login
                    await SharedPreferenceHelper().saveLoginStatus(false);
                    await SharedPreferenceHelper().saveUserName("");
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        '/login',
                        (route) => false,
                      );
                    }
                  }
                },
                icon: const Icon(FontAwesomeIcons.rightFromBracket),
                label: const Text('Đăng xuất'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.error,
                  foregroundColor: theme.colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    ThemeService themeService,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final isSelected = themeService.themeMode == mode;

    return InkWell(
      onTap: () => themeService.setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurface.withOpacity(0.5),
      ),
      onTap: onTap,
    );
  }
}
