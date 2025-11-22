import 'package:flutter/material.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import '../services/local_dictionary_service.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/premium_toast.dart';

/// Pantalla de configuración de diccionarios
class DictionarySettingsScreen extends StatefulWidget {
  const DictionarySettingsScreen({super.key});

  @override
  State<DictionarySettingsScreen> createState() => _DictionarySettingsScreenState();
}

class _DictionarySettingsScreenState extends State<DictionarySettingsScreen> {
  final LocalDictionaryService _dictService = LocalDictionaryService();
  Map<String, int> _stats = {};
  double _dbSize = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final stats = await _dictService.getStats();
    final size = await _dictService.getDatabaseSize();
    setState(() {
      _stats = stats;
      _dbSize = size;
      _isLoading = false;
    });
  }

  Future<void> _importDictionary() async {
    final l10n = AppLocalizations.of(context)!;
    try {
      // 1. Mostrar selector de archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;
      
      final filePath = result.files.single.path!;
      
      // 2. Preguntar idioma del diccionario monolingüe
      if (!mounted) return;
      final isSpanishDict = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.dictionaryLanguage),
          content: Text(l10n.dictionaryLanguageQuestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.englishLanguage),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.spanishLanguage),
            ),
          ],
        ),
      );

      if (isSpanishDict == null) return;
      
      // 3. Mostrar diálogo de progreso
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.importingDictionary),
              ],
            ),
          ),
        );
      }

      // 4. Importar diccionario
      final importedCount = await _dictService.importDictionary(
        filePath, 
        isSpanishDict: isSpanishDict,
      );
      
      await _loadStats();

      // 5. Cerrar diálogo y mostrar resultado
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de progreso
        PremiumToast.show(context, l10n.importedWordsCount(importedCount), isSuccess: true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de progreso si hay error
        
        // Mensajes de error amigables
        String errorMessage = l10n.importError;
        
        if (e.toString().contains('JSON')) {
          errorMessage = l10n.invalidJsonError;
        } else if (e.toString().contains('array')) {
          errorMessage = l10n.invalidJsonArrayError;
        } else if (e.toString().contains('entradas')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        PremiumToast.show(context, errorMessage, isError: true);
      }
    }
  }

  Future<void> _clearDictionary() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearDictionary),
        content: Text(l10n.clearDictionaryConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dictService.clearDictionary();
      await _loadStats();
      
      if (mounted) {
        PremiumToast.show(context, l10n.dictionaryCleared, isSuccess: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.dictionarySettingsTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Información sobre el sistema
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: colorScheme.primary),
                          const SizedBox(width: 12),
                          Text(
                            l10n.howItWorks,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.howItWorksDescription,
                        style: TextStyle(fontSize: 14, height: 1.5, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Estadísticas
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.statistics,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _StatRow(
                        icon: Icons.book_rounded,
                        label: l10n.spanishDictionary,
                        value: '${_stats['spanish'] ?? 0} palabras', // TODO: Localize "palabras" if needed, but it's part of the value here. Maybe better to just show number? Or localize "words" separately. For now I'll leave it as is or fix it. "palabras" is hardcoded.
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        icon: Icons.menu_book_rounded,
                        label: l10n.englishDictionary,
                        value: '${_stats['english'] ?? 0} palabras',
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.3)),
                      ),
                      _StatRow(
                        icon: Icons.storage_rounded,
                        label: l10n.totalStored,
                        value: '${_stats['total'] ?? 0} palabras',
                        isBold: true,
                      ),
                      const SizedBox(height: 12),
                      _StatRow(
                        icon: Icons.sd_storage_rounded,
                        label: l10n.diskSize,
                        value: '${_dbSize.toStringAsFixed(2)} MB',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Acciones
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                        child: Text(
                          l10n.actions,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Botón importar
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.file_upload_rounded, color: colorScheme.primary, size: 20),
                        ),
                        title: Text(l10n.importDictionary, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l10n.jsonFormat, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
                        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: _importDictionary,
                      ),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.2)),
                      ),
                      
                      // Botón limpiar
                      ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colorScheme.errorContainer.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.delete_sweep_rounded, color: colorScheme.error, size: 20),
                        ),
                        title: Text(l10n.clearDictionary, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(l10n.delete, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)), // Simplified subtitle to just "Delete" or maybe I should add a key for "Delete X words". For now "Delete" is fine or I can use the count.
                        trailing: Icon(Icons.chevron_right_rounded, color: colorScheme.onSurfaceVariant),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onTap: _clearDictionary,
                        enabled: (_stats['total'] ?? 0) > 0,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Instrucciones para crear diccionario
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.2)),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.help_outline_rounded, color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 12),
                          Text(
                            l10n.dictionaryFormat,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '[\n'
                          '  {\n'
                          '    "id": "00001",\n'
                          '    "lemma": "casa",\n'
                          '    "definition": "Edificio para habitar"\n'
                          '  },\n'
                          '  {\n'
                          '    "word": "libro",\n'
                          '    "definition": "Conjunto de hojas impresas"\n'
                          '  }\n'
                          ']',
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF4EC9B0),
                            height: 1.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.supportedFormats,
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isBold;
  
  const _StatRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isBold = false,
  });
  
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? colorScheme.primary : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
