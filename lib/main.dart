import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'screens.dart';
part 'widgets.dart';

const _green = Color(0xFF17633E);
const _darkGreen = Color(0xFF123C2C);
const _cream = Color(0xFFF6F8F4);
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _supabaseConfigured = _supabaseUrl != '' && _supabaseAnonKey != '';
const _passwordRecoveryRedirect = 'io.supabase.flutter://reset-callback/';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (_supabaseConfigured) {
    await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  }
  runApp(const GoGreenApp());
}

class GoGreenApp extends StatelessWidget {
  const GoGreenApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Go Green Mates',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _green),
      scaffoldBackgroundColor: _cream,
      appBarTheme: const AppBarTheme(
        backgroundColor: _cream,
        foregroundColor: _darkGreen,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFE4EAE5)),
        ),
      ),
    ),
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _tab = 0;
  final _hubKey = GlobalKey<ImpactHubPageState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const CampaignsPage(),
      ImpactHubPage(key: _hubKey),
      const AboutPage(),
    ];
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _tab, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
          if (index == 2) _hubKey.currentState?.refresh();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.campaign_outlined),
            selectedIcon: Icon(Icons.campaign),
            label: 'Campaigns',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_outlined),
            selectedIcon: Icon(Icons.eco),
            label: 'Impact Hub',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline),
            selectedIcon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }
}
