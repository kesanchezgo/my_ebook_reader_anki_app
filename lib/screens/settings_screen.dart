import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Apariencia',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Tema Global',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          ...AppTheme.themes.values.map((theme) => _buildThemeOption(context, theme)),
        ],
      ),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppTheme theme) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.themeNotifier,
      builder: (context, currentThemeId, _) {
        final isSelected = currentThemeId == theme.id;
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isSelected 
                ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                : BorderSide.none,
          ),
          child: InkWell(
            onTap: () => SettingsService.instance.setThemeId(theme.id),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: Theme.of(context).primaryColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
