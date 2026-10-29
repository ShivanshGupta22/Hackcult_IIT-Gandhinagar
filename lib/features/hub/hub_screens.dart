import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/widgets.dart';
import '../../data/app_state.dart';
import '../../data/mock_data.dart';
import '../../data/models.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final last = s.assessments.firstOrNull;
    final solarVendors = MockData.vendors
        .where((v) =>
            v.category == 'solar' && v.districts.contains(s.user!.district))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Solar & Schemes')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          AppCard(
            gradient: AppColors.solarAmber,
            border: false,
            onTap: () => context.push('/hub/solar'),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Is your roof solar-ready?',
                          style: t.titleLarge
                              ?.copyWith(color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('Free 2-minute check · subsidy & payback estimate',
                          style: t.bodySmall?.copyWith(
                              color: AppColors.textPrimary
                                  .withValues(alpha: 0.75))),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                            color: AppColors.textPrimary,
                            borderRadius: BorderRadius.circular(10)),
                        child: Text(
                            last == null
                                ? 'Calculate now  →'
                                : 'Re-calculate  →',
                            style: t.labelLarge?.copyWith(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.solar_power_rounded,
                    size: 72, color: Colors.white),
              ],
            ),
          ),
          if (last != null) ...[
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.push('/hub/solar/result/${last.id}'),
              child: Row(
                children: [
                  const IconTile(
                      icon: Icons.history_rounded,
                      color: AppColors.tertiary,
                      size: 44,
                      iconSize: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Last estimate · ${last.sizeKw.toStringAsFixed(1)} kW',
                            style: t.titleSmall),
                        Text(
                            'Net cost ${Fmt.rupees(last.netCost)} · payback ${_payback(last.paybackYears)}',
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
          const SizedBox(height: 20),
          SectionHeader(
              title: 'Schemes & subsidies',
              actionLabel: 'All',
              onAction: () => _showAllSchemes(context)),
          SizedBox(
            height: 150,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: MockData.schemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final sc = MockData.schemes[i];
                return SizedBox(
                  width: 210,
                  child: AppCard(
                    onTap: () => context.push('/hub/schemes/${sc.id}'),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconTile(
                            icon: sc.icon,
                            color: i.isEven
                                ? AppColors.primary
                                : AppColors.tertiary,
                            size: 36,
                            iconSize: 20,
                            radius: 10),
                        const Spacer(),
                        Text(sc.title,
                            style: t.titleSmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(sc.keyNumbers.first,
                            style: t.labelSmall?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(
              title: 'Empanelled vendors near you',
              subtitle: s.user!.district,
              actionLabel: 'See all',
              onAction: () => context.push('/hub/vendors')),
          if (solarVendors.isEmpty)
            AppCard(
              onTap: () => context.push('/hub/vendors'),
              child: Row(
                children: [
                  const IconTile(
                      icon: Icons.store_mall_directory_outlined,
                      color: AppColors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(
                          'No solar vendor listed for ${s.user!.district} yet. Browse all districts.',
                          style: t.bodyMedium)),
                ],
              ),
            )
          else
            for (final v in solarVendors.take(3))
              VendorCard(vendor: v, compact: true),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Learn'),
          Row(
            children: [
              Expanded(
                  child: _LearnTile(
                      icon: Icons.menu_book_rounded,
                      title: 'Read your bill',
                      color: AppColors.tertiary,
                      onTap: () =>
                          context.push('/hub/schemes/read_your_bill'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _LearnTile(
                      icon: Icons.schedule_rounded,
                      title: 'ToD tariff',
                      color: AppColors.warning,
                      onTap: () => context.push('/hub/schemes/tod_tariff'))),
              const SizedBox(width: 10),
              Expanded(
                  child: _LearnTile(
                      icon: Icons.electric_meter_rounded,
                      title: 'Net metering',
                      color: AppColors.primary,
                      onTap: () => context.push('/hub/schemes/net_metering'))),
            ],
          ),
        ],
      ),
    );
  }

  void _showAllSchemes(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
        children: [
          for (final sc in MockData.schemes)
            ListTile(
              leading: IconTile(
                  icon: sc.icon,
                  color: AppColors.primary,
                  size: 40,
                  iconSize: 20),
              title: Text(sc.title),
              subtitle: Text(sc.keyNumbers.first),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/hub/schemes/${sc.id}');
              },
            ),
        ],
      ),
    );
  }
}

String _payback(double? y) => y == null
    ? '—'
    : y < 1
        ? '< 1 yr'
        : '${y.toStringAsFixed(1)} yrs';

class _LearnTile extends StatelessWidget {
  const _LearnTile(
      {required this.icon,
      required this.title,
      required this.color,
      required this.onTap});
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
              icon: icon, color: color, size: 36, iconSize: 20, radius: 10),
          const SizedBox(height: 10),
          Text(title,
              style: Theme.of(context).textTheme.labelLarge, maxLines: 2),
        ],
      ),
    );
  }
}

