import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/logic/calculators.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

// ---------------------------------------------------------------------------
// Main shell with bottom navigation
// ---------------------------------------------------------------------------
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});
  final Widget child;
  final String location;

  static const _tabs = ['/home', '/impact', '/community', '/hub', '/profile'];

  int get _index {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  static const _destinations = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.insights_outlined, Icons.insights_rounded, 'Impact'),
    (Icons.groups_outlined, Icons.groups_rounded, 'Community'),
    (Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'Hub'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    // During sign-out the router is about to redirect; never build tab
    // screens (which assume a signed-in user) in that intermediate frame.
    if (!s.isSignedIn) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final width = MediaQuery.sizeOf(context).width;

    // ---- Phone (< 600 dp): bottom navigation, full width ----
    if (width < 600) {
      return Scaffold(
        body: child,
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border))),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: [
              for (final d in _destinations)
                NavigationDestination(
                    icon: Icon(d.$1), selectedIcon: Icon(d.$2), label: d.$3),
            ],
          ),
        ),
      );
    }

    // ---- Tablet / desktop / web (>= 600 dp): side rail + centred content ----
    final extended = width >= 1100;
    final contentMax = width >= 900 ? 760.0 : 600.0;
    return Scaffold(
      backgroundColor: const Color(0xFFEEF4EE),
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 210,
            backgroundColor: Colors.white,
            selectedIndex: _index,
            onDestinationSelected: (i) => context.go(_tabs[i]),
            labelType: extended
                ? NavigationRailLabelType.none
                : NavigationRailLabelType.all,
            indicatorColor: AppColors.primarySoft,
            selectedIconTheme: const IconThemeData(color: AppColors.primary),
            selectedLabelTextStyle: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(
                    color: AppColors.primary, fontWeight: FontWeight.w700),
            leading: Padding(
              padding: const EdgeInsets.fromLTRB(8, 16, 8, 20),
              child: Image.asset('assets/images/logo_512.png',
                  width: extended ? 72 : 44, height: extended ? 72 : 44),
            ),
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                    icon: Icon(d.$1),
                    selectedIcon: Icon(d.$2),
                    label: Text(d.$3)),
            ],
          ),
          const VerticalDivider(
              width: 1, thickness: 1, color: AppColors.border),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: contentMax),
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    border: Border.symmetric(
                        vertical: BorderSide(
                            color: AppColors.border.withValues(alpha: 0.8))),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home — Today
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 650),
        () => mounted ? setState(() => _loading = false) : null);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final u = s.user!;
    final t = Theme.of(context).textTheme;
    final tasks = s.todayTasks;
    final done = s.tasksDoneToday;
    final nudge = s.activeNudge;
    final goal = s.myGoal;
    final community = s.myCommunity;

    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const _HomeSkeleton()
            : RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    _Header(user: u),
                    const SizedBox(height: 16),
                    if (nudge != null) ...[
                      NudgeCard(
                        nudge: nudge,
                        onDoIt: () {
                          if (nudge.taskId != null) {
                            showTaskSheet(
                                context, MockData.taskById(nudge.taskId!));
                          } else {
                            context.go('/community');
                          }
                        },
                        onLater: () => s.dismissNudge(nudge.id),
                        onNotForMe: () => s.dismissNudge(nudge.id),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SolarHoursGauge(),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: "Today's tasks",
                      subtitle:
                          '$done/${tasks.length} done · ${Fmt.int(u.points)} Green Points',
                      actionLabel: done == tasks.length ? null : 'Why these?',
                      onAction: () => showAppSnack(context,
                          'Picked from your appliances, season and Mission LiFE themes.',
                          icon: Icons.auto_awesome_rounded),
                    ),
                    if (done == tasks.length && tasks.isNotEmpty)
                      AppCard(
                        color: AppColors.primarySoft,
                        border: false,
                        child: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("You're done for today!",
                                      style: t.titleSmall
                                          ?.copyWith(color: AppColors.primary)),
                                  Text(
                                      'Come back tomorrow for new challenges — streak stays alive 🔥',
                                      style: t.bodySmall),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    for (final task in tasks) ...[
                      TaskCard(
                        task: task,
                        status: s.statusOf(task.id),
                        onTap: () => showTaskSheet(context, task),
                        onDone: () => completeTaskFlow(context, task),
                        onSkip: () =>
                            _saveTaskAction(context, () => s.skipTask(task)),
                        onNotApplicable: () => _saveTaskAction(
                          context,
                          () => s.markNotApplicable(task),
                          successMessage:
                              "Got it — we won't suggest this again.",
                          successIcon: Icons.thumb_up_alt_outlined,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    if (s.pointsTodaySelf >= s.config.dailySelfPointsCap)
                      const Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: InfoBanner(
                            bold: 'Daily cap reached —',
                            text: 'verify with your bill for more points.',
                            icon: Icons.info_outline_rounded,
                            color: AppColors.warning),
                      ),
                    const SizedBox(height: 10),
                    if (community != null && goal != null)
                      AppCard(
                        onTap: () =>
                            context.push('/community/goals/${goal.id}'),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const IconTile(
                                    icon: Icons.groups_rounded,
                                    color: AppColors.primary,
                                    size: 36,
                                    iconSize: 20,
                                    radius: 10),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(community.name,
                                        style: t.titleSmall,
                                        overflow: TextOverflow.ellipsis)),
                                const Icon(Icons.chevron_right_rounded,
                                    color: AppColors.textTertiary),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GoalProgressBar(
                              value: goal.ratio,
                              label:
                                  '${Fmt.int(goal.progress)} / ${Fmt.int(goal.target)} ${goal.metric == 'co2' ? 'kg CO₂' : goal.metric}',
                              trailing:
                                  '${(goal.ratio * 100).round()}% · ${goal.daysLeft} days left',
                            ),
                          ],
                        ),
                      )
                    else
                      AppCard(
                        onTap: () => context.push('/community/join'),
                        color: AppColors.tertiarySoft,
                        border: false,
                        child: Row(
                          children: [
                            const IconTile(
                                icon: Icons.groups_rounded,
                                color: AppColors.tertiary,
                                size: 40,
                                iconSize: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Join your society or village',
                                      style: t.titleSmall),
                                  Text(
                                      'Save as a team and climb the local leaderboard',
                                      style: t.bodySmall),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: AppColors.tertiary),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.receipt_long_rounded,
                            color: AppColors.tertiary,
                            title: "Add this month's bill",
                            subtitle: 'Earn 2 pts / unit saved',
                            onTap: () => context.push('/impact/add-month'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _QuickAction(
                            icon: Icons.solar_power_rounded,
                            color: AppColors.secondary,
                            title: 'Solar calculator',
                            subtitle: 'Net cost after subsidy',
                            onTap: () => context.push('/hub/solar'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final hour = DateTime.now().hour;
    final greet = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          gradient: AppColors.heroGreen,
          borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54)),
                alignment: Alignment.center,
                child: Text(user.initials,
                    style: t.titleSmall?.copyWith(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greet,',
                        style: t.bodySmall?.copyWith(color: Colors.white70)),
                    Text('Namaste, ${user.displayName.split(' ').first}!',
                        style: t.titleLarge?.copyWith(color: Colors.white)),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => context.push('/profile/notifications'),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(
                  label: '${user.streak}-day streak',
                  icon: Icons.local_fire_department_rounded,
                  color: Colors.white.withValues(alpha: 0.2)),
              Pill(
                  label: '${Fmt.int(user.points)} pts',
                  icon: Icons.stars_rounded,
                  color: AppColors.secondary,
                  textColor: AppColors.textPrimary),
              LevelChip(points: user.points, light: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
              icon: icon, color: color, size: 40, iconSize: 22, radius: 12),
          const SizedBox(height: 10),
          Text(title, style: t.titleSmall, maxLines: 2),
          Text(subtitle, style: t.labelSmall),
        ],
      ),
    );
  }
}

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        SkeletonBox(height: 120, radius: 20),
        SizedBox(height: 16),
        SkeletonBox(height: 110, radius: 16),
        SizedBox(height: 16),
        SkeletonBox(height: 120, radius: 16),
        SizedBox(height: 24),
        SkeletonBox(height: 18, width: 140),
        SizedBox(height: 12),
        SkeletonBox(height: 84, radius: 16),
        SizedBox(height: 10),
        SkeletonBox(height: 84, radius: 16),
        SizedBox(height: 10),
        SkeletonBox(height: 84, radius: 16),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Task completion flow + detail sheet (shared by Home and nudges)
