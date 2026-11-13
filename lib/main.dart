import 'package:flutter/material.dart';

import 'account_page.dart';
import 'auth_screens.dart';
import 'register_page.dart';
import 'search_page.dart';
import 'store.dart';

final AppStore store = AppStore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await store.load();
  runApp(const DepanneurApp());
}

class DepanneurApp extends StatelessWidget {
  const DepanneurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Le Dépanneur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE8590C),
      ),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.configured) return const ConfigMissingScreen();
          if (!store.signedIn) return SignUpScreen(store: store);
          if (!store.hasAccess) return PaywallScreen(store: store);
          return const HomeShell();
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          SearchPage(store: store),
          RegisterPage(store: store, onDone: () => setState(() => _index = 2)),
          AccountPage(store: store),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.search), label: 'Rechercher'),
          NavigationDestination(
              icon: Icon(Icons.handyman_outlined), label: 'Je suis pro'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Mon compte'),
        ],
      ),
    );
  }
}

class ConfigMissingScreen extends StatelessWidget {
  const ConfigMissingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Serveur non configuré : renseignez l’URL et la clé Supabase '
            'dans lib/config.dart, puis recompilez.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
