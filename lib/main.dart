import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _green = Color(0xFF17633E);
const _darkGreen = Color(0xFF123C2C);
const _cream = Color(0xFFF6F8F4);
const _supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const _supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
const _supabaseConfigured = _supabaseUrl != '' && _supabaseAnonKey != '';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
        home: const _StartupGate(),
      );
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _ready = false;
  bool _starting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() { _starting = true; _error = null; });
    try {
      if (_supabaseConfigured) {
        await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
      }
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (mounted) setState(() { _ready = true; _starting = false; });
    } catch (error) {
      if (mounted) setState(() { _error = error.toString(); _starting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const MainShell();
    return _SplashScreen(
      loading: _starting,
      error: _error,
      onRetry: _start,
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen({required this.loading, required this.error, required this.onRetry});

  final bool loading;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _cream,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: _green,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(color: Color(0x22123C2C), blurRadius: 22, offset: Offset(0, 10)),
                      ],
                    ),
                    child: const Icon(Icons.eco_rounded, color: Color(0xFFBFE77B), size: 54),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'GO GREEN MATES',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: _darkGreen, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1.8),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Small actions. Visible impact.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 30),
                  if (loading)
                    const SizedBox(width: 140, child: LinearProgressIndicator(color: _green, backgroundColor: Color(0xFFDDE8DE)))
                  else if (error != null) ...[
                    Text(error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),
                    FilledButton(onPressed: onRetry, child: const Text('Retry')),
                  ],
                ],
              ),
            ),
          ),
        ),
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
  final _walletKey = GlobalKey<WalletPageState>();

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const CampaignsPage(),
      ImpactHubPage(key: _hubKey),
      const EventsPage(),
      WalletPage(key: _walletKey),
    ];
    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _tab, children: pages)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) {
          setState(() => _tab = index);
          if (index == 2) _hubKey.currentState?.refresh();
          if (index == 4) _walletKey.currentState?.refresh();
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.miscellaneous_services_outlined), selectedIcon: Icon(Icons.miscellaneous_services), label: 'Services'),
          NavigationDestination(icon: Icon(Icons.eco_outlined), selectedIcon: Icon(Icons.eco), label: 'Go Green'),
          NavigationDestination(icon: Icon(Icons.event_outlined), selectedIcon: Icon(Icons.event), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Wallet'),
        ],
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 18),
          Container(
            height: 390,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              color: _darkGreen,
              image: const DecorationImage(
                image: NetworkImage('https://images.pexels.com/photos/356036/pexels-photo-356036.jpeg?auto=compress&cs=tinysrgb&w=1200'),
                fit: BoxFit.cover,
                opacity: .34,
              ),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.end, children: [
              const Text('Together for a greener tomorrow', style: TextStyle(color: Colors.white, fontSize: 36, height: 1.08, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              const Text('Engage · Empower · Earn', style: TextStyle(color: Colors.white70, fontSize: 17)),
              const SizedBox(height: 24),
              FilledButton.icon(onPressed: () => _openHub(context), icon: const Icon(Icons.eco), label: const Text('Explore the Impact Hub')),
            ]),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Make a difference together', 'Take part in community action and follow verified activities.'),
          const SizedBox(height: 14),
          const _InfoCard(icon: Icons.park_outlined, title: 'Care for nature', text: 'Join tree planting and environmental learning activities shared by organizers.'),
          const _InfoCard(icon: Icons.groups_outlined, title: 'Build community', text: 'Meet people taking practical steps toward cleaner, greener neighbourhoods.'),
          const _InfoCard(icon: Icons.verified_outlined, title: 'Track participation', text: 'Sign in to register. Organizers confirm attendance and the system records points.'),
        ],
      );
}

void _openHub(BuildContext context) {
  final shell = context.findAncestorStateOfType<_MainShellState>();
  shell?.setState(() => shell._tab = 2);
}

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});
  static const campaigns = [
    ('One Million Trees', 'A community reforestation campaign supporting tree planting and care. Ask the team for current scope, locations and a dated progress update.', Icons.park_outlined),
    ('Clean Streets, Green Future', 'Community waste collection and recycling activities that support cleaner neighbourhoods.', Icons.recycling_outlined),
    ('Plastic-Free Homes', 'Workshops that help families reduce single-use plastics and choose sustainable alternatives.', Icons.water_drop_outlined),
  ];
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const _BrandHeader(),
        const SizedBox(height: 28),
        const _SectionTitle('Services & campaigns', 'Find practical ways to take part in environmental action and community programmes.'),
        const SizedBox(height: 16),
        for (final campaign in campaigns)
          _InfoCard(icon: campaign.$3, title: campaign.$1, text: campaign.$2),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const AboutPage())),
          icon: const Icon(Icons.info_outline),
          label: const Text('About Go Green Mates'),
        ),
      ]);
}