// ---------------------------------------------------------------------------
Future<void> completeTaskFlow(BuildContext context, TaskItem task,
    {bool fromSheet = false}) async {
  final s = AppScope.read(context);
  if (task.verification == Verification.bill) {
    context.push('/impact/add-month');
    return;
  }
  if (s.useFirebase && task.verification == Verification.photo) {
    showAppSnack(
      context,
      'Photo verification is not available for online accounts yet.',
      icon: Icons.info_outline_rounded,
      color: AppColors.warning,
    );
    return;
  }
  var withPhoto = false;
  if (task.verification == Verification.photo) {
    final picked = await showModalBottomSheet<bool>(
      context: context,
      builder: (_) => const _PhotoPickerSheet(),
    );
    if (picked != true) return;
    withPhoto = true;
  }
  late final TaskCompletion result;
  try {
    result = await s.completeTask(task, withPhoto: withPhoto);
  } catch (error) {
    if (!context.mounted) return;
    showAppSnack(
      context,
      'Could not save task progress: $error',
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
    );
    return;
  }
  if (!context.mounted) return;
  HapticFeedback.lightImpact();
  if (result.points > 0) showConfetti(context);
  showAppSnack(
    context,
    result.points > 0
        ? '+${result.points} Green Points'
        : s.useFirebase
            ? 'Task progress saved. Online rewards are not enabled yet.'
            : 'Logged! Daily cap reached — verify with your bill for more.',
    icon: Icons.stars_rounded,
    color: AppColors.primary,
  );
  if (result.leveledUp != null) {
    await showDialog<void>(
        context: context,
        builder: (_) =>
            _LevelUpDialog(level: result.leveledUp!, points: s.user!.points));
  }
  for (final b in result.newBadges) {
    if (!context.mounted) return;
    await showDialog<void>(
        context: context, builder: (_) => _BadgeDialog(badge: b));
  }
}

