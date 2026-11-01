part of 'main.dart';

class _GamificationDashboard extends StatelessWidget {
  const _GamificationDashboard({
    required this.points,
    required this.verifiedActions,
    required this.registeredActions,
  });

  final int points;
  final int verifiedActions;
  final int registeredActions;

  @override
  Widget build(BuildContext context) {
    final nextMilestone = points < 100
        ? 100
        : points < 250
        ? 250
        : points < 500
        ? 500
        : ((points ~/ 500) + 1) * 500;
    final progress = points / nextMilestone;
    final remaining = nextMilestone - points;
    final badges = <({String title, IconData icon, bool earned})>[
      (
        title: 'First step',
        icon: Icons.eco_outlined,
        earned: verifiedActions >= 1,
      ),
      (
        title: 'Green regular',
        icon: Icons.recycling_outlined,
        earned: verifiedActions >= 5,
      ),
      (
        title: 'Impact builder',
        icon: Icons.park_outlined,
        earned: verifiedActions >= 10,
      ),
      (
        title: 'Point collector',
        icon: Icons.stars_outlined,
        earned: points >= 100,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(
              'Your green journey',
              'Track verified participation and unlock milestones as you take action.',
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _JourneyStat(
                    value: '$verifiedActions',
                    label: 'Verified actions',
                    icon: Icons.verified_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _JourneyStat(
                    value: '$registeredActions',
                    label: 'Sign-ups',
                    icon: Icons.event_available_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Next points milestone',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                Text('$points / $nextMilestone'),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.clamp(0.0, 1.0)),
            const SizedBox(height: 6),
            Text(
              '$remaining Green Points to your next milestone',
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final badge in badges)
                  Chip(
                    avatar: Icon(
                      badge.icon,
                      size: 18,
                      color: badge.earned ? _green : Colors.black45,
                    ),
                    label: Text(badge.title),
                    backgroundColor: badge.earned
                        ? const Color(0xFFE7F4E9)
                        : const Color(0xFFF1F2F1),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _JourneyStat extends StatelessWidget {
  const _JourneyStat({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFEAF1E9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: _green),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w900,
                  color: _darkGreen,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    ),
  );
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
  String? _startError;
  int _capacity = 20;
  int _points = 50;

  @override
  void dispose() {
    _title.dispose();
    _place.dispose();
    _description.dispose();
    _impact.dispose();
    _source.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    if (!_form.currentState!.validate()) return;
    if (_starts == null) {
      setState(() => _startError = 'Choose the activity date and start time.');
      return;
    }

    setState(() => _busy = true);
    try {
      await Supabase.instance.client.from('activities').insert({
        'organizer_id': widget.userId,
        'title': _title.text.trim(),
        'category': _category,
        'place': _place.text.trim(),
        'starts_at': _starts!.toUtc().toIso8601String(),
        'capacity': _capacity,
        'points': _points,
        'description': _description.text.trim(),
        'impact_measure': _impact.text.trim(),
        'impact_source_url': _source.text.trim().isEmpty
            ? null
            : _source.text.trim(),
        'status': 'published',
      });
      _title.clear();
      _place.clear();
      _description.clear();
      _impact.clear();
      _source.clear();
      if (mounted) {
        setState(() {
          _open = false;
          _starts = null;
          _startError = null;
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Activity published')));
      }
      await widget.onPublished();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not publish activity: ${_friendlyAppError(e)}',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _chooseStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day + 1),
      lastDate: DateTime(now.year + 2, now.month, now.day),
      initialDate: DateTime(now.year, now.month, now.day + 7),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
    );
    if (time == null || !mounted) return;

    setState(() {
      _starts = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      _startError = null;
    });
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Organizer tools',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _open = !_open),
                icon: Icon(_open ? Icons.close : Icons.add),
                label: Text(_open ? 'Close' : 'Publish'),
              ),
            ],
          ),
          if (_open)
            Form(
              key: _form,
              child: Column(
                children: [
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: 'Activity title',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 5
                        ? 'Enter at least 5 characters'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items:
                        const [
                              'Tree planting',
                              'Clean-ups',
                              'Learning',
                              'Clean energy',
                            ]
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value),
                              ),
                            )
                            .toList(),
                    onChanged: (value) =>
                        setState(() => _category = value ?? _category),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _place,
                    decoration: const InputDecoration(labelText: 'Place'),
                    validator: (value) =>
                        value == null || value.trim().length < 2
                        ? 'Enter a place'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) =>
                        value == null || value.trim().length < 20
                        ? 'Add at least 20 characters'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _impact,
                    decoration: const InputDecoration(
                      labelText: 'Impact measure',
                    ),
                    validator: (value) =>
                        value == null || value.trim().length < 3
                        ? 'Describe the measure'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _source,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Impact source URL (optional)',
                      hintText: 'https://…',
                    ),
                    validator: (value) =>
                        value != null &&
                            value.isNotEmpty &&
                            !value.startsWith('https://')
                        ? 'Use an https URL'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _busy ? null : _chooseStart,
                      icon: const Icon(Icons.calendar_month),
                      label: Text(
                        _starts == null
                            ? 'Choose date and time'
                            : _displayDateTime(context, _starts!),
                      ),
                    ),
                  ),
                  if (_startError != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _startError!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: _StepperField(
                          label: 'Capacity',
                          value: _capacity,
                          min: 1,
                          max: 5000,
                          onChanged: (value) =>
                              setState(() => _capacity = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StepperField(
                          label: 'Points',
                          value: _points,
                          min: 0,
                          max: 10000,
                          onChanged: (value) => setState(() => _points = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _publish,
                      child: Text(_busy ? 'Publishing…' : 'Publish activity'),
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

class _StepperField extends StatelessWidget {
  const _StepperField({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
      Row(
        children: [
          IconButton(
            onPressed: value <= min ? null : () => onChanged(value - 1),
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Expanded(
            child: Text(
              '$value',
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          IconButton(
            onPressed: value >= max ? null : () => onChanged(value + 1),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    ],
  );
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.signedUp,
    required this.role,
    required this.busy,
    required this.onJoin,
  });

  final Map<String, dynamic> activity;
  final bool signedUp;
  final String role;
  final bool busy;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse('${activity['starts_at']}')?.toLocal();
    final spotsRemaining = (activity['spots_remaining'] as num?)?.toInt() ?? 0;
    final hasNotStarted = date != null && date.isAfter(DateTime.now());
    final canJoin =
        role == 'participant' &&
        !signedUp &&
        spotsRemaining > 0 &&
        hasNotStarted;
    final joinLabel = signedUp
        ? 'You are registered'
        : role != 'participant'
        ? 'Participants can join'
        : date == null
        ? 'Date unavailable'
        : !hasNotStarted
        ? 'Activity ended'
        : spotsRemaining == 0
        ? 'Fully booked'
        : 'Join this activity';
    final image = activity['image_url'] as String?;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image != null && image.startsWith('https://'))
            Image.network(
              image,
              height: 170,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const SizedBox(
                height: 72,
                child: Center(child: Icon(Icons.eco, size: 36, color: _green)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity['category'] ?? ''}'.toUpperCase(),
                  style: const TextStyle(
                    color: _green,
                    fontSize: 11,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${activity['title']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${activity['description']}',
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
                const SizedBox(height: 12),
                _MetaLine(
                  icon: Icons.location_on_outlined,
                  text: '${activity['place']}',
                ),
                _MetaLine(
                  icon: Icons.calendar_month_outlined,
                  text: _displayDateTime(context, date),
                ),
                _MetaLine(
                  icon: Icons.people_outline,
                  text: '${activity['spots_remaining'] ?? 0} places remaining',
                ),
                _MetaLine(
                  icon: Icons.stars_outlined,
                  text: '${activity['points']} points after verification',
                ),
                if ('${activity['impact_measure'] ?? ''}'.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      'Impact measure: ${activity['impact_measure']}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canJoin && !busy ? onJoin : null,
                    child: Text(joinLabel),
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

class _SignupCard extends StatelessWidget {
  const _SignupCard({required this.signup});

  final Map<String, dynamic> signup;

  @override
  Widget build(BuildContext context) {
    final activity = signup['activity'] as Map<String, dynamic>? ?? {};
    final date = DateTime.tryParse('${activity['starts_at'] ?? ''}')?.toLocal();
    final attended = signup['status'] == 'attended';
    final dateTime = date == null
        ? ''
        : ' · ${_displayDateTime(context, date)}';

    return Card(
      child: ListTile(
        leading: Icon(
          attended ? Icons.verified : Icons.event_available,
          color: _green,
        ),
        title: Text(
          '${activity['title'] ?? 'Activity'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${activity['place'] ?? ''}$dateTime'),
        trailing: Text(
          attended
              ? 'Verified\n+${activity['points'] ?? 0}'
              : '${signup['status']}',
          textAlign: TextAlign.end,
          style: const TextStyle(color: _green, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _CheckinCard extends StatelessWidget {
  const _CheckinCard({
    required this.signup,
    required this.busy,
    required this.onVerify,
  });

  final Map<String, dynamic> signup;
  final bool busy;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    final activity = signup['activity'] as Map<String, dynamic>? ?? {};
    final person = signup['participant'] as Map<String, dynamic>? ?? {};
    final status = signup['status'];

    return Card(
      child: ListTile(
        title: Text(
          '${person['display_name'] ?? 'Participant'}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${activity['title'] ?? 'Activity'} · $status'),
        trailing: status == 'registered'
            ? IconButton(
                onPressed: busy ? null : onVerify,
                tooltip: 'Confirm attendance',
                icon: const Icon(Icons.verified_outlined, color: _green),
              )
            : const Icon(Icons.check_circle, color: _green),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _green.withOpacity(.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.eco, color: _green),
      ),
      const SizedBox(width: 10),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'GO GREEN MATES',
            style: TextStyle(
              color: _green,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          Text(
            'Small actions. Visible impact.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 24,
          height: 1.1,
          color: _darkGreen,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 7),
      Text(
        subtitle,
        style: const TextStyle(height: 1.45, color: Colors.black54),
      ),
    ],
  );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _green),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  text,
                  style: const TextStyle(color: Colors.black54, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Row(
      children: [
        Icon(icon, size: 16, color: _green),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ),
      ],
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.text, this.good = false});

  final String text;
  final bool good;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: good ? const Color(0xFFE7F4E9) : const Color(0xFFFFEAE7),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      text,
      style: TextStyle(color: good ? _darkGreen : Colors.red.shade900),
    ),
  );
}

String _displayDateTime(BuildContext context, DateTime? date) {
  if (date == null) return 'Date and time not available';
  final dateLabel = MaterialLocalizations.of(context).formatMediumDate(date);
  final timeLabel = MaterialLocalizations.of(context)
      .formatTimeOfDay(TimeOfDay.fromDateTime(date));
  return '$dateLabel · $timeLabel';
}