class VendorCard extends StatelessWidget {
  const VendorCard(
      {super.key, required this.vendor, this.compact = false, this.onRequest});
  final Vendor vendor;
  final bool compact;
  final VoidCallback? onRequest;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cat = MockData.vendorCategories
        .firstWhere((c) => c.$1 == vendor.category, orElse: () => ('', 'Other'))
        .$2;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                  icon: _catIcon(vendor.category),
                  color: AppColors.primary,
                  size: 44,
                  iconSize: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vendor.name,
                        style: t.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.secondary),
                        Expanded(
                          child: Text(
                              ' ${vendor.rating}  ·  $cat  ·  ${vendor.districts.join(', ')}',
                              style: t.labelSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              StatusTag(
                  label: vendor.empanelledBy,
                  color: AppColors.tertiary,
                  icon: Icons.verified_rounded),
            ],
          ),
          if (!compact) ...[
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                if (vendor.pricePerKw != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text('~${Fmt.rupees(vendor.pricePerKw!)}/kW',
                        style:
                            t.labelLarge?.copyWith(color: AppColors.primary)),
                  ),
                TextButton.icon(
                  onPressed: () => showAppSnack(
                      context, 'Calling ${vendor.phone}…',
                      icon: Icons.call_rounded),
                  icon: const Icon(Icons.call_rounded, size: 18),
                  label: const Text('Call'),
                ),
                FilledButton(
                  onPressed: onRequest,
                  style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      padding: const EdgeInsets.symmetric(horizontal: 14)),
                  child: const Text('Request quote'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  IconData _catIcon(String c) => switch (c) {
        'solar' => Icons.solar_power_rounded,
        'led' => Icons.lightbulb_rounded,
        'solar_water_heater' => Icons.hot_tub_rounded,
        'ev_charging' => Icons.ev_station_rounded,
        'ewaste' => Icons.recycling_rounded,
        _ => Icons.store_rounded,
      };
}

// ---------------------------------------------------------------------------
// Solar calculator
// ---------------------------------------------------------------------------
class SolarCalculatorScreen extends StatefulWidget {
  const SolarCalculatorScreen({super.key});

  @override
  State<SolarCalculatorScreen> createState() => _SolarCalculatorScreenState();
}

class _SolarCalculatorScreenState extends State<SolarCalculatorScreen> {
  late final TextEditingController _units;
  double _roof = 30;
  bool _ownRoof = true;
  bool _scSt = false;
  bool _shadeFree = true;

  @override
  void initState() {
    super.initState();
    final u = AppScope.read(context).user!;
    _units = TextEditingController(
        text: u.baselineUnits > 0 ? u.baselineUnits.round().toString() : '');
    if (u.roofAccess == 'shared') _ownRoof = false;
  }

  @override
  void dispose() {
    _units.dispose();
    super.dispose();
  }

  Future<void> _calc() async {
    final units = double.tryParse(_units.text) ?? 0;
    if (units <= 0) {
      showAppSnack(context, 'Enter your monthly units',
          icon: Icons.error_outline_rounded, color: AppColors.error);
      return;
    }
    late final SolarAssessment a;
    try {
      a = await AppScope.read(context)
          .assess(monthlyUnits: units, roofAreaM2: _roof, scSt: _scSt);
    } catch (error) {
      if (!mounted) return;
      showAppSnack(
        context,
        'Could not save your task progress: $error',
        icon: Icons.error_outline_rounded,
        color: AppColors.error,
      );
      return;
    }
    if (!mounted) return;
    context.push('/hub/solar/result/${a.id}');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = AppScope.of(context);
    final units = double.tryParse(_units.text) ?? 0;
    final liveKw =
        units > 0 ? (units / 30 / s.config.solar.specificYield) : 0.0;
    final maxKw = _roof / s.config.solar.areaPerKw;

    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/hub'),
          title: const Text('Solar feasibility')),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Check your rooftop', style: t.headlineSmall),
            const SizedBox(height: 4),
            Text(
                'Estimates use PM Surya Ghar + Gujarat state subsidy rules (Oct 2026).',
                style: t.bodyMedium),
            const SizedBox(height: 20),
            AppTextField(
              label: 'Monthly electricity units',
              controller: _units,
              keyboardType: TextInputType.number,
              prefixIcon: Icons.bolt_rounded,
              hint: 'e.g. 250',
              helper: units > 0
                  ? 'Suggested system ≈ ${liveKw.toStringAsFixed(1)} kW'
                  : 'From your latest bill',
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: Text('Usable roof area', style: t.titleSmall)),
                Text(
                    '${_roof.round()} m² · fits ${maxKw.toStringAsFixed(1)} kW',
                    style: t.labelMedium?.copyWith(color: AppColors.primary)),
              ],
            ),
            Slider(
                value: _roof,
                min: 5,
                max: 120,
                divisions: 23,
                label: '${_roof.round()} m²',
                onChanged: (v) => setState(() => _roof = v)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                    child: Text('5 m² (balcony)',
                        style: t.labelSmall, overflow: TextOverflow.ellipsis)),
                Flexible(
                    child: Text('120 m² (bungalow)',
                        style: t.labelSmall, overflow: TextOverflow.ellipsis))
              ],
            ),
            const SizedBox(height: 16),
            Text('Roof details', style: t.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                    child: SelectableTile(
                        label: 'Own roof',
                        icon: Icons.home_rounded,
                        selected: _ownRoof,
                        onTap: () => setState(() => _ownRoof = true),
                        compact: true)),
                const SizedBox(width: 10),
                Expanded(
                    child: SelectableTile(
                        label: 'Shared / society',
                        icon: Icons.apartment_rounded,
                        selected: !_ownRoof,
                        onTap: () => setState(() => _ownRoof = false),
                        compact: true)),
              ],
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Roof is mostly shade-free'),
              subtitle:
                  const Text('No tall buildings/trees blocking south side'),
              value: _shadeFree,
              onChanged: (v) => setState(() => _shadeFree = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('SC / ST household'),
              subtitle:
                  const Text('Higher Gujarat state subsidy (consumer pays 5%)'),
              value: _scSt,
              onChanged: (v) => setState(() => _scSt = v),
            ),
            if (!_ownRoof) ...[
              const SizedBox(height: 8),
              const InfoBanner(
                  text:
                      'Shared roofs qualify under the Group Housing Society route — common-area loads up to 500 kW. Your society captain can apply.',
                  icon: Icons.groups_rounded),
            ],
            if (!_shadeFree) ...[
              const SizedBox(height: 8),
              const InfoBanner(
                  text:
                      'Shading can cut generation by 20–40%. A vendor site survey will confirm the exact yield.',
                  icon: Icons.wb_shade_rounded,
                  color: AppColors.warning),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
                label: 'Calculate savings',
                icon: Icons.calculate_rounded,
                onPressed: _calc),
            const SizedBox(height: 10),
            Center(
                child: Text(
                    'Indicative only · final figures from vendor & DISCOM',
                    style: t.labelSmall)),
          ],
        ),
      ),
    );
  }
}

