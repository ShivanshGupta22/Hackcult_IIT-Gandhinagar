import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _scope = 'community';
  bool _weekly = false;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final c = s.myCommunity;
    final g = s.myGoal;
    final board = s.leaderboard(
        c == null && _scope == 'community' ? 'district' : _scope,
        weekly: _weekly);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Community'),
        actions: [
          if (c != null)
            IconButton(
              tooltip: 'Invite',
              onPressed: () => _showInvite(context, c),
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await s.refreshCommunityProgress();
          } catch (error) {
            if (!context.mounted) return;
            showAppSnack(
              context,
              'Could not refresh community goal: $error',
              icon: Icons.error_outline_rounded,
              color: AppColors.error,
            );
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            if (c == null)
              AppCard(
                gradient: AppColors.heroGreen,
                onTap: () => context.push('/community/join'),
                child: Row(
                  children: [
                    const IconTile(
                        icon: Icons.groups_rounded,
                        color: Colors.white,
                        size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Join your society or ward',
                              style:
                                  t.titleMedium?.copyWith(color: Colors.white)),
                          const SizedBox(height: 4),
                          Text(
                              s.useFirebase
                                  ? 'Join a shared goal and track progress together'
                                  : 'Compete on shared goals and earn bonus points together',
                              style:
                                  t.bodySmall?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white),
                  ],
                ),
              )
            else ...[
              if (s.useFirebase) ...[
                const InfoBanner(
                  text:
                      'Task contributions are self-reported. Online reward points are disabled until secure verification is available.',
                  icon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 12),
              ],
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconTile(
                            icon: _typeIcon(c.type),
                            color: AppColors.primary,
                            size: 52),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.name, style: t.titleMedium),
                              Text(
                                  '${c.type} · ${c.district} · ${Fmt.int(c.memberCount)} members',
                                  style: t.labelSmall),
                            ],
                          ),
                        ),
                        if (s.user!.role == UserRole.captain)
                          const StatusTag(
                              label: 'Captain', color: AppColors.secondary),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                            child: _MiniStat(
                                value: Fmt.compact(c.totalUnitsSaved),
                                label: 'units saved')),
                        Expanded(
                            child: _MiniStat(
                                value: Fmt.tonnes(c.totalUnitsSaved *
                                    s.config.factors.electricity),
                                label: 'CO₂ avoided')),
                        Expanded(
                            child: _MiniStat(
                                value: s.useFirebase
                                    ? '—'
                                    : '#${_communityRank(c)}',
                                label: 'in ${c.district}')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (g != null)
                AppCard(
                  onTap: () => context.push('/community/goals/${g.id}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.flag_rounded,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                              child:
                                  Text('Community goal', style: t.titleSmall)),
                          Pill(
                              label: '${g.daysLeft} days left',
                              color: AppColors.secondarySoft,
                              textColor: AppColors.warning),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(g.title, style: t.titleMedium),
                      const SizedBox(height: 10),
                      GoalProgressBar(
                        value: g.ratio,
                        label:
                            '${Fmt.compact(g.progress)} / ${Fmt.compact(g.target)} ${_metricLabel(g.metric)}',
                        trailing: '${(g.ratio * 100).round()}%',
                      ),
                      const SizedBox(height: 8),
                      Text(
                          'Your contribution: ${Fmt.compact(g.myContribution)} ${_metricLabel(g.metric)} · ${g.bonusPoints} bonus points on completion',
                          style: t.labelSmall),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Leaderboard',
              subtitle: s.useFirebase
                  ? 'Online points rankings are not enabled'
                  : _weekly
                      ? 'This week'
                      : 'All time',
              actionLabel: s.useFirebase
                  ? null
                  : _weekly
                      ? 'All time'
                      : 'This week',
              onAction: s.useFirebase
                  ? null
                  : () => setState(() => _weekly = !_weekly),
            ),
            if (!s.useFirebase)
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                      value: 'community',
                      label: Text(c == null ? 'Nearby' : 'Community')),
                  const ButtonSegment(
                      value: 'district', label: Text('District')),
                  const ButtonSegment(value: 'state', label: Text('Gujarat')),
                ],
                selected: {_scope},
                onSelectionChanged: (v) => setState(() => _scope = v.first),
                showSelectedIcon: false,
                style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.primarySoft,
                    selectedForegroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.border)),
              ),
            if (!s.useFirebase) const SizedBox(height: 12),
            if (board.length >= 3) _Podium(top: board.take(3).toList()),
            const SizedBox(height: 8),
            AppCard(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  for (final e in board.skip(3).take(12))
                    LeaderboardTile(entry: e, dense: true),
                  if (board.where((e) => e.isMe).isNotEmpty &&
                      board.indexWhere((e) => e.isMe) >= 15) ...[
                    const Divider(height: 8),
                    LeaderboardTile(
                        entry: board.firstWhere((e) => e.isMe), dense: true),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 10),
            InfoBanner(
                text: s.useFirebase
                    ? 'Online points rankings are not enabled yet.'
                    : 'Points reset weekly for the challenge board. All-time points decide your level.',
                icon: Icons.emoji_events_outlined,
                color: AppColors.secondary),
          ],
        ),
      ),
    );
  }

  int _communityRank(Community c) {
    final sorted = [...MockData.communities]
      ..sort((a, b) => b.totalUnitsSaved.compareTo(a.totalUnitsSaved));
    return sorted.indexWhere((x) => x.id == c.id) + 1;
  }

  void _showInvite(BuildContext context, Community c) {
    final t = Theme.of(context).textTheme;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite neighbours', style: t.titleLarge),
            const SizedBox(height: 6),
            Text(
                'Share this code. Every member who joins and completes a task earns you +100 referral points.',
                style: t.bodyMedium),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primaryContainer)),
              child: Row(
                children: [
                  Expanded(
                      child: Text(c.joinCode,
                          style: t.headlineMedium?.copyWith(
                              letterSpacing: 4, color: AppColors.primary))),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(
                          text:
                              'Join ${c.name} on LiFE Mitra Gujarat! Code: ${c.joinCode}'));
                      Navigator.pop(ctx);
                      showAppSnack(context, 'Invite copied to clipboard',
                          icon: Icons.copy_rounded);
                    },
                    icon: const Icon(Icons.copy_rounded,
                        color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            PrimaryButton(
              label: 'Share on WhatsApp',
              icon: Icons.share_rounded,
              onPressed: () {
                Navigator.pop(ctx);
                showAppSnack(
                    context, 'Share sheet would open here (share_plus)',
                    icon: Icons.share_rounded);
              },
            ),
          ],
        ),
      ),
    );
  }
}

