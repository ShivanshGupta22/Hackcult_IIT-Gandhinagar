import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/logic/calculators.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final u = s.user!;
    final next = LevelEngine.nextLevel(u.points);
    final earned =
        MockData.badges.where((b) => u.badges.contains(b.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
              onPressed: () => context.push('/profile/notifications'),
              icon: const Icon(Icons.notifications_outlined))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            gradient: AppColors.heroGreen,
            child: Column(
              children: [
                Row(
                  children: [
                    Avatar(
                        initials: u.initials,
                        size: 64,
                        color: Colors.white24,
                        photoUrl: u.photoUrl),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.displayName,
                              style:
                                  t.titleLarge?.copyWith(color: Colors.white)),
                          Text('${u.district} · ${u.pincode}',
                              style:
                                  t.bodySmall?.copyWith(color: Colors.white70)),
                          const SizedBox(height: 6),
                          LevelChip(points: u.points, light: true),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.push('/profile/edit'),
                      icon:
                          const Icon(Icons.edit_outlined, color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GoalProgressBar(
                  value: LevelEngine.progress(u.points),
                  color: AppColors.secondary,
                  label: next == null
                      ? 'Max level reached!'
                      : '${Fmt.int(u.points)} / ${Fmt.int(next.$3)} pts → ${next.$4} ${next.$2}',
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _HeadStat(
                        icon: Icons.stars_rounded,
                        value: Fmt.int(u.points),
                        label: 'points'),
                    _HeadStat(
                        icon: Icons.local_fire_department_rounded,
                        value: '${u.streak}',
                        label: 'day streak'),
                    _HeadStat(
                        icon: Icons.military_tech_rounded,
                        value: '${earned.length}',
                        label: 'badges'),
                    _HeadStat(
                        icon: Icons.ac_unit_rounded,
                        value: '${u.freezeTokens}',
                        label: 'freezes'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Badges',
            subtitle: '${earned.length} of ${MockData.badges.length} earned',
            actionLabel: 'See all',
            onAction: () => context.push('/profile/badges'),
          ),
          SizedBox(
            height: 112,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.badges.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final b = MockData.badges[i];
                return SizedBox(
                    width: 96,
                    child: BadgeTile(
                        badge: b,
                        earned: u.badges.contains(b.id),
                        onTap: () =>
                            _badgeDialog(context, b, u.badges.contains(b.id))));
              },
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Points history',
            actionLabel: 'All',
            onAction: () => context.push('/profile/points'),
          ),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: s.ledger.isEmpty
                ? const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No points yet',
                    body: 'Complete a task on Home to earn your first points',
                    compact: true)
                : Column(children: [
                    for (final e in s.ledger.take(4)) _LedgerTile(e)
                  ]),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'My home'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                    icon: Icons.home_outlined,
                    title: 'Household & appliances',
                    subtitle:
                        '${u.householdSize} people · ${u.appliances.length} appliances · ${u.homeType}',
                    onTap: () => context.push('/profile/edit')),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                    icon: Icons.flag_outlined,
                    title: 'Monthly goal',
                    subtitle: 'Reduce ${u.goalPercent}% vs baseline',
                    onTap: () => _goalSheet(context)),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                    icon: Icons.language_rounded,
                    title: 'Language',
                    subtitle: u.language == 'gu' ? 'ગુજરાતી' : 'English',
                    onTap: () => s.updateProfile(
                        (x) => x.language = x.language == 'gu' ? 'en' : 'gu')),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                    icon: Icons.notifications_outlined,
                    title: 'Notifications & nudges',
                    subtitle: u.peakNudge
                        ? 'Peak-hour nudge on'
                        : 'Peak-hour nudge off',
                    onTap: () => context.push('/profile/notifications')),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Account'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                _MenuTile(
                    icon: Icons.mail_outline_rounded,
                    title: u.email,
                    subtitle: u.authProvider == AuthProvider.google
                        ? 'Signed in with Google'
                        : 'Email & password',
                    onTap: null),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'Privacy & data',
                    subtitle: 'Export or delete my data',
                    onTap: () => _privacySheet(context)),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & feedback',
                    subtitle: 'FAQ · support@lifemitra.gujarat.gov.in',
                    onTap: () => showAppSnack(context, 'Help centre opens here',
                        icon: Icons.help_outline_rounded)),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Sign out',
                  color: AppColors.error,
                  onTap: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Sign out?'),
                        content: const Text(
                            'Your streak is safe — it continues when you sign back in today.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.error,
                                  minimumSize: const Size(0, 40)),
                              child: const Text('Sign out')),
                        ],
                      ),
                    );
                    if (ok == true && context.mounted) {
                      context.go('/login');
                      s.signOut();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
              child: Text('LiFE Mitra Gujarat · v1.0.0 · GEDA',
                  style: t.labelSmall)),
        ],
      ),
    );
  }

  void _badgeDialog(BuildContext context, BadgeItem b, bool earned) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconTile(
                icon: b.icon,
                color: earned ? b.color : AppColors.textTertiary,
                size: 72,
                iconSize: 36,
                radius: 36),
            const SizedBox(height: 12),
            Text(b.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(b.description, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            StatusTag(
                label: earned ? 'Earned' : 'Locked',
                color: earned ? AppColors.success : AppColors.textTertiary),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'))
        ],
      ),
    );
  }

  void _goalSheet(BuildContext context) {
    final s = AppScope.read(context);
    var g = s.user!.goalPercent;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Monthly reduction goal',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final v in const [5, 10, 15, 20])
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: SelectableTile(
                            label: '−$v%',
                            selected: g == v,
                            onTap: () => setSt(() => g = v),
                            compact: true),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: 'Save goal',
                onPressed: () {
                  s.updateProfile((u) => u.goalPercent = g);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _privacySheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
                leading: const Icon(Icons.download_rounded),
                title: const Text('Export my data (JSON)'),
                subtitle: const Text(
                    'Footprint, tasks, points — emailed within 24 h'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnack(context, 'Export requested',
                      icon: Icons.download_rounded);
                }),
            ListTile(
                leading: const Icon(Icons.policy_outlined),
                title: const Text('Privacy policy'),
                subtitle: const Text(
                    'DPDP Act 2023 compliant · data stored in India'),
                onTap: () => Navigator.pop(ctx)),
            ListTile(
                leading: const Icon(Icons.delete_forever_rounded,
                    color: AppColors.error),
                title: const Text('Delete account',
                    style: TextStyle(color: AppColors.error)),
                subtitle:
                    const Text('Removes all personal data within 30 days'),
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnack(
                      context, 'Deletion flow (confirm by email) — demo',
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.error);
                }),
          ],
        ),
      ),
    );
  }
}