class SolarResultScreen extends StatelessWidget {
  const SolarResultScreen({super.key, required this.assessmentId});
  final String assessmentId;

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final t = Theme.of(context).textTheme;
    final a = s.assessmentById(assessmentId);
    if (a == null) {
      return Scaffold(
          appBar: AppBar(
            leading: const SafeBackButton(fallback: '/hub'),
          ),
          body: EmptyState(
              icon: Icons.solar_power_outlined,
              title: 'Estimate not found',
              body: 'Run the calculator again',
              actionLabel: 'Open calculator',
              onAction: () => context.go('/hub/solar')));
    }
    final subsidyPct = a.grossCost == 0
        ? 0
        : ((a.centralSubsidy + a.stateSubsidy) / a.grossCost * 100).round();
    final hasLead = s.myLeads.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your solar estimate'),
        actions: [
          IconButton(
              onPressed: () => showAppSnack(
                  context, 'Estimate PDF shared (demo)',
                  icon: Icons.share_rounded),
              icon: const Icon(Icons.ios_share_rounded))
        ],
      ),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              gradient: AppColors.solarAmber,
              border: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recommended system',
                      style: t.labelMedium?.copyWith(
                          color: AppColors.textPrimary.withValues(alpha: 0.7))),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CountUpText(
                                  value: a.sizeKw,
                                  decimals: 1,
                                  style: t.displaySmall!
                                      .copyWith(color: AppColors.textPrimary)),
                              Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8, left: 4),
                                  child: Text('kW rooftop',
                                      style: t.titleMedium?.copyWith(
                                          color: AppColors.textPrimary))),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.solar_power_rounded,
                          size: 56, color: Colors.white),
                    ],
                  ),
                  Text(
                      'Generates ≈ ${Fmt.int(a.annualGenUnits)} units / year · covers your ${Fmt.int(a.monthlyUnits)} units / month',
                      style:
                          t.bodySmall?.copyWith(color: AppColors.textPrimary)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child:
                              Text('Cost after subsidy', style: t.titleMedium)),
                      StatusTag(
                          label: '$subsidyPct% subsidised',
                          color: AppColors.success,
                          icon: Icons.savings_rounded),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _CostRow(
                      label: 'System cost (benchmark)',
                      value: Fmt.rupees(a.grossCost)),
                  _CostRow(
                      label: 'Central subsidy (PM Surya Ghar)',
                      value: '− ${Fmt.rupees(a.centralSubsidy)}',
                      color: AppColors.success),
                  _CostRow(
                      label: 'Gujarat state subsidy',
                      value: '− ${Fmt.rupees(a.stateSubsidy)}',
                      color: AppColors.success,
                      note: a.stateSubsidy == 0
                          ? 'Only for systems ≤ 2.18 kW'
                          : null),
                  const Divider(height: 24),
                  Row(
                    children: [
                      Expanded(child: Text('You pay', style: t.titleMedium)),
                      Text(Fmt.rupees(a.netCost),
                          style: t.headlineSmall
                              ?.copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      height: 14,
                      child: Row(
                        children: [
                          Expanded(
                              flex: (a.centralSubsidy * 100)
                                  .round()
                                  .clamp(1, 1 << 20),
                              child: Container(color: AppColors.success)),
                          Expanded(
                              flex: (a.stateSubsidy * 100)
                                  .round()
                                  .clamp(1, 1 << 20),
                              child: Container(color: AppColors.primaryLight)),
                          Expanded(
                              flex: (a.netCost * 100).round().clamp(1, 1 << 20),
                              child: Container(color: AppColors.secondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 14,
                    children: const [
                      _Legend(color: AppColors.success, label: 'Central'),
                      _Legend(color: AppColors.primaryLight, label: 'State'),
                      _Legend(color: AppColors.secondary, label: 'You pay'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: StatCard(
                        icon: Icons.currency_rupee_rounded,
                        value: Fmt.rupees(a.annualSavings),
                        label: 'saved / year',
                        dense: true)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatCard(
                        icon: Icons.timelapse_rounded,
                        iconColor: AppColors.tertiary,
                        value: _payback(a.paybackYears),
                        label: 'payback',
                        dense: true)),
                const SizedBox(width: 10),
                Expanded(
                    child: StatCard(
                        icon: Icons.forest_rounded,
                        iconColor: AppColors.success,
                        value: Fmt.tonnes(a.co2Avoided25yKg),
                        label: 'CO₂ / 25 yrs',
                        dense: true)),
              ],
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('25-year view', style: t.titleSmall),
                  const SizedBox(height: 10),
                  _Bar(
                      label: 'Lifetime savings',
                      value: a.annualSavings * 25 * 0.9,
                      max: a.annualSavings * 25,
                      color: AppColors.primary),
                  _Bar(
                      label: 'Your investment',
                      value: a.netCost,
                      max: a.annualSavings * 25,
                      color: AppColors.secondary),
                  const SizedBox(height: 6),
                  Text(
                      'Assumes 4.2 units/kW/day, 10% degradation over life, ₹${s.config.avgTariffPerUnit.toStringAsFixed(1)}/unit tariff.',
                      style: t.labelSmall),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label:
                  hasLead ? 'Survey requested ✓' : 'Request free site survey',
              icon: Icons.engineering_rounded,
              onPressed: hasLead
                  ? null
                  : () => showRequestSurveySheet(context, assessment: a),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
                label: 'Compare empanelled vendors',
                icon: Icons.storefront_rounded,
                onPressed: () => context.push('/hub/vendors')),
            const SizedBox(height: 10),
            TextButton(
                onPressed: () => context.push('/hub/schemes/pm_surya_ghar'),
                child: const Text('How does the subsidy work?')),
          ],
        ),
      ),
    );
  }
}