class EventsPage extends StatefulWidget {
  const EventsPage({super.key});
  @override
  EventsPageState createState() => EventsPageState();
}

class EventsPageState extends State<EventsPage> {
  int _tab = 0;
  final List<_GreenTicket> _tickets = [];
  final List<_GreenEvent> _events = [
    _GreenEvent(
      id: 'summit-2026',
      title: 'Global Climate Summit 2026',
      startsAt: DateTime(2026, 11, 15, 9),
      place: 'Nairobi, Kenya',
      available: 150,
      price: 15,
      points: 150,
      description: 'Join community leaders, environmental experts and local organizers for a day of practical climate action, learning and collaboration.',
    ),
    _GreenEvent(
      id: 'workshop-2026',
      title: 'Sustainability Workshop',
      startsAt: DateTime(2026, 10, 30, 14),
      place: 'Online Event',
      available: 80,
      price: 0,
      points: 50,
      description: 'Learn simple, practical ways to make homes and communities more sustainable.',
    ),
    _GreenEvent(
      id: 'tree-marathon-2026',
      title: 'Tree Planting Marathon',
      startsAt: DateTime(2026, 11, 28, 7),
      place: 'Kampala, Uganda',
      available: 120,
      price: 5,
      points: 100,
      description: 'Take part in a community tree planting day and help care for young trees in the local area.',
    ),
  ];

  void _showDetails(_GreenEvent event) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .88),
          decoration: const BoxDecoration(
            color: _cream,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(child: Container(width: 42, height: 4, decoration: BoxDecoration(color: const Color(0xFFCAD3CC), borderRadius: BorderRadius.circular(8)))),
              const SizedBox(height: 22),
              Text(event.title, style: const TextStyle(fontSize: 24, height: 1.12, color: _darkGreen, fontWeight: FontWeight.w900)),
              const SizedBox(height: 14),
              _MetaLine(icon: Icons.access_time, text: '${MaterialLocalizations.of(context).formatMediumDate(event.startsAt)} · ${TimeOfDay.fromDateTime(event.startsAt).format(context)}'),
              _MetaLine(icon: Icons.location_on_outlined, text: event.place),
              _MetaLine(icon: Icons.confirmation_number_outlined, text: '${event.available} tickets available'),
              const SizedBox(height: 22),
              const Text('About this event', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: _darkGreen)),
              const SizedBox(height: 8),
              Text(event.description, style: const TextStyle(color: Colors.black54, height: 1.5)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Ticket price', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text(event.price == 0 ? 'Free' : '${event.price.toStringAsFixed(2)} cUSD', style: const TextStyle(color: _green, fontWeight: FontWeight.w900, fontSize: 20)),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    const Text('Eco Points', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    const SizedBox(height: 4),
                    Text('+ ${event.points}', style: const TextStyle(color: _green, fontWeight: FontWeight.w900, fontSize: 18)),
                  ]),
                ]),
              ),
              const SizedBox(height: 10),
              const Text('Ticket checkout is a screen preview; payment processing is not connected.', style: TextStyle(color: Colors.black54, fontSize: 11)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    _reservePreviewTicket(event);
                  },
                  child: const Text('Purchase Ticket'),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _reservePreviewTicket(_GreenEvent event) {
    if (_tickets.any((ticket) => ticket.event.id == event.id)) {
      setState(() => _tab = 1);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This event is already in My Tickets.')));
      return;
    }
    final reference = 'TICKET-2026-${(_tickets.length + 1).toString().padLeft(3, '0')}';
    setState(() {
      _tickets.insert(0, _GreenTicket(event: event, reference: reference));
      _tab = 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preview ticket saved on this device. No payment was taken.')));
  }

  void _showTicket(_GreenTicket ticket) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(color: _cream, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ticket.event.title, style: const TextStyle(fontSize: 23, height: 1.12, color: _darkGreen, fontWeight: FontWeight.w900)),
            const SizedBox(height: 18),
            Center(child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                CustomPaint(size: const Size.square(180), painter: _QrPreviewPainter(ticket.reference)),
                const SizedBox(height: 14),
                Text(ticket.reference, style: const TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w800)),
                const SizedBox(height: 12),
                _MetaLine(icon: Icons.calendar_month_outlined, text: MaterialLocalizations.of(context).formatMediumDate(ticket.event.startsAt)),
                _MetaLine(icon: Icons.location_on_outlined, text: ticket.event.place),
              ]),
            )),
            const SizedBox(height: 14),
            const Text('Preview ticket only. A verified ticket QR will require a ticketing service.', style: TextStyle(color: Colors.black54, fontSize: 11)),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.of(sheetContext).pop(), child: const Text('Close'))),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleEvents = _events.where((event) => event.startsAt.isAfter(DateTime.now())).toList();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
        child: Row(children: [
          const Expanded(child: Text('Events & Tickets', style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900, color: _darkGreen))),
          IconButton(onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('You are all caught up.'))), tooltip: 'Notifications', icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () => _openHub(context), tooltip: 'Account', icon: const Icon(Icons.person_outline)),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Upcoming')),
            ButtonSegment(value: 1, label: Text('My Tickets')),
          ],
          selected: {_tab},
          onSelectionChanged: (selection) => setState(() => _tab = selection.first),
          showSelectedIcon: false,
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: _tab == 0
            ? ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                children: [
                  for (final event in visibleEvents) _EventListCard(event: event, onTap: () => _showDetails(event)),
                  if (visibleEvents.isEmpty) const _InfoCard(icon: Icons.event_busy, title: 'No upcoming events', text: 'Check back when new community events are announced.'),
                  const SizedBox(height: 8),
                  const Text('Sample event listings for the screen preview.', style: TextStyle(color: Colors.black45, fontSize: 11)),
                ],
              )
            : _tickets.isEmpty
                ? ListView(padding: const EdgeInsets.fromLTRB(18, 24, 18, 24), children: const [
                    _InfoCard(icon: Icons.confirmation_number_outlined, title: 'No tickets yet', text: 'Tickets you reserve will appear here.'),
                  ])
                : ListView(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
                    children: [
                      for (final ticket in _tickets) _TicketListCard(ticket: ticket, onTap: () => _showTicket(ticket)),
                    ],
                  ),
      ),
    ]);
  }
}