Future<void> _saveTaskAction(
  BuildContext context,
  Future<void> Function() save, {
  String? successMessage,
  IconData successIcon = Icons.check_circle_outline_rounded,
}) async {
  try {
    await save();
    if (!context.mounted || successMessage == null) return;
    showAppSnack(context, successMessage, icon: successIcon);
  } catch (error) {
    if (!context.mounted) return;
    showAppSnack(
      context,
      'Could not save task progress: $error',
      icon: Icons.error_outline_rounded,
      color: AppColors.error,
    );
  }
}

class _PhotoPickerSheet extends StatefulWidget {
  const _PhotoPickerSheet();

  @override
  State<_PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<_PhotoPickerSheet> {
  bool _picked = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add a photo as proof', style: t.headlineSmall),
          const SizedBox(height: 4),
          Text(
              'Our AI checks the image, then your points are credited instantly. +5 bonus for photo proof.',
              style: t.bodySmall),
          const SizedBox(height: 20),
          if (_picked)
            Container(
              height: 160,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                    colors: [Color(0xFFDDE7DD), Color(0xFFC6D8C7)]),
              ),
              child: Stack(
                children: [
                  const Center(
                      child: Icon(Icons.image_rounded,
                          size: 56, color: Colors.white)),
                  Positioned(
                    right: 10,
                    top: 10,
                    child: StatusTag(
                        label: 'Looks good ✓', color: AppColors.success),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                    child: _PickTile(
                        icon: Icons.photo_camera_rounded,
                        label: 'Camera',
                        onTap: () => setState(() => _picked = true))),
                const SizedBox(width: 12),
                Expanded(
                    child: _PickTile(
                        icon: Icons.photo_library_rounded,
                        label: 'Gallery',
                        onTap: () => setState(() => _picked = true))),
              ],
            ),
          const SizedBox(height: 20),
          PrimaryButton(
              label: _picked ? 'Complete task' : 'Choose a photo first',
              onPressed: _picked ? () => Navigator.pop(context, true) : null),
        ],
      ),
    );
  }
}

class _PickTile extends StatelessWidget {
  const _PickTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppColors.border,
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside),
          color: AppColors.background,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

Future<void> showTaskSheet(BuildContext context, TaskItem task) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => TaskDetailSheet(task: task),
  );
}

