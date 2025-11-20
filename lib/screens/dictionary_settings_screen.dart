import 'package:flutter/material.dart';
import '../services/local_dictionary_service.dart';
import 'package:file_picker/file_picker.dart';

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
    try {
      // 1. Mostrar selector de archivo
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
      );

      if (result == null || result.files.single.path == null) return;
      
      final filePath = result.files.single.path!;
      
      // 2. Preguntar idioma del diccionario monolingüe
      final isSpanishDict = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Idioma del diccionario'),
          content: const Text('¿En qué idioma están las definiciones?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('🇬🇧 Inglés (EN)'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('🇪🇸 Español (ES)'),
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
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Importando diccionario...'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Importadas $importedCount palabras'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Cerrar diálogo de progreso si hay error
        
        // Mensajes de error amigables
        String errorMessage = 'Error al importar diccionario';
        
        if (e.toString().contains('JSON')) {
          errorMessage = 'El archivo no es un JSON válido';
        } else if (e.toString().contains('array')) {
          errorMessage = 'Formato incorrecto: se esperaba un array JSON';
        } else if (e.toString().contains('entradas')) {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        } else {
          errorMessage = e.toString().replaceAll('Exception: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'DETALLES',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error de importación'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.toString()),
                          const SizedBox(height: 16),
                          const Text(
                            'Formatos soportados:\n\n'
                            '📖 SpanishBFF:\n'
                            '  {"id": "00001", "lemma": "palabra", "definition": "..."}\n\n'
                            '📖 Estándar:\n'
                            '  {"word": "palabra", "definition": "...", "examples": "..."}\n\n'
                            '📖 Alternativo:\n'
                            '  {"term": "palabra", "meaning": "..."}\n\n'
                            'Nota: El diccionario debe ser monolingüe\n'
                            '(palabra y definición en el mismo idioma)',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('CERRAR'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _clearDictionary() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpiar diccionario'),
        content: const Text('¿Estás seguro? Se eliminarán todas las palabras guardadas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _dictService.clearDictionary();
      await _loadStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Diccionario limpiado'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Diccionarios'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Información sobre el sistema
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            const Text(
                              'Cómo funciona',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '1. El diccionario local se consulta primero (rápido, offline)\n'
                          '2. Si no encuentra la palabra, busca online\n'
                          '3. Las palabras encontradas online se guardan localmente',
                          style: TextStyle(fontSize: 14, height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Estadísticas
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estadísticas',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _StatRow(
                          icon: Icons.book,
                          label: '🇪🇸 Diccionario Español',
                          value: '${_stats['spanish'] ?? 0} palabras',
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.menu_book,
                          label: '🇬🇧 Diccionario English',
                          value: '${_stats['english'] ?? 0} palabras',
                        ),
                        const Divider(height: 24),
                        _StatRow(
                          icon: Icons.storage,
                          label: 'Total almacenado',
                          value: '${_stats['total'] ?? 0} palabras',
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
                        _StatRow(
                          icon: Icons.sd_storage,
                          label: 'Tamaño en disco',
                          value: '${_dbSize.toStringAsFixed(2)} MB',
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Acciones
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Acciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Botón importar
                        ListTile(
                          leading: const Icon(Icons.file_upload, color: Colors.blue),
                          title: const Text('Importar diccionario'),
                          subtitle: const Text('Formato JSON monolingüe (palabra y definición en el mismo idioma)'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _importDictionary,
                        ),
                        
                        const Divider(),
                        
                        // Botón limpiar
                        ListTile(
                          leading: const Icon(Icons.delete_sweep, color: Colors.red),
                          title: const Text('Limpiar diccionario'),
                          subtitle: Text('Eliminar ${_stats['total'] ?? 0} palabras'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: _clearDictionary,
                          enabled: (_stats['total'] ?? 0) > 0,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Instrucciones para crear diccionario
                Card(
                  color: Colors.grey.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.help_outline, color: Colors.grey.shade700),
                            const SizedBox(width: 12),
                            const Text(
                              'Formato de diccionario',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D2D2D),
                            border: Border.all(color: Colors.grey.shade600),
                            borderRadius: BorderRadius.circular(8),
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
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Formatos soportados:\n'
                          '📖 SpanishBFF: {"id", "lemma", "definition"}\n'
                          '📖 Estándar: {"word", "definition", "examples"}\n'
                          '📖 Alternativo: {"term", "meaning"}\n\n'
                          'Nota: Diccionarios monolingües solamente\n'
                          '(palabra y definición en el mismo idioma)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
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
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}