class _GreenEvent {
  const _GreenEvent({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.place,
    required this.available,
    required this.price,
    required this.points,
    required this.description,
  });
  final String id;
  final String title;
  final DateTime startsAt;
  final String place;
  final int available;
  final double price;
  final int points;
  final String description;
}

class _GreenTicket {
  const _GreenTicket({required this.event, required this.reference});
  final _GreenEvent event;
  final String reference;
}

class _EventListCard extends StatelessWidget {
  const _EventListCard({required this.event, required this.onTap});
  final _GreenEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(event.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFE7F4E9), borderRadius: BorderRadius.circular(20)),
                child: const Text('Upcoming', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
              ),
            ]),
            const SizedBox(height: 8),
            _MetaLine(icon: Icons.access_time, text: '${MaterialLocalizations.of(context).formatMediumDate(event.startsAt)} · ${TimeOfDay.fromDateTime(event.startsAt).format(context)}'),
            _MetaLine(icon: Icons.location_on_outlined, text: event.place),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.confirmation_number_outlined, size: 15, color: _green),
              const SizedBox(width: 6),
              Expanded(child: Text(event.price == 0 ? 'Free entry' : '${event.price.toStringAsFixed(2)} cUSD', style: const TextStyle(fontSize: 12, color: Colors.black54))),
              Text('${event.available} available', style: const TextStyle(fontSize: 11, color: _green, fontWeight: FontWeight.w700)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _TicketListCard extends StatelessWidget {
  const _TicketListCard({required this.ticket, required this.onTap});
  final _GreenTicket ticket;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(children: [
            Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFE7F4E9), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.qr_code_2, color: _green)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(ticket.event.title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 5),
              Text('${MaterialLocalizations.of(context).formatMediumDate(ticket.event.startsAt)} · ${ticket.event.place}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 5),
              Text(ticket.reference, style: const TextStyle(fontSize: 11, letterSpacing: 1.1, color: _green, fontWeight: FontWeight.w700)),
            ])),
            const SizedBox(width: 8),
            const Text('Active', style: TextStyle(color: _green, fontSize: 11, fontWeight: FontWeight.w700)),
          ]),
        ),
      ),
    );
  }
}

class _QrPreviewPainter extends CustomPainter {
  _QrPreviewPainter(this.value);
  final String value;