class _CostRow extends StatelessWidget {
  const _CostRow(
      {required this.label, required this.value, this.color, this.note});
  final String label;
  final String value;
  final Color? color;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: t.bodyMedium),
                if (note != null)
                  Text(note!,
                      style: t.labelSmall?.copyWith(color: AppColors.warning))
              ],
            ),
          ),
          Text(value, style: t.titleSmall?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 5),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar(
      {required this.label,
      required this.value,
      required this.max,
      required this.color});
  final String label;
  final double value;
  final double max;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(label, style: t.labelMedium)),
            Text(Fmt.rupees(value), style: t.labelLarge)
          ]),
          const SizedBox(height: 4),
          GoalProgressBar(
              value: max == 0 ? 0 : (value / max).clamp(0.02, 1),
              color: color,
              height: 8),
        ],
      ),
    );
  }
}

Future<void> showRequestSurveySheet(BuildContext context,
    {SolarAssessment? assessment, Vendor? vendor}) async {
  final s = AppScope.read(context);
  final phone = TextEditingController();
  var consent = false;
  var slot = 'Weekday morning';
  var submitting = false;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        final t = Theme.of(ctx).textTheme;
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 0, 24, 24 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  vendor == null
                      ? 'Request free site survey'
                      : 'Request quote from ${vendor.name}',
                  style: t.titleLarge),
              const SizedBox(height: 6),
              Text(
                  s.useFirebase
                      ? 'Your request will be saved to your account. Vendor contact is not connected yet; your details will not be sent automatically.'
                      : 'A GEDA-empanelled vendor will visit, verify roof & shading, and share a final quote. No obligation.',
                  style: t.bodyMedium),
              const SizedBox(height: 16),
              AppTextField(
                  label: 'Contact number',
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.call_outlined,
                  hint: '10-digit mobile',
                  maxLength: 10),
              const SizedBox(height: 12),
              Text('Preferred visit slot', style: t.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final sl in const [
                    'Weekday morning',
                    'Weekday evening',
                    'Weekend'
                  ])
                    ChoiceChip(
                        label: Text(sl),
                        selected: slot == sl,
                        onSelected: (_) => setSt(() => slot = sl)),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: consent,
                onChanged: (v) => setSt(() => consent = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                    s.useFirebase
                        ? 'Save my contact number, preferred time and estimate with this account'
                        : 'Share my name, district & estimate with GEDA and the vendor',
                    style: t.bodySmall),
              ),
              const SizedBox(height: 8),
              PrimaryButton(
                label: submitting
                    ? 'Saving...'
                    : s.useFirebase
                        ? 'Save request'
                        : 'Submit request  · +${s.config.solarLeadPoints} pts',
                onPressed:
                    consent && phone.text.trim().length == 10 && !submitting
                        ? () async {
                            setSt(() => submitting = true);
                            try {
                              await s.requestSurvey(
                                  assessment: assessment,
                                  vendor: vendor,
                                  phone: phone.text.trim(),
                                  preferredSlot: slot,
                                  type: vendor == null ? 'survey' : 'quote');
                              if (!ctx.mounted) return;
                              Navigator.pop(ctx);
                              if (s.useFirebase) {
                                showAppSnack(
                                  context,
                                  'Request saved to your account. Vendor contact is not connected yet.',
                                  icon: Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                );
                              } else {
                                showConfetti(context);
                                showAppSnack(context,
                                    'Request sent! Vendor will call within 2 working days.',
                                    icon: Icons.check_circle_rounded,
                                    color: AppColors.primary);
                              }
                            } catch (error) {
                              if (!context.mounted) return;
                              showAppSnack(
                                context,
                                'Could not save your request: $error',
                                icon: Icons.error_outline_rounded,
                                color: AppColors.error,
                              );
                            } finally {
                              if (ctx.mounted) setSt(() => submitting = false);
                            }
                          }
                        : null,
              ),
              const SizedBox(height: 4),
              Center(
                  child: TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Maybe later'))),
            ],
          ),
        );
      },
    ),
  );
  phone.dispose();
}