class _HeadStat extends StatelessWidget {
  const _HeadStat(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.secondaryLight, size: 20),
          const SizedBox(height: 4),
          Text(value, style: t.titleMedium?.copyWith(color: Colors.white)),
          Text(label, style: t.labelSmall?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.color});
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.primary),
      title: Text(title,
          style: TextStyle(color: color),
          maxLines: 1,
          overflow: TextOverflow.ellipsis),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: onTap == null
          ? null
          : const Icon(Icons.chevron_right_rounded,
              color: AppColors.textTertiary),
    );
  }
}

class _LedgerTile extends StatelessWidget {
  const _LedgerTile(this.e);
  final PointsEntry e;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pos = e.delta >= 0;
    return ListTile(
      dense: true,
      leading: IconTile(
          icon: e.icon ?? Icons.stars_rounded,
          color: pos ? AppColors.primary : AppColors.error,
          size: 38,
          iconSize: 20,
          radius: 10),
      title: Text(e.reason, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(Fmt.dateTime(e.createdAt)),
      trailing: Text('${pos ? '+' : ''}${e.delta}',
          style: t.titleSmall
              ?.copyWith(color: pos ? AppColors.success : AppColors.error)),
    );
  }
}

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = AppScope.of(context).user!;
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/profile'),
          title: const Text('Badges')),
      body: PhoneFrame(
        child: GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 130,
              mainAxisExtent: 124,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10),
          itemCount: MockData.badges.length,
          itemBuilder: (_, i) {
            final b = MockData.badges[i];
            return BadgeTile(
                badge: b,
                earned: u.badges.contains(b.id),
                onTap: () => showAppSnack(
                    context, '${b.name}: ${b.description}',
                    icon: b.icon));
          },
        ),
      ),
    );
  }
}