  @override
  void paint(Canvas canvas, Size size) {
    const cells = 25;
    final cell = size.width / cells;
    final paint = Paint()..color = const Color(0xFF202124);
    final seed = value.codeUnits.fold<int>(0, (sum, unit) => sum * 31 + unit);
    bool finder(int x, int y, int originX, int originY) {
      final dx = x - originX;
      final dy = y - originY;
      if (dx < 0 || dx > 6 || dy < 0 || dy > 6) return false;
      return dx == 0 || dx == 6 || dy == 0 || dy == 6 || (dx >= 2 && dx <= 4 && dy >= 2 && dy <= 4);
    }

    for (var y = 0; y < cells; y++) {
      for (var x = 0; x < cells; x++) {
        final inFinderArea = (x < 7 && y < 7) || (x >= cells - 7 && y < 7) || (x < 7 && y >= cells - 7);
        final isFinder = finder(x, y, 0, 0) || finder(x, y, cells - 7, 0) || finder(x, y, 0, cells - 7);
        final bit = ((x * 17 + y * 29 + seed + x * y * 3) % 7) < 3;
        if (isFinder || (!inFinderArea && bit)) {
          canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, cell * .86, cell * .86), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPreviewPainter oldDelegate) => oldDelegate.value != value;
}

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});
  @override
  WalletPageState createState() => WalletPageState();
}

class WalletPageState extends State<WalletPage> {
  bool _loading = true;
  int _points = 0;
  String? _error;

  Future<void> refresh() async {
    if (!_supabaseConfigured) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() { _loading = false; _points = 0; });
      return;
    }
    if (mounted) setState(() { _loading = true; _error = null; });
    try {
      final rows = await Supabase.instance.client
          .from('point_ledger')
          .select('points')
          .eq('participant_id', user.id);
      final total = (rows as List).fold<int>(0, (sum, row) => sum + ((row['points'] as num?)?.toInt() ?? 0));
      if (mounted) setState(() { _points = total; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabaseConfigured ? Supabase.instance.client.auth.currentUser : null;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 28), children: [
      const _BrandHeader(),
      const SizedBox(height: 24),
      const _SectionTitle('Green Wallet', 'Your verified participation and community reward points.'),
      const SizedBox(height: 16),
      if (!_supabaseConfigured)
        const _InfoCard(icon: Icons.settings_outlined, title: 'Wallet setup needed', text: 'Connect Supabase to load your account and verified Green Points.')
      else if (user == null)
        _InfoCard(
          icon: Icons.lock_outline,
          title: 'Sign in to view your wallet',
          text: 'Open the Go Green tab to create an account or sign in.',
        )
      else ...[
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('GREEN POINTS BALANCE', style: TextStyle(color: Colors.white70, letterSpacing: 1.1, fontSize: 11, fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            if (_loading) const SizedBox(height: 42, child: Align(alignment: Alignment.centerLeft, child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))))
            else Text('$_points', style: const TextStyle(color: Color(0xFFBFE77B), fontSize: 38, fontWeight: FontWeight.w900)),
            const SizedBox(height: 6),
            const Text('Earn points when an organizer verifies your attendance.', style: TextStyle(color: Colors.white70, height: 1.35)),
          ]),
        ),
        if (_error != null) _Message(text: _error!),
        const SizedBox(height: 12),
        const _InfoCard(icon: Icons.verified_outlined, title: 'Verified activity only', text: 'Points are recorded after an organizer confirms attendance. Green Points have no cash value.'),
        const _InfoCard(icon: Icons.confirmation_number_outlined, title: 'Event tickets', text: 'Ticket reservation is a preview in this build. Payments and ticket validation are not connected.'),
      ],
    ]);
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: const [
        _BrandHeader(),
        SizedBox(height: 28),
        _SectionTitle('About Go Green Mates', 'A community initiative focused on practical environmental action.'),
        SizedBox(height: 16),
        _InfoCard(icon: Icons.lightbulb_outline, title: 'Our approach', text: 'Engage communities through activities, empower local action and recognize participation.'),
        _InfoCard(icon: Icons.public, title: 'Where we work', text: 'The website describes work in Uganda, Kenya and South Sudan. Contact the team for current programme details.'),
        _InfoCard(icon: Icons.handshake_outlined, title: 'Partnerships', text: 'Partner names and logo use should be confirmed by the organization before public promotion.'),
        SizedBox(height: 20),
        Text('For enquiries: googreenmates@gmail.com', style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen)),
      ]);
}

class ImpactHubPage extends StatefulWidget {
  const ImpactHubPage({super.key});
  @override
  State<ImpactHubPage> createState() => ImpactHubPageState();
}

