import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pizza_app_vs_010/services/theme_service.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);
    
    return IconButton(
      icon: Icon(
        themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
        color: theme.colorScheme.onPrimary,
      ),
      onPressed: () => themeService.toggleTheme(),
      tooltip: 'Chuyển đổi giao diện',
    );
  }
} 