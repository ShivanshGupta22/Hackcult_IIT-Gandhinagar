import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';

const _workspaceGreen = Color(0xFF155E20);
const _workspaceBackground = Color(0xFFF0FAF2);
const _workspaceBorder = Color(0xFFDCE8DD);

class AdminWorkspaceUnavailable extends StatelessWidget {
  const AdminWorkspaceUnavailable({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.cloud_off_outlined,
                    color: AppColors.warning, size: 40),
                const SizedBox(height: 12),
                Text(title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkspacePage extends StatelessWidget {
  const _WorkspacePage({
    required this.title,
    required this.subtitle,
    required this.children,
    this.actions = const [],
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 12,
          spacing: 16,
          children: [
            SizedBox(
              width: 640,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: text.headlineSmall),
                  const SizedBox(height: 4),
                  Text(subtitle, style: text.bodyMedium),
                ],
              ),
            ),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          text:
              'Demo workspace — sample records and changes are not connected to a live GEDA service.',
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }
}

class _WorkspacePanel extends StatelessWidget {
  const _WorkspacePanel({
    required this.title,
    required this.child,
    this.trailing,
  });

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _workspaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child:
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _WorkspaceStats extends StatelessWidget {
  const _WorkspaceStats({required this.items});
  final List<(String, String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 900
            ? 4
            : constraints.maxWidth > 540
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final item in items)
              SizedBox(
                width: width,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _workspaceBorder),
                  ),
                  child: Row(
                    children: [
                      IconTile(
                        icon: item.$3,
                        color: _workspaceGreen,
                        size: 38,
                        iconSize: 19,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.$1,
                                style: Theme.of(context).textTheme.labelMedium),
                            const SizedBox(height: 3),
                            Text(item.$2,
                                style: Theme.of(context).textTheme.titleLarge),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search_rounded),
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _workspaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: _workspaceBorder),
          ),
        ),
      ),
    );
  }
}

class _CitizenRecord {
  const _CitizenRecord({
    required this.name,
    required this.email,
    required this.consumerId,
    required this.district,
    required this.community,
    required this.points,
    required this.units,
    required this.lastActive,
    this.role = 'Citizen',
  });

  final String name;
  final String email;
  final String consumerId;
  final String district;
  final String community;
  final int points;
  final int units;
  final String lastActive;
  final String role;
}

class AdminCitizensScreen extends StatefulWidget {
  const AdminCitizensScreen({super.key});

  @override
  State<AdminCitizensScreen> createState() => _AdminCitizensScreenState();
}

class _AdminCitizensScreenState extends State<AdminCitizensScreen> {
  static const _records = <_CitizenRecord>[
    _CitizenRecord(
      name: 'Nisha Patel',
      email: 'n***@gmail.com',
      consumerId: 'GJ-4029-A',
      district: 'Ahmedabad',
      community: 'Shanti Nagar Society',
      points: 840,
      units: 212,
      lastActive: 'Today',
    ),
    _CitizenRecord(
      name: 'Rajesh Shah',
      email: 'r***@yahoo.in',
      consumerId: 'GJ-1102-B',
      district: 'Surat',
      community: 'Adajan Green Enclave',
      points: 1420,
      units: 420,
      lastActive: 'Yesterday',
      role: 'Captain',
    ),
    _CitizenRecord(
      name: 'Amit Trivedi',
      email: 'a***@gmail.com',
      consumerId: 'GJ-9821-C',
      district: 'Vadodara',
      community: 'Alkapuri Heights',
      points: 180,
      units: 48,
      lastActive: '26 Oct',
    ),
    _CitizenRecord(
      name: 'Meena Joshi',
      email: 'm***@gmail.com',
      consumerId: 'GJ-3341-D',
      district: 'Rajkot',
      community: 'Kalawad Road Society',
      points: 760,
      units: 190,
      lastActive: '25 Oct',
    ),
    _CitizenRecord(
      name: 'Ravi Desai',
      email: 'r***@geda.gov.in',
      consumerId: 'GJ-0012-G',
      district: 'Gandhinagar',
      community: 'Sector 8 Bungalows',
      points: 2120,
      units: 512,
      lastActive: 'Today',
      role: 'Officer',
    ),
    _CitizenRecord(
      name: 'Bhavna Patel',
      email: 'b***@gmail.com',
      consumerId: 'GJ-8842-K',
      district: 'Bhavnagar',
      community: 'Hill Drive Society',
      points: 95,
      units: 18,
      lastActive: 'Inactive',
    ),
  ];