class ImpactHubPageState extends State<ImpactHubPage> {
  SupabaseClient? get _db => Supabase.instance.client;
  bool get _configured => _supabaseConfigured;
  StreamSubscription<AuthState>? _authSub;
  User? _user;
  String _role = 'participant';
  bool _loading = true;
  bool _working = false;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _signups = [];
  int _points = 0;
  String? _error;
  String? _notice;
  String _query = '';
  String _category = 'All activities';
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _creatingAccount = false;

  @override
  void initState() {
    super.initState();
    if (_configured) {
      _user = _db!.auth.currentUser;
      _authSub = _db!.auth.onAuthStateChange.listen((event) {
        setState(() => _user = event.session?.user);
        refresh();
      });
      refresh();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    if (!_configured || _user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final results = await Future.wait([
        _db!.from('activity_listing').select().order('starts_at'),
        _db!.from('activity_signups').select('id,activity_id,participant_id,status,created_at,activity:activities(title,starts_at,place,points),participant:profiles(display_name)').order('created_at', ascending: false),
        _db!.from('point_ledger').select('points').eq('participant_id', _user!.id),
        _db!.from('profiles').select('role').eq('id', _user!.id).maybeSingle(),
      ]);
      if (!mounted) return;
      setState(() {
        _activities = List<Map<String, dynamic>>.from(results[0] as List);
        _signups = List<Map<String, dynamic>>.from(results[1] as List);
        _points = (results[2] as List).fold<int>(0, (sum, row) => sum + ((row['points'] as num?)?.toInt() ?? 0));
        _role = ((results[3] as Map<String, dynamic>?)?['role'] as String?) ?? 'participant';
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _error = _friendly(e); _loading = false; });
    }
  }

  String _friendly(Object error) => error is PostgrestException ? error.message : error.toString();

  Future<void> _authenticate() async {
    setState(() { _working = true; _error = null; _notice = null; });
    try {
      if (_creatingAccount) {
        final response = await _db!.auth.signUp(email: _email.text.trim(), password: _password.text, data: {'display_name': _name.text.trim()});
        if (response.session == null) _notice = 'Check your email to confirm your account, then sign in.';
      } else {
        await _db!.auth.signInWithPassword(email: _email.text.trim(), password: _password.text);
      }
    } catch (e) { _error = _friendly(e); }
    if (mounted) setState(() => _working = false);
  }

  Future<void> _join(String activityId) async {
    await _run(() async {
      await _db!.rpc('join_activity', params: {'activity_uuid': activityId});
      _notice = 'You are registered. An organizer can confirm attendance after the activity.';
    });
  }

  Future<void> _verify(String signupId) async {
    await _run(() async {
      final points = await _db!.rpc('verify_attendance', params: {'signup_uuid': signupId});
      _notice = 'Attendance verified. $points Green Points recorded.';
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() { _working = true; _error = null; _notice = null; });
    try { await action(); await refresh(); }
    catch (e) { if (mounted) setState(() => _error = _friendly(e)); }
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_configured) return _setupNotice();
    if (_user == null) return _authPanel();
    final visible = _activities.where((a) {
      final text = '${a['title']} ${a['description']} ${a['place']} ${a['category']}'.toLowerCase();
      return text.contains(_query.toLowerCase()) && (_category == 'All activities' || a['category'] == _category);
    }).toList();
    final mine = _signups.where((s) => s['participant_id'] == _user!.id).toList();
    final managed = _signups.where((s) => _role == 'admin' || _activities.any((a) => a['id'] == s['activity_id'] && a['organizer_id'] == _user!.id)).toList();
    return RefreshIndicator(onRefresh: refresh, child: ListView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 30), children: [
      _BrandHeader(),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: _darkGreen, borderRadius: BorderRadius.circular(22)), child: Row(children: [
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Your impact', style: TextStyle(color: Colors.white70)), SizedBox(height: 4), Text('Green Points', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))]),),
        Text('$_points', style: const TextStyle(color: Color(0xFFBFE77B), fontSize: 34, fontWeight: FontWeight.w900)),
        IconButton(onPressed: _working ? null : () => _db!.auth.signOut(), tooltip: 'Sign out', color: Colors.white, icon: const Icon(Icons.logout)),
      ])),
      if (_notice != null) _Message(text: _notice!, good: true),
      if (_error != null) _Message(text: _error!),
      const SizedBox(height: 20),
      if (_role == 'organizer' || _role == 'admin') _OrganizerTools(onPublished: refresh, userId: _user!.id),
      const _SectionTitle('Community activities', 'Published by organizers. Points are added after attendance is verified.'),
      const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search activities'), onChanged: (v) => setState(() => _query = v)),
      const SizedBox(height: 10),
      DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Category'), items: const ['All activities', 'Tree planting', 'Clean-ups', 'Learning', 'Clean energy'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => setState(() => _category = v ?? 'All activities')),
      if (_loading) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
      if (!_loading && visible.isEmpty) const _InfoCard(icon: Icons.event_busy, title: 'No activities yet', text: 'Check back when an organizer publishes an activity.'),
      for (final activity in visible) _ActivityCard(activity: activity, signedUp: mine.any((s) => s['activity_id'] == activity['id'] && s['status'] != 'cancelled'), role: _role, busy: _working, onJoin: () => _join(activity['id'] as String)),
      const SizedBox(height: 14),
      const _SectionTitle('My activity', 'Your sign-ups and verified participation.'),
      for (final signup in mine) _SignupCard(signup: signup),
      if (mine.isEmpty) const _InfoCard(icon: Icons.event_available, title: 'No sign-ups yet', text: 'Join a community activity to get started.'),
      if (_role == 'organizer' || _role == 'admin') ...[
        const SizedBox(height: 14),
        const _SectionTitle('Organizer check-in', 'Attendance verification records points on the server.'),
        for (final signup in managed) _CheckinCard(signup: signup, busy: _working, onVerify: () => _verify(signup['id'] as String)),
      ],
      const SizedBox(height: 12),
      const Text('Green Points record verified participation and have no cash value.', style: TextStyle(color: Colors.black54, fontSize: 12)),
    ]));
  }

  Widget _setupNotice() => ListView(padding: const EdgeInsets.all(20), children: const [
        _BrandHeader(), SizedBox(height: 28), _SectionTitle('Impact Hub setup needed', 'Connect the app to the shared Go Green Mates Supabase project.'),
        SizedBox(height: 12), _InfoCard(icon: Icons.settings_outlined, title: 'Add Supabase configuration', text: 'See README.md for SUPABASE_URL and SUPABASE_ANON_KEY setup. Use only the public anon key in the app.'),
      ]);

  Widget _authPanel() => ListView(padding: const EdgeInsets.all(20), children: [
        const _BrandHeader(), const SizedBox(height: 28),
        _SectionTitle(_creatingAccount ? 'Create your account' : 'Sign in to Impact Hub', 'Your activities and points follow your account across devices.'),
        const SizedBox(height: 16),
        if (_creatingAccount) ...[const Text('Your name'), const SizedBox(height: 6), TextField(controller: _name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(hintText: 'Full name')), const SizedBox(height: 12)],
        const Text('Email'), const SizedBox(height: 6), TextField(controller: _email, keyboardType: TextInputType.emailAddress, autofillHints: const [AutofillHints.email], decoration: const InputDecoration(hintText: 'you@example.com')),
        const SizedBox(height: 12), const Text('Password'), const SizedBox(height: 6), TextField(controller: _password, obscureText: true, autofillHints: [_creatingAccount ? AutofillHints.newPassword : AutofillHints.password], decoration: const InputDecoration(hintText: 'At least 8 characters')),
        const SizedBox(height: 16), FilledButton(onPressed: _working ? null : _authenticate, child: Text(_working ? 'Please wait…' : _creatingAccount ? 'Create account' : 'Sign in')),
        TextButton(onPressed: () => setState(() { _creatingAccount = !_creatingAccount; _error = null; _notice = null; }), child: Text(_creatingAccount ? 'Already have an account? Sign in' : 'New here? Create an account')),
        if (_notice != null) _Message(text: _notice!, good: true), if (_error != null) _Message(text: _error!),
      ]);
}