class TaskDetailSheet extends StatelessWidget {
  const TaskDetailSheet({super.key, required this.task});
  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppScope.of(context);
    final status = s.statusOf(task.id);
    final done = status == TaskStatus.done;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 0, 20, 20 + MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconTile(
                    icon: task.theme.icon,
                    color: task.theme.color,
                    size: 44,
                    iconSize: 22),
                const SizedBox(width: 12),
                Pill(
                    label: task.theme.label,
                    color: task.theme.color.withValues(alpha: 0.12),
                    textColor: task.theme.color),
                const Spacer(),
                Pill(
                    label: '+${task.points} pts',
                    color: AppColors.secondarySoft,
                    textColor: const Color(0xFF694300),
                    icon: Icons.stars_rounded),
              ],
            ),
            const SizedBox(height: 14),
            Text(task.title, style: t.headlineSmall),
            const SizedBox(height: 8),
            Text('Why it matters', style: t.labelMedium),
            const SizedBox(height: 2),
            Text(task.description, style: t.bodyMedium),
            const SizedBox(height: 16),
            Row(
              children: [
                _ImpactStat(
                    value: task.estUnitsSaved > 0
                        ? '${task.estUnitsSaved} units'
                        : '—',
                    label: 'Energy'),
                _ImpactStat(
                    value:
                        task.estRupees > 0 ? Fmt.rupees(task.estRupees) : '—',
                    label: 'Saving'),
                _ImpactStat(
                    value: task.estCo2Kg > 0 ? Fmt.kg(task.estCo2Kg) : '—',
                    label: 'CO₂'),
              ],
            ),
            if (task.steps.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('How to do it', style: t.titleSmall),
              const SizedBox(height: 8),
              for (var i = 0; i < task.steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                            color: AppColors.primarySoft,
                            shape: BoxShape.circle),
                        child: Text('${i + 1}',
                            style: t.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(task.steps[i], style: t.bodyMedium)),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(task.verification.icon,
                    size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(task.verification.label, style: t.labelMedium),
                if (task.verification == Verification.photo)
                  Text(' · +${s.config.photoBonus} bonus',
                      style: t.labelMedium?.copyWith(color: AppColors.success)),
              ],
            ),
            const SizedBox(height: 18),
            if (done)
              const SecondaryButton(label: 'Completed today ✓')
            else
              PrimaryButton(
                label: switch (task.verification) {
                  Verification.photo => 'Add photo & complete',
                  Verification.bill => 'Upload bill',
                  Verification.vendor => 'Book with a vendor',
                  _ => 'Mark as done',
                },
                icon: task.verification == Verification.photo
                    ? Icons.photo_camera_rounded
                    : Icons.check_rounded,
                onPressed: () async {
                  Navigator.pop(context);
                  if (task.verification == Verification.vendor) {
                    context.push('/hub/vendors');
                    return;
                  }
                  await completeTaskFlow(context, task);
                },
              ),
            if (!done)
              Center(
                child: TextButton(
                  onPressed: () {
                    _saveTaskAction(
                      context,
                      () => s.markNotApplicable(task),
                      successMessage: "Got it — we won't suggest this again.",
                      successIcon: Icons.thumb_up_alt_outlined,
                    ).then((_) {
                      if (context.mounted) Navigator.pop(context);
                    });
                  },
                  style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary),
                  child: const Text('Not applicable to me'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ImpactStat extends StatelessWidget {
  const _ImpactStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border)),
        child: Column(
          children: [
            FittedBox(
                child: Text(value,
                    style: t.titleSmall?.copyWith(color: AppColors.primary))),
            Text(label, style: t.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _LevelUpDialog extends StatelessWidget {
  const _LevelUpDialog({required this.level, required this.points});
  final String level;
  final int points;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = LevelEngine.levelFor(points);
    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
            gradient: AppColors.heroGreen,
            borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.$4, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text('Level up!',
                style: t.headlineSmall?.copyWith(color: Colors.white)),
            Text("You're now a $level",
                style: t.bodyMedium?.copyWith(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Continue',
                color: Colors.white,
                foreground: AppColors.primary,
                onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}

class _BadgeDialog extends StatelessWidget {
  const _BadgeDialog({required this.badge});
  final BadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                  color: badge.color.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                  border: Border.all(color: badge.color, width: 3)),
              child: Icon(badge.icon, color: badge.color, size: 40),
            ),
            const SizedBox(height: 16),
            Text('Badge earned!', style: t.labelMedium),
            Text(badge.name, style: t.headlineSmall),
            const SizedBox(height: 4),
            Text(badge.description,
                style: t.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Awesome', onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }
}
