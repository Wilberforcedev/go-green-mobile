part of 'main.dart';

String _friendlyAppError(Object error) {
  if (error is AuthException) {
    final message = error.message.toLowerCase();
    if (message.contains('invalid login credentials')) {
      return 'The email or password is incorrect. Please try again.';
    }
    if (message.contains('email not confirmed')) {
      return 'Please confirm your email address before signing in.';
    }
    if (message.contains('already registered')) {
      return 'An account already exists for this email. Try signing in.';
    }
    return error.message;
  }
  if (error is PostgrestException) return error.message;
  return 'Something went wrong. Check your connection and try again.';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
    children: [
      const _BrandHeader(),
      const SizedBox(height: 24),
      ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Container(
          constraints: const BoxConstraints(minHeight: 390),
          padding: const EdgeInsets.all(25),
          decoration: const BoxDecoration(color: _darkGreen),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  'https://images.pexels.com/photos/356036/pexels-photo-356036.jpeg?auto=compress&cs=tinysrgb&w=1200',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const ColoredBox(color: _darkGreen),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        _darkGreen.withOpacity(.42),
                        _darkGreen.withOpacity(.96),
                      ],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.16),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: const Text(
                      'ENGAGE  ·  EMPOWER  ·  EARN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Small actions.\nA greener future.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.04,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.8,
                    ),
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Join people making everyday environmental action count in their communities.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => _openHub(context),
                      icon: const Icon(Icons.eco_outlined),
                      label: const Text('Explore the Impact Hub'),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFBFE77B),
                        foregroundColor: _darkGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 30),
      const _SectionTitle(
        'Make your actions count',
        'Choose practical ways to care for the environment and connect with your community.',
      ),
      const SizedBox(height: 16),
      const _HomePillar(
        icon: Icons.park_outlined,
        title: 'Grow greener spaces',
        text: 'Take part in tree planting and learn how to care for the trees we grow.',
      ),
      const _HomePillar(
        icon: Icons.recycling_outlined,
        title: 'Keep communities clean',
        text: 'Support clean-ups, better waste practices and recycling in your neighbourhood.',
      ),
      const _HomePillar(
        icon: Icons.school_outlined,
        title: 'Learn and inspire',
        text: 'Discover simple climate actions and share what you learn with others.',
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1E9),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.stars_rounded, color: _green, size: 27),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your impact, recognised',
                    style: TextStyle(
                      color: _darkGreen,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Sign up for activities and earn Green Points when an organizer verifies your participation.',
                    style: TextStyle(
                      color: Colors.black54,
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      const _SectionTitle(
        'How Go Green Mates works',
        'A simple path from taking action to seeing your contribution.',
      ),
      const SizedBox(height: 16),
      const _HomeStep(
        number: '01',
        title: 'Discover',
        text: 'Find an activity or environmental challenge that interests you.',
      ),
      const _HomeStep(
        number: '02',
        title: 'Participate',
        text: 'Join in, contribute and connect with other community members.',
      ),
      const _HomeStep(
        number: '03',
        title: 'Get recognised',
        text:
            'Have your participation verified and see your Green Points grow.',
      ),
      const SizedBox(height: 20),
      OutlinedButton.icon(
        onPressed: () => _openHub(context),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Get started in the Impact Hub'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _green,
          side: const BorderSide(color: _green),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ],
  );
}