// ---------------------------------------------------------------------------
// Vendors
// ---------------------------------------------------------------------------
class VendorsScreen extends StatefulWidget {
  const VendorsScreen({super.key});

  @override
  State<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends State<VendorsScreen> {
  String _cat = 'solar';
  late String _district = AppScope.read(context).user!.district;
  bool _allDistricts = false;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final list = MockData.vendors
        .where((v) =>
            v.category == _cat &&
            (_allDistricts || v.districts.contains(_district)))
        .toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));

    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/hub'),
          title: const Text('Empanelled vendors')),
      body: PhoneFrame(
        child: Column(
          children: [
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final c in MockData.vendorCategories)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                          label: Text(c.$2),
                          selected: _cat == c.$1,
                          onSelected: (_) => setState(() => _cat = c.$1)),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _district,
                        isDense: true,
                        isExpanded: true,
                        style: t.labelLarge
                            ?.copyWith(color: AppColors.textPrimary),
                        items: [
                          for (final d in MockData.gujaratDistricts)
                            DropdownMenuItem(value: d, child: Text(d))
                        ],
                        onChanged: _allDistricts
                            ? null
                            : (v) => setState(() => _district = v!),
                      ),
                    ),
                  ),
                  FilterChip(
                      label: const Text('All Gujarat'),
                      selected: _allDistricts,
                      onSelected: (v) => setState(() => _allDistricts = v)),
                ],
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      icon: Icons.storefront_outlined,
                      title: 'No vendors here yet',
                      body: 'Try "All Gujarat" or another category',
                      actionLabel: 'Show all Gujarat',
                      onAction: () => setState(() => _allDistricts = true))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        const InfoBanner(
                            text:
                                'All vendors are empanelled by GEDA / MNRE / DISCOM. Prices are indicative; pay only after a written quote.',
                            icon: Icons.verified_user_outlined),
                        const SizedBox(height: 12),
                        for (final v in list)
                          VendorCard(
                              vendor: v,
                              onRequest: () => showRequestSurveySheet(context,
                                  vendor: v,
                                  assessment: AppScope.read(context)
                                      .assessments
                                      .firstOrNull)),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Scheme detail