class _OrganizerTools extends StatefulWidget {
  const _OrganizerTools({required this.onPublished, required this.userId});
  final Future<void> Function() onPublished;
  final String userId;
  @override
  State<_OrganizerTools> createState() => _OrganizerToolsState();
}

class _OrganizerToolsState extends State<_OrganizerTools> {
  bool _open = false;
  bool _busy = false;
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _place = TextEditingController();
  final _description = TextEditingController();
  final _impact = TextEditingController();
  final _source = TextEditingController();
  String _category = 'Tree planting';
  DateTime? _starts;
  int _capacity = 20;
  int _points = 50;

  @override
  void dispose() { _title.dispose(); _place.dispose(); _description.dispose(); _impact.dispose(); _source.dispose(); super.dispose(); }

  Future<void> _publish() async {
    if (!_form.currentState!.validate() || _starts == null) return;
    setState(() => _busy = true);
    try {
      await Supabase.instance.client.from('activities').insert({
        'organizer_id': widget.userId, 'title': _title.text.trim(), 'category': _category,
        'place': _place.text.trim(), 'starts_at': _starts!.toUtc().toIso8601String(),
        'capacity': _capacity, 'points': _points, 'description': _description.text.trim(),
        'impact_measure': _impact.text.trim(), 'impact_source_url': _source.text.trim().isEmpty ? null : _source.text.trim(),
        'status': 'published',
      });
      _title.clear(); _place.clear(); _description.clear(); _impact.clear(); _source.clear();
      if (mounted) { setState(() => _open = false); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Activity published'))); }
      await widget.onPublished();
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()))); }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [const Expanded(child: Text('Organizer tools', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18))), TextButton.icon(onPressed: () => setState(() => _open = !_open), icon: Icon(_open ? Icons.close : Icons.add), label: Text(_open ? 'Close' : 'Publish'))]),
        if (_open) Form(key: _form, child: Column(children: [
          TextFormField(controller: _title, decoration: const InputDecoration(labelText: 'Activity title'), validator: (v) => v == null || v.trim().length < 5 ? 'Enter at least 5 characters' : null),
          const SizedBox(height: 10), DropdownButtonFormField<String>(value: _category, decoration: const InputDecoration(labelText: 'Category'), items: const ['Tree planting', 'Clean-ups', 'Learning', 'Clean energy'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(), onChanged: (v) => _category = v ?? _category),
          const SizedBox(height: 10), TextFormField(controller: _place, decoration: const InputDecoration(labelText: 'Place'), validator: (v) => v == null || v.trim().length < 2 ? 'Enter a place' : null),
          const SizedBox(height: 10), TextFormField(controller: _description, minLines: 2, maxLines: 4, decoration: const InputDecoration(labelText: 'Description'), validator: (v) => v == null || v.trim().length < 20 ? 'Add at least 20 characters' : null),
          const SizedBox(height: 10), TextFormField(controller: _impact, decoration: const InputDecoration(labelText: 'Impact measure'), validator: (v) => v == null || v.trim().length < 3 ? 'Describe the measure' : null),
          const SizedBox(height: 10), TextFormField(controller: _source, keyboardType: TextInputType.url, decoration: const InputDecoration(labelText: 'Impact source URL (optional)', hintText: 'https://…'), validator: (v) => v != null && v.isNotEmpty && !v.startsWith('https://') ? 'Use an https URL' : null),
          const SizedBox(height: 8), Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () async { final d = await showDatePicker(context: context, firstDate: DateTime.now().add(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 730)), initialDate: DateTime.now().add(const Duration(days: 7))); if (d == null || !mounted) return; final t = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if (t != null) setState(() => _starts = DateTime(d.year, d.month, d.day, t.hour, t.minute)); }, icon: const Icon(Icons.calendar_month), label: Text(_starts == null ? 'Choose date and time' : _starts!.toLocal().toString().substring(0, 16)))),
          Row(children: [Expanded(child: _StepperField(label: 'Capacity', value: _capacity, min: 1, max: 5000, onChanged: (v) => _capacity = v)), const SizedBox(width: 12), Expanded(child: _StepperField(label: 'Points', value: _points, min: 0, max: 10000, onChanged: (v) => _points = v))]),
          const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: _busy ? null : _publish, child: Text(_busy ? 'Publishing…' : 'Publish activity'))),
        ])),
      ])));
}

