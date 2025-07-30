import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pizza_app_vs_010/services/theme_service.dart';
import 'package:provider/provider.dart';

class ThemeDemo extends StatelessWidget {
  const ThemeDemo({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo Theme'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(
              themeService.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeService.toggleTheme(),
          ),
        ],
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
            // Theme Mode Display
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chế độ hiện tại', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          themeService.getThemeModeIcon(),
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          themeService.getThemeModeName(),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Theme Options
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Chọn chế độ', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),

                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.light,
                      'Chế độ sáng',
                      Icons.light_mode,
                    ),

                    const SizedBox(height: 8),

                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.dark,
                      'Chế độ tối',
                      Icons.dark_mode,
                    ),

                    const SizedBox(height: 8),

                    _buildThemeOption(
                      context,
                      themeService,
                      ThemeMode.system,
                      'Theo hệ thống',
                      Icons.brightness_auto,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // UI Components Demo
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Demo UI Components',
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {},
                            child: const Text('Primary Button'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Secondary Button'),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Text Fields
                    TextField(
                      decoration: const InputDecoration(
                        labelText: 'Input Field',
                        hintText: 'Enter text here',
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Icon(
                          FontAwesomeIcons.pizzaSlice,
                          color: theme.colorScheme.primary,
                          size: 32,
                        ),
                        Icon(
                          FontAwesomeIcons.burger,
                          color: theme.colorScheme.secondary,
                          size: 32,
                        ),
                        Icon(
                          FontAwesomeIcons.iceCream,
                          color: theme.colorScheme.error,
                          size: 32,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Color Palette
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Color Palette', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 16),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildColorSwatch('Primary', theme.colorScheme.primary),
                        _buildColorSwatch(
                          'Secondary',
                          theme.colorScheme.secondary,
                        ),
                        _buildColorSwatch('Surface', theme.colorScheme.surface),
                        _buildColorSwatch(
                          'Background',
                          theme.colorScheme.surface,
                        ),
                        _buildColorSwatch('Error', theme.colorScheme.error),
                        _buildColorSwatch('Outline', theme.colorScheme.outline),
                      ],
                    ),
                  ],
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
              child: Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
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

  Widget _buildColorSwatch(String name, Color color) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: const TextStyle(fontSize: 10),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