class PointsHistoryScreen extends StatelessWidget {
  const PointsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/profile'),
          title: const Text('Points history')),
      body: PhoneFrame(
        child: s.ledger.isEmpty
            ? const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Nothing yet',
                body: 'Complete tasks and upload bills to see entries here')
            : ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: s.ledger.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 64),
                itemBuilder: (_, i) => _LedgerTile(s.ledger[i]),
              ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Edit profile
// ---------------------------------------------------------------------------
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late final AppUser u = AppScope.read(context).user!;
  late final _name = TextEditingController(text: u.displayName);
  late final _pin = TextEditingController(text: u.pincode);
  late int _household = u.householdSize;
  late String _homeType = u.homeType;
  late final Set<String> _appl = {...u.appliances};
  late String _travel = u.travelMode;
  late double _km = u.weeklyKm;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().length < 2) {
      showAppSnack(context, 'Enter your name',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    AppScope.read(context).updateProfile((x) => x
      ..displayName = _name.text.trim()
      ..pincode = _pin.text.trim()
      ..district = MockData.districtFromPin(_pin.text.trim())
      ..householdSize = _household
      ..homeType = _homeType
      ..appliances = _appl.toList()
      ..travelMode = _travel
      ..weeklyKm = _km);
    showAppSnack(context, 'Profile updated',
        icon: Icons.check_circle_rounded, color: AppColors.primary);
    context.safePop('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/profile'),
          title: const Text('Edit profile'),
          actions: [TextButton(onPressed: _save, child: const Text('Save'))]),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
                child: Avatar(
                    initials: u.initials, size: 80, photoUrl: u.photoUrl)),
            const SizedBox(height: 8),
            Center(
                child: TextButton(
                    onPressed: () => showAppSnack(
                        context, 'Photo picker (image_picker) opens here',
                        icon: Icons.photo_camera_outlined),
                    child: const Text('Change photo'))),
            const SizedBox(height: 8),
            AppTextField(
                label: 'Full name',
                controller: _name,
                prefixIcon: Icons.person_outline_rounded),
            const SizedBox(height: 14),
            AppTextField(
                label: 'Pincode',
                controller: _pin,
                keyboardType: TextInputType.number,
                maxLength: 6,
                prefixIcon: Icons.location_on_outlined,
                helper: 'District: ${MockData.districtFromPin(_pin.text)}',
                onChanged: (_) => setState(() {})),
            const SizedBox(height: 14),
            StepperField(
                label: 'People at home',
                value: _household,
                min: 1,
                max: 15,
                onChanged: (v) => setState(() => _household = v)),
            const SizedBox(height: 16),
            Text('Home type', style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in const [
                  ('flat', 'Flat'),
                  ('bungalow', 'Bungalow'),
                  ('row_house', 'Row house'),
                  ('rented', 'Rented')
                ])
                  ChoiceChip(
                      label: Text(label),
                      selected: _homeType == id,
                      onSelected: (_) => setState(() => _homeType = id)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Appliances', style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in MockData.appliances)
                  FilterChip(
                    label: Text(a.$2),
                    avatar: Icon(a.$3, size: 16),
                    selected: _appl.contains(a.$1),
                    onSelected: (v) => setState(
                        () => v ? _appl.add(a.$1) : _appl.remove(a.$1)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Daily travel', style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (id, label) in const [
                  ('two_wheeler', 'Two-wheeler'),
                  ('car', 'Car'),
                  ('bus_metro', 'Bus / Metro'),
                  ('walk_cycle', 'Walk / Cycle'),
                  ('ev', 'EV')
                ])
                  ChoiceChip(
                      label: Text(label),
                      selected: _travel == id,
                      onSelected: (_) => setState(() => _travel = id)),
              ],
            ),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: Text('Weekly km', style: t.titleSmall)),
              Text('${_km.round()} km',
                  style: t.labelLarge?.copyWith(color: AppColors.primary))
            ]),
            Slider(
                value: _km,
                min: 0,
                max: 300,
                divisions: 30,
                onChanged: (v) => setState(() => _km = v)),
            const SizedBox(height: 12),
            const InfoBanner(
                text:
                    'Changing appliances or travel updates your task recommendations, not your baseline footprint.',
                icon: Icons.info_outline_rounded),
            const SizedBox(height: 20),
            PrimaryButton(label: 'Save changes', onPressed: _save),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Notification settings