  String _query = '';
  String _district = 'All Gujarat';
  _CitizenRecord? _selected;

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live citizen directory is not connected',
        message:
            'Citizen directory, household meter details, and account actions are not available in this build. No sample citizen data is shown for live accounts.',
      );
    }
    final rows = _records
        .where((r) =>
            (_district == 'All Gujarat' || r.district == _district) &&
            ('${r.name} ${r.email} ${r.consumerId} ${r.community} ${r.district}')
                .toLowerCase()
                .contains(_query))
        .toList();
    return _WorkspacePage(
      title: 'Citizens',
      subtitle: 'Mission LiFE Gujarat Energy Directory · sample records',
      actions: [
        OutlinedButton.icon(
          onPressed: () => showAppSnack(
            context,
            'Citizen export is unavailable until a directory service is connected.',
            icon: Icons.info_outline_rounded,
          ),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
        ),
      ],
      children: [
        _WorkspaceStats(items: [
          ('Sample citizens', '6', Icons.people_alt_outlined),
          ('Active this month', '5', Icons.person_outline_rounded),
          ('Inactive sample', '1', Icons.person_off_outlined),
          ('Community captains', '1', Icons.shield_outlined),
        ]),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Citizen directory',
          trailing: Text('${rows.length} records',
              style: Theme.of(context).textTheme.labelMedium),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _SearchField(
                    hint: 'Search name, consumer ID, society…',
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                  DropdownButton<String>(
                    value: _district,
                    items: [
                      'All Gujarat',
                      ..._records.map((record) => record.district).toSet()
                    ]
                        .map((district) => DropdownMenuItem(
                            value: district, child: Text(district)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _district = value ?? 'All Gujarat'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('No citizens match these filters.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('CITIZEN')),
                      DataColumn(label: Text('CONSUMER ID')),
                      DataColumn(label: Text('DISTRICT')),
                      DataColumn(label: Text('SOCIETY / WARD')),
                      DataColumn(label: Text('POINTS')),
                      DataColumn(label: Text('UNITS SAVED')),
                      DataColumn(label: Text('LAST ACTIVE')),
                      DataColumn(label: Text('ROLE')),
                    ],
                    rows: rows
                        .map((record) => DataRow(
                              onSelectChanged: (_) =>
                                  setState(() => _selected = record),
                              cells: [
                                DataCell(Row(
                                  children: [
                                    Avatar(
                                        initials: _initials(record.name),
                                        size: 32),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(record.name),
                                        Text(record.email,
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelSmall),
                                      ],
                                    ),
                                  ],
                                )),
                                DataCell(Text('#${record.consumerId}')),
                                DataCell(Text(record.district)),
                                DataCell(Text(record.community)),
                                DataCell(Text('${record.points} pts')),
                                DataCell(Text('${record.units} kWh')),
                                DataCell(Text(record.lastActive)),
                                DataCell(Pill(
                                  label: record.role,
                                  color: AppColors.primarySoft,
                                  textColor: _workspaceGreen,
                                )),
                              ],
                            ))
                        .toList(),
                  ),
                ),
              if (_selected != null) ...[
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline_rounded,
                      color: _workspaceGreen),
                  title: Text('${_selected!.name} · ${_selected!.consumerId}'),
                  subtitle: Text(
                      '${_selected!.district} · ${_selected!.community} · ${_selected!.units} kWh saved'),
                  trailing: IconButton(
                    tooltip: 'Close details',
                    onPressed: () => setState(() => _selected = null),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _initials(String name) =>
      name.split(' ').map((part) => part[0]).take(2).join();
}

class AdminCommunitiesScreen extends StatefulWidget {
  const AdminCommunitiesScreen({super.key});

  @override
  State<AdminCommunitiesScreen> createState() => _AdminCommunitiesScreenState();
}

class _AdminCommunitiesScreenState extends State<AdminCommunitiesScreen> {
  String _query = '';
  String _type = 'All';
  String _district = 'All Gujarat';

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (state.useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live community administration is not connected',
        message:
            'Community creation, ward challenges, and captain assignments need a reviewed admin service. No live records are modified here.',
      );
    }
    final communities = MockData.communities.where((community) {
      final matchesType =
          _type == 'All' || community.type.toLowerCase() == _type.toLowerCase();
      final matchesDistrict =
          _district == 'All Gujarat' || community.district == _district;
      final matchesSearch =
          '${community.name} ${community.district} ${community.joinCode}'
              .toLowerCase()
              .contains(_query);
      return matchesType && matchesDistrict && matchesSearch;
    }).toList();
    final members = MockData.communities
        .fold<int>(0, (sum, item) => sum + item.memberCount);
    final units = MockData.communities
        .fold<double>(0, (sum, item) => sum + item.totalUnitsSaved);
    return _WorkspacePage(
      title: 'Communities & Challenges',
      subtitle:
          'Community energy collectives and ward-level demand-cut challenges',
      actions: [
        OutlinedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: const Text('Add Community'),
        ),
        FilledButton.icon(
          onPressed: () => _showChallengeDialog(context),
          icon: const Icon(Icons.flag_outlined),
          label: const Text('Create Challenge'),
        ),
      ],
      children: [
        _WorkspaceStats(items: [
          (
            'Communities',
            '${MockData.communities.length}',
            Icons.groups_outlined
          ),
          ('Citizens enrolled', '$members', Icons.people_alt_outlined),
          ('Units saved', '${Fmt.compact(units)} kWh', Icons.bolt_rounded),
          (
            'Active challenges',
            '${MockData.goals.length}',
            Icons.flag_outlined
          ),
        ]),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Community directory',
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 8,
                children: [
                  _SearchField(
                    hint: 'Search community, society, ward…',
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                  for (final type in [
                    'All',
                    'Society',
                    'Ward',
                    'Village',
                    'School'
                  ])
                    ChoiceChip(
                      label: Text(type),
                      selected: _type == type,
                      onSelected: (_) => setState(() => _type = type),
                    ),
                  DropdownButton<String>(
                    value: _district,
                    items: [
                      'All Gujarat',
                      ...MockData.communities
                          .map((community) => community.district)
                          .toSet()
                    ]
                        .map((district) => DropdownMenuItem(
                            value: district, child: Text(district)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _district = value ?? 'All Gujarat'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (communities.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('No communities match these filters.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('NAME & TYPE')),
                      DataColumn(label: Text('DISTRICT / PIN')),
                      DataColumn(label: Text('MEMBERS')),
                      DataColumn(label: Text('UNITS SAVED')),
                      DataColumn(label: Text('JOIN CODE')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTIONS')),
                    ],
                    rows: communities
                        .map((community) => DataRow(cells: [
                              DataCell(
                                  Text('${community.name}\n${community.type}')),
                              DataCell(Text(
                                  '${community.district} · ${community.pincode}')),
                              DataCell(Text('${community.memberCount}')),
                              DataCell(Text(
                                  '${Fmt.int(community.totalUnitsSaved.round())} kWh')),
                              DataCell(Text(community.joinCode)),
                              const DataCell(StatusTag(
                                  label: 'Demo',
                                  color: AppColors.success,
                                  dot: true)),
                              DataCell(IconButton(
                                tooltip: 'Copy join code',
                                onPressed: () => showAppSnack(
                                    context, 'Join code: ${community.joinCode}',
                                    icon: Icons.copy_rounded),
                                icon: const Icon(Icons.copy_rounded, size: 18),
                              )),
                            ]))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context) {
    final name = TextEditingController();
    final district = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add community · demo preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(label: 'Community name', controller: name),
            const SizedBox(height: 12),
            AppTextField(label: 'District', controller: district),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showAppSnack(
                context,
                'Community creation is a preview; it was not saved.',
                icon: Icons.info_outline_rounded,
              );
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    ).whenComplete(() {
      name.dispose();
      district.dispose();
    });
  }

  void _showChallengeDialog(BuildContext context) {
    final title = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create challenge · demo preview'),
        content: AppTextField(label: 'Challenge title', controller: title),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              showAppSnack(
                  context, 'Challenge creation is a preview; it was not saved.',
                  icon: Icons.info_outline_rounded);
            },
            child: const Text('Preview'),
          ),
        ],
      ),
    ).whenComplete(title.dispose);
  }
}

class _UtilitySubmission {
  _UtilitySubmission({
    required this.date,
    required this.name,
    required this.district,
    required this.utility,
    required this.provider,
    required this.consumer,
    required this.monthly,
  });

  final String date;
  final String name;
  final String district;
  final String utility;
  final String provider;
  final String consumer;
  final String monthly;
  String status = 'Pending';
}

class AdminUtilitiesScreen extends StatefulWidget {
  const AdminUtilitiesScreen({super.key});

  @override
  State<AdminUtilitiesScreen> createState() => _AdminUtilitiesScreenState();
}

class _AdminUtilitiesScreenState extends State<AdminUtilitiesScreen> {
  final _records = <_UtilitySubmission>[
    _UtilitySubmission(
        date: '28 Oct · 10:14',
        name: 'Nisha Patel',
        district: 'Ahmedabad',
        utility: 'LPG cylinder',
        provider: 'Indane Oil',
        consumer: 'SV-2847192048',
        monthly: '1 cylinder / mo'),
    _UtilitySubmission(
        date: '28 Oct · 09:40',
        name: 'Rajesh Shah',
        district: 'Surat',
        utility: 'PNG gas',
        provider: 'Gujarat Gas',
        consumer: 'GG-91048201',
        monthly: '18.5 SCM / mo'),
    _UtilitySubmission(
        date: '27 Oct · 16:15',
        name: 'Amit Trivedi',
        district: 'Vadodara',
        utility: 'Electricity bill',
        provider: 'MGVCL',
        consumer: 'MG-48291038',
        monthly: '212 kWh / mo'),
    _UtilitySubmission(
        date: '27 Oct · 14:20',
        name: 'Meena Joshi',
        district: 'Rajkot',
        utility: 'LPG cylinder',
        provider: 'Bharat Gas',
        consumer: 'SV-1094829102',
        monthly: '1 cylinder / mo'),
    _UtilitySubmission(
        date: '27 Oct · 11:30',
        name: 'Ravi Desai',
        district: 'Gandhinagar',
        utility: 'LPG cylinder',
        provider: 'HP Gas',
        consumer: 'SV-4720194821',
        monthly: '2 cylinders / mo'),
  ];
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live utility verification is not connected',
        message:
            'Utility proof, household identifiers, and credit approvals require a protected verification service. No live submissions or approval actions are available.',
      );
    }
    final rows = _records.where((record) {
      final matchesFilter = _filter == 'All' ||
          (_filter == 'Pending' && record.status == 'Pending') ||
          (_filter == 'Verified' && record.status == 'Verified') ||
          (_filter == 'Rejected' && record.status == 'Rejected');
      final matchesQuery =
          '${record.name} ${record.consumer} ${record.provider} ${record.district}'
              .toLowerCase()
              .contains(_query);
      return matchesFilter && matchesQuery;
    }).toList();
    return _WorkspacePage(
      title: 'Gas & Utility Verification Queue',
      subtitle:
          'Statutory utility-link review and subsidy-credit sign-off · sample queue',
      actions: [
        OutlinedButton.icon(
          onPressed: () => showAppSnack(
            context,
            'Utility export is unavailable until the verification service is connected.',
            icon: Icons.info_outline_rounded,
          ),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export CSV'),
        ),
      ],
      children: [
        _WorkspaceStats(items: [
          (
            'Pending',
            '${_records.where((r) => r.status == 'Pending').length}',
            Icons.pending_actions_rounded
          ),
          (
            'Verified',
            '${_records.where((r) => r.status == 'Verified').length}',
            Icons.verified_outlined
          ),
          (
            'Rejected',
            '${_records.where((r) => r.status == 'Rejected').length}',
            Icons.block_outlined
          ),
          ('Submissions', '${_records.length}', Icons.receipt_long_outlined),
        ]),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Queue ledger',
          trailing: const StatusTag(
              label: 'Demo records', color: AppColors.warning, dot: true),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final status in [
                    'All',
                    'Pending',
                    'Verified',
                    'Rejected'
                  ])
                    ChoiceChip(
                      label: Text(status),
                      selected: status == _filter,
                      onSelected: (_) => setState(() => _filter = status),
                    ),
                  _SearchField(
                    hint: 'Search citizen, consumer no.…',
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (rows.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('No utility submissions match this filter.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('SUBMITTED')),
                      DataColumn(label: Text('CITIZEN')),
                      DataColumn(label: Text('UTILITY')),
                      DataColumn(label: Text('PROVIDER')),
                      DataColumn(label: Text('CONSUMER / SV NO.')),
                      DataColumn(label: Text('DECLARED MONTHLY')),
                      DataColumn(label: Text('STATUS')),
                      DataColumn(label: Text('ACTION')),
                    ],
                    rows: rows.map((record) {
                      return DataRow(cells: [
                        DataCell(Text(record.date)),
                        DataCell(Text('${record.name}\n${record.district}')),
                        DataCell(Text(record.utility)),
                        DataCell(Text(record.provider)),
                        DataCell(Text(record.consumer)),
                        DataCell(Text(record.monthly)),
                        DataCell(StatusTag(
                          label: record.status,
                          color: record.status == 'Verified'
                              ? AppColors.success
                              : record.status == 'Rejected'
                                  ? AppColors.error
                                  : AppColors.warning,
                          dot: true,
                        )),
                        DataCell(record.status == 'Pending'
                            ? TextButton(
                                onPressed: () =>
                                    _reviewSubmission(context, record),
                                child: const Text('Inspect'),
                              )
                            : const Text('—')),
                      ]);
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _reviewSubmission(
      BuildContext context, _UtilitySubmission record) async {
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Review ${record.utility}'),
        content: Text(
            '${record.name} · ${record.district}\n${record.provider} · ${record.consumer}\n\nPreview action only. No documents or live utility account are attached.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, 'Rejected'),
              child: const Text('Reject preview')),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, 'Verified'),
              child: const Text('Approve preview')),
        ],
      ),
    );
    if (!mounted || result == null) return;
    setState(() => record.status = result);
    showAppSnack(
      context,
      'Demo record marked $result for this session only.',
      icon: Icons.info_outline_rounded,
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live reporting is not connected',
        message:
            'Statutory energy, subsidy, and carbon exports are not configured for live accounts in this build.',
      );
    }
    const reports = [
      (
        'Monthly Programme Summary',
        'GEDA-M-01',
        'District-level kWh saved, active households, and solar adoption.',
        Icons.assessment_outlined,
      ),
      (
        'District Verification Ledger',
        'GEDA-D-09',
        'Sample DISCOM meter and utility verification activity.',
        Icons.electric_meter_outlined,
      ),
      (
        'Solar Leads Conversion Funnel',
        'GEDA-S-04',
        'Vendor response times, lead status, and conversion overview.',
        Icons.solar_power_outlined,
      ),
      (
        'Community Engagement',
        'GEDA-C-12',
        'Community participation and challenge progress summary.',
        Icons.groups_outlined,
      ),
      (
        'Campaign Performance',
        'GEDA-N-08',
        'Nudge delivery and engagement report template.',
        Icons.campaign_outlined,
      ),
      (
        'Carbon Accounting',
        'GEDA-E-21',
        'Estimated emissions conversion using current app factors.',
        Icons.co2_outlined,
      ),
    ];
    return _WorkspacePage(
      title: 'Reports & Exports',
      subtitle: 'Programme reporting templates and statutory export workspace',
      actions: [
        OutlinedButton.icon(
          onPressed: () => showAppSnack(
              context, 'Report scheduling is unavailable in this demo build.',
              icon: Icons.info_outline_rounded),
          icon: const Icon(Icons.schedule_rounded),
          label: const Text('Schedule export'),
        ),
      ],
      children: [
        const InfoBanner(
          text:
              'Report cards are templates only. Generated PDF, CSV, and XLSX files require a configured reporting service.',
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Statutory & programme reports',
          trailing: const StatusTag(
              label: '6 templates', color: AppColors.primary, dot: true),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 3
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final width =
                  (constraints.maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final report in reports)
                    SizedBox(
                      width: width,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _workspaceBackground,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _workspaceBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                IconTile(
                                  icon: report.$4,
                                  color: _workspaceGreen,
                                  size: 40,
                                ),
                                const SizedBox(width: 10),
                                Text(report.$2,
                                    style:
                                        Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(report.$1,
                                style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 6),
                            Text(report.$3,
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: () => showAppSnack(
                                context,
                                '${report.$1}: report generation is not configured.',
                                icon: Icons.info_outline_rounded,
                              ),
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Generate'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class AdminAuditLogScreen extends StatefulWidget {
  const AdminAuditLogScreen({super.key});

  @override
  State<AdminAuditLogScreen> createState() => _AdminAuditLogScreenState();
}

class _AdminAuditLogScreenState extends State<AdminAuditLogScreen> {
  String _query = '';
  String _event = 'All events';

  static const _events = <List<String>>[
    [
      '28 Oct · 10:14',
      'K. Parmar',
      'Utility review',
      'Nisha Patel · LPG link',
      'Pending → reviewed (demo)',
    ],
    [
      '28 Oct · 09:52',
      'R. Mehta',
      'Lead status updated',
      'Lead LM-0214',
      'New → contacted',
    ],
    [
      '27 Oct · 16:30',
      'K. Parmar',
      'Task content edited',
      'Peak-hour task',
      'Draft preview created',
    ],
    [
      '27 Oct · 14:20',
      'A. Shah',
      'Campaign draft',
      'Evening energy reminder',
      'Draft saved in demo',
    ],
    [
      '26 Oct · 11:05',
      'K. Parmar',
      'Community record',
      'Shanti Nagar Society',
      'Directory viewed',
    ],
  ];

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live audit ledger is not connected',
        message:
            'This screen has no immutable server-side event stream. No demo activity is presented as a live statutory audit record.',
      );
    }
    final rows = _events.where((event) {
      final matchesQuery = event.join(' ').toLowerCase().contains(_query);
      final matchesEvent = _event == 'All events' || event[2] == _event;
      return matchesQuery && matchesEvent;
    }).toList();
    return _WorkspacePage(
      title: 'Audit Log & Security Ledger',
      subtitle: 'Administrative activity log · sample events only',
      actions: [
        OutlinedButton.icon(
          onPressed: () => showAppSnack(
            context,
            'Signed audit export requires a configured ledger service.',
            icon: Icons.info_outline_rounded,
          ),
          icon: const Icon(Icons.download_outlined),
          label: const Text('Export ledger'),
        ),
      ],
      children: [
        const InfoBanner(
          text:
              'Demo audit events are not immutable or cryptographically signed. Configure a server-side audit ledger before statutory use.',
          icon: Icons.shield_outlined,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Append-only verification log · demo',
          trailing: const StatusTag(
              label: 'Not integrity verified',
              color: AppColors.warning,
              dot: true),
          child: Column(
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _SearchField(
                    hint: 'Search actor, action, target…',
                    onChanged: (value) =>
                        setState(() => _query = value.trim().toLowerCase()),
                  ),
                  DropdownButton<String>(
                    value: _event,
                    items: [
                      'All events',
                      ..._events.map((event) => event[2]).toSet()
                    ]
                        .map((event) =>
                            DropdownMenuItem(value: event, child: Text(event)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _event = value ?? 'All events'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (rows.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(28),
                    child: Text('No audit events match these filters.'))
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('TIMESTAMP')),
                      DataColumn(label: Text('OFFICER / ACTOR')),
                      DataColumn(label: Text('ACTION TYPE')),
                      DataColumn(label: Text('TARGET ENTITY')),
                      DataColumn(label: Text('STATE CHANGE')),
                      DataColumn(label: Text('INTEGRITY')),
                    ],
                    rows: rows
                        .map((event) => DataRow(cells: [
                              DataCell(Text(event[0])),
                              DataCell(Text(event[1])),
                              DataCell(Text(event[2])),
                              DataCell(Text(event[3])),
                              DataCell(Text(event[4])),
                              const DataCell(Text('Demo only')),
                            ]))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _dailyCap = TextEditingController(text: '150');
  final _monthlyCap = TextEditingController(text: '2500');
  final _gridFactor = TextEditingController(text: '0.71');
  bool _quietHours = true;
  bool _requireReview = true;
  String _section = 'Programme & caps';

  @override
  void dispose() {
    _dailyCap.dispose();
    _monthlyCap.dispose();
    _gridFactor.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (AppScope.of(context).useFirebase) {
      return const AdminWorkspaceUnavailable(
        title: 'Live governance settings are read-only',
        message:
            'Saving statutory caps, emission factors, roles, or integrations is not connected to a reviewed configuration service.',
      );
    }
    return _WorkspacePage(
      title: 'Console Settings & Governance',
      subtitle:
          'Programme parameters, scoring rules, emission factors, and integrations',
      actions: [
        OutlinedButton.icon(
          onPressed: _reset,
          icon: const Icon(Icons.history_rounded),
          label: const Text('Revert'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save settings'),
        ),
      ],
      children: [
        const InfoBanner(
          text:
              'Settings are a local preview only and reset when this page is reloaded. No statutory configuration is changed.',
          icon: Icons.info_outline_rounded,
          color: AppColors.warning,
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 820;
            final sections = _WorkspacePanel(
              title: 'Config sections',
              child: Column(
                children: [
                  for (final section in [
                    'Programme & caps',
                    'Points & level tiers',
                    'Emission factors',
                    'Roles & console access',
                    'System integrations',
                    'DPDP data retention',
                  ])
                    ListTile(
                      dense: true,
                      selected: section == _section,
                      selectedTileColor: AppColors.primarySoft,
                      leading: Icon(_sectionIcon(section), size: 20),
                      title: Text(section),
                      onTap: () => setState(() => _section = section),
                    ),
                ],
              ),
            );
            final settings = _WorkspacePanel(
              title: _section,
              trailing: const StatusTag(
                  label: 'Draft · local preview',
                  color: AppColors.warning,
                  dot: true),
              child: _settingsFields(context),
            );
            return wide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: 260, child: sections),
                      const SizedBox(width: 16),
                      Expanded(child: settings),
                    ],
                  )
                : Column(
                    children: [
                      sections,
                      const SizedBox(height: 16),
                      settings,
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _settingsFields(BuildContext context) {
    if (_section == 'Programme & caps') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _numberSetting('Daily self-verified points cap', _dailyCap, 'pts'),
          _numberSetting('Monthly maximum points', _monthlyCap, 'pts'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _quietHours,
            onChanged: (value) => setState(() => _quietHours = value),
            title: const Text('Enforce quiet hours'),
            subtitle: const Text('10:00 PM – 07:00 AM IST'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _requireReview,
            onChanged: (value) => setState(() => _requireReview = value),
            title: const Text('Require second-officer review'),
            subtitle: const Text('For high-impact content changes'),
          ),
        ],
      );
    }
    if (_section == 'Emission factors') {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _numberSetting('Grid electricity factor', _gridFactor, 'kg CO₂/kWh'),
          const InfoBanner(
            text:
                'Reference value shown for preview. Confirm the current CEA baseline before statutory reporting.',
            icon: Icons.info_outline_rounded,
          ),
        ],
      );
    }
    return InfoBanner(
      text:
          '$_section is available as a design preview. No roles, integrations, retention rules, or point tiers are changed by this screen.',
      icon: Icons.info_outline_rounded,
    );
  }

  Widget _numberSetting(
      String label, TextEditingController controller, String suffix) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  IconData _sectionIcon(String section) => switch (section) {
        'Programme & caps' => Icons.verified_user_outlined,
        'Points & level tiers' => Icons.military_tech_outlined,
        'Emission factors' => Icons.co2_outlined,
        'Roles & console access' => Icons.admin_panel_settings_outlined,
        'System integrations' => Icons.hub_outlined,
        _ => Icons.shield_outlined,
      };

  void _reset() {
    _dailyCap.text = '150';
    _monthlyCap.text = '2500';
    _gridFactor.text = '0.71';
    setState(() {
      _quietHours = true;
      _requireReview = true;
    });
    showAppSnack(context, 'Preview values reverted.',
        icon: Icons.history_rounded);
  }

  void _save() {
    final daily = int.tryParse(_dailyCap.text);
    final monthly = int.tryParse(_monthlyCap.text);
    final factor = double.tryParse(_gridFactor.text);
    if (daily == null ||
        daily < 0 ||
        monthly == null ||
        monthly < 0 ||
        factor == null ||
        factor <= 0) {
      showAppSnack(context, 'Enter valid positive numeric settings.',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    showAppSnack(
      context,
      'Settings validated; preview values remain local to this session.',
      icon: Icons.info_outline_rounded,
    );
  }
}

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final _read = <int>{};
  String _filter = 'All';

  static const _items = [
    (
      'DISCOM telemetry delay',
      'MGVCL sync is delayed for the Vadodara demo telemetry feed.',
      'Critical alert',
      Icons.warning_amber_rounded,
      '/admin/reports',
    ),
    (
      'Solar lead SLA reminder',
      'Review sample leads awaiting vendor assignment.',
      'Lead SLA',
      Icons.solar_power_outlined,
      '/admin/leads',
    ),
    (
      'Utility verification queue',
      'Sample utility records are waiting for review.',
      'Verification',
      Icons.fact_check_outlined,
      '/admin/utilities',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final items = List.generate(_items.length, (index) => index)
        .where((index) =>
            _filter == 'All' ||
            (_filter == 'Unread' && !_read.contains(index)) ||
            _items[index].$3 == _filter)
        .toList();
    return _WorkspacePage(
      title: 'Notifications & Action Queue',
      subtitle: 'Operational alerts and review shortcuts · sample alerts',
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => _read.addAll(
                List.generate(_items.length, (index) => index),
              )),
          icon: const Icon(Icons.done_all_rounded),
          label: const Text('Mark all read'),
        ),
      ],
      children: [
        const InfoBanner(
          text:
              'These are sample notifications. Live telemetry and alert delivery are not connected.',
          icon: Icons.info_outline_rounded,
        ),
        const SizedBox(height: 16),
        _WorkspacePanel(
          title: 'Action queue',
          trailing: Text('${_items.length - _read.length} unread'),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                children: [
                  for (final filter in [
                    'All',
                    'Unread',
                    'Critical alert',
                    'Lead SLA',
                    'Verification',
                  ])
                    ChoiceChip(
                      label: Text(filter),
                      selected: _filter == filter,
                      onSelected: (_) => setState(() => _filter = filter),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No notifications in this filter.'),
                )
              else
                for (final index in items)
                  ListTile(
                    leading: IconTile(
                      icon: _items[index].$4,
                      color: _read.contains(index)
                          ? AppColors.textTertiary
                          : _workspaceGreen,
                      size: 40,
                    ),
                    title: Text(_items[index].$1),
                    subtitle: Text(_items[index].$2),
                    trailing: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (!_read.contains(index))
                          const StatusTag(
                              label: 'Unread',
                              color: AppColors.warning,
                              dot: true),
                        IconButton(
                          tooltip: 'Review',
                          onPressed: () {
                            setState(() => _read.add(index));
                            context.go(_items[index].$5);
                          },
                          icon: const Icon(Icons.arrow_forward_rounded),
                        ),
                      ],
                    ),
                    onTap: () => setState(() => _read.add(index)),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}
