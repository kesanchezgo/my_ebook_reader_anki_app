import 'package:flutter/material.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../config/app_theme.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader(context, l10n.appearance),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.appLanguageTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.appLanguageSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildLanguageSelector(context),
                const SizedBox(height: 24),
                Divider(color: colorScheme.outlineVariant.withOpacity(0.2)),
                const SizedBox(height: 24),
                Text(
                  l10n.themeTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.themeSubtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                ...AppTheme.themes.values.map((theme) => _buildThemeOption(context, theme)),
              ],
            ),
          ),
          
          const SizedBox(height: 32),

          _buildSectionHeader(context, l10n.aiServices),
          const SizedBox(height: 16),
          _buildAiServicesSection(context),
          
          const SizedBox(height: 32),

          _buildSectionHeader(context, l10n.smartDictionary),
          const SizedBox(height: 16),
          _buildDictionaryPrioritySection(context),
          
          const SizedBox(height: 32),

          _buildSectionHeader(context, l10n.contextExplanation),
          const SizedBox(height: 16),
          _buildContextPrioritySection(context),
          
          const SizedBox(height: 32),
          
          _buildSectionHeader(context, l10n.information),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _buildInfoTile(
                  context, 
                  l10n.version, 
                  '1.0.0', 
                  Icons.info_outline_rounded
                ),
                Divider(height: 1, indent: 56, color: colorScheme.outlineVariant.withOpacity(0.2)),
                _buildInfoTile(
                  context, 
                  l10n.developer, 
                  'Book Lector', 
                  Icons.code_rounded
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return ValueListenableBuilder<Locale?>(
      valueListenable: SettingsService.instance.localeNotifier,
      builder: (context, currentLocale, _) {
        final currentCode = currentLocale?.languageCode;
        
        return Row(
          children: [
            _buildLanguageOption(
              context, 
              label: 'Español', 
              code: 'es', 
              isSelected: currentCode == 'es'
            ),
            const SizedBox(width: 12),
            _buildLanguageOption(
              context, 
              label: 'English', 
              code: 'en', 
              isSelected: currentCode == 'en'
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(BuildContext context, {
    required String label,
    required String code,
    required bool isSelected,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: InkWell(
        onTap: () => SettingsService.instance.setLocale(code),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiServicesSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.apiCredentials,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.apiCredentialsSubtitle,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          
          // Gemini
          _buildApiKeyField(
            context,
            label: 'Gemini API Key',
            hint: l10n.apiKeyHint,
            icon: Icons.auto_awesome_rounded,
            controller: TextEditingController(text: SettingsService.instance.geminiApiKey),
            onChanged: (val) => SettingsService.instance.setGeminiApiKey(val),
          ),
          const SizedBox(height: 16),
          
          // Perplexity
          _buildApiKeyField(
            context,
            label: 'Perplexity API Key',
            hint: 'pplx-...',
            icon: Icons.psychology_rounded,
            controller: TextEditingController(text: SettingsService.instance.perplexityApiKey),
            onChanged: (val) => SettingsService.instance.setPerplexityApiKey(val),
          ),
          const SizedBox(height: 16),
          
          // OpenRouter
          _buildApiKeyField(
            context,
            label: 'OpenRouter API Key',
            hint: 'sk-or-...',
            icon: Icons.cloud_circle_rounded,
            controller: TextEditingController(text: SettingsService.instance.openRouterApiKey),
            onChanged: (val) => SettingsService.instance.setOpenRouterApiKey(val),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyField(BuildContext context, {
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    required Function(String) onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: colorScheme.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildDictionaryPrioritySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.definitionPriority,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.definitionPrioritySubtitle,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildPriorityList(context),
        ],
      ),
    );
  }

  Widget _buildContextPrioritySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.explanationPriority,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.explanationPrioritySubtitle,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _buildContextPriorityList(context),
        ],
      ),
    );
  }

  Widget _buildPriorityList(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final priorities = SettingsService.instance.dictionaryPriority;
        
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final newPriorities = List<String>.from(priorities);
              final item = newPriorities.removeAt(oldIndex);
              newPriorities.insert(newIndex, item);
              
              SettingsService.instance.setDictionaryPriority(newPriorities);
            });
          },
          children: [
            for (final source in priorities)
              ListTile(
                key: ValueKey(source),
                leading: Icon(Icons.drag_handle_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text(_getSourceName(context, source)),
                trailing: Icon(_getSourceIcon(source), color: Theme.of(context).colorScheme.primary),
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
          ],
        );
      },
    );
  }

  Widget _buildContextPriorityList(BuildContext context) {
    return StatefulBuilder(
      builder: (context, setState) {
        final priorities = SettingsService.instance.contextPriority;
        
        return ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final newPriorities = List<String>.from(priorities);
              final item = newPriorities.removeAt(oldIndex);
              newPriorities.insert(newIndex, item);
              
              SettingsService.instance.setContextPriority(newPriorities);
            });
          },
          children: [
            for (final source in priorities)
              ListTile(
                key: ValueKey(source),
                leading: Icon(Icons.drag_handle_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
                title: Text(_getSourceName(context, source)),
                trailing: Icon(_getSourceIcon(source), color: Theme.of(context).colorScheme.primary),
                tileColor: Theme.of(context).colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
          ],
        );
      },
    );
  }

  String _getSourceName(BuildContext context, String source) {
    final l10n = AppLocalizations.of(context)!;
    switch (source) {
      case 'gemini': return l10n.geminiAi;
      case 'perplexity': return l10n.perplexityAi;
      case 'openrouter': return l10n.openRouter;
      case 'local': return l10n.localDictionary;
      case 'web': return l10n.webDictionary;
      default: return source;
    }
  }

  IconData _getSourceIcon(String source) {
    switch (source) {
      case 'gemini': return Icons.auto_awesome_rounded;
      case 'perplexity': return Icons.psychology_rounded;
      case 'openrouter': return Icons.cloud_circle_rounded;
      case 'local': return Icons.sd_storage_rounded;
      case 'web': return Icons.public_rounded;
      default: return Icons.help_outline_rounded;
    }
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildInfoTile(BuildContext context, String title, String subtitle, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer.withOpacity(0.4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: colorScheme.secondary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );
  }

  Widget _buildThemeOption(BuildContext context, AppTheme theme) {
    return ValueListenableBuilder<String>(
      valueListenable: SettingsService.instance.themeNotifier,
      builder: (context, currentThemeId, _) {
        final isSelected = currentThemeId == theme.id;
        final colorScheme = Theme.of(context).colorScheme;
        final l10n = AppLocalizations.of(context)!;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: InkWell(
            onTap: () => SettingsService.instance.setThemeId(theme.id),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.backgroundColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          color: theme.textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          theme.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (isSelected)
                          Text(
                            l10n.active,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, color: colorScheme.onPrimary, size: 16),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