// ---------------------------------------------------------------------------
class SchemeDetailScreen extends StatelessWidget {
  const SchemeDetailScreen({super.key, required this.schemeId});
  final String schemeId;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sc = MockData.schemeById(schemeId);
    return Scaffold(
      appBar: AppBar(
          leading: const SafeBackButton(fallback: '/hub'),
          title: Text(sc.title, overflow: TextOverflow.ellipsis)),
      body: PhoneFrame(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              children: [
                IconTile(
                    icon: sc.icon,
                    color: AppColors.primary,
                    size: 56,
                    iconSize: 28),
                const SizedBox(width: 14),
                Expanded(child: Text(sc.title, style: t.headlineSmall)),
              ],
            ),
            const SizedBox(height: 12),
            Text(sc.summary, style: t.bodyLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final k in sc.keyNumbers)
                  Pill(
                      label: k,
                      color: AppColors.primarySoft,
                      textColor: AppColors.primary,
                      icon: Icons.check_circle_rounded)
              ],
            ),
            const SizedBox(height: 20),
            _Section(
                title: 'Who is eligible',
                icon: Icons.how_to_reg_rounded,
                items: sc.eligibility,
                numbered: false),
            const SizedBox(height: 16),
            _Section(
                title: 'How to apply',
                icon: Icons.format_list_numbered_rounded,
                items: sc.steps,
                numbered: true),
            const SizedBox(height: 20),
            PrimaryButton(
                label: 'Open official site',
                icon: Icons.open_in_new_rounded,
                onPressed: () => showAppSnack(
                    context, 'Opens ${sc.officialUrl} (url_launcher)',
                    icon: Icons.link_rounded)),
            if (schemeId == 'pm_surya_ghar' ||
                schemeId == 'gujarat_state_subsidy') ...[
              const SizedBox(height: 10),
              SecondaryButton(
                  label: 'Check my eligibility & savings',
                  icon: Icons.calculate_rounded,
                  onPressed: () => context.push('/hub/solar')),
            ],
            const SizedBox(height: 16),
            Text(
                'Source: GEDA / MNRE notifications. Figures as of Oct 2026 — verify on the official portal before applying.',
                style: t.labelSmall),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title,
      required this.icon,
      required this.items,
      required this.numbered});
  final String title;
  final IconData icon;
  final List<String> items;
  final bool numbered;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(title, style: t.titleMedium)
          ]),
          const SizedBox(height: 10),
          for (var i = 0; i < items.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  numbered
                      ? Container(
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
                        )
                      : const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(Icons.check_rounded,
                              size: 16, color: AppColors.success)),
                  const SizedBox(width: 10),
                  Expanded(child: Text(items[i], style: t.bodyMedium)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