class _StepperField extends StatelessWidget {
  const _StepperField({required this.label, required this.value, required this.min, required this.max, required this.onChanged});
  final String label; final int value; final int min; final int max; final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)), Row(children: [IconButton(onPressed: value <= min ? null : () => onChanged(value - 1), icon: const Icon(Icons.remove_circle_outline)), Expanded(child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w800))), IconButton(onPressed: value >= max ? null : () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline))])]);
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity, required this.signedUp, required this.role, required this.busy, required this.onJoin});
  final Map<String, dynamic> activity; final bool signedUp; final String role; final bool busy; final VoidCallback onJoin;
  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${activity['starts_at']}')?.toLocal();
    final canJoin = role == 'participant' && !signedUp && (activity['spots_remaining'] as num? ?? 0) > 0 && date != null && date.isAfter(DateTime.now());
    final image = activity['image_url'] as String?;
    return Card(clipBehavior: Clip.antiAlias, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (image != null && image.startsWith('https://')) Image.network(image, height: 170, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(height: 72, child: Icon(Icons.eco, size: 36, color: _green))),
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${activity['category'] ?? ''}'.toUpperCase(), style: const TextStyle(color: _green, fontSize: 11, letterSpacing: 1.1, fontWeight: FontWeight.w800)),
        const SizedBox(height: 5), Text('${activity['title']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19)),
        const SizedBox(height: 6), Text('${activity['description']}', maxLines: 4, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black54, height: 1.4)),
        const SizedBox(height: 12), _MetaLine(icon: Icons.location_on_outlined, text: '${activity['place']}'),
        _MetaLine(icon: Icons.calendar_month_outlined, text: date == null ? '' : MaterialLocalizations.of(context).formatMediumDate(date)),
        _MetaLine(icon: Icons.people_outline, text: '${activity['spots_remaining'] ?? 0} places remaining'),
        _MetaLine(icon: Icons.stars_outlined, text: '${activity['points']} points after verification'),
        if ('${activity['impact_measure'] ?? ''}'.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10), child: Text('Impact measure: ${activity['impact_measure']}', style: const TextStyle(fontSize: 12, color: Colors.black54))),
        const SizedBox(height: 12), SizedBox(width: double.infinity, child: FilledButton(onPressed: canJoin && !busy ? onJoin : null, child: Text(signedUp ? 'You are registered' : role != 'participant' ? 'Participants can join' : !canJoin ? 'Registration unavailable' : 'Join this activity'))),
      ])),
    ]));
  }
}

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.signup});
  final Map<String, dynamic> signup;
  @override
  Widget build(BuildContext context) {
    final activity = signup['activity'] as Map<String, dynamic>? ?? {};
    final date = DateTime.tryParse('${activity['starts_at'] ?? ''}')?.toLocal();
    final attended = signup['status'] == 'attended';
    return Card(child: ListTile(leading: Icon(attended ? Icons.verified : Icons.event_available, color: _green), title: Text('${activity['title'] ?? 'Activity'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${activity['place'] ?? ''}${date == null ? '' : ' · ${MaterialLocalizations.of(context).formatMediumDate(date)}'}'), trailing: Text(attended ? 'Verified\n+${activity['points'] ?? 0}' : '${signup['status']}', textAlign: TextAlign.end, style: const TextStyle(color: _green, fontWeight: FontWeight.w700))));
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({required this.signup, required this.busy, required this.onVerify});
  final Map<String, dynamic> signup; final bool busy; final VoidCallback onVerify;
  @override
  Widget build(BuildContext context) {
    final activity = signup['activity'] as Map<String, dynamic>? ?? {};
    final person = signup['participant'] as Map<String, dynamic>? ?? {};
    final status = signup['status'];
    return Card(child: ListTile(title: Text('${person['display_name'] ?? 'Participant'}', style: const TextStyle(fontWeight: FontWeight.w700)), subtitle: Text('${activity['title'] ?? 'Activity'} · $status'), trailing: status == 'registered' ? IconButton(onPressed: busy ? null : onVerify, tooltip: 'Confirm attendance', icon: const Icon(Icons.verified_outlined, color: _green)) : const Icon(Icons.check_circle, color: _green)));
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();
  @override
  Widget build(BuildContext context) => Row(children: [Container(width: 42, height: 42, decoration: BoxDecoration(color: _green.withOpacity(.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.eco, color: _green)), const SizedBox(width: 10), const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('GO GREEN MATES', style: TextStyle(color: _green, fontWeight: FontWeight.w900, letterSpacing: 1)), Text('Small actions. Visible impact.', style: TextStyle(fontSize: 12, color: Colors.black54))])]);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);
  final String title; final String subtitle;
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 24, height: 1.1, color: _darkGreen, fontWeight: FontWeight.w900)), const SizedBox(height: 7), Text(subtitle, style: const TextStyle(height: 1.45, color: Colors.black54))]);
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title, required this.text});
  final IconData icon; final String title; final String text;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: _green), const SizedBox(width: 13), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)), const SizedBox(height: 5), Text(text, style: const TextStyle(color: Colors.black54, height: 1.4))]))])));
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});
  final IconData icon; final String text;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 6), child: Row(children: [Icon(icon, size: 16, color: _green), const SizedBox(width: 7), Expanded(child: Text(text, style: const TextStyle(color: Colors.black54, fontSize: 13)))]));
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.good = false});
  final String text; final bool good;
  @override
  Widget build(BuildContext context) => Container(margin: const EdgeInsets.only(top: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: good ? const Color(0xFFE7F4E9) : const Color(0xFFFFEAE7), borderRadius: BorderRadius.circular(12)), child: Text(text, style: TextStyle(color: good ? _darkGreen : Colors.red.shade900)));
}
