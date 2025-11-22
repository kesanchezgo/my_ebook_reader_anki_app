import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../models/book.dart';
import '../services/settings_service.dart';

class PurposeModal extends StatefulWidget {
  final Book book;
  final Function(Book) onConfigured;

  const PurposeModal({
    super.key,
    required this.book,
    required this.onConfigured,
  });

  @override
  State<PurposeModal> createState() => _PurposeModalState();
}

class _PurposeModalState extends State<PurposeModal> {
  String? _selectedMode;
  String? _targetLanguage;
  
  @override
  void initState() {
    super.initState();
    // Pre-select based on logic
    final appLocale = SettingsService.instance.locale?.languageCode ?? 'es'; // Default to 'es' if system is unknown or null
    final bookLang = widget.book.language?.toLowerCase() ?? 'en'; // Default to 'en' if unknown
    
    if (bookLang == appLocale) {
      _selectedMode = 'native_vocab';
    } else {
      _selectedMode = 'learn_language';
      _targetLanguage = appLocale;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final appLocale = SettingsService.instance.locale?.languageCode ?? 'es';
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Flexible(
            child: Text(
              l10n.purposeModalTitle,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.purposeModalSubtitle,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          
          // Opciones
          _buildOption(
            context,
            id: 'read_only',
            title: l10n.readOnlyMode,
            subtitle: l10n.readOnlyModeDesc,
            icon: Icons.menu_book_rounded,
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            id: 'native_vocab',
            title: l10n.nativeMode,
            subtitle: l10n.nativeModeDesc,
            icon: Icons.school_rounded,
            isRecommended: widget.book.language == appLocale,
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            id: 'learn_language',
            title: l10n.studyMode,
            subtitle: l10n.studyModeDesc,
            icon: Icons.translate_rounded,
            isRecommended: widget.book.language != appLocale,
            child: _selectedMode == 'learn_language' 
              ? _buildTargetLanguageSelector(context) 
              : null,
          ),
          
          const SizedBox(height: 32),
          
          // Botón Confirmar
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _selectedMode != null ? () {
                final updatedBook = widget.book.copyWith(
                  studyMode: _selectedMode,
                  targetLanguage: _selectedMode == 'learn_language' ? _targetLanguage : null,
                );
                widget.onConfigured(updatedBook);
              } : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(
                l10n.startReading,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOption(BuildContext context, {
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isRecommended = false,
    Widget? child,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _selectedMode == id;
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => setState(() => _selectedMode = id),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? colorScheme.primaryContainer.withOpacity(0.4) 
              : colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: colorScheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                l10n.recommended.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: colorScheme.primary),
              ],
            ),
            if (child != null) ...[
              const SizedBox(height: 12),
              child,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTargetLanguageSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.targetLanguage,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _targetLanguage,
              isDense: true,
              icon: Icon(Icons.arrow_drop_down_rounded, color: colorScheme.primary),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              items: [
                DropdownMenuItem(value: 'es', child: Text(l10n.langSpanish)),
                DropdownMenuItem(value: 'en', child: Text(l10n.langEnglish)),
                DropdownMenuItem(value: 'fr', child: Text(l10n.langFrench)),
                DropdownMenuItem(value: 'de', child: Text(l10n.langGerman)),
                DropdownMenuItem(value: 'it', child: Text(l10n.langItalian)),
                DropdownMenuItem(value: 'pt', child: Text(l10n.langPortuguese)),
              ],
              onChanged: (val) => setState(() => _targetLanguage = val),
            ),
          ),
        ],
      ),
    );
  }
}