// ---------------------------------------------------------------------------
class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = s.user!;
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/profile'),
          title: const Text('Notifications & nudges')),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const InfoBanner(
                text:
                    'Max 2 nudges a day · quiet hours 10 pm – 7 am · you can switch any off.',
                icon: Icons.do_not_disturb_on_outlined),
            const SizedBox(height: 12),
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    secondary: const Icon(Icons.schedule_rounded,
                        color: AppColors.warning),
                    title: const Text('Peak-hour reminder'),
                    subtitle:
                        const Text('5:30 pm · shift heavy loads before 6 pm'),
                    value: u.peakNudge,
                    onChanged: (v) => s.updateProfile((x) => x.peakNudge = v),
                  ),
                  const Divider(height: 1, indent: 60),
                  SwitchListTile(
                    secondary: const Icon(Icons.thermostat_rounded,
                        color: AppColors.error),
                    title: const Text('Heatwave / weather tips'),
                    subtitle:
                        const Text('AC & cooling advice when it crosses 40°C'),
                    value: u.weatherNudge,
                    onChanged: (v) =>
                        s.updateProfile((x) => x.weatherNudge = v),
                  ),
                  const Divider(height: 1, indent: 60),
                  SwitchListTile(
                    secondary: const Icon(Icons.groups_rounded,
                        color: AppColors.primary),
                    title: const Text('Community updates'),
                    subtitle: const Text(
                        'Goal milestones, rank changes, captain posts'),
                    value: u.communityUpdates,
                    onChanged: (v) =>
                        s.updateProfile((x) => x.communityUpdates = v),
                  ),
                  const Divider(height: 1, indent: 60),
                  SwitchListTile(
                    secondary: const Icon(Icons.local_fire_department_rounded,
                        color: AppColors.secondary),
                    title: const Text('Streak reminders'),
                    subtitle: const Text('8 pm if no task done yet today'),
                    value: u.streakReminders,
                    onChanged: (v) =>
                        s.updateProfile((x) => x.streakReminders = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Demo tools', style: t.titleSmall),
            const SizedBox(height: 8),
            AppCard(
              padding: EdgeInsets.zero,
              child: ListTile(
                leading:
                    const Icon(Icons.bolt_rounded, color: AppColors.warning),
                title: const Text('Trigger peak-hour nudge now'),
                subtitle: const Text('Shows the 5:30 pm nudge card on Home'),
                trailing: const Icon(Icons.play_arrow_rounded),
                onTap: () {
                  s.triggerDemoNudge();
                  showAppSnack(context, 'Nudge queued — check Home',
                      icon: Icons.notifications_active_rounded);
                  context.go('/home');
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
