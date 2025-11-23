import 'package:flutter/material.dart';
import 'package:my_ebook_reader_anki_app/l10n/app_localizations.dart';
import 'biblioteca_screen.dart';
import 'vocabulario_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    BibliotecaScreen(),
    VocabularioScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: colorScheme.surface,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.2),
        indicatorColor: colorScheme.primaryContainer,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.library_books_outlined),
            selectedIcon: const Icon(Icons.library_books_rounded),
            label: l10n.libraryTitle,
          ),
          NavigationDestination(
            icon: const Icon(Icons.style_outlined),
            selectedIcon: const Icon(Icons.style_rounded),
            label: l10n.myVocabulary,
          ),
        ],
      ),
    );
  }
}