IconData _typeIcon(String type) => switch (type) {
      'Village' => Icons.holiday_village_rounded,
      'School' => Icons.school_rounded,
      'Ward' => Icons.location_city_rounded,
      'Office' => Icons.business_rounded,
      _ => Icons.apartment_rounded,
    };

String _metricLabel(String m) => switch (m) {
      'units' => 'units',
      'tasks' => 'tasks',
      'co2' => 'kg CO₂',
      _ => m
    };

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: t.titleMedium?.copyWith(color: AppColors.primary)),
        Text(label, style: t.labelSmall)
      ],
    );
  }
}

class _Podium extends StatelessWidget {
  const _Podium({required this.top});
  final List<LeaderboardEntry> top;

  @override
  Widget build(BuildContext context) {
    Widget slot(LeaderboardEntry e, double h, Color color) {
      final t = Theme.of(context).textTheme;
      final initials =
          e.name.split(' ').map((p) => p.isEmpty ? '' : p[0]).take(2).join();
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Avatar(
                initials: initials,
                size: e.rank == 1 ? 52 : 42,
                color: e.isMe ? AppColors.primary : color),
            const SizedBox(height: 6),
            Text(e.isMe ? 'You' : e.name.split(' ').first,
                style: t.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            Text(Fmt.int(e.points), style: t.labelSmall),
            const SizedBox(height: 6),
            Container(
              height: h,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [color, color.withValues(alpha: 0.55)]),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              alignment: Alignment.topCenter,
              padding: const EdgeInsets.only(top: 8),
              child: Text('${e.rank}',
                  style: t.titleLarge?.copyWith(color: Colors.white)),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          slot(top[1], 56, const Color(0xFF9E9E9E)),
          slot(top[0], 84, AppColors.secondary),
          slot(top[2], 42, const Color(0xFFBF8970)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Join / create community
// ---------------------------------------------------------------------------
class JoinCommunityScreen extends StatefulWidget {
  const JoinCommunityScreen({super.key, this.fromOnboarding = false});
  final bool fromOnboarding;

  @override
  State<JoinCommunityScreen> createState() => _JoinCommunityScreenState();
}

class _JoinCommunityScreenState extends State<JoinCommunityScreen> {
  final _search = TextEditingController();
  final _code = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _code.dispose();
    super.dispose();
  }

  void _afterJoin(Community c) {
    showAppSnack(context, 'Welcome to ${c.name}!',
        icon: Icons.celebration_rounded, color: AppColors.primary);
    if (widget.fromOnboarding) {
      context.go('/home');
    } else {
      context.safePop('/community');
    }
  }

  Future<void> _join(Community c) async {
    final s = AppScope.read(context);
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconTile(icon: _typeIcon(c.type), color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: t.titleLarge),
                        Text('${c.type} · ${c.district} · ${c.pincode}',
                            style: t.labelSmall)
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                      child: _MiniStat(
                          value: Fmt.int(c.memberCount), label: 'members')),
                  Expanded(
                      child: _MiniStat(
                          value: Fmt.compact(c.totalUnitsSaved),
                          label: 'units saved')),
                  Expanded(
                      child: _MiniStat(
                          value: s.goalById(c.id) == null ? 'None' : 'Active',
                          label: 'goal')),
                ],
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                  label: 'Join ${c.type.toLowerCase()}',
                  onPressed: () => Navigator.pop(ctx, true)),
            ],
          ),
        );
      },
    );
    if (ok == true && mounted) {
      try {
        await s.joinCommunity(c);
        if (mounted) _afterJoin(c);
      } catch (error) {
        if (!mounted) return;
        showAppSnack(
          context,
          'Could not join this community: $error',
          icon: Icons.error_outline_rounded,
          color: AppColors.error,
        );
      }
    }
  }

  Future<void> _joinByCode() async {
    final code = _code.text.trim().toUpperCase();
    late final Community? c;
    try {
      c = await AppScope.read(context).communityByJoinCode(code);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Could not look up that community: $error',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );
      return;
    }
    if (c == null) {
      showAppSnack(context, 'Code not found. Check with your society captain.',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    await _join(c);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final u = s.user!;
    final all = s.communities;
    final list = (_query.isEmpty
            ? all.where((c) => c.district == u.district).toList()
            : all
                .where((c) =>
                    c.name.toLowerCase().contains(_query) ||
                    c.pincode.contains(_query) ||
                    c.district.toLowerCase().contains(_query))
                .toList())
        .where((c) => c.id != u.communityId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        leading: const SafeBackButton(fallback: '/community'),
        title: const Text('Join a community'),
        actions: [
          if (s.useFirebase)
            IconButton(
              tooltip: 'Refresh communities',
              onPressed: () async {
                try {
                  await s.refreshCommunities();
                } catch (error) {
                  if (!context.mounted) return;
                  showAppSnack(
                    context,
                    'Could not load communities: $error',
                    icon: Icons.error_outline_rounded,
                    color: AppColors.error,
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded),
            ),
          if (widget.fromOnboarding)
            TextButton(
                onPressed: () => context.go('/home'),
                child: const Text('Skip')),
        ],
      ),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Save together', style: t.headlineSmall),
            const SizedBox(height: 4),
            Text(
                'Communities with shared goals save 2× more. Find yours by name or pincode.',
                style: t.bodyMedium),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Search',
              controller: _search,
              hint: 'Society, ward, village or pincode',
              prefixIcon: Icons.search_rounded,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
            const SizedBox(height: 16),
            if (_query.isEmpty)
              Text('Near you · ${u.district}', style: t.titleSmall),
            const SizedBox(height: 8),
            if (list.isEmpty)
              const EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Nothing found',
                  body: 'Try a pincode, or create your community below',
                  compact: true)
            else
              for (final c in list)
                AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  onTap: () => _join(c),
                  child: Row(
                    children: [
                      IconTile(
                          icon: _typeIcon(c.type),
                          color: AppColors.primary,
                          size: 44,
                          iconSize: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: t.titleSmall),
                            Text(
                                '${c.type} · ${c.pincode} · ${Fmt.int(c.memberCount)} members',
                                style: t.labelSmall),
                          ],
                        ),
                      ),
                      TextButton(
                          onPressed: () => _join(c), child: const Text('Join')),
                    ],
                  ),
                ),
            const SizedBox(height: 10),
            Text('Have a join code?', style: t.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Join code',
                    controller: _code,
                    hint: 'e.g. SHNT15',
                    prefixIcon: Icons.qr_code_rounded,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: SizedBox(
                      height: 52,
                      child: FilledButton(
                          onPressed: _joinByCode, child: const Text('Go'))),
                ),
              ],
            ),
            const SizedBox(height: 24),
            AppCard(
              color: AppColors.secondarySoft,
              border: false,
              onTap: () async {
                final created =
                    await context.push<Community>('/community/create');
                if (created != null && mounted) _afterJoin(created);
              },
              child: Row(
                children: [
                  const IconTile(
                      icon: Icons.add_home_work_rounded,
                      color: AppColors.warning),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Can't find yours? Create it",
                            style: t.titleSmall),
                        Text(
                            'Become the captain · earn the Community Builder badge',
                            style: t.labelSmall),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final _name = TextEditingController();
  late final _pin =
      TextEditingController(text: AppScope.read(context).user!.pincode);
  String _type = 'Society';
  bool _accept = false;
  bool _saving = false;
  String? _nameError;

  @override
  void dispose() {
    _name.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_saving) return;
    setState(() => _nameError =
        _name.text.trim().length < 3 ? 'Enter at least 3 characters' : null);
    if (_nameError != null) return;
    if (_pin.text.trim().length != 6) {
      showAppSnack(context, 'Enter a valid 6-digit pincode',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    setState(() => _saving = true);
    try {
      final c = await AppScope.read(context).createCommunity(
          name: _name.text.trim(), type: _type, pincode: _pin.text.trim());
      if (!mounted) return;
      if (context.canPop()) {
        context.pop(c);
      } else {
        context.go('/community');
      }
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Could not create community: $error',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/community/join'),
          title: const Text('Create community')),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppTextField(
                label: 'Community name',
                controller: _name,
                hint: 'e.g. Shanti Nagar Society',
                errorText: _nameError,
                prefixIcon: Icons.badge_outlined),
            const SizedBox(height: 16),
            Text('Type', style: t.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final ty in const [
                  'Society',
                  'Ward',
                  'Village',
                  'School',
                  'Office'
                ])
                  ChoiceChip(
                    label: Text(ty),
                    avatar: Icon(_typeIcon(ty),
                        size: 16,
                        color: _type == ty
                            ? AppColors.primary
                            : AppColors.textSecondary),
                    selected: _type == ty,
                    onSelected: (_) => setState(() => _type = ty),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Pincode',
              controller: _pin,
              keyboardType: TextInputType.number,
              maxLength: 6,
              prefixIcon: Icons.location_on_outlined,
              helper: 'District: ${MockData.districtFromPin(_pin.text)}',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _accept,
              onChanged: (v) => setState(() => _accept = v ?? false),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                  'I agree to be the community captain and keep it respectful',
                  style: t.bodyMedium),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
                label: _saving ? 'Creating...' : 'Create & become captain',
                onPressed: _accept && !_saving ? _create : null,
                icon: Icons.star_rounded),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal detail
// ---------------------------------------------------------------------------
class GoalDetailScreen extends StatelessWidget {
  const GoalDetailScreen({super.key, required this.goalId});
  final String goalId;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final g = s.goalById(goalId);
    if (g == null) {
      return Scaffold(
          appBar: AppBar(
            leading: const SafeBackButton(fallback: '/community'),
          ),
          body: const EmptyState(
              icon: Icons.flag_outlined,
              title: 'Goal not found',
              body: 'This goal may have ended'));
    }
    final c = s.communityById(g.communityId);
    if (c == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const SafeBackButton(fallback: '/community'),
        ),
        body: const EmptyState(
          icon: Icons.groups_outlined,
          title: 'Community not found',
          body: 'Join or create a community to view its goal.',
        ),
      );
    }
    final perDay = g.daysLeft == 0 ? 0 : (g.target - g.progress) / g.daysLeft;
    final contributors = s.leaderboard('community').take(5).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Community goal')),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              gradient: AppColors.heroGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style: t.labelMedium?.copyWith(color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text(g.title,
                      style: t.headlineSmall?.copyWith(color: Colors.white)),
                  const SizedBox(height: 16),
                  Center(
                    child: ProgressRing(
                      value: g.ratio,
                      size: 150,
                      stroke: 14,
                      color: AppColors.secondary,
                      track: Colors.white24,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${(g.ratio * 100).round()}%',
                              style: t.headlineMedium
                                  ?.copyWith(color: Colors.white)),
                          Text(
                              '${Fmt.compact(g.progress)} / ${Fmt.compact(g.target)}',
                              style: t.labelSmall
                                  ?.copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroStat(value: '${g.daysLeft}', label: 'days left'),
                      _HeroStat(
                          value: Fmt.compact(perDay),
                          label: '${_metricLabel(g.metric)} / day needed'),
                      _HeroStat(
                          value: '+${g.bonusPoints}', label: 'bonus points'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your contribution', style: t.titleSmall),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                            '${Fmt.compact(g.myContribution)} ${_metricLabel(g.metric)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.headlineSmall
                                ?.copyWith(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                          g.progress == 0
                              ? ''
                              : '${(g.myContribution / g.progress * 100).toStringAsFixed(1)}% of total',
                          style: t.labelSmall),
                    ],
                  ),
                  const SizedBox(height: 10),
                  GoalProgressBar(
                      value: g.progress == 0
                          ? 0
                          : (g.myContribution / g.progress).clamp(0, 1),
                      color: AppColors.secondary,
                      height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Top contributors'),
            AppCard(
              padding: const EdgeInsets.all(6),
              child: Column(children: [
                for (final e in contributors)
                  LeaderboardTile(entry: e, dense: true)
              ]),
            ),
            const SizedBox(height: 16),
            const SectionHeader(title: 'Quick ways to help'),
            for (final id in const ['load_shift_wm', 'ac_24', 'led_swap'])
              Builder(builder: (context) {
                final task = MockData.taskById(id);
                return AppCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  onTap: () => context.go('/home'),
                  child: Row(
                    children: [
                      IconTile(
                          icon: task.theme.icon,
                          color: task.theme.color,
                          size: 42,
                          iconSize: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(task.title, style: t.titleSmall)),
                      Pill(
                          label: '+${task.points}',
                          color: AppColors.primarySoft,
                          textColor: AppColors.primary),
                    ],
                  ),
                );
              }),
            const SizedBox(height: 8),
            SecondaryButton(
                label: 'Invite neighbours',
                icon: Icons.person_add_alt_1_rounded,
                onPressed: () => showAppSnack(
                    context, 'Join code: ${c.joinCode}',
                    icon: Icons.qr_code_rounded)),
          ],
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: t.titleLarge?.copyWith(color: Colors.white)),
          Text(label, style: t.labelSmall?.copyWith(color: Colors.white70))
        ],
      ),
    );
  }
}