class _HomePillar extends StatelessWidget {
  const _HomePillar({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _green.withOpacity(.09),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: _green, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _darkGreen,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _HomeStep extends StatelessWidget {
  const _HomeStep({
    required this.number,
    required this.title,
    required this.text,
  });

  final String number;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          number,
          style: const TextStyle(
            color: _green,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _darkGreen,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                text,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

void _openHub(BuildContext context) {
  final shell = context.findAncestorStateOfType<_MainShellState>();
  shell?.setState(() => shell._tab = 2);
}

class CampaignsPage extends StatelessWidget {
  const CampaignsPage({super.key});
  static const campaigns = [
    (
      'One Million Trees',
      'A community reforestation campaign supporting tree planting and care. Ask the team for current scope, locations and a dated progress update.',
      Icons.park_outlined,
    ),
    (
      'Clean Streets, Green Future',
      'Community waste collection and recycling activities that support cleaner neighbourhoods.',
      Icons.recycling_outlined,
    ),
    (
      'Plastic-Free Homes',
      'Workshops that help families reduce single-use plastics and choose sustainable alternatives.',
      Icons.water_drop_outlined,
    ),
  ];
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _BrandHeader(),
      const SizedBox(height: 28),
      const _SectionTitle(
        'Campaigns & partnerships',
        'Explore community priorities. Progress figures will be shown when organizers publish dated, sourced updates.',
      ),
      const SizedBox(height: 16),
      for (final campaign in campaigns)
        _InfoCard(icon: campaign.$3, title: campaign.$1, text: campaign.$2),
    ],
  );
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      _BrandHeader(),
      SizedBox(height: 28),
      _SectionTitle(
        'About Go Green Mates',
        'A community initiative focused on practical environmental action.',
      ),
      SizedBox(height: 16),
      _InfoCard(
        icon: Icons.lightbulb_outline,
        title: 'Our approach',
        text: 'Engage communities through activities, empower local action and recognize participation.',
      ),
      _InfoCard(
        icon: Icons.public,
        title: 'Where we work',
        text: 'The website describes work in Uganda, Kenya and South Sudan. Contact the team for current programme details.',
      ),
      _InfoCard(
        icon: Icons.handshake_outlined,
        title: 'Partnerships',
        text: 'Partner names and logo use should be confirmed by the organization before public promotion.',
      ),
      SizedBox(height: 20),
      Text(
        'For enquiries: googreenmates@gmail.com',
        style: TextStyle(fontWeight: FontWeight.w700, color: _darkGreen),
      ),
    ],
  );
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
  final _search = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _authFormKey = GlobalKey<FormState>();
  bool _creatingAccount = false;
  bool _obscurePassword = true;
  int _refreshRequestId = 0;

  @override
  void initState() {
    super.initState();
    if (_configured) {
      _user = _db!.auth.currentUser;
      _authSub = _db!.auth.onAuthStateChange.listen((event) {
        if (!mounted) return;
        final nextUser = event.session?.user;
        final identityChanged = _user?.id != nextUser?.id;
        setState(() {
          _user = nextUser;
          if (identityChanged) {
            _activities = [];
            _signups = [];
            _points = 0;
            _role = 'participant';
            _error = null;
            _notice = null;
          }
        });
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
    _search.dispose();
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  Future<void> refresh() async {
    final requestId = ++_refreshRequestId;
    final userId = _user?.id;
    if (!_configured || userId == null) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _activities = [];
        _signups = [];
        _points = 0;
        _role = 'participant';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _db!.from('activity_listing').select().order('starts_at'),
        _db!
            .from('activity_signups')
            .select(
              'id,activity_id,participant_id,status,created_at,activity:activities(title,starts_at,place,points),participant:profiles(display_name)',
            )
            .order('created_at', ascending: false),
        _db!.from('point_ledger').select('points').eq('participant_id', userId),
        _db!.from('profiles').select('role').eq('id', userId).maybeSingle(),
      ]);
      if (!mounted || requestId != _refreshRequestId || _user?.id != userId) {
        return;
      }
      setState(() {
        _activities = List<Map<String, dynamic>>.from(results[0] as List);
        _signups = List<Map<String, dynamic>>.from(results[1] as List);
        _points = (results[2] as List).fold<int>(
          0,
          (sum, row) => sum + ((row['points'] as num?)?.toInt() ?? 0),
        );
        _role =
            ((results[3] as Map<String, dynamic>?)?['role'] as String?) ??
            'participant';
        _loading = false;
      });
    } catch (e) {
      if (mounted && requestId == _refreshRequestId && _user?.id == userId) {
        setState(() {
          _error = _friendly(e);
          _loading = false;
        });
      }
    }
  }

  String _friendly(Object error) => _friendlyAppError(error);

  Future<void> _authenticate() async {
    if (!_authFormKey.currentState!.validate()) return;
    setState(() {
      _working = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_creatingAccount) {
        final response = await _db!.auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          data: {'display_name': _name.text.trim()},
        );
        if (response.session == null) {
          _notice = 'Check your email to confirm your account, then sign in.';
        }
      } else {
        await _db!.auth.signInWithPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } catch (e) {
      _error = _friendly(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _requestPasswordReset() async {
    final email = _email.text.trim();
    final validEmail = RegExp(r'^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$').hasMatch(email);
    if (!validEmail) {
      setState(() {
        _error = 'Enter a valid email address to reset your password.';
        _notice = null;
      });
      return;
    }

    setState(() {
      _working = true;
      _error = null;
      _notice = null;
    });
    try {
      await _db!.auth.resetPasswordForEmail(email);
      _notice =
          'If an account exists for this email, a password reset link has been sent.';
    } catch (e) {
      _error = _friendly(e);
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }
  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You can sign back in to view your activities and points.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _working = true);
    try {
      await _db!.auth.signOut();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _join(String activityId) async {
    await _run(() async {
      await _db!.rpc('join_activity', params: {'activity_uuid': activityId});
      _notice = 'You are registered. An organizer can confirm attendance after the activity.';
    });
  }

  Future<void> _verify(String signupId) async {
    await _run(() async {
      final points = await _db!.rpc(
        'verify_attendance',
        params: {'signup_uuid': signupId},
      );
      _notice = 'Attendance verified. $points Green Points recorded.';
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _error = null;
      _notice = null;
    });
    try {
      await action();
      await refresh();
    } catch (e) {
      if (mounted) setState(() => _error = _friendly(e));
    }
    if (mounted) setState(() => _working = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_configured) return _setupNotice();
    if (_user == null) return _authPanel();
    final visible = _activities.where((a) {
      final text =
          '${a['title']} ${a['description']} ${a['place']} ${a['category']}'
              .toLowerCase();
      return text.contains(_query.toLowerCase()) &&
          (_category == 'All activities' || a['category'] == _category);
    }).toList();
    final mine = _signups
        .where((s) => s['participant_id'] == _user!.id)
        .toList();
    final managed = _signups
        .where(
          (s) =>
              _role == 'admin' ||
              _activities.any(
                (a) =>
                    a['id'] == s['activity_id'] &&
                    a['organizer_id'] == _user!.id,
              ),
        )
        .toList();
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 30),
        children: [
          _BrandHeader(),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _darkGreen,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your impact',
                        style: TextStyle(color: Colors.white70),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Green Points',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '$_points',
                  style: const TextStyle(
                    color: Color(0xFFBFE77B),
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                IconButton(
                  onPressed: _working ? null : _confirmSignOut,
                  tooltip: 'Sign out',
                  color: Colors.white,
                  icon: const Icon(Icons.logout),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _GamificationDashboard(
            points: _points,
            verifiedActions: mine
                .where((s) => s['status'] == 'attended')
                .length,
            registeredActions: mine
                .where((s) => s['status'] != 'cancelled')
                .length,
          ),
          if (_notice != null) _Message(text: _notice!, good: true),
          if (_error != null) ...[
            _Message(text: _error!),
            if (!_loading)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: refresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ),
          ],
          const SizedBox(height: 20),
          if (_role == 'organizer' || _role == 'admin')
            _OrganizerTools(onPublished: refresh, userId: _user!.id),
          const _SectionTitle(
            'Community activities',
            'Published by organizers. Points are added after attendance is verified.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search activities',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(labelText: 'Category'),
            items: const [
              'All activities',
              'Tree planting',
              'Clean-ups',
              'Learning',
              'Clean energy',
            ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() => _category = v ?? 'All activities'),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (!_loading && _error == null && visible.isEmpty)
            _InfoCard(
              icon: Icons.event_busy,
              title: _activities.isEmpty
                  ? 'No activities yet'
                  : 'No matching activities',
              text: _activities.isEmpty
                  ? 'Check back when an organizer publishes an activity.'
                  : 'Try a different search or category filter.',
            ),
          if (!_loading && _activities.isNotEmpty && visible.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() {
                  _search.clear();
                  _query = '';
                  _category = 'All activities';
                }),
                icon: const Icon(Icons.filter_alt_off),
                label: const Text('Clear search and filters'),
              ),
            ),
          for (final activity in visible)
            _ActivityCard(
              activity: activity,
              signedUp: mine.any(
                (s) =>
                    s['activity_id'] == activity['id'] &&
                    s['status'] != 'cancelled',
              ),
              role: _role,
              busy: _working,
              onJoin: () => _join(activity['id'] as String),
            ),
          const SizedBox(height: 14),
          const _SectionTitle(
            'My activity',
            'Your sign-ups and verified participation.',
          ),
          for (final signup in mine) _SignupCard(signup: signup),
          if (mine.isEmpty)
            const _InfoCard(
              icon: Icons.event_available,
              title: 'No sign-ups yet',
              text: 'Join a community activity to get started.',
            ),
          if (_role == 'organizer' || _role == 'admin') ...[
            const SizedBox(height: 14),
            const _SectionTitle(
              'Organizer check-in',
              'Attendance verification records points on the server.',
            ),
            for (final signup in managed)
              _CheckinCard(
                signup: signup,
                busy: _working,
                onVerify: () => _verify(signup['id'] as String),
              ),
          ],
          const SizedBox(height: 12),
          const Text(
            'Green Points record verified participation and have no cash value.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _setupNotice() => ListView(
    padding: const EdgeInsets.all(20),
    children: const [
      _BrandHeader(),
      SizedBox(height: 28),
      _SectionTitle(
        'Impact Hub setup needed',
        'Connect the app to the shared Go Green Mates Supabase project.',
      ),
      SizedBox(height: 12),
      _InfoCard(
        icon: Icons.settings_outlined,
        title: 'Add Supabase configuration',
        text: 'See README.md for SUPABASE_URL and SUPABASE_ANON_KEY setup. Use only the public anon key in the app.',
      ),
    ],
  );

  Widget _authPanel() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const _BrandHeader(),
      const SizedBox(height: 28),
      _SectionTitle(
        _creatingAccount ? 'Create your account' : 'Sign in to Impact Hub',
        'Your activities and points follow your account across devices.',
      ),
      const SizedBox(height: 16),
      Form(
        key: _authFormKey,
        child: AutofillGroup(
          child: Column(
            children: [
              if (_creatingAccount) ...[
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Your name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name.'
                      : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) {
                  final email = value?.trim() ?? '';
                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                      ? null
                      : 'Enter a valid email address.';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _password,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: [
                  _creatingAccount
                      ? AutofillHints.newPassword
                      : AutofillHints.password,
                ],
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: _creatingAccount ? 'At least 8 characters' : null,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (value) {
                  final password = value ?? '';
                  if (password.isEmpty) return 'Enter your password.';
                  if (_creatingAccount && password.length < 8) {
                    return 'Use at least 8 characters.';
                  }
                  return null;
                },
                onFieldSubmitted: (_) {
                  if (!_working) _authenticate();
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _working ? null : _authenticate,
                  child: Text(
                    _working
                        ? 'Please wait…'
                        : _creatingAccount
                        ? 'Create account'
                        : 'Sign in',
                  ),
                ),
              ),
              if (!_creatingAccount)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _working ? null : _requestPasswordReset,
                    child: const Text('Forgot password?'),
                  ),
                ),
              TextButton(
                onPressed: _working
                    ? null
                    : () => setState(() {
                        _creatingAccount = !_creatingAccount;
                        _error = null;
                        _notice = null;
                        _authFormKey.currentState?.reset();
                      }),
                child: Text(
                  _creatingAccount
                      ? 'Already have an account? Sign in'
                      : 'New here? Create an account',
                ),
              ),
              if (_notice != null) _Message(text: _notice!, good: true),
              if (_error != null) _Message(text: _error!),
            ],
          ),
        ),
      ),
    ],
  );
}
